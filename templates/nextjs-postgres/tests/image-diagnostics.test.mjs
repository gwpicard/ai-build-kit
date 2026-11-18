import { randomBytes } from 'node:crypto';
import { readFileSync, mkdtempSync, writeFileSync, existsSync, rmSync } from 'node:fs';
import { spawn as spawnChild } from 'node:child_process';
import { once } from 'node:events';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { expect, test, vi, afterEach } from 'vitest';
import { checkImage } from '../scripts/test-image.mjs';
import { redact, tail } from '../scripts/image-diagnostics.mjs';

afterEach(() => { vi.unstubAllEnvs(); vi.restoreAllMocks(); });

function fixture(fault) {
  vi.stubEnv('CODEX_RUN_ID', 'image-diagnostics-test');
  vi.stubEnv('ABK_DOCKER_SCOPE', 'fixture');
  const canary = randomBytes(24).toString('hex');
  const connection = `postgresql://fixture:${canary}@database.invalid/tool`;
  const calls = [];
  let worker = false, stopped = false, database = true, password;
  const output = `old line\nconnection=${connection}\npassword="${canary}"\ncontainer-specific failure\n`;
  const success = (stdout = '') => ({ status: 0, stdout, stderr: '' });
  function spawn(command, args, options) {
    calls.push({ command, args, options });
    if (args[0] === 'build') {
      const source = readFileSync(args[args.indexOf('-f') + 1], 'utf8');
      expect(source.match(/^LABEL ai-build-kit.run=/gm)?.length).toBe(source.match(/^FROM /gm)?.length);
      expect(options.env.DOCKER_BUILDKIT).toBe('0');
      expect(args).toContain('--force-rm');
    }
    if (command === 'docker' && ['run', 'build'].includes(args[0]) || args[0] === 'network' && args[1] === 'create') {
      expect(args).toContain('ai-build-kit.run=image-diagnostics-test');
      expect(args).toContain('ai-build-kit.scope=fixture');
    }
    const role = args.at(-1);
    if (args[0] === 'run' && ['web', 'worker'].includes(role)) password = options.env.SMTP_PASSWORD;
    if (fault === 'build' && args[0] === 'build'
      || fault === `${role} start` && args[0] === 'run'
      || fault === 'migrate' && role === 'migrate') return { status: 1, stdout: '', stderr: output };
    if (args[0] === 'port') return success('127.0.0.1:12345');
    if (args[0] === 'run' && role === 'worker') worker = true;
    if (args[0] === 'stop') {
      if (args[1].endsWith('-worker')) stopped = true;
      else database = false;
    }
    if (args[0] === 'logs') {
      if (args.includes('--tail')) return success(output);
      if (fault === 'credentials') return success(JSON.stringify({ event: 'fixture.leak', value: password }));
      if (fault === 'logs' || fault === 'worker logs' && args[1].endsWith('-worker')) return success(output);
      return success('{"event":"fixture.started"}\n');
    }
    return success();
  }
  async function request() {
    if (fault === 'health' || fault === 'heartbeat' && worker || fault === 'stopped heartbeat' && stopped
      || fault === 'database health' && !database) throw new Error(`fetch failed ${connection}`);
    return { status: worker && !stopped ? 200 : 503,
      json: async () => ({ database: database ? 'ok' : 'unavailable', commit: 'a'.repeat(40) }) };
  }
  return { canary, connection, calls, options: { spawn, request, sleep: async () => {}, waitMs: 0, report: () => {} } };
}

for (const [fault, role, stage] of [
  ['build', 'web/worker/migrate', 'build'],
  ['web start', 'web', 'start'], ['worker start', 'worker', 'start'],
  ['migrate', 'migrate', 'migrate'], ['health', 'web', 'health'],
  ['heartbeat', 'worker', 'heartbeat'], ['stopped heartbeat', 'worker', 'heartbeat'],
  ['database health', 'web', 'health'], ['logs', 'web', 'logs'], ['worker logs', 'worker', 'logs'],
  ['credentials', 'web', 'logs'],
]) test(`reports and redacts a planted ${fault} failure`, async () => {
  const f = fixture(fault);
  let message;
  try { await checkImage(f.options); } catch (error) { message = error.message; }
  expect(message).toContain(`${role} ${stage} failed`);
  expect(message).toContain('container-specific failure');
  expect(message).toContain('[redacted]');
  expect(message).not.toContain(f.canary);
  expect(message).not.toContain(f.connection);
  for (const call of f.calls) {
    if (call.options.env.SMTP_PASSWORD) expect(message.includes(call.options.env.SMTP_PASSWORD)).toBe(false);
  }
  const diagnostic = f.calls.find(call => call.args.includes('--tail'));
  if (fault !== 'build') {
    expect(diagnostic.args.at(-1)).toMatch(new RegExp(`-${role === 'migrate' ? 'migrate-0' : role}$`));
  }
  const created = f.calls.filter(call => call.args[0] === 'run').map(call => call.args[call.args.indexOf('--name') + 1]);
  const removed = f.calls.filter(call => call.args[0] === 'rm').map(call => call.args.at(-1));
  expect(removed.sort()).toEqual(created.sort());
  expect(f.calls.some(call => call.args[0] === 'image' && call.args[1] === 'rm')).toBe(true);
});

