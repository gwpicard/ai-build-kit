import "server-only";

export function jobsConfig() {
  const mode = process.env.JOBS_MODE ?? "worker";
  if (mode !== "worker" && mode !== "timer") throw new Error("JOBS_MODE must be worker or timer");
  const token = process.env.JOBS_TIMER_TOKEN;
  if (mode === "timer" && (!token || token.length < 32)) {
    throw new Error("Timer mode requires JOBS_TIMER_TOKEN with at least 32 characters");
  }
  return { mode, token, burstMs: 5000, jobMs: 2000, heartbeatMaxAgeSeconds: mode === "worker" ? 90 : 180 } as const;
}
