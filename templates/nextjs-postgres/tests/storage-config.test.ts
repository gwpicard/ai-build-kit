import { expect, test } from "vitest";
import { storageConfig, storageScope } from "../src/lib/files/config";

const base = { AWS_ACCESS_KEY_ID: "fixture", AWS_SECRET_ACCESS_KEY: "fixture", FILES_S3_BUCKET: "private-files", FILES_S3_REGION: "eu-west-2" };
test("S3 is the default and links default to one minute", () => {
  expect(storageConfig(base)).toMatchObject({ adapter: "s3", linkSeconds: 60 });
});
for (const seconds of ["0", "301", "1.5", "NaN", ""]) {
  test(`reject an unsafe link lifetime: ${seconds}`, () => {
    expect(() => storageConfig({ ...base, FILES_LINK_SECONDS: seconds })).toThrow("FILES_LINK_SECONDS");
  });
}
test("reject unknown adapters and missing configuration", () => {
  expect(() => storageConfig({ FILES_ADAPTER: "other" })).toThrow("FILES_ADAPTER");
  expect(() => storageConfig({})).toThrow("FILES_S3_BUCKET");
  expect(() => storageConfig({ FILES_ADAPTER: "azure-blob" })).toThrow("FILES_AZURE_ACCOUNT");
});
for (const endpoint of ["http://storage.example", "https://user:pass@storage.example", "https://storage.example?token=value"]) {
  test(`reject unsafe endpoint ${endpoint}`, () => {
    expect(() => storageConfig({ ...base, FILES_S3_ENDPOINT: endpoint })).toThrow("Storage endpoints");
  });
}
test("loopback HTTP is only available outside production", () => {
  expect(storageConfig({ ...base, FILES_S3_ENDPOINT: "http://127.0.0.1:9000" })).toMatchObject({ endpoint: "http://127.0.0.1:9000" });
  expect(() => storageConfig({ ...base, NODE_ENV: "production", FILES_S3_ENDPOINT: "http://127.0.0.1:9000" })).toThrow();
});
test("scope depends on location but not link lifetime or account key", () => {
  const config = storageConfig(base);
  expect(storageScope(config)).toBe(storageScope({ ...config, linkSeconds: 2 }));
  const azure = storageConfig({ FILES_ADAPTER: "azure-blob", FILES_AZURE_ACCOUNT: "example", FILES_AZURE_ACCOUNT_KEY: "test", FILES_AZURE_CONTAINER: "private" });
  if (azure.adapter !== "azure-blob") throw new Error("Wrong test adapter");
  expect(storageScope(azure)).toBe(storageScope({ ...azure, accountKey: "changed" }));
});

test("S3 keeps the SDK credential chain when no static keys are supplied", () => {
  const config = storageConfig({ FILES_S3_BUCKET: "private-files", FILES_S3_REGION: "eu-west-2", NODE_ENV: "production" });
  expect(config.adapter).toBe("s3");
  expect(config).not.toHaveProperty("credentials");
  expect(() => storageConfig({ FILES_S3_BUCKET: "private-files", FILES_S3_REGION: "eu-west-2", AWS_ACCESS_KEY_ID: "fixture" })).toThrow("AWS_SECRET_ACCESS_KEY");
});
