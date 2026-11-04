import { defineConfig } from "@playwright/test";

const baseURL = `http://127.0.0.1:${process.env.PORT ?? "3000"}`;

export default defineConfig({
  testDir: "./e2e",
  use: { baseURL },
  webServer: {
    command: "npm run start",
    url: `${baseURL}/api/health`,
    reuseExistingServer: false,
  },
});
