import { randomBytes } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { setTimeout as delay } from 'node:timers/promises';
import { mkdtempSync, rmSync, writeFileSync, chmodSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import { labelledDockerfile, tail, redact } from './image-diagnostics.mjs';

export async function checkImage({ spawn = spawnSync, request = fetch, sleep = delay, waitMs = 180_000,
  image: suppliedImage, report = console.log } = {}) {

  if (!process.env.ABK_DOCKER_SCOPE || !process.env.CODEX_RUN_ID) throw new Error('Run through scripts/docker-run.sh');
  const id = `handover-image-${randomBytes(6).toString('hex')}`;
  const scratch = mkdtempSync(join(tmpdir(), id));
  const signals = [['SIGHUP', 129], ['SIGINT', 130], ['SIGTERM', 143]].map(([signal, code]) => {
    const stop = () => { rmSync(scratch, { recursive: true, force: true }); process.exit(code); };
    process.once(signal, stop);
    return [signal, stop];
  });
  const image = suppliedImage ?? `${id}:test`;
  const ownImage = !suppliedImage;
  const containers = [];
  let network = false;
  const env = { ...process.env, BUILDX_CONFIG: join(scratch, 'buildx') };
  const labels = ['--label', `ai-build-kit.run=${env.CODEX_RUN_ID}`, '--label', `ai-build-kit.scope=${env.ABK_DOCKER_SCOPE}`];
  const secrets = Object.entries(env).filter(([name]) => /password|secret|token|key|credential|url|dsn/i.test(name)).map(([, value]) => value);
  let context = { role: 'web/worker/migrate', stage: 'build' };
  let captured = '';
  let stderr = '';
  let failure;
  function at(role, stage, container) { context = { role, stage, container }; captured = ''; }
  function run(command, args, extra = {}) {
    for (const [name, value] of Object.entries(extra)) {
      if (/password|secret|token|key|credential|url|dsn/i.test(name)) secrets.push(value);
    }
    const result = spawn(command, args, { env: { ...env, ...extra }, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024, timeout: 600_000 });
    stderr = result.stderr ?? '';
    captured = `${result.stdout ?? ''}\n${stderr}`;
    if (result.status !== 0) throw new Error(result.error?.code ?? `command exited ${result.status ?? 'without a status'}`);
    return result.stdout.trim();
  }
  function docker(args, extra) { return run('docker', args, extra); }
  async function until(action) {
    const deadline = performance.now() + waitMs;
    let lastError;
    do {
      try { if (await action()) return; } catch (error) { lastError = error; }
      await sleep(500);
    } while (performance.now() < deadline);
    throw new Error(`Expected condition did not arrive within ${waitMs / 1000}s${lastError ? ` (${lastError.message})` : ''}`);
  }
  try {
    if (ownImage) {
      // The classic builder inherits these labels in every intermediate image and container.
      // Its forced removal and the enclosing label sweep also cover failed or interrupted builds.
      const dockerfile = join(scratch, 'Dockerfile');
      writeFileSync(dockerfile, labelledDockerfile(readFileSync('Dockerfile', 'utf8'), env.CODEX_RUN_ID, env.ABK_DOCKER_SCOPE));
      docker(['build', '--force-rm', ...labels, '-f', dockerfile, '-t', image, '.'], { DOCKER_BUILDKIT: '0' });
    }
    at('migrate', 'start');
    docker(['network', 'create', ...labels, id]); network = true;
    const password = randomBytes(24).toString('hex'); secrets.push(password);
    const db = `${id}-db`; containers.push(db);
    at('migrate', 'start', db);
    docker(['run', ...labels, '-d', '--name', db, '--network', id, '--network-alias', 'database',
      '--tmpfs', '/var/lib/postgresql/data', '-p', '127.0.0.1::5432',
      '-e', 'POSTGRES_PASSWORD', '-e', 'POSTGRES_DB=tool_test', 'postgres:17.6-alpine'], { POSTGRES_PASSWORD: password });
    await until(() => { docker(['exec', db, 'pg_isready', '-U', 'postgres', '-d', 'tool_test']); return true; });
    const port = docker(['port', db, '5432/tcp']).split(':').at(-1);
    const url = (role, host) => `postgresql://${role}:${password}@${host}/tool_test`;
    at('migrate', 'migrate', db);
    run(process.execPath, ['scripts/bootstrap.mjs'], { NODE_ENV: 'test',
      ADMIN_DATABASE_URL: url('postgres', `127.0.0.1:${port}`),
      AUTH_DATABASE_URL: url('tool_auth', `127.0.0.1:${port}`),
      MIGRATION_DATABASE_URL: url('tool_owner', `127.0.0.1:${port}`), DATABASE_URL: url('tool_app', `127.0.0.1:${port}`) });
    const migration = { MIGRATION_DATABASE_URL: url('tool_owner', 'database:5432') };
    for (let i = 0; i < 2; i++) {
      const name = `${id}-migrate-${i}`; containers.push(name);
      at('migrate', 'migrate', name);
      docker(['run', ...labels, '--name', name, '--network', id, '-e', 'MIGRATION_DATABASE_URL', image, 'migrate'], migration);
    }
    report('Passed: the image migrates and repeats migration');
    const secretPath = join(scratch, 'sign-in-secret');
    writeFileSync(secretPath, password);
    chmodSync(scratch, 0o755); chmodSync(secretPath, 0o644);
    const mounts = ['--mount', `type=bind,source=${secretPath},target=/run/secrets/sign-in,readonly`];
    const runtime = { AUTH_BASE_URL: 'https://tool.example.test', STAFF_PROVIDER: 'none',
      AUTH_SECRET_FILE: '/run/secrets/sign-in', AUTH_DATABASE_URL: url('tool_auth', 'database:5432'),
      SMTP_FROM: 'sign-in@example.test', SMTP_PASSWORD_FILE: '/run/secrets/sign-in',
      DATABASE_URL: url('tool_app', 'database:5432'), JOBS_MODE: 'worker',
      FILES_S3_BUCKET: 'private-files', FILES_S3_REGION: 'local', AWS_ACCESS_KEY_ID: password, AWS_SECRET_ACCESS_KEY: password,
      SMTP_HOST: 'smtp.example.test', SMTP_PORT: '587', SMTP_USER: 'fixture', SMTP_PASSWORD: password,
      MAIL_FROM: 'tool@example.test', SOURCE_COMMIT: 'a'.repeat(40) };
    const options = Object.keys(runtime).flatMap(name => ['-e', name]);
    const web = `${id}-web`; containers.push(web);
    at('web', 'start', web);
    docker(['run', ...labels, '-d', '--name', web, '--network', id, '-p', '127.0.0.1::3000', ...mounts, ...options, image, 'web'], runtime);
    const webPort = docker(['port', web, '3000/tcp']).split(':').at(-1);
    const health = () => request(`http://127.0.0.1:${webPort}/api/health`, { signal: AbortSignal.timeout(10_000) });
    at('web', 'health', web);
    await until(async () => (await health()).status === 503);
    assert.equal((await (await health()).json()).database, 'ok');
    const worker = `${id}-worker`; containers.push(worker);
    at('worker', 'start', worker);
    docker(['run', ...labels, '-d', '--name', worker, '--network', id, ...options, image, 'worker'], runtime);
    at('worker', 'heartbeat', worker);
    await until(async () => (await health()).status === 200);
    assert.equal((await (await health()).json()).commit, 'a'.repeat(40));
    docker(['stop', worker]);
    await until(async () => (await health()).status === 503);
    report('Passed: health detects absent, running and stopped worker heartbeats');
    // Health must detect database loss even when the app still has a pooled connection.
    at('web', 'health', web);
    docker(['stop', db]);
    await until(async () => (await (await health()).json()).database === 'unavailable');
    report('Passed: health detects database failure');
    for (const name of [web, worker]) {
      at(name === web ? 'web' : 'worker', 'logs', name);
      const logs = docker(['logs', name]);
      assert.equal(stderr, '');
      assert.ok(logs.trim());
      for (const line of logs.split('\n').filter(Boolean)) assert.equal(typeof JSON.parse(line).event, 'string');
      assert.ok(!logs.includes(password));
    }
    report('Passed: web and worker emit JSON events without credentials');
  } catch (error) {
    const { role, stage, container } = context;
    const reason = error instanceof SyntaxError ? 'container output is not JSON'
      : error.code === 'ERR_ASSERTION' ? 'image assertion failed' : error.message;
    let output = `${role} ${stage} failed: ${redact(reason, secrets)}\nCommand output (last lines):\n${tail(captured, secrets)}`;
    if (container) {
      const logs = spawn('docker', ['logs', '--tail', 'all', container], { env, encoding: 'utf8', timeout: 10_000, maxBuffer: 32 * 1024 * 1024 });
      output += `\n${role} container output (last lines):\n${logs.error ? '(container output could not be captured)' : tail(`${logs.stdout ?? ''}\n${logs.stderr ?? ''}`, secrets)}`;
    }
    failure = new Error(output);
  }
  finally {
    let failed = false;
    for (const name of containers.reverse()) {
      try { docker(['rm', '-f', name]); } catch { failed = true; }
    }
    if (network) { try { docker(['network', 'rm', id]); } catch { failed = true; } }
    if (ownImage) { try { docker(['image', 'rm', '--no-prune', image]); } catch { failed = true; } }
    rmSync(scratch, { recursive: true });
    for (const [signal, stop] of signals) process.removeListener(signal, stop);
    if (failed) failure = new Error(`${failure?.message ?? ''}\nContainer cleanup needs checking; the enclosing label sweep will retry`);
  }
  if (failure) throw failure;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try { await checkImage({ image: process.argv[2] }); }
  catch (error) { console.error(error.message); process.exitCode = 1; }
}
