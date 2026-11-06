import { randomBytes } from "node:crypto";
import { defineConfig } from "@playwright/test";

process.env.JOBS_TIMER_TOKEN ??= randomBytes(32).toString("hex");

const port = process.env.PORT ?? "3107";
const baseURL = `http://127.0.0.1:${port}`;

export default defineConfig({
  testDir: "./e2e",
  use: { baseURL },
  webServer: {
    command: "npm run start",
    env: { PORT: port, JOBS_MODE: "timer", JOBS_TIMER_TOKEN: process.env.JOBS_TIMER_TOKEN },
    url: baseURL,
    reuseExistingServer: false,
  },
});
