import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
  resolve: {
    alias: { "server-only": fileURLToPath(new URL("./tests/support/server-only.ts", import.meta.url)) },
  },
  test: {
    environment: "node",
    testTimeout: 15000,
    include: ["tests/**/*.test.{ts,mjs}"],
    fileParallelism: false,
    exclude: ["tests/handover.test.mjs"],
    coverage: { include: ["src/lib/db/**/*.ts"] },
  },
});
