import { randomBytes } from "node:crypto";
import { mkdtemp, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { S3Client, CreateBucketCommand } from "@aws-sdk/client-s3";
import { BlobServiceClient, StorageSharedKeyCredential } from "@azure/storage-blob";

// Provision disposable loopback fixtures only. Credentials never reach tracked files or output.
if (process.env.NODE_ENV === "production") throw new Error("File tests refuse production");
const scratch = await mkdtemp(path.join(tmpdir(), "file-tests-"));
const project = `files-${randomBytes(6).toString("hex")}`;
const secret = () => randomBytes(24).toString("hex");
const accountKey = randomBytes(32).toString("base64");
const env = { ...process.env, NODE_ENV: "test", POSTGRES_USER: "postgres", POSTGRES_DB: "tool_test",
  POSTGRES_PORT: "0", POSTGRES_PASSWORD: secret(), AWS_ACCESS_KEY_ID: secret(), AWS_SECRET_ACCESS_KEY: secret(),
  AWS_EC2_METADATA_DISABLED: "true", FILES_AZURE_ACCOUNT: "filetests", FILES_AZURE_ACCOUNT_KEY: accountKey,
  AZURITE_ACCOUNTS: `filetests:${accountKey}`, FILES_S3_BUCKET: "file-tests", FILES_S3_REGION: "us-east-1",
  FILES_S3_FORCE_PATH_STYLE: "true", FILES_AZURE_CONTAINER: "file-tests" };
// Do not pass inherited AWS session credentials into the local emulator.
delete env.AWS_SESSION_TOKEN;
delete env.AWS_PROFILE;
const envFile = path.join(scratch, "compose.env");
await writeFile(envFile, "", { mode: 0o600 });
const compose = ["compose", "--project-name", project, "--env-file", envFile, "-f", "compose.yml", "-f", "compose.files.yml"];
function run(command, args, capture = false) {
  const result = spawnSync(command, args, { env, encoding: "utf8", stdio: capture ? "pipe" : "inherit" });
  if (result.status !== 0) throw new Error("File test command failed");
  return result.stdout?.trim();
}
function port(service, port) {
  return run("docker", [...compose, "port", service, String(port)], true).split(":").at(-1);
}
async function ready(label, work) {
  let code = "unavailable";
  for (let attempt = 0; attempt < 40; attempt++) {
    try { await work(); return; }
    catch (error) {
      if (/^[A-Za-z0-9_]+$/.test(error.code ?? "")) code = error.code;
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  }
  console.error(`${label} fixture did not start (${code})`);
  throw new Error("Local storage fixture could not start");
}
try {
  run("docker", [...compose, "up", "-d", "--wait"]);
  const dbPort = port("postgres", 5432);
  env.ADMIN_DATABASE_URL = `postgresql://postgres:${env.POSTGRES_PASSWORD}@127.0.0.1:${dbPort}/tool_test`;
  env.MIGRATION_DATABASE_URL = `postgresql://tool_owner:${secret()}@127.0.0.1:${dbPort}/tool_test`;
  env.DATABASE_URL = `postgresql://tool_app:${secret()}@127.0.0.1:${dbPort}/tool_test`;
  env.FILES_S3_ENDPOINT = `http://127.0.0.1:${port("s3", 9000)}`;
  env.FILES_AZURE_ENDPOINT = `http://127.0.0.1:${port("azurite", 10000)}/filetests`;
  run(process.execPath, ["scripts/bootstrap.mjs"]);
  run(process.execPath, ["scripts/migrate.mjs"]);
  const s3 = new S3Client({ endpoint: env.FILES_S3_ENDPOINT, region: env.FILES_S3_REGION, forcePathStyle: true,
    credentials: { accessKeyId: env.AWS_ACCESS_KEY_ID, secretAccessKey: env.AWS_SECRET_ACCESS_KEY } });
  await ready("S3", () => s3.send(new CreateBucketCommand({ Bucket: env.FILES_S3_BUCKET })));
  s3.destroy();
  const azure = new BlobServiceClient(env.FILES_AZURE_ENDPOINT, new StorageSharedKeyCredential(env.FILES_AZURE_ACCOUNT, accountKey));
  await ready("Azure Blob", () => azure.getContainerClient(env.FILES_AZURE_CONTAINER).create());
  run(process.execPath, ["node_modules/vitest/vitest.mjs", "run", "--config", "vitest.files.config.ts"]);
} catch {
  console.error("File container checks failed; signed addresses and credentials are withheld");
  process.exitCode = 1;
} finally {
  try { run("docker", [...compose, "down", "--volumes"]); }
  finally { await rm(scratch, { recursive: true, force: true }); }
}
