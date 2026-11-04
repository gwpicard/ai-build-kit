import { randomBytes, randomUUID } from "node:crypto";
import { spawn, type ChildProcess } from "node:child_process";
import { setTimeout as delay } from "node:timers/promises";
import { afterAll, beforeAll, expect, test, vi } from "vitest";
import { sql } from "kysely";
import { createQueue, withJobDatabase } from "../src/lib/jobs/queue";
import { schedules } from "../src/lib/jobs/schedules";
import { runBurst } from "../src/lib/jobs/runner";
import { jobIdentity } from "../src/lib/jobs/identity";
import { performJob } from "../src/lib/jobs/tasks";
import { heartbeat } from "../src/lib/jobs/heartbeat";
import { withDatabase, executeDatabaseStatements } from "../src/lib/db/with-database";
import { appRoles } from "../src/lib/db/identity";
import { testIdentity } from "./support/identity";
import { inspect } from "./support/database";
import { POST } from "../src/app/api/jobs/tick/route";
import { GET } from "../src/app/api/health/route";

const queue = createQueue();
const children = new Set<ChildProcess>();
beforeAll(async () => { await queue.start(); });
afterAll(async () => {
  for (const child of children) await stop(child, "SIGKILL");
  await queue.stop();
});
async function until(predicate: () => Promise<boolean>, timeout = 10000) {
  const end = Date.now() + timeout;
  while (Date.now() < end) { if (await predicate()) return; await delay(100); }
  throw new Error("The expected job outcome did not arrive");
}
function worker() {
  const child = spawn(process.execPath, ["dist/worker.mjs"], {
    env: { ...process.env, JOBS_MODE: "worker" }, stdio: ["ignore", "ignore", "pipe"],
  });
  // Do not print inherited configuration or driver diagnostics.
  child.stderr?.resume();
  children.add(child);
  return child;
}
async function stop(child: ChildProcess, signal: NodeJS.Signals = "SIGTERM") {
  if (child.exitCode === null && child.signalCode === null) {
    const exited = new Promise<void>((resolve) => child.once("exit", () => resolve()));
    child.kill(signal);
    await exited;
  }
  children.delete(child);
}
async function hasRecord(id: string) {
  return withJobDatabase(async (db) => Boolean(await db.selectFrom("records").select("id")
    .where("id", "=", id).executeTakeFirst()));
}
async function dueSchedule() {
  const now = new Date();
  const monday = new Date(now);
  monday.setUTCHours(9, 0, 0, 0);
  monday.setUTCDate(monday.getUTCDate() - (monday.getUTCDay() + 6) % 7);
  if (monday > now) monday.setUTCDate(monday.getUTCDate() - 7);
  const before = new Date(monday.getTime() - 1000);
  await withJobDatabase((db) => db.insertInto("job_runtime.schedules")
    .values({ name: schedules[0].name, checked_at: before })
    .onConflict((conflict) => conflict.column("name").doUpdateSet({ checked_at: before })).execute());
  return `Weekly reminder: ${monday.toISOString()}`;
}
async function reminders(title: string) {
  return inspect(async (client) => (await client.query("select id from records where title=$1", [title])).rows);
}

test("a claimed slow job survives a killed worker and completes after restart", async () => {
  const id = (await queue.send("slow-document", { title: "Restart example" }))!;
  const first = worker();
  try {
    await until(async () => (await queue.findJobs("slow-document", { id })).some((job) => job.state === "active"));
    await stop(first, "SIGKILL");
    expect(await hasRecord(id)).toBe(false);
    const second = worker();
    try {
      // Use the real 30-second lease and supervisor, without editing queue internals.
      await until(() => hasRecord(id), 45000);
      await until(async () => (await queue.findJobs("slow-document", { id })).some((job) => job.state === "completed"));
    } finally { await stop(second); }
    const [job] = await queue.findJobs("slow-document", { id });
    expect(job.retryCount).toBe(1);
  } finally { await stop(first, "SIGKILL"); }
}, 60000);

