import "server-only";
import { createHash } from "node:crypto";

export type StorageConfig = {
  linkSeconds: number;
} & ({
  adapter: "s3";
  bucket: string;
  region: string;
  endpoint?: string;
  forcePathStyle: boolean;
} | {
  adapter: "azure-blob";
  container: string;
  account: string;
  accountKey: string;
  endpoint: string;
});

export function storageConfig(env: Record<string, string | undefined> = process.env): StorageConfig {
  const required = (name: string) => {
    const value = env[name];
    if (!value) throw new Error(`${name} is required`);
    return value;
  };
  const endpoint = (value: string) => {
    let url: URL;
    try { url = new URL(value); }
    catch { throw new Error("Storage endpoint must be a valid URL"); }
    const loopback = ["localhost", "127.0.0.1", "[::1]"].includes(url.hostname);
    if (url.username || url.password || url.search || url.hash
      || (url.protocol !== "https:" && !(url.protocol === "http:" && loopback && env.NODE_ENV !== "production"))) {
      throw new Error("Storage endpoints require HTTPS, except local development emulators");
    }
    return url.href.replace(/\/$/, "");
  };
  const linkSeconds = Number(env.FILES_LINK_SECONDS ?? "60");
  if (!Number.isInteger(linkSeconds) || linkSeconds < 1 || linkSeconds > 300) {
    throw new Error("FILES_LINK_SECONDS must be an integer from 1 to 300");
  }
  const adapter = env.FILES_ADAPTER ?? "s3";
  if (adapter === "s3") {
    if (env.FILES_S3_FORCE_PATH_STYLE && !["true", "false"].includes(env.FILES_S3_FORCE_PATH_STYLE)) {
      throw new Error("FILES_S3_FORCE_PATH_STYLE must be true or false");
    }
    return { adapter, linkSeconds, bucket: required("FILES_S3_BUCKET"), region: required("FILES_S3_REGION"),
      endpoint: env.FILES_S3_ENDPOINT ? endpoint(env.FILES_S3_ENDPOINT) : undefined,
      forcePathStyle: env.FILES_S3_FORCE_PATH_STYLE === "true" };
  }
  if (adapter === "azure-blob") {
    const account = required("FILES_AZURE_ACCOUNT");
    return { adapter, linkSeconds, account, container: required("FILES_AZURE_CONTAINER"),
      accountKey: required("FILES_AZURE_ACCOUNT_KEY"),
      endpoint: endpoint(env.FILES_AZURE_ENDPOINT ?? `https://${account}.blob.core.windows.net`) };
  }
  throw new Error("FILES_ADAPTER must be s3 or azure-blob");
}

// Bind metadata to its storage location without persisting credentials.
export function storageScope(config: StorageConfig): string {
  const location = config.adapter === "s3"
    ? [config.adapter, config.endpoint ?? "aws", config.region, config.bucket]
    : [config.adapter, config.endpoint, config.account, config.container];
  return createHash("sha256").update(JSON.stringify(location)).digest("hex");
}
