import { defineConfig } from "vitest/config";
import base from "./vitest.config";

export default defineConfig({
  ...base,
  test: { ...base.test, include: ["tests/files.integration.ts"], testTimeout: 120000, hookTimeout: 30000 },
});
