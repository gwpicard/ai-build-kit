import "server-only";
// Deployment configuration is read only here. Local test tools have their own inputs.
export const environmentNames = [
  "DATABASE_URL",
  "MIGRATION_DATABASE_URL",
  "NODE_ENV",
  "PORT",
  "HOSTNAME",
  "SOURCE_COMMIT",
  "JOBS_MODE",
  "JOBS_TIMER_TOKEN",
  "FILES_ADAPTER",
  "FILES_LINK_SECONDS",
  "FILES_S3_BUCKET",
  "FILES_S3_REGION",
  "FILES_S3_ENDPOINT",
  "FILES_S3_FORCE_PATH_STYLE",
  "AWS_ACCESS_KEY_ID",
  "AWS_SECRET_ACCESS_KEY",
  "AWS_SESSION_TOKEN",
  "FILES_AZURE_ACCOUNT",
  "FILES_AZURE_ACCOUNT_KEY",
  "FILES_AZURE_CONTAINER",
  "FILES_AZURE_ENDPOINT",
  "SMTP_HOST",
  "SMTP_PORT",
  "SMTP_SECURE",
  "SMTP_USER",
  "SMTP_PASSWORD",
  "MAIL_FROM"
] as const;

export type EnvironmentName = typeof environmentNames[number];
export function environment(): Record<EnvironmentName, string | undefined> {
  return Object.fromEntries(environmentNames.map(name => [name, process.env[name]])) as Record<EnvironmentName, string | undefined>;
}

import { createHash } from "node:crypto";

export type StorageConfig = {
  linkSeconds: number;
} & ({
  adapter: "s3";
  bucket: string;
  region: string;
  endpoint?: string;
  forcePathStyle: boolean;
  credentials: { accessKeyId: string; secretAccessKey: string; sessionToken?: string };
} | {
  adapter: "azure-blob";
  container: string;
  account: string;
  accountKey: string;
  endpoint: string;
});

export function storageConfig(env: Record<string, string | undefined> = environment()): StorageConfig {
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
      forcePathStyle: env.FILES_S3_FORCE_PATH_STYLE === "true",
      credentials: { accessKeyId: required("AWS_ACCESS_KEY_ID"), secretAccessKey: required("AWS_SECRET_ACCESS_KEY"), sessionToken: env.AWS_SESSION_TOKEN || undefined } };
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


export function jobsConfig() {
  const env = environment();
  const mode = env.JOBS_MODE ?? "worker";
  if (mode !== "worker" && mode !== "timer") throw new Error("JOBS_MODE must be worker or timer");
  const token = env.JOBS_TIMER_TOKEN;
  if (mode === "timer" && (!token || token.length < 32)) {
    throw new Error("Timer mode requires JOBS_TIMER_TOKEN with at least 32 characters");
  }
  return { mode, token, burstMs: 5000, jobMs: 2000, heartbeatMaxAgeSeconds: mode === "worker" ? 90 : 180 } as const;
}

export function databaseUrl(role: "app" | "migrate" = "app"): string {
  const name = role === "app" ? "DATABASE_URL" : "MIGRATION_DATABASE_URL";
  const value = environment()[name];
  let url: URL;
  try { url = new URL(value ?? ""); } catch { throw new Error(`${name} is required`); }
  if (!["postgres:", "postgresql:"].includes(url.protocol)) throw new Error(`${name} must use Postgres`);
  return value!;
}

export function mailConfig() {
  const env = environment();
  const port = Number(env.SMTP_PORT ?? "587");
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error("SMTP_PORT is invalid");
  if (env.SMTP_SECURE && !["true", "false"].includes(env.SMTP_SECURE)) throw new Error("SMTP_SECURE must be true or false");
  const host = env.SMTP_HOST;
  if (!host || !/^[a-zA-Z0-9.-]+$/.test(host)) throw new Error("SMTP_HOST is required and must be a hostname");
  if (!env.MAIL_FROM || !/^[^\s<>@]+@[^\s<>@]+\.[^\s<>@]+$/.test(env.MAIL_FROM)) throw new Error("MAIL_FROM must be an email address");
  const local = env.NODE_ENV !== "production" && ["localhost", "127.0.0.1"].includes(host);
  if (!local && (!env.SMTP_USER || !env.SMTP_PASSWORD)) throw new Error("SMTP credentials are required");
  if (Boolean(env.SMTP_USER) !== Boolean(env.SMTP_PASSWORD)) throw new Error("Supply both SMTP credential names");
  return { host, port, secure: env.SMTP_SECURE === "true", requireTLS: !local,
    auth: env.SMTP_USER ? { user: env.SMTP_USER, pass: env.SMTP_PASSWORD! } : undefined,
    from: env.MAIL_FROM };
}

export function validateRuntime(role: "web" | "worker" | "migrate") {
  databaseUrl(role === "migrate" ? "migrate" : "app");
  if (role === "migrate") return;
  jobsConfig();
  storageConfig();
  mailConfig();
  const env = environment();
  if (env.SOURCE_COMMIT && !/^[a-f0-9]{40}$/.test(env.SOURCE_COMMIT)) throw new Error("SOURCE_COMMIT must be a full commit identifier");
  const port = Number(env.PORT ?? "3000");
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error("PORT is invalid");
}
