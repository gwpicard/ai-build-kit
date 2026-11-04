import { randomUUID } from "node:crypto";
import { sql } from "kysely";
import { expect, test, vi } from "vitest";
import { appRoles } from "../src/lib/db/identity";
import { withDatabase } from "../src/lib/db/with-database";
import { roleMatrix, tables } from "./role-matrix";
import { inspect } from "./support/database";
import { testIdentity } from "./support/identity";

const user = randomUUID();

test("every record table forces RLS, every business table is audited, and the matrix covers the schema", async () => {
  const metadata = await inspect((client) => client.query(`SELECT n.nspname AS schema, c.relname AS name,
    c.relrowsecurity AS rls, c.relforcerowsecurity AS forced, pg_get_userbyid(c.relowner) AS owner,
    EXISTS (SELECT 1 FROM pg_trigger t JOIN pg_proc p ON p.oid=t.tgfoid
      JOIN pg_namespace pn ON pn.oid=p.pronamespace
      WHERE t.tgrelid=c.oid AND NOT t.tgisinternal AND pn.nspname='audit' AND p.proname='record_change'
        AND t.tgenabled='O' AND t.tgtype=29) AS audited
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema') AND n.nspname NOT LIKE 'pg_%'
      AND c.relkind IN ('r', 'p')`));
  expect(metadata.rows.length).toBeGreaterThan(0);
  for (const row of metadata.rows) {
    expect(row.rls, row.name).toBe(true);
    expect(row.forced, row.name).toBe(true);
    expect(row.owner, row.name).toBe("tool_owner");
    if (!["job_queue", "job_runtime"].includes(row.schema) && row.schema !== "audit" && `${row.schema}.${row.name}` !== "private.schema_migrations") {
      expect(row.audited, row.name).toBe(true);
    }
  }
  const appTables = metadata.rows.filter((row) => !["job_queue", "job_runtime"].includes(row.schema) && `${row.schema}.${row.name}` !== "private.schema_migrations")
    .map((row) => row.schema === "public" ? row.name : `${row.schema}.${row.name}`).sort();
  expect([...tables].sort()).toEqual(appTables);
  expect(Object.keys(roleMatrix).sort()).toEqual([...appRoles].sort());
  for (const role of appRoles) expect(Object.keys(roleMatrix[role]).sort()).toEqual(appTables);
});

test("the jobs catalogue contains only reviewed tables and queue statistics partitions", async () => {
  const { rows } = await inspect((client) => client.query(`SELECT n.nspname AS schema, c.relname AS name,
    (SELECT pn.nspname || '.' || parent.relname FROM pg_inherits i
      JOIN pg_class parent ON parent.oid=i.inhparent
      JOIN pg_namespace pn ON pn.oid=parent.relnamespace WHERE i.inhrelid=c.oid) AS parent
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname IN ('job_queue', 'job_runtime') AND c.relkind IN ('r', 'p')`));
  const reviewed = ["bam", "instance", "job", "job_common", "job_dependency", "queue", "queue_stats",
    "schedule", "subscription", "version", "warning"].map((name) => `job_queue.${name}`)
    .concat(["job_runtime.heartbeats", "job_runtime.schedules"]);
  expect(rows.filter((row) => !/^queue_stats_[0-9]{8}$/.test(row.name))
    .map((row) => `${row.schema}.${row.name}`).sort()).toEqual(reviewed.sort());
  for (const row of rows.filter((row) => /^queue_stats_[0-9]{8}$/.test(row.name))) {
    expect(row.schema).toBe("job_queue");
    expect(row.parent).toBe("job_queue.queue_stats");
  }
  const schemas = await inspect((client) => client.query(`SELECT nspname FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%' AND nspname <> 'information_schema'
      AND has_schema_privilege('tool_app', oid, 'CREATE')`));
  expect(schemas.rows).toEqual([]);
});

test("the app role owns no tables, bypasses no row rules and has no role memberships", async () => {
  const metadata = await inspect((client) => client.query(`SELECT rolsuper, rolbypassrls, rolcreatedb, rolcreaterole,
    (SELECT count(*)::int FROM pg_class WHERE relowner=r.oid) AS owned,
    (SELECT count(*)::int FROM pg_auth_members WHERE member=r.oid) AS memberships,
    (SELECT pg_get_userbyid(nspowner) FROM pg_namespace WHERE nspname='public') AS schema_owner,
    has_schema_privilege('tool_app', 'public', 'CREATE') AS schema_create
    FROM pg_roles r WHERE rolname='tool_app'`));
  expect(metadata.rows).toEqual([{ rolsuper: false, rolbypassrls: false, rolcreatedb: false,
    rolcreaterole: false, owned: 0, memberships: 0, schema_owner: "tool_owner", schema_create: false }]);
  const connection = await withDatabase(testIdentity(user, "admin"), (db) =>
    sql<{ name: string }>`select current_user as name`.execute(db));
  expect(connection.rows).toEqual([{ name: "tool_app" }]);
  await expect(withDatabase(testIdentity(user, "admin"), (db) =>
    sql`alter table public.records add column forbidden text`.execute(db))).rejects.toMatchObject({ code: "42501" });
  await expect(withDatabase(testIdentity(user, "admin"), (db) =>
    sql`set local role tool_owner`.execute(db))).rejects.toMatchObject({ code: "42501" });
  await expect(withDatabase(testIdentity(user, "admin"), (db) =>
    sql`create temporary table forbidden_temp (id integer)`.execute(db))).rejects.toMatchObject({ code: "42501" });
});

