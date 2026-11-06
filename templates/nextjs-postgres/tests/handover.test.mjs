import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, cpSync, readFileSync, writeFileSync, rmSync, symlinkSync } from 'node:fs';
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
  assert.equal(h.sign_in.outsiders, 'email-link');
  assert.equal(h.sign_in.staff_provider, sign_in === 'entra' ? 'microsoft' : sign_in === 'google' ? 'google' : 'none');
  assert.ok(h.sign_in.configuration.AUTH_SECRET_FILE);
  if (h.sign_in.staff) assert.equal(h.sign_in.staff.redirect_path, `/api/auth/callback/${h.sign_in.staff_provider}`);
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

for (const name of ['AUTH_BASE_URL', 'STAFF_CLIENT_SECRET_FILE']) {
  test(`removing sign-in configuration ${name} from the handover fails`, () => {
    assert.throws(() => checkCode(root, mutate(h => { h.config = h.config.filter(c => c.name !== name); })), /config/);
  });
  test(`removing typed sign-in configuration ${name} without updating the handover fails`, () => {
    const dir = copy(), path = resolve(dir, 'src/lib/config.ts');
    writeFileSync(path, readFileSync(path, 'utf8').replace(`  "${name}",\n`, ''));
    assert.throws(() => run('check', dir), /config/);
  });
}
test('a new typed sign-in name needs a handover update in both directions', () => {
  const dir = copy(), path = resolve(dir, 'src/lib/config.ts');
  const before = readFileSync(path, 'utf8');
  writeFileSync(path, before.replace('"AUTH_BASE_URL",', '"AUTH_BASE_URL", "AUTH_NEW_SETTING",'));
  assert.throws(() => checkCode(dir, original), /config/);
  const updated = mutate(h => h.config.push({ name: 'AUTH_NEW_SETTING', kind: 'setting', phase: 'runtime', source: 'host' }));
  const example = resolve(dir, '.env.example');
  writeFileSync(example, readFileSync(example, 'utf8') + '\nAUTH_NEW_SETTING=\n');
  assert.doesNotThrow(() => checkCode(dir, updated));
  writeFileSync(path, before);
  assert.throws(() => checkCode(dir, updated), /config/);
});
for (const [field, value] of [['staff_provider', 'oidc'], ['outsiders', 'none']]) {
  test(`unsupported sign-in ${field} fails`, () => assert.throws(() => checkCode(root, mutate(h => { h.sign_in[field] = value; })), /sign_in/));
}

