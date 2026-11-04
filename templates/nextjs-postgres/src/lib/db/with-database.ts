import { environment } from "../config";
import "server-only";
import { Kysely, PostgresDialect, sql, type Transaction } from "kysely";
import { Pool } from "pg";
import { appRoles, type DatabaseIdentity } from "./identity";
import type { Database } from "./schema";

let database: Kysely<Database> | undefined;
let pool: Pool | undefined;

function assertIdentity(identity: DatabaseIdentity) {
  if (!identity || !/^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(identity.userId)
    || !appRoles.includes(identity.role)) {
    throw new Error("A verified database identity is required");
  }
}

function databasePool() {
  if (!pool) {
    const connectionString = environment().DATABASE_URL;
    if (!connectionString) throw new Error("DATABASE_URL is required");
    pool = new Pool({ connectionString, max: 1, connectionTimeoutMillis: 1000, idleTimeoutMillis: 1000 });
    pool.on("error", () => console.log(JSON.stringify({ event: "database.connection_lost" })));
  }
  return pool;
}

export async function withDatabase<T>(
  identity: DatabaseIdentity,
  work: (transaction: Transaction<Database>) => Promise<T>,
): Promise<T> {
  assertIdentity(identity);
  database ??= new Kysely<Database>({ dialect: new PostgresDialect({ pool: databasePool() }) });
  return database.transaction().execute(async (transaction) => {
    // Parameterised SET LOCAL equivalents, confined to this transaction.
    await sql`select set_config('app.user_id', ${identity.userId}, true),
      set_config('app.role', ${identity.role}, true)`.execute(transaction);
    return work(transaction);
  });
}

// pg-boss maintenance returns several result sets. Kysely's Postgres dialect
// keeps only one, so flatten these here while retaining the same pool and RLS.
export async function executeDatabaseStatements(identity: DatabaseIdentity, text: string, values?: unknown[]) {
  assertIdentity(identity);
  const client = await databasePool().connect();
  try {
    await client.query("BEGIN");
    await client.query(`select set_config('app.user_id', $1, true), set_config('app.role', $2, true),
      set_config('statement_timeout', '1000', true), set_config('lock_timeout', '500', true)`, [identity.userId, identity.role]);
    const result = await client.query(text, values);
    await client.query("COMMIT");
    return { rows: (Array.isArray(result) ? result : [result]).flatMap((item) => item.rows) };
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally { client.release(); }
}