test("effective app privileges match every table, including privileges outside RLS", async () => {
  const metadata = await inspect((client) => client.query(`SELECT n.nspname AS schema, c.relname AS name,
    ARRAY(SELECT privilege FROM unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
      'TRUNCATE', 'REFERENCES', 'TRIGGER', 'MAINTAIN']) AS privilege
      WHERE has_table_privilege('tool_app', c.oid, privilege) ORDER BY privilege) AS privileges
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema') AND n.nspname NOT LIKE 'pg_%'
      AND c.relkind IN ('r', 'p')`));
  expect(metadata.rows.length).toBeGreaterThan(0);
  for (const row of metadata.rows) {
    const name = `${row.schema}.${row.name}`;
    const expected = name === "private.schema_migrations" ? []
      : row.schema === "audit" ? ["SELECT"]
      : name === "public.files" ? ["DELETE", "SELECT"] : ["DELETE", "INSERT", "SELECT", "UPDATE"];
    expect(row.privileges, name).toEqual(expected);
  }
});

test("effective file column grants permit insertion and title changes only", async () => {
  const metadata = await inspect((client) => client.query(`SELECT a.attname AS name,
    ARRAY(SELECT privilege FROM unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'REFERENCES']) AS privilege
      WHERE has_column_privilege('tool_app', a.attrelid, a.attnum, privilege)
      ORDER BY privilege) AS privileges
    FROM pg_attribute a WHERE a.attrelid='public.files'::regclass
      AND a.attnum > 0 AND NOT a.attisdropped ORDER BY a.attname`));
  expect(metadata.rows).toEqual([
    { name: "id", privileges: ["INSERT", "SELECT"] },
    { name: "owner_id", privileges: ["INSERT", "SELECT"] },
    { name: "storage_scope", privileges: ["INSERT", "SELECT"] },
    { name: "title", privileges: ["INSERT", "SELECT", "UPDATE"] },
  ]);
});

test("the app has no unreviewed views, materialised views, sequences or callable functions", async () => {
  const relations = await inspect((client) => client.query(`SELECT n.nspname AS schema,
    c.relname AS name, c.relkind AS kind
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema') AND n.nspname NOT LIKE 'pg_%'
      AND c.relkind IN ('v', 'm', 'S', 'f') AND has_schema_privilege('tool_app', n.oid, 'USAGE')
      AND CASE WHEN c.relkind='S' THEN has_sequence_privilege('tool_app', c.oid, 'SELECT, UPDATE, USAGE')
        ELSE has_table_privilege('tool_app', c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN')
          OR has_any_column_privilege('tool_app', c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') END
    ORDER BY n.nspname, c.relname`));
  expect(relations.rows).toEqual([]);
  const functions = await inspect((client) => client.query(`SELECT n.nspname AS schema, p.proname AS name,
    pg_get_function_identity_arguments(p.oid) AS arguments, p.prosecdef AS security_definer
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema') AND n.nspname NOT LIKE 'pg_%'
      AND has_schema_privilege('tool_app', n.oid, 'USAGE')
      AND has_function_privilege('tool_app', p.oid, 'EXECUTE')
    ORDER BY n.nspname, p.proname, arguments`));
  expect(functions.rows).toEqual([
    { schema: "job_queue", name: "job_now", arguments: "", security_definer: false },
  ]);
});

test("the audit function runs as the owner with a fixed search path and restricted execution", async () => {
  const metadata = await inspect((client) => client.query(`SELECT pg_get_userbyid(p.proowner) AS owner,
    p.prosecdef AS security_definer, p.proconfig AS settings,
    EXISTS (SELECT 1 FROM aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) acl
      WHERE acl.grantee=0 AND acl.privilege_type='EXECUTE') AS public_execute,
    ARRAY(SELECT r.rolname::text FROM pg_roles r WHERE NOT r.rolsuper
      AND has_function_privilege(r.oid, p.oid, 'EXECUTE') ORDER BY r.rolname) AS executable_roles
    FROM pg_proc p WHERE p.oid='audit.record_change()'::regprocedure`));
  expect(metadata.rows).toEqual([{ owner: "tool_owner", security_definer: true,
    settings: ["search_path=pg_catalog"], public_execute: false, executable_roles: ["tool_owner"] }]);
});