test('keeps every image assertion and removes containers after a pass', async () => {
  const f = fixture();
  const reports = [];
  await checkImage({ ...f.options, report: line => reports.push(line) });
  expect(reports).toHaveLength(4);
  expect(f.calls.filter(call => call.args[0] === 'run' && call.args.at(-1) === 'migrate')).toHaveLength(2);
  expect(f.calls.filter(call => call.args[0] === 'rm')).toHaveLength(5);
});

test('waits for readiness beyond the old 45-second limit', async () => {
  const f = fixture();
  let failures = 0, elapsed = 0;
  vi.spyOn(performance, 'now').mockImplementation(() => elapsed);
  await checkImage({ ...f.options, waitMs: undefined, sleep: async ms => { elapsed += ms; }, request: async (...args) => {
    if (failures++ < 100) throw new Error('not listening yet');
    return f.options.request(...args);
  } });
  expect(elapsed).toBe(50_000);
});

test('redacts credentials before selecting the final output lines', () => {
  const canary = randomBytes(24).toString('base64');
  const unknown = randomBytes(24).toString('hex');
  const output = `-----BEGIN PRIVATE KEY-----\n${'private material\n'.repeat(50)}-----END PRIVATE KEY-----\n`
    + [`postgresql://user:${unknown}@db.invalid/tool`, `Password='${unknown}'`, `access_token: "${unknown}"`,
      `Authorization: Bearer ${unknown}`, `AccountKey=${unknown};`, `api-key=${unknown}`, `pwd=${unknown}`,
      `host=database.invalid user=fixture password=${unknown}`,
      `Server=database.invalid;User Id=fixture;Password=${unknown}`,
      JSON.stringify({ event: 'fixture', credentials: { value: unknown }, tokens: [unknown, unknown] }),
      `sk_${unknown}`, `ghp_${unknown}`,
      canary, encodeURIComponent(canary), Buffer.from(canary).toString('base64'), 'useful final line'].join('\n');
  const clean = tail(output, [canary]);
  expect(clean).not.toContain(canary);
  expect(clean).not.toContain(unknown);
  expect(clean).not.toContain('private material');
  expect(clean).toContain('useful final line');
  expect(tail(Array.from({ length: 60 }, (_, i) => `line ${i}`).join('\n'))).not.toContain('line 19\n');
  expect(redact('password="two words"\ntoken=another value')).toBe('password=[redacted]\ntoken=[redacted]');
});

test('a short known value cannot break connection-string redaction', () => {
  const canary = randomBytes(24).toString('hex');
  const clean = redact(`postgresql://user:${canary}@database.invalid/tool`, ['/']);
  expect(clean.includes(canary)).toBe(false);
  expect(clean).toBe('[redacted]');
});

test('an interrupted image build removes its temporary directory', async () => {
  const work = mkdtempSync(join(tmpdir(), 'image-interrupt-'));
  const marker = join(work, 'marker');
  writeFileSync(join(work, 'docker'), `#!/bin/sh
if [ "$1" = build ]; then
  while [ "$#" -gt 0 ]; do
    if [ "$1" = -f ]; then
      printf '%s' "$2" > "$IMAGE_CHECK_MARKER.pending"
      mv "$IMAGE_CHECK_MARKER.pending" "$IMAGE_CHECK_MARKER"
      break
    fi
    shift
  done
  exec sleep 300
fi
`, { mode: 0o700 });
  const child = spawnChild(process.execPath, ['scripts/test-image.mjs'], {
    detached: true, stdio: 'ignore', env: { ...process.env,
      PATH: `${work}:${process.env.PATH}`, IMAGE_CHECK_MARKER: marker,
      CODEX_RUN_ID: 'image-interrupt-test', ABK_DOCKER_SCOPE: 'fixture' },
  });
  const ended = once(child, 'exit');
  try {
    const deadline = performance.now() + 10_000;
    while (!existsSync(marker) && performance.now() < deadline) await delay(20);
    expect(existsSync(marker)).toBe(true);
    const scratch = dirname(readFileSync(marker, 'utf8'));
    process.kill(-child.pid, 'SIGTERM');
    const [code] = await ended;
    expect(code).not.toBe(0);
    expect(existsSync(scratch)).toBe(false);
  } finally {
    if (child.exitCode === null && child.signalCode === null) {
      process.kill(-child.pid, 'SIGTERM');
      await ended;
    }
    rmSync(work, { recursive: true, force: true });
  }
});
