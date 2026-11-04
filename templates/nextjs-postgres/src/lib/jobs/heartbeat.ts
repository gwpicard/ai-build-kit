import "server-only";
import { sql } from "kysely";
import { jobsConfig } from "./config";
import { withJobDatabase } from "./queue";

export async function heartbeat(id: string, mode: "worker" | "timer", stopped = false) {
  await withJobDatabase((db) => db.insertInto("job_runtime.heartbeats")
    .values({ id, mode, stopped })
    .onConflict((conflict) => conflict.column("id").doUpdateSet({
      seen_at: sql`clock_timestamp()`, stopped,
    })).execute());
}

export async function jobsHealthy() {
  const config = jobsConfig();
  const result = await withJobDatabase((db) => sql<{ healthy: boolean }>`select exists (
    select 1 from job_runtime.heartbeats where mode = ${config.mode} and not stopped
    and seen_at > clock_timestamp() - ${config.heartbeatMaxAgeSeconds} * interval '1 second'
  ) as healthy`.execute(db));
  return result.rows[0].healthy;
}