// Complete records exercise only the published schema, with no reader-side scan.
const credentialSamples = [
  'postgres://fixture:fixture@database.test/tool',
  'https://fixture:fixture@example.test',
  'custom+driver://fixture@example.test/resource',
  'POSTGRESQL://fixture:fixture@database.test/tool',
  '-----BEGIN PRIVATE KEY-----',
  'token=synthetic-marker',
  'Secret = synthetic-marker',
  'AKIA' + 'X'.repeat(16),
  'ghp_' + 'x'.repeat(36),
  'sk-' + 'x'.repeat(32),
];
function leaves(value, path = []) {
  if (value && typeof value === 'object') return Object.entries(value).flatMap(([key, child]) => leaves(child, [...path, key]));
  return [path];
}
function parent(record, path) { return path.slice(0, -1).reduce((value, key) => value[key], record); }
test('schema alone rejects recognisable credentials in every declaration value', () => {
  for (const path of leaves(original)) for (const sample of credentialSamples) {
    const h = structuredClone(original);
    parent(h, path)[path.at(-1)] = sample;
    assert.equal(validate(h), false, path.join('.'));
  }
});
test('schema alone rejects credentials in nested extension values throughout the record', () => {
  function objects(value, path = []) {
    if (!value || typeof value !== 'object') return [];
    return [...(Array.isArray(value) ? [] : [path]), ...Object.entries(value).flatMap(([key, child]) => objects(child, [...path, key]))];
  }
  for (const path of objects(original)) for (const sample of credentialSamples) {
    const h = structuredClone(original);
    path.reduce((value, key) => value[key], h).optional_note = { nested: [sample] };
    assert.equal(validate(h), false, path.join('.'));
  }
});
test('ordinary prose extensions remain valid', () => {
  assert.equal(validate({ ...original, optional_note: { text: 'An arbitrary secret can resemble prose' } }), true);
});
for (const [name, target] of [
  ['root', h => h],
  ['tool', h => h.tool],
  ['extension object', h => (h.optional_note = {})],
  ['configuration map', h => h.sign_in.configuration],
]) test(`schema alone rejects a credential URL as a field name in ${name}`, () => {
  assert.equal(validate(mutate(h => {
    target(h)['postgres://fixture:synthetic-marker@database.test/tool'] = 'note';
  })), false);
});
const company = mutate(h => {
  h.sign_in.staff = { provider: 'entra', directory: 'company tenant', outside_refused_test: 'tests/outside-account.ts', redirect_path: '/api/auth/callback/microsoft' };
  h.sign_in.staff_provider = 'microsoft';
});
const requiredPaths = [
  'sign_in.public_origin_env', 'sign_in.staff_provider', 'sign_in.configuration',
  ...Object.keys(original.sign_in.configuration).filter(n => n !== 'VITEST' && n !== 'GOOGLE_WORKSPACE_DOMAIN').map(n => `sign_in.configuration.${n}`),
  'sign_in.secret_files', 'sign_in.secret_files.0.name', 'sign_in.secret_files.0.required_when', 'sign_in.secret_files.0.description',
  'sign_in.host_setup', 'sign_in.host_setup.owner', 'sign_in.host_setup.request',
  'sign_in.host_setup.microsoft', 'sign_in.host_setup.google', 'sign_in.host_setup.callbacks',
  'sign_in.host_setup.callbacks.microsoft', 'sign_in.host_setup.callbacks.google',
  'sign_in.email_link', 'sign_in.email_link.verification_path', 'sign_in.email_link.requires',
  'postgres.sign_in', ...Object.keys(original.postgres.sign_in).map(n => `postgres.sign_in.${n}`), 'postgres.roles.auth',
];
for (const field of requiredPaths) test(`missing or malformed ${field} fails the schema and project check`, () => {
  const dir = copy();
  for (const value of [undefined, 42, true, []]) {
    const h = structuredClone(company), path = field.split('.');
    if (value === undefined) delete parent(h, path)[path.at(-1)];
    else parent(h, path)[path.at(-1)] = value;
    assert.equal(validate(h), false, `${field}: ${JSON.stringify(value)}`);
    writeFileSync(resolve(dir, 'hosting/handover.json'), JSON.stringify(h));
    assert.throws(() => run('check', dir));
  }
});
for (const name of ['AUTH_BASE_URL', 'AUTH_SECRET_FILE', 'AUTH_DATABASE_URL', 'STAFF_CLIENT_SECRET_FILE', 'SMTP_PASSWORD_FILE']) {
  test(`schema and project check require the active sign-in config declaration ${name}`, () => {
    const dir = copy(), h = structuredClone(company);
    h.config = h.config.filter(c => c.name !== name);
    assert.equal(validate(h), false);
    writeFileSync(resolve(dir, 'hosting/handover.json'), JSON.stringify(h));
    assert.throws(() => run('check', dir));
  });
}
test('an unfinished sign-in declaration does not require provisioned sign-in fields', () => {
  const h = structuredClone(original);
  h.sign_in = { staff: null, outsiders: 'none' };
  delete h.postgres.sign_in; delete h.postgres.roles.auth;
  assert.equal(validate(h), true);
});
test('the response contract also refuses copied key shapes in references', () => {
  for (const sample of credentialSamples) assert.equal(response({ status: 'passed', evidence: sample }), false);
});
test('Google sign-in requires its directory setting declaration and description', () => {
  for (const edit of [h => { delete h.sign_in.configuration.GOOGLE_WORKSPACE_DOMAIN; }, h => { h.config = h.config.filter(c => c.name !== 'GOOGLE_WORKSPACE_DOMAIN'); }]) {
    const h = structuredClone(company), dir = copy();
    h.sign_in.staff.provider = 'google'; h.sign_in.staff_provider = 'google';
    h.sign_in.staff.redirect_path = '/api/auth/callback/google';
    edit(h);
    assert.equal(validate(h), false);
    writeFileSync(resolve(dir, 'hosting/handover.json'), JSON.stringify(h));
    assert.throws(() => run('check', dir));
  }
});

