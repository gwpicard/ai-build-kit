import { randomBytes } from "node:crypto";
import { spawnSync } from "node:child_process";

// The enclosing docker-run.sh owns the exit and signal traps.
if (!process.env.ABK_DOCKER_SCOPE) throw new Error("Run through scripts/docker-run.sh");
const secret = () => randomBytes(24).toString("hex");
const env = { ...process.env, NODE_ENV: "test", ABK_DATABASE_READY: "1",
  POSTGRES_USER: "postgres", POSTGRES_DB: "tool_test", POSTGRES_PORT: "0", POSTGRES_PASSWORD: secret() };
const compose = ["compose", "--env-file", "/dev/null", "-f", "compose.yml"];
function run(command, args, capture = false) {
  const result = spawnSync(command, args, { env, encoding: "utf8", stdio: capture ? "pipe" : "inherit" });
  if (result.status !== 0) throw new Error("Disposable database check failed");
  return result.stdout?.trim();
}
try {
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
  run("docker", [...compose, "down", "--volumes"]);
}
