import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, cpSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import Ajv2020 from 'ajv/dist/2020.js';
import { schemaFor, validateRecord, checkCode, run } from '../scripts/handover.mjs';
import { found, questions } from '../scripts/found-handover.mjs';
const root = resolve('.');
const schema = schemaFor(root);
const original = JSON.parse(readFileSync('hosting/handover.json', 'utf8'));
const copies = [];
after(() => { for (const path of copies) rmSync(path, { recursive: true }); });
function copy() {
  const dir = mkdtempSync(resolve(tmpdir(), 'handover-test-'));
  copies.push(dir);
  for (const path of ['src', 'scripts', 'db', 'hosting', 'masterplan.md', 'Dockerfile', '.env.example']) cpSync(resolve(root, path), resolve(dir, path), { recursive: true });
  writeFileSync(resolve(dir, 'hosting/handover.schema.json'), JSON.stringify(schema));
  return dir;
}
function mutate(edit) { const value = structuredClone(original); edit(value); return value; }
const ajv = new Ajv2020({ strict: false });
const validate = ajv.compile(schema);
test('the template record validates and the generated hosting section agrees', () => run('check', root));
for (const key of ['value', 'secret_value', 'default', 'token', 'credentials', 'nested']) {
  test(`secret metadata refuses ${key}`, () => assert.equal(validate(mutate(h => { h.config[0][key] = key === 'nested' ? { value: 'synthetic-marker' } : 'synthetic-marker'; })), false));
}
test('secret values cannot be provided at build time', () => assert.equal(validate(mutate(h => { h.config[0].phase = 'build'; })), false));
test('an unknown major gives an update instruction', () => assert.throws(() => validateRecord({ ...original, schema_version: '2.0' }, schema), /update the reader/));
const response = ajv.compile({ $schema: schema.$schema, $defs: schema.$defs, $ref: '#/$defs/response' });
for (const location of ['https://example.test/health?token=synthetic-marker', 'https://example.test/file?sig=synthetic-marker', 'https://user:password@example.test/path', 'AES-GCM; key=synthetic-marker', 'https://example.test/file%3Fsig%3Dmarker', '../key.pem']) {
  test('credential-bearing reference is refused', () => {
    for (const field of ['location', 'evidence']) assert.equal(response({ status: 'passed', evidence: 'evidence/run.txt', [field]: location }), false);
  });
}
test('plain references and all four requests validate', () => {
  assert.equal(response({ status: 'passed', location: 'https://example.test/preview', evidence: 'evidence/run.txt' }), true);
  const request = ajv.compile({ $schema: schema.$schema, $defs: schema.$defs, $ref: '#/$defs/request' });
  for (const item of [{ action: 'preview', branch: 'feature/example', commit: 'a'.repeat(40) }, { action: 'logs', minutes: 60 }, { action: 'health' }, { action: 'release', commit: 'b'.repeat(40) }]) assert.equal(request({ ...item, tool: 'team-tool', handover: 'hosting/handover.json' }), true);
  assert.equal(request({ action: 'rollback', tool: 'team-tool', handover: 'hosting/handover.json' }), false);
});
for (const [name, edit] of [
  ['missing config name', h => h.config.pop()],
  ['extra config name', h => h.config.push({ name: 'EXTRA_NAME', kind: 'setting', phase: 'runtime', source: 'host' })],
  ['duplicate config name', h => h.config.push(h.config[0])],
  ['file storage without files', h => delete h.files],
  ['missing schedule', h => { h.jobs.schedules = []; }],
  ['changed schedule', h => { h.jobs.schedules[0].cron = '0 8 * * 1'; }],
  ['missing migrate step', h => delete h.processes.migrate],
]) test(name, () => assert.throws(() => { const h = mutate(edit); validateRecord(h, schema); checkCode(root, h); }));
test('a new typed configuration name fails until recorded', () => {
  const dir = copy(), path = resolve(dir, 'src/lib/config.ts');
  writeFileSync(path, readFileSync(path, 'utf8').replace('"DATABASE_URL",', '"DATABASE_URL", "NEW_SETTING",'));
  assert.throws(() => run('check', dir), /config/);
});
test('an upload added to a project without files fails', () => {
  const dir = copy();
  rmSync(resolve(dir, 'src/lib/files'), { recursive: true });
  const withoutFiles = mutate(h => { delete h.files; });
  assert.doesNotThrow(() => checkCode(dir, withoutFiles));
  writeFileSync(resolve(dir, 'src/upload.ts'), 'import { files } from "./lib/files"; export const upload = files;');
  assert.throws(() => checkCode(dir, withoutFiles), /files/);
});
test('environment access outside the typed module fails', () => {
  const dir = copy();
  for (const code of ['process.env.NEW_NAME', 'process["env"].NEW_NAME', 'const { env } = process']) {
    writeFileSync(resolve(dir, 'src/escape.ts'), code);
    assert.throws(() => checkCode(dir, original), /environment/);
  }
});
test('a hand edit fails, rendering repairs it and preserves other sections', () => {
  const dir = copy(), path = resolve(dir, 'masterplan.md');
  writeFileSync(path, 'Outside section\n' + readFileSync(path, 'utf8').replace('Recovery allows', 'Changed recovery allows'));
  assert.throws(() => run('check', dir), /masterplan/);
  run('render', dir); run('check', dir);
  assert.ok(readFileSync(path, 'utf8').startsWith('Outside section\n'));
});
for (const sign_in of questions[0].values) test(`founding records ${sign_in}, region and recovery answers`, () => {
  const dir = copy();
  mkdirSync(resolve(dir, 'tests')); writeFileSync(resolve(dir, 'tests/outside-account.ts'), '// Fixture evidence reference\n');
  found(dir, { sign_in, residency: 'eu', max_data_loss_hours: 2, max_restore_hours: 4, outside_refused_test: 'tests/outside-account.ts' });
  const h = JSON.parse(readFileSync(resolve(dir, 'hosting/handover.json')));
  assert.equal(h.sign_in.staff?.provider ?? h.sign_in.outsiders, sign_in);
  assert.equal(h.residency, 'eu'); assert.deepEqual(h.recovery, { max_data_loss_hours: 2, max_restore_hours: 4 });
  run('check', dir);
});
test('invalid founding answers leave both records untouched', () => {
  const dir = copy(), path = resolve(dir, 'hosting/handover.json');
  const before = readFileSync(path, 'utf8');
  assert.throws(() => found(dir, { sign_in: 'email-link', residency: 'any', max_data_loss_hours: -1, max_restore_hours: 4 }));
  assert.equal(readFileSync(path, 'utf8'), before);
});

test('a new environment read in the typed module needs a declaration', () => {
  const dir = copy(), path = resolve(dir, 'src/lib/config.ts');
  writeFileSync(path, readFileSync(path, 'utf8') + '\nfunction added(env) { return env.NEW_SETTING; }\n');
  assert.throws(() => run('check', dir), /config/);
});

test('a later minor may add optional metadata outside secret declarations', () => {
  assert.equal(validate({ ...original, schema_version: '1.1', optional_note: 'A future optional capability' }), true);
});
test('a later minor cannot extend a secret declaration with a value', () => {
  assert.equal(validate(mutate(h => { h.schema_version = '1.1'; h.config[0].default = 'synthetic-marker'; })), false);
});
