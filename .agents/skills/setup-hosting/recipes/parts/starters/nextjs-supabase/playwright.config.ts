import { defineConfig } from "@playwright/test";
import { execFileSync } from "node:child_process";

// Keep the chosen port in the environment so Playwright workers use it too.
const port = process.env.PORT ?? execFileSync(process.execPath, ["-e", `
  const server = require("node:net").createServer();
  server.listen(0, "127.0.0.1", () => {
    console.log(server.address().port);
    server.close();
  });
`], { encoding: "utf8" }).trim();
if (!/^[1-9]\d*$/.test(port) || Number(port) > 65535) {
  throw new Error("PORT must be a whole number between 1 and 65535.");
}
process.env.PORT = port;
const baseURL = `http://127.0.0.1:${port}`;

export default defineConfig({
  testDir: "./e2e",
  use: { baseURL },
  webServer: {
    command: `npm run start -- --hostname 127.0.0.1 --port ${port}`,
    url: `${baseURL}/api/health`,
    reuseExistingServer: false,
  },
});
