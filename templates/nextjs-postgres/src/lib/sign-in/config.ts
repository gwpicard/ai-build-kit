import "server-only";
import { readFileSync } from "node:fs";

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

export function secretFile(name: string): string {
  const location = process.env[name];
  if (!location) throw new Error(`${name} must name a secret file`);
  return readFileSync(location, "utf8").trim();
}

export function validateConfig(config: SignInConfig): void {
  const localTest = process.env.NODE_ENV === "test" && process.env.VITEST === "true";
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

export function readConfig(): SignInConfig {
  const provider = process.env.STAFF_PROVIDER ?? "none";
  if (!["none", "microsoft", "google"].includes(provider)) throw new Error("Unknown STAFF_PROVIDER");
  const config: SignInConfig = {
    baseURL: process.env.AUTH_BASE_URL ?? "",
    secret: secretFile("AUTH_SECRET_FILE"),
    databaseURL: process.env.AUTH_DATABASE_URL ?? "",
    ...(provider === "none" ? {} : { directory: {
      provider: provider as Directory["provider"],
      issuer: process.env.STAFF_ISSUER ?? "",
      clientId: process.env.STAFF_CLIENT_ID ?? "",
      clientSecret: secretFile("STAFF_CLIENT_SECRET_FILE"),
      tenant: process.env.MICROSOFT_TENANT_ID,
      domain: process.env.GOOGLE_WORKSPACE_DOMAIN,
    } }),
  };
  validateConfig(config);
  return config;
}
