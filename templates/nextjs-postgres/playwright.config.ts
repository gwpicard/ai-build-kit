import { randomBytes } from "node:crypto";
import { defineConfig } from "@playwright/test";

process.env.JOBS_TIMER_TOKEN ??= randomBytes(32).toString("hex");

const baseURL = `http://127.0.0.1:${process.env.PORT ?? "3000"}`;

export default defineConfig({
  testDir: "./e2e",
  use: { baseURL },
  webServer: {
    command: "npm run start",
    env: { JOBS_MODE: "timer", JOBS_TIMER_TOKEN: process.env.JOBS_TIMER_TOKEN },
    url: baseURL,
    reuseExistingServer: false,
  },
});
