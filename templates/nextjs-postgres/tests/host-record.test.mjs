import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, writeFileSync, mkdtempSync, cpSync, rmSync, symlinkSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import { run, hostRecordFor, hostingSection } from '../scripts/handover.mjs';

const root = resolve('.');
const require = createRequire(import.meta.url);
const readerPath = existsSync('hosting/host-record.cjs') ? resolve('hosting/host-record.cjs') : resolve('../../.agents/skills/merge/scripts/host-record.cjs');
const { readHostRecord, mergeEffect } = require(readerPath);
const valid = {
  "schema_version": "1.0",
  "tool": JSON.parse(readFileSync("hosting/handover.json", "utf8")).tool.name,
  "recipe": "example-recipe",
  "place": "example-place",
  "address": "https://tool.example.invalid",
  "health_address": "https://tool.example.invalid/api/health",
  "deploys_on_merge": false,
  "services": [
    {
      "name": "database",
      "kind": "postgres",
      "version": "17.0",
      "region": "eu-example"
    }
  ],
  "rollback_targets": [
    {
      "release": "previous-release",
      "image": "registry.example.invalid/tool:previous",
      "database_compatibility": "Compatible with the previous release."
    }
  ],
  "last_backup_check": {
    "at": "2026-11-04T10:00:00Z",
    "result": "passed",
    "evidence": "checks/backup.txt"
  },
  "last_restore_drill": {
    "at": "2026-11-04T11:00:00Z",
    "result": "passed",
    "evidence": "checks/restore.txt",
    "duration_hours": 0.5
  },
  "fit": "gaps",
  "gaps": [
    {
      "field": "residency",
      "reason": "The selected place does not meet the requested region.",
      "status": "accepted",
      "acceptance": {
        "words": "I accept this region for the example.",
        "by": "Example owner",
        "at": "2026-11-04T12:00:00Z"
      }
    }
  ]
};
const adopted = {
  ...valid, address: null, health_address: null, rollback_targets: [],
  last_backup_check: null, last_restore_drill: null, fit: 'unassessed',
  gaps: [{ field: 'last_restore_drill', reason: 'No restore evidence was found.', status: 'open' }],
};
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
  const result = readHostRecord(root, JSON.stringify(valid));
  assert.equal(result.status, 'valid');
  assert.ok(!result.diagnostics.join('\n').includes(valid.tool));
  const cli = spawnSync('node', [readerPath, 'check', root, '--stdin'], { input: JSON.stringify(valid), encoding: 'utf8' });
  assert.equal(cli.status, 0); assert.ok(!cli.stdout.includes(valid.address));
});
test('an adopted record preserves missing evidence', () => {
  const result = readHostRecord(root, JSON.stringify(adopted));
  assert.equal(result.status, 'valid');
  assert.equal(result.record.last_restore_drill, null);
  assert.deepEqual(result.record.rollback_targets, []);
  assert.equal(result.record.gaps[0].status, 'open');
});
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
test('the bundled validator works without project dependencies', () => {
  const dir = mkdtempSync(resolve(tmpdir(), 'host-record-no-deps-'));
  copies.push(dir);
  const result = readHostRecord(dir, JSON.stringify({ ...valid, deploys_on_merge: true }), valid.tool);
  assert.equal(result.status, 'valid');
  assert.ok(mergeEffect(result).includes('This will go live'));
  assert.equal(readHostRecord(dir, JSON.stringify({ ...valid, schema_version: '9.0' })).status, 'unknown-version');
});
test('both reader modes report absence successfully and retain the fallback', () => {
  const dir = copy();
  for (const mode of ['check', 'merge']) {
    const result = spawnSync('node', [readerPath, mode, dir], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /host-record.json: absent/);
    if (mode === 'merge') assert.match(result.stdout, /existing recipe and masterplan/);
  }
  run('render', dir); run('check', dir);
  assert.match(readFileSync(resolve(dir, 'masterplan.md'), 'utf8'), /host-record.json: absent/);
});
test('a mismatched tool cannot render or replace the masterplan', () => {
  const dir = copy(), path = resolve(dir, 'masterplan.md'), before = readFileSync(path, 'utf8');
  const record = { ...valid, tool: 'unrelated-tool', deploys_on_merge: true };
  save(dir, record);
  const result = hostRecordFor(dir);
  assert.equal(result.status, 'invalid');
  assert.match(result.diagnostics.join('\n'), /tool: does not match/);
  assert.ok(!mergeEffect(result).includes('This will go live'));
  for (const mode of ['render', 'check']) assert.throws(() => run(mode, dir), /tool: does not match/);
  assert.equal(readFileSync(path, 'utf8'), before);
  const handover = JSON.parse(readFileSync(resolve(dir, 'hosting/handover.json'), 'utf8'));
  assert.throws(() => hostingSection(handover, { status: 'valid', record }), /tool: does not match/);
});
test('numeric overflow names its field and never renders Infinity', () => {
  const dir = copy(), path = resolve(dir, 'masterplan.md'), before = readFileSync(path, 'utf8');
  for (const number of ['1e400', '-1e400']) {
    const text = JSON.stringify(valid).replace('"duration_hours":0.5', `"duration_hours":${number}`);
    writeFileSync(resolve(dir, 'hosting/host-record.json'), text);
    const result = hostRecordFor(dir);
    assert.equal(result.status, 'invalid');
    assert.ok(result.diagnostics.some(line => line.startsWith('last_restore_drill.duration_hours:')));
    assert.throws(() => run('render', dir), /duration_hours/);
    assert.equal(readFileSync(path, 'utf8'), before);
    assert.ok(!readFileSync(path, 'utf8').includes('Infinity'));
  }
});
test('image digests and full commit tags pass while credential scans remain active', () => {
  const dir = copy();
  const commit = '621011b0cbe38ec046f26a9b9f6334f1b5549fa9';
  for (const suffix of [`:${commit}`, `@sha256:${'0123456789abcdef'.repeat(4)}`]) {
    const record = structuredClone(valid);
    record.rollback_targets[0].image = 'registry.example.invalid/tool' + suffix;
    save(dir, record);
    assert.equal(hostRecordFor(dir).status, 'valid');
    run('render', dir); run('check', dir);
    assert.ok(readFileSync(resolve(dir, 'masterplan.md'), 'utf8').includes(suffix));
  }
  for (const edit of [
    r => { r.recipe = commit; },
    r => { r.gaps[0].acceptance.words = commit; },
    r => { r.rollback_targets[0].image = `registry.example.invalid/${commit}:previous`; },
    r => { r.rollback_targets[0].image = `user:password@registry.example.invalid/tool:${commit}`; },
    r => { r.rollback_targets[0].image = `registry.example.invalid/tool:${commit}?token=synthetic-marker`; },
  ]) {
    const record = structuredClone(valid); edit(record);
    const result = readHostRecord(root, JSON.stringify(record));
    assert.equal(result.status, 'invalid');
    assert.ok(!result.diagnostics.join('\n').includes(commit));
  }
});
test('only a validated true merge setting produces the live wording', () => {
  for (const value of [true, false, 'true', 1, null]) {
    const result = readHostRecord(root, JSON.stringify({ ...valid, deploys_on_merge: value }));
    assert.equal(mergeEffect(result).includes('This will go live'), value === true);
  }
  assert.ok(!mergeEffect(readHostRecord(root, JSON.stringify({ ...valid, deploys_on_merge: true, fit: 'done' }))).includes('This will go live'));
  const duplicate = JSON.stringify(valid).replace('"deploys_on_merge":false', '"deploys_on_merge":false,"deploys_on_merge":true');
  assert.ok(readHostRecord(root, duplicate).diagnostics.includes('deploys_on_merge: duplicate field'));
  assert.ok(!mergeEffect(readHostRecord(root, duplicate)).includes('This will go live'));
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
  save(dir, JSON.parse(JSON.stringify(adopted)));
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
