import { randomBytes } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { setTimeout as delay } from 'node:timers/promises';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import assert from 'node:assert/strict';

const id = `handover-image-${randomBytes(6).toString('hex')}`;
const scratch = mkdtempSync(join(tmpdir(), id));
const image = process.argv[2] ?? `${id}:test`;
const ownImage = !process.argv[2];
const containers = [];
let network = false;
const env = { ...process.env, BUILDX_CONFIG: join(scratch, 'buildx') };
function run(command, args, extra = {}) {
  const result = spawnSync(command, args, { env: { ...env, ...extra }, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
  if (result.status !== 0) throw new Error(`${command} step failed; diagnostics withheld because they may contain connection data`);
  return result.stdout.trim();
}
function docker(args, extra) { return run('docker', args, extra); }
async function until(action) {
  for (let i = 0; i < 90; i++) {
    try { if (await action()) return; } catch { /* Retry while the container starts. */ }
    await delay(500);
  }
  throw new Error('The expected container state did not arrive');
}
try {
  if (ownImage) docker(['build', '-t', image, '.']);
  docker(['network', 'create', id]); network = true;
  const password = randomBytes(24).toString('hex');
  const db = `${id}-db`; containers.push(db);
  docker(['run', '-d', '--name', db, '--network', id, '--network-alias', 'database',
    '--tmpfs', '/var/lib/postgresql/data', '-p', '127.0.0.1::5432',
    '-e', 'POSTGRES_PASSWORD', '-e', 'POSTGRES_DB=tool_test', 'postgres:17.6-alpine'], { POSTGRES_PASSWORD: password });
  await until(() => { docker(['exec', db, 'pg_isready', '-U', 'postgres', '-d', 'tool_test']); return true; });
  const port = docker(['port', db, '5432/tcp']).split(':').at(-1);
  const url = (role, host) => `postgresql://${role}:${password}@${host}/tool_test`;
  run(process.execPath, ['scripts/bootstrap.mjs'], { NODE_ENV: 'test',
    ADMIN_DATABASE_URL: url('postgres', `127.0.0.1:${port}`),
    MIGRATION_DATABASE_URL: url('tool_owner', `127.0.0.1:${port}`), DATABASE_URL: url('tool_app', `127.0.0.1:${port}`) });
  const migration = { MIGRATION_DATABASE_URL: url('tool_owner', 'database:5432') };
  for (let i = 0; i < 2; i++) docker(['run', '--rm', '--network', id, '-e', 'MIGRATION_DATABASE_URL', image, 'migrate'], migration);
  console.log('Passed: the image migrates and repeats migration');
  const runtime = { DATABASE_URL: url('tool_app', 'database:5432'), JOBS_MODE: 'worker',
    FILES_S3_BUCKET: 'private-files', FILES_S3_REGION: 'local', AWS_ACCESS_KEY_ID: password, AWS_SECRET_ACCESS_KEY: password,
    SMTP_HOST: 'smtp.example.test', SMTP_PORT: '587', SMTP_USER: 'fixture', SMTP_PASSWORD: password,
    MAIL_FROM: 'tool@example.test', SOURCE_COMMIT: 'a'.repeat(40) };
  const options = Object.keys(runtime).flatMap(name => ['-e', name]);
  const web = `${id}-web`; containers.push(web);
  docker(['run', '-d', '--name', web, '--network', id, '-p', '127.0.0.1::3000', ...options, image, 'web'], runtime);
  const webPort = docker(['port', web, '3000/tcp']).split(':').at(-1);
  const health = () => fetch(`http://127.0.0.1:${webPort}/api/health`, { signal: AbortSignal.timeout(3000) });
  await until(async () => (await health()).status === 503);
  assert.equal((await (await health()).json()).database, 'ok');
  const worker = `${id}-worker`; containers.push(worker);
  docker(['run', '-d', '--name', worker, '--network', id, ...options, image, 'worker'], runtime);
  await until(async () => (await health()).status === 200);
  assert.equal((await (await health()).json()).commit, 'a'.repeat(40));
  docker(['stop', worker]);
  await until(async () => (await health()).status === 503);
  console.log('Passed: health detects absent, running and stopped worker heartbeats');
  await delay(1500); // Let the idle app connection close before stopping the database.
  docker(['stop', db]);
  await until(async () => (await (await health()).json()).database === 'unavailable');
  console.log('Passed: health detects database failure');
  for (const name of [web, worker]) {
    const captured = spawnSync('docker', ['logs', name], { env, encoding: 'utf8' });
    assert.equal(captured.status, 0);
    assert.equal(captured.stderr, '');
    const logs = captured.stdout;
    assert.ok(logs.trim());
    for (const line of logs.split('\n').filter(Boolean)) assert.equal(typeof JSON.parse(line).event, 'string');
    assert.ok(!logs.includes(password));
  }
  console.log('Passed: web and worker emit JSON events without credentials');
} catch (error) { console.error(error.message); process.exitCode = 1; }
finally {
  let failed = false;
  for (const name of containers.reverse()) {
    try { docker(['rm', '-f', '-v', name]); } catch { failed = true; }
  }
  if (network) { try { docker(['network', 'rm', id]); } catch { failed = true; } }
  if (ownImage) { try { docker(['image', 'rm', image]); } catch { failed = true; } }
  rmSync(scratch, { recursive: true });
  if (failed) { console.error('Container cleanup needs checking'); process.exitCode = 1; }
}