test("a database failure is retried and writes its output once after recovery", async () => {
  const id = (await queue.send("weekly-reminder", {}))!;
  // A competing transaction holds this output ID, making the first insert time out.
  let release!: () => void;
  let locked!: () => void;
  const ready = new Promise<void>((resolve) => { locked = resolve; });
  const blocker = inspect(async (client) => {
    await client.query("BEGIN");
    await client.query("insert into records(id,owner_id,title) values($1,$2,'Uncommitted')", [id, jobIdentity.userId]);
    locked();
    await new Promise<void>((resolve) => { release = resolve; });
    await client.query("ROLLBACK");
  });
  await ready;
  try { await runBurst(queue, AbortSignal.timeout(1000)); }
  finally { release(); await blocker; }
  expect((await queue.findJobs("weekly-reminder", { id }))[0].state).toBe("retry");
  await delay(2200);
  await runBurst(queue, AbortSignal.timeout(3000));
  const [job] = await queue.findJobs("weekly-reminder", { id });
  expect(job.state).toBe("completed");
  expect(job.retryCount).toBe(1);
  expect(await hasRecord(id)).toBe(true);
});

test("independent queue clients claim a durable job only once", async () => {
  const id = (await queue.send("slow-document", { title: "Competing claims" }))!;
  const competitor = createQueue();
  await competitor.start();
  try {
    const claims = (await Promise.all([queue, competitor].map((client) =>
      client.fetch("slow-document", { includeMetadata: true, batchSize: 1 })))).flat();
    expect(claims.filter((job) => job.id === id)).toHaveLength(1);
    const claim = claims.find((job) => job.id === id)!;
    await performJob("slow-document", id, claim.data, AbortSignal.timeout(2000));
    await queue.complete("slow-document", claim);
    expect(await hasRecord(id)).toBe(true);
  } finally { await competitor.stop(); }
});

test("two processes never claim one job together, and replay after a committed effect adds no second record", async () => {
  const id = (await queue.send("slow-document", { title: "One output" }))!;
  const first = worker(); const second = worker();
  try {
    await until(async () => (await queue.findJobs("slow-document", { id })).some((job) => job.state === "completed"));
  } finally { await Promise.all([stop(first), stop(second)]); }
  const [job] = await queue.findJobs("slow-document", { id });
  expect(job.retryCount).toBe(0);
  // Simulate the crash window between committing the output and acknowledging the job.
  await performJob("slow-document", id, { title: "One output" }, AbortSignal.timeout(2000));
  const events = await inspect((client) => client.query("select * from audit.events where record_id=$1", [id]));
  expect(events.rows).toHaveLength(1);
  expect(events.rows[0]).toMatchObject({ actor_role: "system", actor_id: jobIdentity.userId });
});

test("a weekly code schedule fires through the worker", async () => {
  const title = await dueSchedule();
  const before = await reminders(title);
  const child = worker();
  try { await until(async () => (await reminders(title)).length === before.length + 1); }
  finally { await stop(child); }
  expect(await reminders(title)).toHaveLength(before.length + 1);
});

test("timer route rejects missing and wrong tokens, refuses missing configuration, and is disabled in worker mode", async () => {
  vi.stubEnv("JOBS_MODE", "timer"); vi.stubEnv("JOBS_TIMER_TOKEN", randomBytes(32).toString("hex"));
  try {
    for (const header of [undefined, "Bearer wrong"]) {
      const response = await POST(new Request("http://localhost/api/jobs/tick", {
        method: "POST", headers: header ? { authorization: header } : {},
      }));
      expect(response.status).toBe(401);
    }
    vi.stubEnv("JOBS_TIMER_TOKEN", "");
    expect((await POST(new Request("http://localhost", { method: "POST" }))).status).toBe(503);
    vi.stubEnv("JOBS_MODE", "worker");
    expect((await POST(new Request("http://localhost", { method: "POST" }))).status).toBe(404);
  } finally { vi.unstubAllEnvs(); }
});

test("a weekly schedule and slow document run through concurrent timer requests only once", async () => {
  const token = randomBytes(32).toString("hex");
  vi.stubEnv("JOBS_MODE", "timer"); vi.stubEnv("JOBS_TIMER_TOKEN", token);
  const title = await dueSchedule();
  const before = await reminders(title);
  const id = (await queue.send("slow-document", { title: "Timer document" }))!;
  try {
    const responses = await Promise.all([1, 2].map(() => POST(new Request("http://localhost/api/jobs/tick", {
      method: "POST", headers: { authorization: `Bearer ${token}` },
    }))));
    expect(responses.map((response) => response.status)).toEqual([200, 200]);
    expect(await reminders(title)).toHaveLength(before.length + 1);
    expect(await hasRecord(id)).toBe(true);
    const [job] = await queue.findJobs("slow-document", { id });
    expect(job.state).toBe("completed");
    expect(job.retryCount).toBe(0);
    expect((await GET()).status).toBe(200);
  } finally { vi.unstubAllEnvs(); }
});