test("a raw app connection with no identity reads nothing, even after its own commit", async () => {
  await withDatabase(testIdentity(user, "member"), (db) =>
    db.insertInto("records").values({ owner_id: user, title: "Visible only with identity" }).execute());
  const { Client } = await import("pg");
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.user_id', $1, true), set_config('app.role', 'admin', true)", [user]);
    await client.query('COMMIT');
    const rows = await client.query('SELECT * FROM public.records');
    expect(rows.rows).toEqual([]);
    const withheld = await client.query('SELECT * FROM public.withheld');
    expect(withheld.rows).toEqual([]);
  } finally { await client.end(); }
});

test("commit, rollback and concurrent callers keep identities separate on a reused connection", async () => {
  const first = testIdentity(user, "member");
  const second = testIdentity(randomUUID(), "viewer");
  const read = (identity: typeof first) => withDatabase(identity, async (db) => {
    const result = await sql<{ user_id: string; role: string; pid: number }>`select
      current_setting('app.user_id') as user_id, current_setting('app.role') as role,
      pg_backend_pid() as pid`.execute(db);
    return result.rows[0];
  });
  const before = await read(first);
  await expect(withDatabase(first, async () => { throw new Error("Abort work"); })).rejects.toThrow("Abort work");
  const after = await read(second);
  expect(before.pid).toBe(after.pid);
  const results = await Promise.all([read(first), read(second)]);
  expect(results.map(({ user_id, role }) => ({ user_id, role }))).toEqual([
    { user_id: first.userId, role: first.role }, { user_id: second.userId, role: second.role },
  ]);
  expect(after).toMatchObject({ user_id: second.userId, role: second.role });
});

test("a member cannot transfer a record past its WITH CHECK rule", async () => {
  await expect(withDatabase(testIdentity(user, "member"), async (db) => {
    const record = await db.insertInto("records").values({ owner_id: user, title: "Owned" }).returning("id").executeTakeFirstOrThrow();
    await db.updateTable("records").set({ owner_id: randomUUID() }).where("id", "=", record.id).execute();
  })).rejects.toMatchObject({ code: "42501" });
});

test("insert, update and delete write immutable audit rows with actor and before and after values", async () => {
  const id = randomUUID();
  const identity = testIdentity(user, "member");
  await withDatabase(identity, async (db) => {
    await db.insertInto("records").values({ id, owner_id: user, title: "Before" }).execute();
    await db.updateTable("records").set({ title: "After" }).where("id", "=", id).execute();
    await db.deleteFrom("records").where("id", "=", id).execute();
  });
  const events = await withDatabase(testIdentity(user, "admin"), (db) => db.selectFrom("audit.events")
    .selectAll().where("record_id", "=", id).orderBy("occurred_at").execute());
  expect(events.map((event) => event.operation)).toEqual(["INSERT", "UPDATE", "DELETE"]);
  for (const event of events) expect(event).toMatchObject({ actor_id: user, actor_role: "member", table_name: "public.records" });
  expect(events[0].old_row).toBeNull();
  expect(events[0].new_row).toMatchObject({ title: "Before" });
  expect(events[1].old_row).toMatchObject({ title: "Before" });
  expect(events[1].new_row).toMatchObject({ title: "After" });
  expect(events[2].old_row).toMatchObject({ title: "After" });
  expect(events[2].new_row).toBeNull();
  for (const operation of ["update", "delete", "insert"] as const) {
    await expect(withDatabase(testIdentity(user, "admin"), (db) => {
      if (operation === "update") return sql`update audit.events set actor_role='admin' where record_id=${id}::uuid`.execute(db);
      if (operation === "delete") return sql`delete from audit.events where record_id=${id}::uuid`.execute(db);
      return sql`insert into audit.events (table_name, record_id, operation) values ('forged', ${id}::uuid, 'INSERT')`.execute(db);
    })).rejects.toMatchObject({ code: "42501" });
  }
  const unchanged = await withDatabase(testIdentity(user, "admin"), (db) => db.selectFrom("audit.events")
    .selectAll().where("record_id", "=", id).orderBy("occurred_at").execute());
  expect(unchanged).toEqual(events);
});

test("a failed transaction rolls back both the record and its audit event", async () => {
  const id = randomUUID();
  await expect(withDatabase(testIdentity(user, "member"), async (db) => {
    await db.insertInto("records").values({ id, owner_id: user, title: "Rolled back" }).execute();
    throw new Error("Abort work");
  })).rejects.toThrow("Abort work");
  await withDatabase(testIdentity(user, "admin"), async (db) => {
    expect(await db.selectFrom("records").selectAll().where("id", "=", id).execute()).toEqual([]);
    expect(await db.selectFrom("audit.events").selectAll().where("record_id", "=", id).execute()).toEqual([]);
  });
});

test("test sign-in refuses production even when Vitest is present", () => {
  vi.stubEnv("NODE_ENV", "production");
  try { expect(() => testIdentity(user, "admin")).toThrow("only in Vitest"); }
  finally { vi.unstubAllEnvs(); }
  vi.stubEnv("VITEST", "false");
  try { expect(() => testIdentity(user, "admin")).toThrow("only in Vitest"); }
  finally { vi.unstubAllEnvs(); }
});
