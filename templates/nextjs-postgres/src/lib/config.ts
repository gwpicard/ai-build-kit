import "server-only";
import { readFileSync } from "node:fs";
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
  "MAIL_FROM",
  "AUTH_BASE_URL",
  "AUTH_SECRET_FILE",
  "AUTH_DATABASE_URL",
  "STAFF_PROVIDER",
  "STAFF_ISSUER",
  "STAFF_CLIENT_ID",
  "STAFF_CLIENT_SECRET_FILE",
  "MICROSOFT_TENANT_ID",
  "GOOGLE_WORKSPACE_DOMAIN",
  "SMTP_FROM",
  "SMTP_PASSWORD_FILE",
  "VITEST"
] as const;

export const environmentSecrets = [
  "DATABASE_URL",
  "MIGRATION_DATABASE_URL",
  "JOBS_TIMER_TOKEN",
  "AWS_ACCESS_KEY_ID",
  "AWS_SECRET_ACCESS_KEY",
  "AWS_SESSION_TOKEN",
  "FILES_AZURE_ACCOUNT_KEY",
  "SMTP_USER",
  "SMTP_PASSWORD",
  "AUTH_SECRET_FILE",
  "AUTH_DATABASE_URL",
  "STAFF_CLIENT_SECRET_FILE",
  "SMTP_PASSWORD_FILE"
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
  credentials?: { accessKeyId: string; secretAccessKey: string; sessionToken?: string };
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
      ...(env.AWS_ACCESS_KEY_ID || env.AWS_SECRET_ACCESS_KEY ? { credentials: {
        accessKeyId: required("AWS_ACCESS_KEY_ID"), secretAccessKey: required("AWS_SECRET_ACCESS_KEY"),
        sessionToken: env.AWS_SESSION_TOKEN || undefined } } : {}) };
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
  if (role === "web") {
    readSignInConfig();
    signInMailConfig();
  }
  const env = environment();
  if (env.SOURCE_COMMIT && !/^[a-f0-9]{40}$/.test(env.SOURCE_COMMIT)) throw new Error("SOURCE_COMMIT must be a full commit identifier");
  const port = Number(env.PORT ?? "3000");
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error("PORT is invalid");
}

// Sign-in retains its file-based secrets and SMTP settings at the shared boundary.
export function secretFile(name: EnvironmentName): string {
  const location = environment()[name];
  if (!location) throw new Error(`${name} must name a secret file`);
  return readFileSync(location, "utf8").trim();
}

export function signInMailConfig() {
  const env = environment();
  if (!env.SMTP_HOST || !env.SMTP_FROM) throw new Error("SMTP_HOST and SMTP_FROM are required for email sign-in");
  return { from: env.SMTP_FROM, host: env.SMTP_HOST, port: Number(env.SMTP_PORT ?? 587),
    secure: env.SMTP_PORT === "465", requireTLS: true,
    ...(env.SMTP_USER ? { auth: { user: env.SMTP_USER, pass: secretFile("SMTP_PASSWORD_FILE") } } : {}),
    logger: false as const, debug: false as const };
}


export type Directory = {
  provider: "microsoft" | "google";
  issuer: string;
  clientId: string;
  clientSecret: string;
  tenant?: string;
  domain?: string;
};
export type SignInConfig = {
  baseURL: string;
  secret: string;
  databaseURL: string;
  directory?: Directory;
};

export function validateSignInConfig(config: SignInConfig): void {
  const localTest = environment().NODE_ENV === "test" && environment().VITEST === "true";
  const base = new URL(config.baseURL);
  if (base.protocol !== "https:" || base.pathname !== "/" || base.search || base.hash) {
    throw new Error("AUTH_BASE_URL must be an HTTPS origin");
  }
  if (config.secret.length < 32) throw new Error("The sign-in secret needs at least 32 characters");
  const database = new URL(config.databaseURL);
  if (database.username !== "tool_auth") throw new Error("Sign-in requires the tool_auth database role");
  const directory = config.directory;
  if (!directory) return;
  if (!directory.clientId || !directory.clientSecret) throw new Error("Directory credentials are required");
  const issuer = new URL(directory.issuer);
  const testIssuer = localTest && issuer.protocol === "http:" && issuer.hostname === "127.0.0.1";
  if (directory.provider === "microsoft") {
    if (!/^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/.test(directory.tenant ?? "")
      || directory.tenant === "9188040d-6c67-4c5b-b112-36a304b66dad") {
      throw new Error("Microsoft sign-in requires a company tenant UUID");
    }
    if (!testIssuer && directory.issuer !== `https://login.microsoftonline.com/${directory.tenant}/v2.0`) {
      throw new Error("The Microsoft issuer must name the configured tenant");
    }
  } else if (directory.provider === "google") {
    if (!/^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?\.[a-z]{2,}$/.test(directory.domain ?? "")) {
      throw new Error("Google sign-in requires one Workspace domain");
    }
    if (!testIssuer && directory.issuer !== "https://accounts.google.com") {
      throw new Error("The Google issuer must be https://accounts.google.com");
    }
  } else throw new Error("Unknown staff sign-in provider");
}

export function readSignInConfig(): SignInConfig {
  const provider = environment().STAFF_PROVIDER ?? "none";
  if (!["none", "microsoft", "google"].includes(provider)) throw new Error("Unknown STAFF_PROVIDER");
  const config: SignInConfig = {
    baseURL: environment().AUTH_BASE_URL ?? "",
    secret: secretFile("AUTH_SECRET_FILE"),
    databaseURL: environment().AUTH_DATABASE_URL ?? "",
    ...(provider === "none" ? {} : { directory: {
      provider: provider as Directory["provider"],
      issuer: environment().STAFF_ISSUER ?? "",
      clientId: environment().STAFF_CLIENT_ID ?? "",
      clientSecret: secretFile("STAFF_CLIENT_SECRET_FILE"),
      tenant: environment().MICROSOFT_TENANT_ID,
      domain: environment().GOOGLE_WORKSPACE_DOMAIN,
    } }),
  };
  validateSignInConfig(config);
  return config;
}