test("a burst stops at its deadline and an aborted document can retry without an output", async () => {
  const id = (await queue.send("slow-document", { title: "Short deadline" }))!;
  const started = Date.now();
  await runBurst(queue, AbortSignal.timeout(100));
  expect(Date.now() - started).toBeLessThan(1500);
  expect(await hasRecord(id)).toBe(false);
  await delay(2200);
  await runBurst(queue, AbortSignal.timeout(2500));
  expect(await hasRecord(id)).toBe(true);
});

test("health detects fresh, stale and stopped workers and a failed database round trip", async () => {
  vi.stubEnv("JOBS_MODE", "worker");
  const id = randomUUID();
  try {
    await heartbeat(id, "worker");
    expect((await GET()).status).toBe(200);
    await inspect((client) => client.query("update job_runtime.heartbeats set seen_at=now()-interval '10 minutes' where mode='worker'"));
    expect((await GET()).status).toBe(503);
    await heartbeat(id, "worker", true);
    expect((await GET()).status).toBe(503);
    // Hold the health table past the query's lock timeout.
    let release!: () => void; let locked!: () => void;
    const ready = new Promise<void>((resolve) => { locked = resolve; });
    const blocker = inspect(async (client) => {
      await client.query("BEGIN; LOCK TABLE job_runtime.heartbeats IN ACCESS EXCLUSIVE MODE");
      locked(); await new Promise<void>((resolve) => { release = resolve; }); await client.query("ROLLBACK");
    });
    await ready;
    try {
      const response = await GET();
      expect(response.status).toBe(503);
      expect((await response.json()).database).toBe("unavailable");
    } finally { release(); await blocker; }
  } finally { vi.unstubAllEnvs(); }
});

test("the fixed system identity cannot read or change a user's record or the withheld table", async () => {
  const user = randomUUID();
  const record = await withDatabase(testIdentity(user, "member"), (db) => db.insertInto("records")
    .values({ owner_id: user, title: "Private" }).returning("id").executeTakeFirstOrThrow());
  await withJobDatabase(async (db) => {
    expect(await db.selectFrom("records").selectAll().where("id", "=", record.id).execute()).toEqual([]);
    expect(await db.selectFrom("withheld").selectAll().execute()).toEqual([]);
    expect((await db.updateTable("records").set({ title: "Forbidden" }).where("id", "=", record.id).executeTakeFirst()).numUpdatedRows).toBe(BigInt(0));
  });
  await expect(withJobDatabase((db) => db.insertInto("records").values({ owner_id: user, title: "Forbidden" }).execute()))
    .rejects.toMatchObject({ code: "42501" });
});

test("all queue and runtime tables force row rules and deny ordinary roles", async () => {
  const { rows } = await inspect((client) => client.query(`select n.nspname as schema, c.relname as name,
    c.relrowsecurity as rls,c.relforcerowsecurity as forced from pg_class c
    join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('job_queue','job_runtime') and c.relkind in ('r','p')`));
  expect(rows.length).toBeGreaterThan(5);
  for (const row of rows) {
    expect(row).toMatchObject({ rls: true, forced: true });
    for (const role of appRoles) {
      // Even a forged system role with a different user ID is refused.
      const result = await withDatabase(testIdentity(randomUUID(), role), (db) =>
        sql`select * from ${sql.table(`${row.schema}.${row.name}`)}`.execute(db));
      expect(result.rows).toEqual([]);
    }
  }
  await expect(withJobDatabase((db) => sql`create table job_queue.forbidden(id integer)`.execute(db)))
    .rejects.toMatchObject({ code: "42501" });
});

test("queue batches retain result sets, roll back effects on failure and clear the system identity", async () => {
  const result = await executeDatabaseStatements(jobIdentity,
    "select 1 as first; select current_setting('app.role') as role");
  expect(result.rows).toEqual([{ first: 1 }, { role: "system" }]);
  const id = randomUUID();
  await expect(executeDatabaseStatements(jobIdentity, `
    insert into records(id, owner_id, title)
      values ('${id}', '${jobIdentity.userId}', 'Rolled back batch');
    select 1 / 0`)).rejects.toMatchObject({ code: "22012" });
  expect(await hasRecord(id)).toBe(false);
  const audit = await inspect((client) => client.query("select id from audit.events where record_id=$1", [id]));
  expect(audit.rows).toEqual([]);
  const ordinary = await withDatabase(testIdentity(randomUUID(), "unassigned"), (db) =>
    sql`select * from job_queue.job`.execute(db));
  expect(ordinary.rows).toEqual([]);
});
