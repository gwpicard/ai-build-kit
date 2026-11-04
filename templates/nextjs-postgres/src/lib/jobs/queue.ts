import "server-only";
import { PgBoss, fromKysely, type Db } from "pg-boss";
import type { Transaction } from "kysely";
import { sql } from "kysely";
import { withDatabase, executeDatabaseStatements } from "../db/with-database";
import type { Database } from "../db/schema";
import { jobIdentity } from "./identity";

export const queueNames = ["weekly-reminder", "slow-document"] as const;
export type QueueName = (typeof queueNames)[number];

export async function withJobDatabase<T>(work: (db: Transaction<Database>) => Promise<T>) {
  return withDatabase(jobIdentity, async (db) => {
    await sql`select set_config('statement_timeout', '1000', true),
      set_config('lock_timeout', '500', true)`.execute(db);
    return work(db);
  });
}

export function queueDatabase(db: Transaction<Database>): Db {
  return fromKysely(db);
}

const jobStatements: Db = {
  executeSql: (text, values) => executeDatabaseStatements(jobIdentity, text, values),
};

export function createQueue(signal?: AbortSignal) {
  const boss = new PgBoss({
    schema: "job_queue",
    db: { executeSql: (text, values) => {
      signal?.throwIfAborted();
      return jobStatements.executeSql(text, values);
    } },
    migrate: false, createSchema: false, schedule: false, supervise: false,
    registerInstance: false, reindex: false, monitorVacuum: false,
    monitorIntervalSeconds: 1, maintenanceIntervalSeconds: 60,
  });
  // Driver errors can contain connection details or payloads.
  boss.on("error", () => console.error(JSON.stringify({ event: "jobs.queue_error" })));
  return boss;
}

export type Queue = ReturnType<typeof createQueue>;

// A claimed attempt still needs acknowledgement when its processing deadline ends.
export async function settleJob(queue: Queue, name: QueueName, job: { id: string; retryCount: number }, failed: boolean) {
  if (failed) await queue.fail(name, job, { message: "Job failed or exceeded its time limit" }, { db: jobStatements });
  else await queue.complete(name, job, undefined, { db: jobStatements });
}
