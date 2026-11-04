import "server-only";
import { setTimeout as delay } from "node:timers/promises";
import { z } from "zod";
import { withJobDatabase, type QueueName } from "./queue";
import { jobIdentity } from "./identity";

const reminder = z.object({ occurrence: z.iso.datetime().optional() }).strict();
const document = z.object({ title: z.string().min(1).max(150) }).strict();

export async function performJob(name: QueueName, id: string, data: unknown, signal: AbortSignal) {
  let title: string;
  if (name === "weekly-reminder") {
    const payload = reminder.parse(data);
    title = `Weekly reminder${payload.occurrence ? `: ${payload.occurrence}` : ""}`;
  } else {
    const payload = document.parse(data);
    // Stand-in for bounded document generation. It honours the runner's deadline.
    await delay(750, undefined, { signal });
    title = `Document ready: ${payload.title}`;
  }
  signal.throwIfAborted();
  await withJobDatabase(async (db) => {
    signal.throwIfAborted();
    // The durable job ID is also the effect ID. A crash after commit and before
    // queue acknowledgement can replay the handler, but cannot add another record.
    await db.insertInto("records").values({ id, owner_id: jobIdentity.userId, title })
      .onConflict((conflict) => conflict.column("id").doNothing()).execute();
    signal.throwIfAborted();
  });
}
