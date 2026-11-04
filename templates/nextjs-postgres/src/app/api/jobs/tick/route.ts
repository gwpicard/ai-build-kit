import { timingSafeEqual } from "node:crypto";
import { jobsConfig } from "../../../../lib/jobs/config";
import { createQueue } from "../../../../lib/jobs/queue";
import { runBurst } from "../../../../lib/jobs/runner";
import { heartbeat } from "../../../../lib/jobs/heartbeat";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const maxDuration = 15;

export async function POST(request: Request) {
  let config;
  try { config = jobsConfig(); }
  catch { return Response.json({ error: "Jobs configuration is incomplete" }, { status: 503 }); }
  if (config.mode !== "timer") return Response.json({ error: "Timer mode is disabled" }, { status: 404 });
  const provided = Buffer.from(request.headers.get("authorization") ?? "");
  const expected = Buffer.from(`Bearer ${config.token}`);
  if (provided.length !== expected.length || !timingSafeEqual(provided, expected)) {
    return Response.json({ error: "Unauthorised" }, { status: 401 });
  }
  const deadline = AbortSignal.timeout(config.burstMs);
  const queue = createQueue(deadline);
  try {
    await queue.start();
    const result = await runBurst(queue, deadline);
    await heartbeat("00000000-0000-4000-8000-000000000002", "timer");
    return Response.json(result);
  } catch {
    return Response.json({ error: "Jobs are unavailable" }, { status: 503 });
  } finally { await queue.stop(); }
}
