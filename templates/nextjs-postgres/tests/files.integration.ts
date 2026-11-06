import { randomBytes, randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, test, vi } from "vitest";
import { createSignIn } from "../src/lib/sign-in/service";
import { stubProvider } from "./support/oidc";
import type { DatabaseIdentity } from "../src/lib/db/identity";
import { createQueue } from "../src/lib/jobs/queue";
import { jobIdentity } from "../src/lib/jobs/identity";
import { files } from "../src/lib/files";
import { storageConfig } from "../src/lib/files/config";
import { s3Storage } from "../src/lib/files/adapters/s3";
import { azureBlobStorage } from "../src/lib/files/adapters/azure-blob";
import { appRoles } from "../src/lib/db/identity";
import { withDatabase } from "../src/lib/db/with-database";
import { testIdentity } from "./support/identity";
import { inspect } from "./support/database";

// The assertions are identical for both real emulator services, with no SDK mocks.
describe.each(["s3", "azure-blob"])("%s storage contract", (adapter) => {
  let auth: ReturnType<typeof createSignIn>;
  let stub: Awaited<ReturnType<typeof stubProvider>>;
  let owner: DatabaseIdentity;
  let other: DatabaseIdentity;
  let ownerHeaders: Headers;
  let ownerId: string;
  beforeAll(async () => {
    vi.stubEnv("FILES_ADAPTER", adapter);
    vi.stubEnv("FILES_LINK_SECONDS", "2");
    stub = await stubProvider();
    const baseURL = "https://tool.example.test";
    auth = createSignIn({ baseURL, secret: randomBytes(32).toString("hex"),
      databaseURL: process.env.AUTH_DATABASE_URL!, directory: { provider: "google", issuer: stub.issuer,
        domain: "example.test", clientId: "stub-client", clientSecret: randomUUID() } }, async () => {});
    const cookies = (response: Response) => response.headers.getSetCookie()
      .map((cookie) => cookie.split(";")[0]).join("; ");
    const signIn = async () => {
      stub.setClaims({ hd: "example.test", email: `${randomUUID()}@example.test`, sub: randomUUID(), email_verified: true });
      const start = await auth.handler(new Request(`${baseURL}/api/auth/sign-in/social`, {
        method: "POST", headers: { "Content-Type": "application/json", Origin: baseURL },
        body: JSON.stringify({ provider: "google", callbackURL: "/" }),
      }));
      expect(start.status).toBe(200);
      const redirect = await fetch((await start.json()).url, { redirect: "manual" });
      const callback = await auth.handler(new Request(redirect.headers.get("location")!, {
        headers: { Cookie: cookies(start) },
      }));
      const headers = new Headers({ Cookie: cookies(callback) });
      const identity = await auth.identity(headers);
      expect(identity?.role).toBe("member");
      return { headers, identity: identity! };
    };
    const signedIn = await signIn();
    owner = signedIn.identity;
    ownerHeaders = signedIn.headers;
    ownerId = owner.userId;
    other = (await signIn()).identity;
  });
  afterAll(async () => { await auth?.close(); await stub?.close(); });
  const body = new Uint8Array([0, 1, 2, 128, 255]);
  function raw() {
    const config = storageConfig();
    return config.adapter === "s3" ? s3Storage(config) : azureBlobStorage(config);
  }

  test("a queued file handler uses the port and database identity without inheriting queue privileges", async () => {
    const port = files();
    const file = await port.save(owner, "Job input", body);
    const queue = createQueue();
    await queue.start();
    try {
      const id = (await queue.send("slow-document", { fileId: file.id }))!;
      const [job] = await queue.fetch<{ fileId: string }>("slow-document", { includeMetadata: true });
      expect(job.id).toBe(id);
      // The session supplies the actor separately from the untrusted job payload.
      const handle = async (identity: typeof owner) => {
        const bytes = await port.fetch(identity, job.data.fileId);
        await withDatabase(identity, (db) => db.insertInto("records")
          .values({ id: job.id, owner_id: identity.userId, title: `File bytes: ${bytes.length}` })
          .onConflict((conflict) => conflict.column("id").doNothing()).execute());
      };
      await expect(handle(jobIdentity)).rejects.toThrow("File is unavailable");
      await expect(handle(other)).rejects.toThrow("File is unavailable");
      await handle((await auth.identity(ownerHeaders))!);
      await handle((await auth.identity(ownerHeaders))!);
      await queue.complete("slow-document", job);
      const output = await withDatabase(owner, (db) => db.selectFrom("records").selectAll()
        .where("id", "=", id).execute());
      expect(output).toEqual([{ id, owner_id: ownerId, title: `File bytes: ${body.length}` }]);
      const audit = await inspect((client) => client.query("select actor_id, actor_role from audit.events where record_id=$1", [id]));
      expect(audit.rows).toEqual([{ actor_id: ownerId, actor_role: "member" }]);
    } finally { await queue.stop(); await port.delete(owner, file.id); }
  });

  test("current session roles govern file access and queued effects", async () => {
    const port = files();
    const file = await port.save(owner, "Session role", body);
    const queue = createQueue();
    await queue.start();
    try {
      const id = (await queue.send("slow-document", { fileId: file.id, role: "admin", userId: other.userId }))!;
      const [job] = await queue.fetch<{ fileId: string }>("slow-document", { includeMetadata: true });
      const handle = async () => {
        const identity = await auth.identity(ownerHeaders);
        if (!identity) throw new Error("Sign-in required");
        await port.fetch(identity, job.data.fileId);
        await withDatabase(identity, (db) => db.insertInto("records")
          .values({ id, owner_id: identity.userId, title: "Session job" }).execute());
      };
      for (const role of ["viewer", "unassigned"] as const) {
        await inspect((client) => client.query('UPDATE sign_in."user" SET role=$1 WHERE id=$2', [role, ownerId]));
        const identity = (await auth.identity(ownerHeaders))!;
        expect(identity.role).toBe(role);
        if (role === "viewer") {
          expect(new Uint8Array(await port.fetch(identity, file.id))).toEqual(body);
          expect((await fetch(await port.temporaryLink(identity, file.id))).status).toBe(200);
          await expect(handle()).rejects.toMatchObject({ code: "42501" });
        } else {
          await expect(port.temporaryLink(identity, file.id)).rejects.toThrow("File is unavailable");
          await expect(handle()).rejects.toThrow("File is unavailable");
        }
        await expect(port.save(identity, "Denied", body)).rejects.toMatchObject({ code: "42501" });
      }
      await inspect((client) => client.query('UPDATE sign_in."user" SET role=$1 WHERE id=$2', ["member", ownerId]));
      await handle();
      const audit = await inspect((client) => client.query('SELECT actor_id, actor_role FROM audit.events WHERE record_id=$1', [id]));
      expect(audit.rows).toEqual([{ actor_id: ownerId, actor_role: "member" }]);
      await queue.complete("slow-document", job);
    } finally {
      await inspect((client) => client.query('UPDATE sign_in."user" SET role=$1 WHERE id=$2', ["member", ownerId]));
      await queue.stop();
      await port.delete(owner, file.id);
    }
  });

  test("all five adapter actions round-trip binary content and filter listing by prefix", async () => {
    const storage = raw();
    const prefix = `contract/${randomUUID()}/`;
    const key = `${prefix}file with spaces`;
    await storage.save(key, body);
    await storage.save(`${prefix}empty`, new Uint8Array());
    expect(new Uint8Array(await storage.fetch(key))).toEqual(body);
    expect((await storage.fetch(`${prefix}empty`)).byteLength).toBe(0);
    expect((await storage.list(prefix)).sort((a, b) => a.key.localeCompare(b.key))).toEqual([
      { key: `${prefix}empty`, size: 0 }, { key, size: body.length },
    ]);
    expect(await storage.list(`${prefix}absent`)).toEqual([]);
    const url = await storage.temporaryLink(key, 10);
    const response = await fetch(url);
    expect(response.status).toBe(200);
    expect(new Uint8Array(await response.arrayBuffer())).toEqual(body);
    expect(response.headers.get("cache-control")).toBe("no-store");
    expect(response.headers.get("content-disposition")).toBe("attachment");
    await storage.delete(key);
    await storage.delete(key);
    expect(await storage.list(prefix)).toEqual([{ key: `${prefix}empty`, size: 0 }]);
    await expect(storage.fetch(key)).rejects.toThrow();
  });

  test("a signed read link cannot overwrite content or be moved to another key", async () => {
    const port = files();
    const file = await port.save(owner, "Read only", body);
    const url = await port.temporaryLink(owner, file.id);
    expect([401, 403]).toContain((await fetch(url, { method: "PUT", headers: { "x-ms-blob-type": "BlockBlob" }, body: "changed" })).status);
    const changed = new URL(url);
    changed.pathname += "-another-file";
    expect([401, 403, 404]).toContain((await fetch(changed)).status);
    expect(new Uint8Array(await port.fetch(owner, file.id))).toEqual(body);
    await port.delete(owner, file.id);
  });

  test("an upload failure leaves no readable metadata", async () => {
    const setting = adapter === "s3" ? "FILES_S3_BUCKET" : "FILES_AZURE_CONTAINER";
    const previous = process.env[setting]!;
    const identity = testIdentity(randomUUID(), "member");
    vi.stubEnv(setting, "missing-private-store");
    try {
      const port = files();
      await expect(port.save(identity, "Failed upload", body)).rejects.toThrow();
      expect(await port.list(identity)).toEqual([]);
      const rows = await withDatabase(identity, (db) => db.selectFrom("files").select("id")
        .where("owner_id", "=", identity.userId).execute());
      expect(rows).toEqual([]);
    } finally { vi.stubEnv(setting, previous); }
  });

  test("list follows continuation pages", async () => {
    const storage = raw();
    const prefix = `pages/${randomUUID()}/`;
    const keys = Array.from({ length: 1001 }, (_, i) => `${prefix}${String(i).padStart(4, "0")}`);
    for (let i = 0; i < keys.length; i += 25) {
      await Promise.all(keys.slice(i, i + 25).map((key) => storage.save(key, body)));
    }
    expect((await storage.list(prefix)).map((object) => object.key).sort()).toEqual(keys);
  });

  test("unsigned GET, HEAD and bucket or container listing cannot expose a saved file", async () => {
    const port = files();
    const file = await port.save(owner, "Private file", body);
    const signed = new URL(await port.temporaryLink(owner, file.id));
    signed.search = "";
    for (const method of ["GET", "HEAD"]) {
      const response = await fetch(signed, { method });
      expect([401, 403, 404]).toContain(response.status);
    }
    const config = storageConfig();
    const listURL = config.adapter === "s3"
      ? `${config.endpoint}/${config.bucket}?list-type=2`
      : `${config.endpoint}/${config.container}?restype=container&comp=list`;
    expect([401, 403, 404]).toContain((await fetch(listURL)).status);
    await port.delete(owner, file.id);
  });

  test("a link works before its configured expiry and fails afterwards", async () => {
    const port = files();
    const file = await port.save(owner, "Expiring file", body);
    const url = await port.temporaryLink(owner, file.id);
    expect((await fetch(url)).status).toBe(200);
    await new Promise((resolve) => setTimeout(resolve, 3200));
    expect([401, 403]).toContain((await fetch(url)).status);
    await port.delete(owner, file.id);
  });

  for (const role of appRoles) {
    for (const scope of ["self", "other"] as const) {
      test(`${role} ${scope} obtains a link and fetches bytes only when RLS permits reading`, async () => {
        const port = files();
        const file = await port.save(owner, "Role check", body);
        const identity = testIdentity(scope === "self" ? ownerId : other.userId, role);
        const allowed = role === "admin" || (scope === "self" && ["member", "viewer"].includes(role));
        const listed = await port.list(identity);
        expect(listed.some((row) => row.id === file.id)).toBe(allowed);
        if (allowed) {
          const url = await port.temporaryLink(identity, file.id);
          expect((await fetch(url)).status).toBe(200);
          expect(new Uint8Array(await port.fetch(identity, file.id))).toEqual(body);
        } else {
          await expect(port.temporaryLink(identity, file.id)).rejects.toThrow("File is unavailable");
          await expect(port.fetch(identity, file.id)).rejects.toThrow("File is unavailable");
        }
        await port.delete(owner, file.id);
      });
    }
  }

  test("denied writes cannot create objects or delete another user's bytes", async () => {
    const port = files();
    const storage = raw();
    const before = await storage.list("files/");
    for (const role of ["viewer", "unassigned"] as const) {
      await expect(port.save(testIdentity(ownerId, role), "Forbidden", body)).rejects.toMatchObject({ code: "42501" });
    }
    expect(await storage.list("files/")).toEqual(before);
    const file = await port.save(owner, "Keep", body);
    for (const identity of [other, testIdentity(ownerId, "viewer"), testIdentity(ownerId, "unassigned")]) {
      await expect(port.delete(identity, file.id)).rejects.toThrow("File is unavailable");
    }
    expect(new Uint8Array(await port.fetch(owner, file.id))).toEqual(body);
    await port.delete(owner, file.id);
    await expect(port.temporaryLink(owner, file.id)).rejects.toThrow("File is unavailable");
    await expect(storage.fetch(`files/${file.id}`)).rejects.toThrow();
  });

  test("the app cannot redirect a metadata row to another object or storage location", async () => {
    const file = await files().save(owner, "Immutable location", body);
    for (const change of [{ id: randomUUID() }, { owner_id: other.userId }, { storage_scope: "0".repeat(64) }]) {
      await expect(withDatabase(owner, (db) => db.updateTable("files").set(change)
        .where("id", "=", file.id).execute())).rejects.toMatchObject({ code: "42501" });
    }
    await files().delete(owner, file.id);
  });

  test("changing storage configuration cannot sign or fetch a row from another location", async () => {
    const port = files();
    const file = await port.save(owner, "Location-bound", body);
    const setting = adapter === "s3" ? "FILES_S3_BUCKET" : "FILES_AZURE_CONTAINER";
    const previous = process.env[setting]!;
    vi.stubEnv(setting, "another-private-store");
    try {
      await expect(files().temporaryLink(owner, file.id)).rejects.toThrow("File is unavailable");
      await expect(files().fetch(owner, file.id)).rejects.toThrow("File is unavailable");
      expect(await files().list(owner)).toEqual([]);
    } finally { vi.stubEnv(setting, previous); }
    await port.delete(owner, file.id);
  });

  test("removing the read policy denies new links even to the owner", async () => {
    const port = files();
    const file = await port.save(owner, "Policy check", body);
    await inspect(async (client) => {
      await client.query("BEGIN");
      try {
        const policy = await client.query("SELECT qual FROM pg_policies WHERE schemaname='public' AND tablename='files' AND policyname='files_read'");
        await client.query("DROP POLICY files_read ON public.files");
        await client.query("COMMIT");
        try { await expect(port.temporaryLink(owner, file.id)).rejects.toThrow("File is unavailable"); }
        finally {
          await client.query(`CREATE POLICY files_read ON public.files FOR SELECT TO tool_app USING (${policy.rows[0].qual})`);
        }
      } catch (error) { await client.query("ROLLBACK"); throw error; }
    });
    expect((await fetch(await port.temporaryLink(owner, file.id))).status).toBe(200);
    await port.delete(owner, file.id);
  });
});
