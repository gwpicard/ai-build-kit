import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, writeFileSync, mkdtempSync, cpSync, rmSync, symlinkSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import { run, hostRecordFor } from '../scripts/handover.mjs';

const root = resolve('.');
const require = createRequire(import.meta.url);
const readerPath = existsSync('hosting/host-record.cjs') ? resolve('hosting/host-record.cjs') : resolve('../../.agents/skills/merge/scripts/host-record.cjs');
const { readHostRecord, mergeEffect } = require(readerPath);
const fixtures = existsSync('tests/fixtures/host-record') ? resolve('tests/fixtures/host-record') : resolve('../../.agents/tests/fixtures/host-record');
const fixture = name => readFileSync(resolve(fixtures, name), 'utf8');
const valid = JSON.parse(fixture('valid.json'));
const copies = [];
after(() => copies.forEach(path => rmSync(path, { recursive: true })));
function copy() {
  const dir = mkdtempSync(resolve(tmpdir(), 'host-record-test-'));
  copies.push(dir);
  for (const path of ['src', 'scripts', 'db', 'hosting', 'masterplan.md', 'Dockerfile', '.env.example']) cpSync(resolve(root, path), resolve(dir, path), { recursive: true });
  symlinkSync(resolve(root, 'node_modules'), resolve(dir, 'node_modules'), 'dir');
  if (!existsSync(resolve(dir, 'hosting/handover.schema.json'))) cpSync(resolve('../../hosting/handover.schema.json'), resolve(dir, 'hosting/handover.schema.json'));
  return dir;
}
function save(dir, value) { writeFileSync(resolve(dir, 'hosting/host-record.json'), JSON.stringify(value)); }
test('a valid record reports structure without printing values', () => {
  const result = readHostRecord(root, fixture('valid.json'));
  assert.equal(result.status, 'valid');
  assert.ok(!result.diagnostics.join('\n').includes(valid.tool));
  const cli = spawnSync('node', [readerPath, 'check', root, '--stdin'], { input: fixture('valid.json'), encoding: 'utf8' });
  assert.equal(cli.status, 0); assert.ok(!cli.stdout.includes(valid.address));
});
test('an adopted record preserves missing evidence', () => {
  const result = readHostRecord(root, fixture('found.json'));
  assert.equal(result.status, 'valid');
  assert.equal(result.record.last_restore_drill, null);
  assert.deepEqual(result.record.rollback_targets, []);
  assert.equal(result.record.gaps[0].status, 'open');
});
for (const probe of JSON.parse(fixture('invalid-cases.json'))) {
  test(`upstream invalid fixture names ${probe.field} and withholds values`, () => {
    const result = readHostRecord(root, fixture(probe.file.split('/').at(-1)));
    assert.equal(result.status, 'invalid');
    assert.ok(result.diagnostics.some(line => line.startsWith(probe.field + ':')), result.diagnostics.join('\n'));
    if (probe.withheld) assert.ok(!result.diagnostics.join('\n').includes(probe.withheld));
  });
}
test('absent, invalid JSON, unknown versions and unsafe names remain value-free', () => {
  assert.equal(readHostRecord(copy()).status, 'absent');
  for (const version of ['1.1', '2.0', 'synthetic-marker']) {
    const result = readHostRecord(root, JSON.stringify({ ...valid, schema_version: version }));
    assert.equal(result.status, 'unknown-version');
    assert.ok(!result.diagnostics.join('\n').includes(version));
  }
  for (const text of ['{"synthetic-marker":', JSON.stringify({ ...valid, 'synthetic-marker': 'withheld-marker' })]) {
    const result = readHostRecord(root, text);
    assert.equal(result.status, 'invalid');
    assert.ok(!result.diagnostics.join('\n').includes('synthetic-marker'));
    assert.ok(!result.diagnostics.join('\n').includes('withheld-marker'));
  }
});
test('missing reader dependencies cannot turn a true setting into a release claim', () => {
  const dir = mkdtempSync(resolve(tmpdir(), 'host-record-no-deps-'));
  copies.push(dir);
  const result = readHostRecord(dir, JSON.stringify({ ...valid, deploys_on_merge: true }));
  assert.equal(result.status, 'could-not-read');
  assert.ok(!mergeEffect(result).includes('This will go live'));
  assert.equal(readHostRecord(dir, JSON.stringify({ ...valid, schema_version: '9.0' })).status, 'unknown-version');
});
test('only a validated true merge setting produces the live wording', () => {
  for (const value of [true, false, 'true', 1, null]) {
    const result = readHostRecord(root, JSON.stringify({ ...valid, deploys_on_merge: value }));
    assert.equal(mergeEffect(result).includes('This will go live'), value === true);
  }
  assert.ok(!mergeEffect(readHostRecord(root, JSON.stringify({ ...valid, deploys_on_merge: true, fit: 'done' }))).includes('This will go live'));
  const duplicate = fixture('valid.json').replace('"deploys_on_merge": false', '"deploys_on_merge": false, "deploys_on_merge": true');
  assert.ok(readHostRecord(root, duplicate).diagnostics.includes('deploys_on_merge: duplicate field'));
  assert.ok(!mergeEffect(readHostRecord(root, duplicate)).includes('This will go live'));
});
test('a merge reads the proposed commit and ignores an uncommitted record', () => {
  const script = process.env.MERGE_SCRIPT ?? resolve('../../.agents/skills/merge/scripts/merge.py');
  const dir = copy();
  function git(...args) {
    const result = spawnSync('git', ['-C', dir, ...args], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr); return result.stdout.trim();
  }
  git('init', '-q', '-b', 'main');
  git('config', 'user.name', 'Guillaume Picard'); git('config', 'user.email', 'fixture@example.invalid');
  function commit(record) {
    save(dir, record); git('add', 'hosting/host-record.json');
    git('-c', 'user.name=Guillaume Picard', 'commit', '-q', '-m', 'Record host setting');
    return git('rev-parse', 'HEAD');
  }
  function effect(head) {
    const result = spawnSync('python3', [script, '--effect', head], { cwd: dir, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr); return result.stdout;
  }
  const manual = commit(valid);
  save(dir, { ...valid, deploys_on_merge: true });
  assert.ok(!effect(manual).includes('This will go live'));
  const automatic = commit({ ...valid, deploys_on_merge: true });
  save(dir, valid);
  assert.ok(effect(automatic).includes('This will go live'));
  const invalid = commit({ ...valid, deploys_on_merge: true, fit: 'done' });
  assert.ok(!effect(invalid).includes('This will go live'));
  assert.ok(effect(invalid).includes('existing recipe'));
});
test('both records render, drift fails, and a hand edit still fails', () => {
  const dir = copy(), path = resolve(dir, 'masterplan.md');
  const before = readFileSync(path, 'utf8');
  save(dir, valid);
  assert.throws(() => run('check', dir), /masterplan/);
  run('render', dir); run('check', dir);
  const text = readFileSync(path, 'utf8');
  for (const value of ['eu-example', 'previous-release', 'checks/restore.txt', 'accepted', valid.gaps[0].acceptance.words]) assert.ok(text.includes(value));
  assert.ok(text.includes('separate release'));
  const updated = { ...valid, deploys_on_merge: true };
  save(dir, updated);
  assert.throws(() => run('check', dir), /masterplan/);
  run('render', dir); assert.ok(readFileSync(path, 'utf8').includes('This will go live'));
  writeFileSync(path, readFileSync(path, 'utf8').replace('previous-release', 'hand edit'));
  assert.throws(() => run('check', dir), /masterplan/);
  run('render', dir);
  assert.equal(readFileSync(resolve(dir, 'hosting/host-record.json'), 'utf8'), JSON.stringify(updated));
  assert.equal(text.slice(0, text.indexOf('<!-- hosting:generated:start -->')), before.slice(0, before.indexOf('<!-- hosting:generated:start -->')));
});
test('invalid records cannot overwrite the masterplan or claim a live setup', () => {
  const dir = copy(), path = resolve(dir, 'masterplan.md'), before = readFileSync(path, 'utf8');
  save(dir, { ...valid, health_address: 'synthetic-marker' });
  assert.equal(hostRecordFor(dir).status, 'invalid');
  assert.throws(() => run('render', dir), /health_address/);
  assert.equal(readFileSync(path, 'utf8'), before);
});
test('missing evidence and accepted gaps keep their recorded meaning', () => {
  const dir = copy(), path = resolve(dir, 'masterplan.md');
  save(dir, JSON.parse(fixture('found.json')));
  run('render', dir); run('check', dir);
  const text = readFileSync(path, 'utf8');
  assert.ok(text.includes('| last backup check | Not recorded |'));
  assert.ok(text.includes('| last restore drill | Not recorded |'));
  assert.ok(text.includes('| rollback targets | None recorded |'));
  assert.ok(text.includes('| fit | unassessed |'));
  assert.ok(text.includes('| gaps / 0 / status | open |'));
  save(dir, valid); run('render', dir);
  assert.ok(readFileSync(path, 'utf8').includes('| gaps / 0 / status | accepted |'));
});
