import "server-only";
import { Kysely, PostgresDialect, sql, type Transaction } from "kysely";
import { Pool } from "pg";
import { appRoles, type DatabaseIdentity } from "./identity";
import type { Database } from "./schema";

let database: Kysely<Database> | undefined;

export async function withDatabase<T>(
  identity: DatabaseIdentity,
  work: (transaction: Transaction<Database>) => Promise<T>,
): Promise<T> {
  if (!identity || !/^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(identity.userId)
    || !appRoles.includes(identity.role)) {
    throw new Error("A verified database identity is required");
  }
  if (!database) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) throw new Error("DATABASE_URL is required");
    database = new Kysely<Database>({
      dialect: new PostgresDialect({
        pool: new Pool({ connectionString, max: 1, idleTimeoutMillis: 1000 }),
      }),
    });
  }
  return database.transaction().execute(async (transaction) => {
    // Parameterised SET LOCAL equivalents, confined to this transaction.
    await sql`select set_config('app.user_id', ${identity.userId}, true),
      set_config('app.role', ${identity.role}, true)`.execute(transaction);
    return work(transaction);
  });
}
