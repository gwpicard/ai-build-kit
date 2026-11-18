import { randomBytes } from 'node:crypto';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { expect, test, vi, afterEach } from 'vitest';
import { checkImage } from '../scripts/test-image.mjs';

afterEach(() => { vi.unstubAllEnvs(); vi.restoreAllMocks(); });

function fixture(fault, commandTimeout = false) {
  vi.stubEnv('CODEX_RUN_ID', 'image-diagnostics-test');
  vi.stubEnv('ABK_DOCKER_SCOPE', 'fixture');
  const canary = randomBytes(24).toString('hex');
  const connection = `postgresql://fixture:${canary}@database.invalid/tool`;
  const output = `container-specific failure\n${connection}\nPGPASS: ${canary}\n`;
  const calls = [], reports = [];
  let worker = false, stopped = false, database = true, password;
  const success = (stdout = '') => ({ status: 0, stdout, stderr: '' });
  function spawn(command, args, options) {
    calls.push({ command, args, options });
    const role = args.at(-1);
    if (args[0] === 'run' && ['web', 'worker'].includes(role)) password = options.env.SMTP_PASSWORD;
    if (fault === 'build' && args[0] === 'build'
      || fault === 'network start' && args[0] === 'network' && args[1] === 'create'
      || fault === 'database start' && args[0] === 'run' && args.includes('postgres:17.6-alpine')
      || fault === `${role} start` && args[0] === 'run'
      || fault === 'bootstrap' && command === process.execPath
      || fault === 'migrate' && role === 'migrate') {
      return { status: commandTimeout ? null : 23, stdout: output, stderr: output,
        error: commandTimeout ? Object.assign(new Error(output), { code: 'ETIMEDOUT' }) : undefined };
    }
    if (fault === 'database readiness' && args[0] === 'exec') return { status: 1, stdout: output, stderr: output };
    if (args[0] === 'port') return success('127.0.0.1:12345');
    if (args[0] === 'run' && role === 'worker') worker = true;
    if (args[0] === 'stop') {
      if (args[1].endsWith('-worker')) stopped = true;
      else database = false;
    }
    if (args[0] === 'logs') {
      if (fault === 'credentials') return success(JSON.stringify({ event: 'fixture.leak', value: password }));
      if (fault === 'logs' || fault === 'worker logs' && args[1].endsWith('-worker')) return success(output);
      if (fault === 'log stderr') return { status: 0, stdout: '{"event":"fixture.started"}', stderr: output };
      if (fault === 'log exit') return { status: 23, stdout: output, stderr: output };
      return success('{"event":"fixture.started"}\n');
    }
    return success();
  }
  async function request() {
    if (fault === 'health' || fault === 'heartbeat' && worker || fault === 'stopped heartbeat' && stopped
      || fault === 'database health' && !database) throw new Error(output);
    return { status: worker && !stopped ? 200 : 503,
      json: async () => ({ database: fault === 'health assertion' ? connection : database ? 'ok' : 'unavailable', commit: 'a'.repeat(40) }) };
  }
  return { canary, connection, calls, reports,
    options: { spawn, request, sleep: async () => {}, waitMs: 0, report: line => reports.push(line) } };
}

const commandFailures = [
  ['build', 'web/worker/migrate', 'build'], ['network start', 'migrate', 'start'],
  ['database start', 'migrate', 'start'], ['web start', 'web', 'start'], ['worker start', 'worker', 'start'],
  ['bootstrap', 'migrate', 'migrate'], ['migrate', 'migrate', 'migrate'],
];
const failures = [
  ...commandFailures.map(row => [...row, 'exit code 23']),
  ['database readiness', 'migrate', 'start', 'timeout after 0s'],
  ['health', 'web', 'health', 'timeout after 0s'],
  ['heartbeat', 'worker', 'heartbeat', 'timeout after 0s'],
  ['stopped heartbeat', 'worker', 'heartbeat', 'timeout after 0s'],
  ['database health', 'web', 'health', 'timeout after 0s'],
  ['health assertion', 'web', 'health', 'check exit code 1'],
  ['logs', 'web', 'logs', 'check exit code 1'], ['worker logs', 'worker', 'logs', 'check exit code 1'],
  ['log stderr', 'web', 'logs', 'check exit code 1'], ['log exit', 'web', 'logs', 'exit code 23'],
  ['credentials', 'web', 'logs', 'check exit code 1'],
];

