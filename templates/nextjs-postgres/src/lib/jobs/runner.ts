import "server-only";
import { jobsConfig } from "./config";
import { dispatchSchedules } from "./schedules";
import { queueNames, settleJob, type Queue } from "./queue";
import { performJob } from "./tasks";

export async function runBurst(queue: Queue, signal: AbortSignal) {
  const { jobMs } = jobsConfig();
  if (signal.aborted) return { completed: 0 };
  await queue.supervise();
  if (signal.aborted) return { completed: 0 };
  await dispatchSchedules(queue);
  let completed = 0;
  // Round-robin, one claim at a time. No prefetched jobs remain locked on return.
  let found = true;
  while (!signal.aborted && found) {
    found = false;
    for (const name of queueNames) {
      if (signal.aborted) break;
      const [job] = await queue.fetch(name, { includeMetadata: true, batchSize: 1 });
      if (!job) continue;
      found = true;
      const deadline = AbortSignal.any([signal, AbortSignal.timeout(jobMs)]);
      try {
        await performJob(name, job.id, job.data, deadline);
        await settleJob(queue, name, job, false);
        completed++;
      } catch {
        await settleJob(queue, name, job, true);
        console.error(JSON.stringify({ event: "jobs.attempt_failed", queue: name, id: job.id }));
      }
    }
  }
  return { completed };
}
