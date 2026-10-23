import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    clearMocks: false,
    include: ["src/**/*.test.ts"],
    coverage: {
      include: ["src/**/*.{ts,tsx}"],
    },
  },
});
