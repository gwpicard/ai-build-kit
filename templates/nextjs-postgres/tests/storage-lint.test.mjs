import path from "node:path";
import { ESLint } from "eslint";
import { beforeAll, expect, test } from "vitest";

const eslint = new ESLint();
beforeAll(async () => {
  await eslint.calculateConfigForFile(path.resolve("src/lib/bypass.ts"));
}, 30000);
for (const code of [
  'import { S3Client } from "@aws-sdk/client-s3";',
  'import { getSignedUrl } from "@aws-sdk/s3-request-presigner";',
  'import type { BlobClient } from "@azure/storage-blob";',
  'export * from "@azure/storage-blob";',
  'export { S3Client } from "@aws-sdk/client-s3";',
  'const sdk = await import("@aws-sdk/client-s3");',
  'const sdk = require("@azure/storage-blob");',
  'const sdk = module.require("aws-sdk/clients/s3");',
  'import sdk = require("@azure/storage-blob");',
  'import sdk from "@aws-sdk/client-s3/dist-cjs/index.js";',
  'import { s3Storage } from "@/lib/files/adapters/s3";',
  'export * from "./files/adapters/azure-blob";',
  'const sdk = await import(process.env.MODULE);',
]) {
  test(`storage lint rejects bypass: ${code}`, async () => {
    const [result] = await eslint.lintText(code, { filePath: path.resolve("src/lib/bypass.ts") });
    expect(result.messages.some((message) => message.ruleId === "storage/boundary" && message.severity === 2)).toBe(true);
  });
}
for (const file of ["src/lib/files/adapters/s3.ts", "src/lib/files/adapters/azure-blob.ts"]) {
  test(`storage lint permits the exact adapter: ${file}`, async () => {
    const [result] = await eslint.lintText('import "@aws-sdk/client-s3"; import "@azure/storage-blob";', { filePath: path.resolve(file) });
    expect(result.errorCount).toBe(0);
  });
}
test("a nested adapter path cannot claim the exemption", async () => {
  const [result] = await eslint.lintText('import "@aws-sdk/client-s3";', {
    filePath: path.resolve("src/nested/src/lib/files/adapters/s3.ts"),
  });
  expect(result.messages.some((message) => message.ruleId === "storage/boundary")).toBe(true);
});
