const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync, writeFileSync, mkdtempSync, mkdirSync, rmSync } = require('node:fs');
const { resolve } = require('node:path');
const { tmpdir } = require('node:os');
const { spawnSync } = require('node:child_process');
const { createRequire } = require('node:module');
const root = resolve(__dirname, '../..');
const reader = resolve(root, '.agents/skills/merge/scripts/host-record.cjs');
const { readHostRecord, mergeEffect } = require(reader);
const fixture = name => readFileSync(resolve(__dirname, 'fixtures/host-record', name), 'utf8');
const valid = JSON.parse(fixture('valid.json'));
const copies = [];
after(() => copies.forEach(path => rmSync(path, { recursive: true })));
for (const probe of JSON.parse(fixture('invalid-cases.json'))) {
  test(`upstream invalid fixture names ${probe.field} and withholds values`, () => {
    const result = readHostRecord(root, fixture(probe.file.split('/').at(-1)), valid.tool);
    assert.equal(result.status, 'invalid');
    assert.ok(result.diagnostics.some(line => line.startsWith(probe.field + ':')), result.diagnostics.join('\n'));
    if (probe.withheld) assert.ok(!result.diagnostics.join('\n').includes(probe.withheld));
  });
}
test('upstream valid and adopted records validate without project dependencies', () => {
  for (const name of ['valid.json', 'found.json']) {
    assert.equal(readHostRecord(root, fixture(name), valid.tool).status, 'valid');
  }
});
test('a missing bundled validator cannot produce a release claim', () => {
  const dir = mkdtempSync(resolve(tmpdir(), 'host-record-missing-validator-'));
  copies.push(dir);
  for (const name of ['host-record.cjs', '../contracts/ai-host-kit/host-record.schema.json']) {
    writeFileSync(resolve(dir, name.split('/').at(-1)), readFileSync(resolve(root, '.agents/skills/merge/scripts', name)));
  }
  const result = spawnSync('node', [resolve(dir, 'host-record.cjs'), 'merge', dir, '--stdin', '--tool', valid.tool], {
    input: JSON.stringify({ ...valid, deploys_on_merge: true }), encoding: 'utf8',
  });
  assert.equal(result.status, 2);
  assert.match(result.stdout, /bundled validator could not be read/);
  assert.ok(!result.stdout.includes('This will go live'));
});
test('a merge reads both records from the proposed commit and ignores local identities', () => {
  const dir = mkdtempSync(resolve(tmpdir(), 'host-record-merge-'));
  copies.push(dir);
  mkdirSync(resolve(dir, 'hosting'));
  const script = resolve(root, '.agents/skills/merge/scripts/merge.py');
  function git(...args) {
    const result = spawnSync('git', ['-C', dir, ...args], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr); return result.stdout.trim();
  }
  git('init', '-q', '-b', 'main');
  git('config', 'user.name', 'Guillaume Picard'); git('config', 'user.email', 'fixture@example.invalid');
  function handover(tool) { writeFileSync(resolve(dir, 'hosting/handover.json'), JSON.stringify({ tool: { name: tool } })); }
  function record(value) { writeFileSync(resolve(dir, 'hosting/host-record.json'), JSON.stringify(value)); }
  function commit() {
    git('add', 'hosting'); git('-c', 'user.name=Guillaume Picard', 'commit', '-q', '-m', 'Record host setting');
    return git('rev-parse', 'HEAD');
  }
  function effect(head) {
    const result = spawnSync('python3', [script, '--effect', head], { cwd: dir, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr); return result.stdout;
  }
  handover(valid.tool); const absent = commit();
  assert.match(effect(absent), /host-record.json: absent/);
  record(valid); const manual = commit();
  record({ ...valid, deploys_on_merge: true });
  assert.ok(!effect(manual).includes('This will go live'));
  const automatic = commit();
  record(valid); handover('unrelated-tool');
  assert.ok(effect(automatic).includes('This will go live'));
  record({ ...valid, deploys_on_merge: true }); const mismatch = commit();
  handover(valid.tool);
  assert.match(effect(mismatch), /tool: does not match/);
  assert.match(effect(mismatch), /existing recipe/);
  assert.ok(!effect(mismatch).includes('This will go live'));
  record({ ...valid, deploys_on_merge: true, fit: 'done' }); const invalid = commit();
  assert.ok(!effect(invalid).includes('This will go live'));
  assert.match(effect(invalid), /fit:/);
  rmSync(resolve(dir, 'hosting/handover.json')); const noHandover = commit();
  handover(valid.tool);
  assert.match(effect(noHandover), /could not read the tool name from the proposed/);
  assert.ok(!effect(noHandover).includes('This will go live'));
});
test('a project with the older starter Ajv validates records and uses their merge setting', () => {
  const project = process.env.HOST_RECORD_LEGACY_PROJECT;
  assert.ok(project, 'the shell check supplies the older starter dependency project');
  const requireProject = createRequire(resolve(project, 'package.json'));
  assert.match(requireProject('ajv/package.json').version, /^6\./);
  assert.throws(() => requireProject('ajv/dist/2020.js'), { code: 'MODULE_NOT_FOUND' });
  mkdirSync(resolve(project, 'hosting'));
  writeFileSync(resolve(project, 'hosting/handover.json'), JSON.stringify({ tool: { name: valid.tool } }));
  const text = JSON.stringify({ ...valid, deploys_on_merge: true });
  writeFileSync(resolve(project, 'hosting/host-record.json'), text);
  assert.equal(readHostRecord(project).status, 'valid');
  assert.match(mergeEffect(readHostRecord(project)), /This will go live/);
  for (const mode of ['check', 'merge']) {
    const result = spawnSync('node', [reader, mode, project], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    if (mode === 'merge') assert.match(result.stdout, /This will go live/);
  }
});
