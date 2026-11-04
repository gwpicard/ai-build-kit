import { environment } from "../../../lib/config";
import { jobsHealthy } from "../../../lib/jobs/heartbeat";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const healthy = await jobsHealthy();
    return Response.json({ status: healthy ? "ok" : "unhealthy", commit: environment().SOURCE_COMMIT || null, database: "ok", jobs: healthy ? "ok" : "stale" },
      { status: healthy ? 200 : 503 });
  } catch {
    return Response.json({ status: "unhealthy", database: "unavailable", jobs: "unknown" }, { status: 503 });
  }
}
