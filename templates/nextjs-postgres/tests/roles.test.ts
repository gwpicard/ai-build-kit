import { randomUUID } from "node:crypto";
import { sql, type Transaction } from "kysely";
import { beforeAll, describe, expect, test } from "vitest";
import { appRoles } from "../src/lib/db/identity";
import { withDatabase } from "../src/lib/db/with-database";
import type { Database } from "../src/lib/db/schema";
import { roleMatrix, tables, type Scope, type Table } from "./role-matrix";
import { inspect } from "./support/database";
import { testIdentity } from "./support/identity";

const users = { self: randomUUID(), other: randomUUID() };
const fixtures: Record<Table, Record<Scope, string>> = {
  files: { self: randomUUID(), other: randomUUID() },
  records: { self: randomUUID(), other: randomUUID() },
  withheld: { self: randomUUID(), other: randomUUID() },
  "audit.events": { self: "", other: "" },
};
const rollback = new Error("Roll back the test transaction");

beforeAll(async () => {
  // Fixture creation uses the admin connection so removing a policy cannot break setup.
  await inspect(async (client) => {
    await client.query('BEGIN');
    try {
      for (const scope of ["self", "other"] as const) {
        await client.query("SELECT set_config('app.user_id', $1, true), set_config('app.role', 'admin', true)", [users[scope]]);
        for (const table of ["records", "withheld"] as const) {
          await client.query(`INSERT INTO public.${table} (id, owner_id, title) VALUES ($1, $2, 'Fixture')`,
            [fixtures[table][scope], users[scope]]);
        }
        await client.query("INSERT INTO public.files (id, owner_id, title, storage_scope) VALUES ($1, $2, 'Fixture', $3)",
          [fixtures.files[scope], users[scope], "0".repeat(64)]);
        const audit = await client.query("SELECT id FROM audit.events WHERE record_id=$1", [fixtures.records[scope]]);
        fixtures["audit.events"][scope] = audit.rows[0].id;
      }
      await client.query('COMMIT');
    } catch (error) { await client.query('ROLLBACK'); throw error; }
  });
});

for (const role of appRoles) {
  describe(role, () => {
    for (const table of tables) {
      const permissions = roleMatrix[role][table];
      test(`${role} reads ${table}`, async () => {
        const rows = await withDatabase(testIdentity(users.self, role), (db) =>
          sql<{ id: string }>`select id from ${sql.table(table)}
            where id in (${fixtures[table].self}::uuid, ${fixtures[table].other}::uuid) order by id`.execute(db));
        expect(rows.rows.map((row) => row.id)).toEqual(permissions.read.map((scope) => fixtures[table][scope]).sort());
      });
      for (const operation of ["insert", "update", "delete"] as const) {
        for (const scope of ["self", "other"] as const) {
          test(`${role} ${operation} ${scope} ${table}`, async () => {
            const allowed = permissions[operation].includes(scope);
            let checked = false;
            await expect(withDatabase(testIdentity(users.self, role), async (db) => {
              let result;
              try { result = await mutate(db, table, operation, scope); }
              catch (error) {
                expect(allowed).toBe(false);
                expect((error as { code: string }).code).toBe("42501");
                checked = true;
                throw rollback;
              }
              expect(result.rows.length).toBe(allowed ? 1 : 0);
              checked = true;
              throw rollback;
            })).rejects.toBe(rollback);
            expect(checked).toBe(true);
          });
        }
      }
    }
  });
}

function mutate(db: Transaction<Database>, table: Table, operation: string, scope: Scope) {
  if (operation === "insert") {
    if (table === "audit.events") {
      return sql`insert into audit.events (table_name, record_id, operation, actor_id)
        values ('public.records', ${randomUUID()}::uuid, 'INSERT', ${users[scope]}::uuid) returning id`.execute(db);
    }
    if (table === "files") {
      return sql`insert into files (id, owner_id, title, storage_scope)
        values (${randomUUID()}::uuid, ${users[scope]}::uuid, 'New file', ${"0".repeat(64)}) returning id`.execute(db);
    }
    return sql`insert into ${sql.table(table)} (id, owner_id, title)
      values (${randomUUID()}::uuid, ${users[scope]}::uuid, 'New record') returning id`.execute(db);
  }
  if (operation === "update") {
    const column = table === "audit.events" ? "table_name" : "title";
    return sql`update ${sql.table(table)} set ${sql.ref(column)} = 'Changed'
      where id = ${fixtures[table][scope]}::uuid returning id`.execute(db);
  }
  return sql`delete from ${sql.table(table)} where id = ${fixtures[table][scope]}::uuid returning id`.execute(db);
}
