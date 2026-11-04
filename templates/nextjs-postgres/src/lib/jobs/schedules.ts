import "server-only";
import { sql } from "kysely";
import { queueDatabase, withJobDatabase, type Queue, type QueueName } from "./queue";

// UTC. Both entry points evaluate this list against the database clock.
export const schedules: ReadonlyArray<{ name: QueueName; cron: string }> = [
  { name: "weekly-reminder", cron: "0 9 * * 1" },
];

export async function dispatchSchedules(queue: Queue) {
  for (const schedule of schedules) {
    await withJobDatabase(async (db) => {
      // Registration is idempotent. A new schedule starts from its first tick.
      await db.insertInto("job_runtime.schedules").values({ name: schedule.name })
        .onConflict((conflict) => conflict.column("name").doNothing()).execute();
      const cursor = await db.selectFrom("job_runtime.schedules").selectAll()
        .where("name", "=", schedule.name).forUpdate().executeTakeFirstOrThrow();
      const { rows: [clock] } = await sql<{ now: Date }>`select clock_timestamp() as now`.execute(db);
      const [next] = queue.previewSchedule(schedule.cron, { from: cursor.checked_at, count: 1, tz: "UTC" });
      const due = next && next <= clock.now;
      if (due) {
        // Cursor and enqueue commit together. Concurrent runners cannot enqueue the same slot.
        await queue.send(schedule.name, { occurrence: next.toISOString() }, { db: queueDatabase(db) });
      }
      await db.updateTable("job_runtime.schedules").set({ checked_at: due ? next : clock.now })
        .where("name", "=", schedule.name).execute();
    });
  }
}
