import { randomUUID } from "node:crypto";
import { sql } from "kysely";
import { Client } from "pg";
import { expect, test } from "vitest";
import { appRoles } from "../src/lib/db/identity";
import { withDatabase } from "../src/lib/db/with-database";
import { inspect } from "./support/database";
import { testIdentity } from "./support/identity";

const authTables = ["account", "invitations", "session", "user", "verification"];

test("the sign-in table inventory forces row rules and separates app and auth grants", async () => {
  const metadata = await inspect((db) => db.query(`SELECT c.relname AS name, c.relrowsecurity AS rls,
    c.relforcerowsecurity AS forced, pg_get_userbyid(c.relowner) AS owner,
    ARRAY(SELECT privilege FROM unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE',
      'REFERENCES', 'TRIGGER', 'MAINTAIN']) AS privilege
      WHERE has_table_privilege('tool_auth', c.oid, privilege) ORDER BY privilege) AS privileges
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='sign_in' AND c.relkind IN ('r', 'p') ORDER BY c.relname`));
  expect(metadata.rows.map((row) => row.name)).toEqual(authTables);
  for (const row of metadata.rows) {
    expect(row).toEqual({ name: row.name, rls: true, forced: true, owner: "tool_owner",
      privileges: row.name === "invitations" ? ["SELECT"] : ["DELETE", "INSERT", "SELECT", "UPDATE"] });
  }
  const role = await inspect((db) => db.query(`SELECT rolsuper, rolbypassrls, rolcreatedb, rolcreaterole,
    (SELECT count(*)::int FROM pg_auth_members WHERE member=r.oid) AS memberships,
    (SELECT count(*)::int FROM pg_class WHERE relowner=r.oid) AS owned,
    has_schema_privilege('tool_auth', 'sign_in', 'CREATE') AS schema_create
    FROM pg_roles r WHERE rolname='tool_auth'`));
  expect(role.rows).toEqual([{ rolsuper: false, rolbypassrls: false, rolcreatedb: false,
    rolcreaterole: false, memberships: 0, owned: 0, schema_create: false }]);
  const auth = new Client({ connectionString: process.env.AUTH_DATABASE_URL });
  await auth.connect();
  try {
    await expect(auth.query('SELECT * FROM public.records')).rejects.toMatchObject({ code: "42501" });
    await expect(auth.query(`INSERT INTO sign_in.invitations (email, "expiresAt")
      VALUES ('forbidden@example.test', now())`)).rejects.toMatchObject({ code: "42501" });
  } finally { await auth.end(); }
});

for (const role of appRoles) {
  test(`${role} cannot read or change authentication tables`, async () => {
    for (const table of authTables.filter((name) => name !== "invitations")) {
      for (const query of [sql`select * from ${sql.table(`sign_in.${table}`)}`,
        sql`update ${sql.table(`sign_in.${table}`)} set id=id`,
        sql`delete from ${sql.table(`sign_in.${table}`)}`]) {
        await expect(withDatabase(testIdentity(randomUUID(), role), (db) => query.execute(db)))
          .rejects.toMatchObject({ code: "42501" });
      }
    }
  });
  test(`${role} invitation permissions and audit match the policy`, async () => {
    const email = `${randomUUID()}@outside.test`;
    const admin = testIdentity(randomUUID(), "admin");
    const identity = testIdentity(randomUUID(), role);
    const created = await withDatabase(admin, (db) => sql<{ id: string }>`insert into sign_in.invitations
      (email, "expiresAt") values (${email}, now()+interval '1 day') returning id`.execute(db));
    const id = created.rows[0].id;
    const read = await withDatabase(identity, (db) => sql`select id from sign_in.invitations where id=${id}::uuid`.execute(db));
    expect(read.rows).toHaveLength(role === "admin" ? 1 : 0);
    const insert = () => withDatabase(identity, (db) => sql`insert into sign_in.invitations
      (email, "expiresAt") values (${`${randomUUID()}@outside.test`}, now()) returning id`.execute(db));
    if (role === "admin") expect((await insert()).rows).toHaveLength(1);
    else await expect(insert()).rejects.toMatchObject({ code: "42501" });
    for (const query of [sql`update sign_in.invitations set revoked=true where id=${id}::uuid returning id`,
      sql`delete from sign_in.invitations where id=${id}::uuid returning id`]) {
      const result = await withDatabase(identity, (db) => query.execute(db));
      expect(result.rows).toHaveLength(role === "admin" ? 1 : 0);
    }
    const audit = await withDatabase(admin, (db) => sql<{ operation: string }>`select operation from audit.events
      where record_id=${id}::uuid order by occurred_at`.execute(db));
    expect(audit.rows.map((row) => row.operation)).toEqual(role === "admin" ? ["INSERT", "UPDATE", "DELETE"] : ["INSERT"]);
  });
}