for (const sample of [
  'postgresql://database.test/tool?user=fixture&%70assword=synthetic-marker',
  'postgresql://database.test/tool?user=fixture&%2570assword=synthetic-marker',
  'postgresql://database.test/tool?%75ser=fixture&%70%61ssword=synthetic-marker',
  'https://database.test/tool?%74oken=synthetic-marker',
  'https://fixture%3Asynthetic-marker@database.test/tool',
  'https://database.test/tool',
]) test('schema alone rejects URL values in descriptions and extensions', () => {
  for (const edit of [
    h => { h.sign_in.configuration.AUTH_DATABASE_URL = sample; },
    h => { h.config[0].description = sample; },
    h => { h.optional_note = { nested: [sample] }; },
  ]) assert.equal(validate(mutate(edit)), false);
});
for (const key of ['password', 'PASSWD', 'clientSecret', 'access_token', 'apiKey', 'credentialNote']) {
  test(`schema alone refuses nested secret metadata ${key}`, () => {
    assert.equal(validate(mutate(h => { h.sign_in.optional_note = { nested: { [key]: 'synthetic-marker' } }; })), false);
  });
}
for (const [name, edit] of [
  ['missing authentication table', h => { h.postgres.sign_in.tables = ['invitations']; }],
  ['wrong authentication role', h => { h.postgres.sign_in.runtime_role = 'tool_app'; }],
  ['wrong authentication owner', h => { h.postgres.sign_in.owner = 'tool_app'; }],
  ['wrong authentication schema', h => { h.postgres.sign_in.schema = 'public'; }],
  ['missing authentication migration', h => { h.postgres.sign_in.migration = 'db/migrations/absent.sql'; }],
  ['wrong callback path', h => { h.sign_in.host_setup.callbacks.microsoft = '/wrong'; }],
  ['wrong email verification path', h => { h.sign_in.email_link.verification_path = '/wrong'; }],
  ['sign-in secret reclassified as build setting', h => { Object.assign(h.config.find(c => c.name === 'AUTH_DATABASE_URL'), { kind: 'setting', phase: 'build' }); }],
  ['setting reclassified as secret', h => { h.config.find(c => c.name === 'PORT').kind = 'secret'; }],
]) test(name, () => assert.throws(() => checkCode(root, mutate(edit))));
test('the authentication migration path is read from the declaration', () => {
  const dir = copy(), migration = 'db/migrations/003_authentication.sql';
  cpSync(resolve(dir, original.postgres.sign_in.migration), resolve(dir, migration));
  rmSync(resolve(dir, original.postgres.sign_in.migration));
  assert.doesNotThrow(() => checkCode(dir, mutate(h => { h.postgres.sign_in.migration = migration; })));
});
test('the authentication migration cannot link outside the project', () => {
  const dir = copy(), outside = copy(), migration = 'db/migrations/outside.sql';
  symlinkSync(resolve(outside, original.postgres.sign_in.migration), resolve(dir, migration));
  const h = mutate(h => { h.postgres.sign_in.migration = migration; });
  assert.equal(validate(h), true);
  assert.throws(() => checkCode(dir, h), /postgres.sign_in.migration: resolved file must be inside db\/migrations/);
});
for (const location of ['root', 'extension']) test(`schema alone rejects copied key material as a ${location} field name`, () => {
  const key = 'ghp_' + 'a'.repeat(36);
  const h = mutate(h => {
    if (location === 'root') h[key] = 'synthetic-marker';
    else h.optional_note = { [key]: 'synthetic-marker' };
  });
  assert.equal(validate(h), false);
});
test('authentication ownership must match the migration execution role', () => {
  const dir = copy(), path = resolve(dir, 'scripts/migrate.mjs');
  writeFileSync(path, readFileSync(path, 'utf8').replace("role.rows[0].name !== 'tool_owner'", "role.rows[0].name !== 'tool_app'"));
  assert.throws(() => checkCode(dir, original), /postgres.sign_in.owner/);
});
for (const name of ['AUTH_DATABASE_URL', 'AUTH_SECRET_FILE', 'STAFF_CLIENT_SECRET_FILE', 'SMTP_PASSWORD_FILE', 'SMTP_USER']) {
  for (const metadata of [{ kind: 'setting', phase: 'build' }, { kind: 'setting', phase: 'runtime' }, { kind: 'secret', phase: 'build' }]) {
    test(`schema alone requires runtime secret metadata for ${name}: ${JSON.stringify(metadata)}`, () => {
      assert.equal(validate(mutate(h => { Object.assign(h.config.find(c => c.name === name), metadata); })), false);
    });
  }
}