for (const [fault, role, stage, reason] of failures) test(`names a planted ${fault} failure and withholds all output`, async () => {
  const f = fixture(fault);
  let message;
  try { await checkImage(f.options); } catch (error) { message = error.message; }
  expect(message).toBe(`${role} ${stage} failed (${reason}); diagnostics withheld because they may contain connection data`);
  const printed = [...f.reports, message].join('\n');
  expect(printed).not.toContain(f.canary);
  expect(printed).not.toContain(f.connection);
  expect(printed).not.toContain('container-specific failure');
  for (const call of f.calls) {
    if (call.options.env.SMTP_PASSWORD) expect(printed).not.toContain(call.options.env.SMTP_PASSWORD);
  }
  expect(f.calls.some(call => call.args.includes('--tail'))).toBe(false);
  const created = f.calls.filter(call => call.args[0] === 'run' && call.args.includes('--name'))
    .map(call => call.args[call.args.indexOf('--name') + 1]);
  const removed = f.calls.filter(call => call.args[0] === 'rm').map(call => call.args.at(-1));
  expect(removed.sort()).toEqual(created.sort());
  expect(f.calls.some(call => call.args[0] === 'image' && call.args[1] === 'rm')).toBe(true);
});

for (const [fault, role, stage] of commandFailures) test(`reports a ${fault} command timeout without its error text`, async () => {
  const f = fixture(fault, true);
  await expect(checkImage(f.options)).rejects.toThrow(
    `${role} ${stage} failed (timeout after 600s); diagnostics withheld because they may contain connection data`);
});

test('keeps every image assertion and removes containers after a pass', async () => {
  const f = fixture();
  await checkImage(f.options);
  expect(f.reports).toEqual([
    'Passed: the image migrates and repeats migration',
    'Passed: health detects absent, running and stopped worker heartbeats',
    'Passed: health detects database failure',
    'Passed: web and worker emit JSON events without credentials',
  ]);
  expect(f.calls.filter(call => call.args[0] === 'run' && call.args.at(-1) === 'migrate')).toHaveLength(2);
  expect(f.calls.filter(call => call.args[0] === 'rm')).toHaveLength(3);
});

for (const readiness of ['database', 'web']) test(`waits for ${readiness} readiness beyond the old 45-second limit`, async () => {
  const f = fixture();
  let attempts = 0, elapsed = 0;
  vi.spyOn(performance, 'now').mockImplementation(() => elapsed);
  const timeout = vi.spyOn(AbortSignal, 'timeout');
  await checkImage({ ...f.options, waitMs: undefined, sleep: async ms => { elapsed += ms; },
    spawn: (...args) => {
      if (readiness === 'database' && args[1][0] === 'exec' && attempts++ < 100) return { status: 1, stdout: '', stderr: '' };
      return f.options.spawn(...args);
    },
    request: async (...args) => {
      if (readiness === 'web' && attempts++ < 100) throw new Error('not listening yet');
      return f.options.request(...args);
    },
  });
  expect(elapsed).toBe(50_000);
  expect(timeout.mock.calls.every(([ms]) => ms === 10_000)).toBe(true);
});

test('stops polling at the readiness deadline and withholds the last error', async () => {
  const f = fixture('health');
  let elapsed = 0;
  vi.spyOn(performance, 'now').mockImplementation(() => elapsed);
  await expect(checkImage({ ...f.options, waitMs: undefined, sleep: async ms => { elapsed += ms; } }))
    .rejects.toThrow('web health failed (timeout after 180s); diagnostics withheld because they may contain connection data');
  expect(elapsed).toBe(180_000);
});

test('the command line withholds build output even if cleanup also fails', () => {
  vi.stubEnv('CODEX_RUN_ID', 'image-diagnostics-test');
  vi.stubEnv('ABK_DOCKER_SCOPE', 'fixture');
  const work = mkdtempSync(join(tmpdir(), 'image-output-'));
  const canary = randomBytes(24).toString('hex');
  try {
    writeFileSync(join(work, 'docker'), `#!/bin/sh\nprintf '%s\\n' '${canary}'\nprintf '%s\\n' '${canary}' >&2\nexit 23\n`, { mode: 0o700 });
    const result = spawnSync(process.execPath, ['scripts/test-image.mjs'], {
      encoding: 'utf8', env: { ...process.env, PATH: `${work}:${process.env.PATH}` },
    });
    expect(result.status).toBe(1);
    expect(result.stdout).toBe('');
    expect(result.stderr).toBe('web/worker/migrate build failed (exit code 23); diagnostics withheld because they may contain connection data\nContainer cleanup needs checking\n');
    expect(result.stderr).not.toContain(canary);
  } finally {
    rmSync(work, { recursive: true, force: true });
  }
});
