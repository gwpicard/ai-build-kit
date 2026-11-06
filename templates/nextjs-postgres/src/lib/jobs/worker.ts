import { randomUUID } from "node:crypto";
import { setTimeout as delay } from "node:timers/promises";
import { jobsConfig } from "./config";
import { createQueue } from "./queue";
import { heartbeat } from "./heartbeat";
import { runBurst } from "./runner";

async function main() {
  const config = jobsConfig();
  if (config.mode !== "worker") throw new Error("The worker command requires JOBS_MODE=worker");
  const queue = createQueue();
  const id = randomUUID();
  const shutdown = new AbortController();
  const stop = () => shutdown.abort();
  process.once("SIGTERM", stop);
  process.once("SIGINT", stop);
  try {
    await queue.start();
    console.log(JSON.stringify({ event: "jobs.worker_started", id }));
    while (!shutdown.signal.aborted) {
      await runBurst(queue, AbortSignal.any([shutdown.signal, AbortSignal.timeout(config.burstMs)]));
      await heartbeat(id, "worker");
      await delay(500, undefined, { signal: shutdown.signal }).catch(() => {});
    }
  } finally {
    try { await heartbeat(id, "worker", true); }
    finally {
      await queue.stop();
      process.removeListener("SIGTERM", stop);
      process.removeListener("SIGINT", stop);
    }
  }
}

main().catch(() => {
  console.error(JSON.stringify({ event: "jobs.worker_stopped_with_error" }));
  process.exitCode = 1;
});
