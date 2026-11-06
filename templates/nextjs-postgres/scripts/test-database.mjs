import { randomBytes } from "node:crypto";
import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";

// The enclosing docker-run.sh owns the exit and signal traps.
if (!process.env.ABK_DOCKER_SCOPE) throw new Error("Run through scripts/docker-run.sh");
const secret = () => randomBytes(24).toString("hex");
const secretDirectory = mkdtempSync(join(tmpdir(), "abk-sign-in-"));
const secretPath = join(secretDirectory, "secret");
const removeSecret = () => rmSync(secretDirectory, { recursive: true, force: true });
for (const [signal, code] of [["SIGHUP", 129], ["SIGINT", 130], ["SIGTERM", 143]]) {
  process.once(signal, () => { removeSecret(); process.exit(code); });
}
const env = { ...process.env, NODE_ENV: "test", ABK_DATABASE_READY: "1",
  FILES_ADAPTER: "s3", FILES_S3_BUCKET: "private-files", FILES_S3_REGION: "local",
  SMTP_HOST: "127.0.0.1", SMTP_PORT: "1025", SMTP_SECURE: "false",
  AUTH_SECRET_FILE: secretPath, AUTH_BASE_URL: "https://tool.example.test", SMTP_FROM: "tool@example.test",
  SMTP_USER: "", SMTP_PASSWORD: "", MAIL_FROM: "tool@example.test",
  POSTGRES_USER: "postgres", POSTGRES_DB: "tool_test", POSTGRES_PORT: "0", POSTGRES_PASSWORD: secret() };
const compose = ["compose", "--env-file", "/dev/null", "-f", "compose.yml"];
function run(command, args, capture = false) {
  const result = spawnSync(command, args, { env, encoding: "utf8", stdio: capture ? "pipe" : "inherit" });
  if (result.status !== 0) throw new Error("Disposable database check failed");
  return result.stdout?.trim();
}
try {
  writeFileSync(secretPath, secret(), { mode: 0o600 });
  run("npm", ["run", "build:worker"]);
  run("docker", [...compose, "up", "-d", "--wait"]);
  const port = run("docker", [...compose, "port", "postgres", "5432"], true).split(":").at(-1);
  env.ADMIN_DATABASE_URL = `postgresql://postgres:${env.POSTGRES_PASSWORD}@127.0.0.1:${port}/tool_test`;
  env.MIGRATION_DATABASE_URL = `postgresql://tool_owner:${secret()}@127.0.0.1:${port}/tool_test`;
  env.AUTH_DATABASE_URL = `postgresql://tool_auth:${secret()}@127.0.0.1:${port}/tool_test`;
  env.DATABASE_URL = `postgresql://tool_app:${secret()}@127.0.0.1:${port}/tool_test`;
  run(process.execPath, ["scripts/bootstrap.mjs"]);
  run(process.execPath, ["scripts/migrate.mjs"]);
  run(process.execPath, ["scripts/migrate.mjs"]);
  const [command, ...args] = process.argv.slice(2);
  run(command, args);
} catch {
  console.error("Disposable database checks failed; credentials are withheld");
  process.exitCode = 1;
} finally {
  try { run("docker", [...compose, "down", "--volumes"]); }
  finally { removeSecret(); }
}
