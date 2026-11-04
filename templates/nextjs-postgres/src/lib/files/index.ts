import "server-only";
import { randomUUID } from "node:crypto";
import type { DatabaseIdentity } from "../db/identity";
import { withDatabase } from "../db/with-database";
import { storageConfig, storageScope } from "./config";
import { s3Storage } from "./adapters/s3";
import { azureBlobStorage } from "./adapters/azure-blob";

export interface FileRecord { id: string; owner_id: string; title: string }

// Create on the server; the identity must come from a verified server session.
export function files() {
  const config = storageConfig();
  const scope = storageScope(config);
  const storage = config.adapter === "s3" ? s3Storage(config) : azureBlobStorage(config);
  const key = (id: string) => `files/${id}`;
  const columns = ["id", "owner_id", "title"] as const;
  return {
    async save(identity: DatabaseIdentity, title: string, bytes: Uint8Array): Promise<FileRecord> {
      const id = randomUUID();
      // A failed upload rolls back metadata. An interrupted operation can leave a private orphan.
      return withDatabase(identity, async (db) => {
        const record = await db.insertInto("files").values({ id, owner_id: identity.userId, title, storage_scope: scope })
          .returning(columns).executeTakeFirstOrThrow();
        await storage.save(key(id), bytes);
        return record;
      });
    },
    async fetch(identity: DatabaseIdentity, id: string): Promise<Uint8Array> {
      return withDatabase(identity, async (db) => {
        await db.selectFrom("files").select("id").where("id", "=", id).where("storage_scope", "=", scope)
          .executeTakeFirstOrThrow(() => new Error("File is unavailable"));
        return storage.fetch(key(id));
      });
    },
    async temporaryLink(identity: DatabaseIdentity, id: string): Promise<string> {
      return withDatabase(identity, async (db) => {
        await db.selectFrom("files").select("id").where("id", "=", id).where("storage_scope", "=", scope)
          .executeTakeFirstOrThrow(() => new Error("File is unavailable"));
        return storage.temporaryLink(key(id), config.linkSeconds);
      });
    },
    async delete(identity: DatabaseIdentity, id: string): Promise<void> {
      return withDatabase(identity, async (db) => {
        await db.deleteFrom("files").where("id", "=", id).where("storage_scope", "=", scope).returning("id")
          .executeTakeFirstOrThrow(() => new Error("File is unavailable"));
        await storage.delete(key(id));
      });
    },
    async list(identity: DatabaseIdentity): Promise<FileRecord[]> {
      return withDatabase(identity, (db) => db.selectFrom("files").select(columns)
        .where("storage_scope", "=", scope).orderBy("id").execute());
    },
  };
}
