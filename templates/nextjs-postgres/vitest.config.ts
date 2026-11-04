import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
  resolve: {
    alias: { "server-only": fileURLToPath(new URL("./tests/support/server-only.ts", import.meta.url)) },
  },
  test: {
    environment: "node",
    include: ["tests/**/*.test.{ts,mjs}"],
    fileParallelism: false,
    coverage: { include: ["src/lib/db/**/*.ts"] },
  },
});
