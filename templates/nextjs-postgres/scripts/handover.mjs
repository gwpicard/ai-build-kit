import { readFileSync, writeFileSync, existsSync, readdirSync, realpathSync } from 'node:fs';
import { resolve, dirname, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import Ajv2020 from 'ajv/dist/2020.js';
import ts from 'typescript';
import { createRequire } from 'node:module';

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
export function hostRecordFor(root) {
  const local = resolve(root, 'hosting/host-record.cjs');
  const reader = require(existsSync(local) ? local : resolve(here, '../../../.agents/skills/merge/scripts/host-record.cjs'));
  return reader.readHostRecord(root);
}
export function schemaFor(root) {
  const local = resolve(root, 'hosting/handover.schema.json');
  return JSON.parse(readFileSync(existsSync(local) ? local : resolve(here, '../../../hosting/handover.schema.json'), 'utf8'));
}
export function validateRecord(record, schema) {
  if (!/^1\./.test(record.schema_version ?? '')) throw new Error('schema_version: update the reader to support this major version');
  const validate = new Ajv2020({ strict: false, allErrors: true }).compile(schema);
  if (!validate(record)) throw new Error(validate.errors.map(e => `${e.instancePath || '/'}: ${e.keyword}`).join('\n'));

}
function source(path) { return ts.createSourceFile(path, readFileSync(path, 'utf8'), ts.ScriptTarget.Latest, true); }
function walk(node, visit) { visit(node); ts.forEachChild(node, child => walk(child, visit)); }
function literal(node) {
  if (ts.isAsExpression(node) || ts.isSatisfiesExpression(node) || ts.isParenthesizedExpression(node)) return literal(node.expression);
  if (ts.isStringLiteral(node)) return node.text;
  if (ts.isArrayLiteralExpression(node)) return node.elements.map(literal);
  if (ts.isObjectLiteralExpression(node)) return Object.fromEntries(node.properties.map(p => {
    if (!ts.isPropertyAssignment(p)) throw new Error('Declare configuration and schedules as literals');
    return [p.name.text, literal(p.initializer)];
  }));
  throw new Error('Declare configuration and schedules as literals');
}
function declaration(path, name) {
  let result;
  walk(source(path), node => {
    if (ts.isVariableDeclaration(node) && node.name.getText() === name) result = literal(node.initializer);
  });
  if (!result) throw new Error(`${name}: missing declaration`);
  return result;
}
function files(folder) {
  return readdirSync(folder, { withFileTypes: true }).flatMap(entry => {
    const path = resolve(folder, entry.name);
    return entry.isDirectory() ? files(path) : /\.[cm]?[jt]sx?$/.test(path) ? [path] : [];
  });
}
function same(actual, expected, field) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) throw new Error(`${field}: code and handover disagree`);
}
export function checkCode(root, handover) {
  const configPath = resolve(root, 'src/lib/config.ts');
  const names = declaration(configPath, 'environmentNames');
  walk(source(configPath), node => {
    const member = ts.isPropertyAccessExpression(node) ? node.name.text
      : ts.isElementAccessExpression(node) && ts.isStringLiteral(node.argumentExpression) ? node.argumentExpression.text : null;
    if (member && ['env', 'process.env', 'environment()'].includes(node.expression.getText()) && !names.includes(member)) throw new Error('config: undeclared environment access');
    if (ts.isCallExpression(node) && ['required', 'secretFile'].includes(node.expression.getText()) && ts.isStringLiteral(node.arguments[0]) && !names.includes(node.arguments[0].text)) throw new Error('config: undeclared required name');
  });
  const signInConfig = resolve(root, 'src/lib/sign-in/config.ts');
  if (existsSync(signInConfig)) {
    same(handover.sign_in.outsiders, 'email-link', 'sign_in.outsiders');
    const paths = declaration(resolve(root, 'src/lib/sign-in/service.ts'), 'signInPaths');
    same(handover.sign_in.host_setup.callbacks, { microsoft: paths.microsoft, google: paths.google }, 'sign_in.callbacks');
    same(handover.sign_in.email_link.verification_path, paths.email, 'sign_in.email_link');
    const migrationPath = resolve(root, handover.postgres.sign_in.migration);
    if (!existsSync(migrationPath)) throw new Error('postgres.sign_in.migration: declared file is missing');
    const resolvedMigration = realpathSync(migrationPath);
    const migrationsFolder = resolve(realpathSync(root), 'db/migrations');
    if (!resolvedMigration.startsWith(migrationsFolder + sep)) throw new Error('postgres.sign_in.migration: resolved file must be inside db/migrations');
    const migration = readFileSync(resolvedMigration, 'utf8');
    const createdSchema = migration.match(/CREATE SCHEMA ([a-z_]+) AUTHORIZATION ([a-z_]+);/);
    if (!createdSchema) throw new Error('postgres.sign_in: schema ownership missing from migration');
    same(handover.postgres.sign_in.schema, createdSchema[1], 'postgres.sign_in.schema');
    same(handover.postgres.sign_in.owner, createdSchema[2], 'postgres.sign_in.owner');
    const runner = readFileSync(resolve(root, 'scripts/migrate.mjs'), 'utf8');
    const executionRole = runner.match(/role\.rows\[0\]\.name !== '([a-z_]+)'/);
    if (!executionRole) throw new Error('postgres.sign_in.owner: migration execution role is missing');
    same(handover.postgres.sign_in.owner, executionRole[1], 'postgres.sign_in.owner');
    const tables = [...migration.matchAll(/CREATE TABLE ([a-z_]+)\."?([a-z_]+)"?\s*\(/g)]
      .filter(match => match[1] === createdSchema[1]).map(match => match[2]);
    same([...handover.postgres.sign_in.tables].sort(), tables.sort(), 'postgres.sign_in.tables');
    let runtimeRole;
    walk(source(configPath), node => {
      if (ts.isBinaryExpression(node) && node.left.getText() === 'database.username'
        && ts.isStringLiteral(node.right)) runtimeRole = node.right.text;
    });
    if (!runtimeRole || !migration.includes(`TO ${runtimeRole}`)) throw new Error('sign_in: runtime role missing from implementation');
    same(handover.postgres.sign_in.runtime_role, runtimeRole, 'postgres.sign_in.runtime_role');

    const provider = handover.sign_in.staff?.provider;
    if (provider && !['entra', 'google'].includes(provider)) throw new Error('sign_in: unsupported staff provider');
    same(handover.sign_in.staff_provider, provider === 'entra' ? 'microsoft' : provider ?? 'none', 'sign_in.staff_provider');
    same(handover.sign_in.public_origin_env, 'AUTH_BASE_URL', 'sign_in.public_origin_env');
    if (provider) same(handover.sign_in.staff.redirect_path, paths[provider === 'entra' ? 'microsoft' : provider], 'sign_in.redirect_path');
  }
  const secrets = declaration(configPath, 'environmentSecrets');
  for (const config of handover.config) {
    same(config.kind, secrets.includes(config.name) ? 'secret' : 'setting', `config.${config.name}.kind`);
    same(config.phase, 'runtime', `config.${config.name}.phase`);
  }
  const declared = handover.config.map(c => c.name);
  if (new Set(names).size !== names.length || new Set(declared).size !== declared.length) throw new Error('config: duplicate name');
  same([...names].sort(), [...declared].sort(), 'config');
  const example = readFileSync(resolve(root, '.env.example'), 'utf8');
  for (const name of names) if (!new RegExp(`^(?:# )?${name}=`, 'm').test(example)) throw new Error('config: name missing from .env.example');
  let usesFiles = false;
  let usesMail = false;
  for (const path of files(resolve(root, 'src'))) {
    const tree = source(path);
    walk(tree, node => {
      if (path !== configPath) {
        const member = ts.isPropertyAccessExpression(node) ? node.name.text
          : ts.isElementAccessExpression(node) && ts.isStringLiteral(node.argumentExpression) ? node.argumentExpression.text : null;
        if (member === 'env' || (ts.isImportDeclaration(node) && ['process', 'node:process'].includes(node.moduleSpecifier.text))) {
          throw new Error(`${relative(root, path)}: read environment through the typed configuration module`);
        }
        if (ts.isBindingElement(node) && (node.propertyName?.getText() ?? node.name.getText()) === 'env') throw new Error('config: environment alias outside the typed module');
      }
      if (ts.isImportDeclaration(node) || ts.isExportDeclaration(node)) {
        const value = node.moduleSpecifier?.text ?? '';
        usesFiles ||= /(?:\/files(?:\/|$)|storage-blob|client-s3)/.test(value);
        usesMail ||= value === 'nodemailer';
      }
    });
  }
  if (usesFiles && !handover.files) throw new Error('files: storage code needs a files entry');
  if (usesMail && !handover.email) throw new Error('email: mail code needs an email entry');
  const schedules = declaration(resolve(root, 'src/lib/jobs/schedules.ts'), 'schedules');
  const order = list => [...list].sort((a, b) => a.name.localeCompare(b.name));
  same(order(schedules), order(handover.jobs?.schedules ?? []), 'jobs.schedules');
  same(handover.processes.migrate, { command: 'migrate', when: 'before-release' }, 'processes.migrate');
  for (const [role, process] of Object.entries(handover.processes)) {
    if (process && process.command !== role) throw new Error(`processes.${role}: command does not match the image role`);
  }
  for (const path of [handover.image.dockerfile, 'scripts/entrypoint.sh', 'scripts/migrate.mjs', 'db/migrations']) {
    if (!existsSync(resolve(root, path))) throw new Error('processes: image or migration step is missing');
  }
  const dockerfile = readFileSync(resolve(root, handover.image.dockerfile), 'utf8');
  if (!dockerfile.includes('ENTRYPOINT ["sh", "scripts/entrypoint.sh"]')) throw new Error('processes: image does not dispatch its roles');
  same(handover.health.checks, ['database', 'worker'], 'health.checks');
  if (handover.health.path !== '/api/health' || !existsSync(resolve(root, 'src/app/api/health/route.ts'))) throw new Error('health: route missing');
}
export const startMarker = '<!-- hosting:generated:start -->';
export const endMarker = '<!-- hosting:generated:end -->';
export function hostingSection(h, host = { status: 'absent', diagnostics: ['hosting/host-record.json: absent'] }) {
  const staff = h.sign_in.staff?.provider ?? (h.sign_in.outsiders === 'email-link' ? 'email link' : 'not configured');
  const rows = [];
  const cell = value => String(value).replaceAll('\\', '\\\\').replaceAll('|', '\\|').replaceAll('\n', ' ').replaceAll('<', '&lt;');
  function collect(value, path = [], fromHost = false) {
    if (value && typeof value === 'object' && Object.keys(value).length) {
      for (const [key, child] of Object.entries(value)) collect(child, [...path, key.replaceAll('_', ' ')], fromHost);
    } else rows.push(`| ${cell(path.join(' / '))} | ${cell(value === null ? (fromHost ? 'Not recorded' : 'Not configured') : Array.isArray(value) ? (fromHost ? 'None recorded' : 'None') : value)} |`);
  }
  collect(h);
  // Include every requirement and validated host field so changes cause drift.
  const requirements = rows.join('\n');
  rows.length = 0;
  if (host.status === 'valid') collect(host.record, [], true);
  const running = host.status === 'valid'
    ? `The host record describes the setup; it does not prove that the live tool is safe. ${host.record.deploys_on_merge ? 'This will go live when the pull request merges.' : 'A merge does not deploy the tool; a separate release is needed.'}\n\n` +
      '| Recorded setup | Value |\n| --- | --- |\n' + rows.join('\n') + '\n'
    : host.diagnostics.map(line => cell(line)).join('\n\n') + '\n\nNo live setup is confirmed by this section.\n';
  return `${startMarker}\n## How it stays running\n\n` +
    `This section comes from hosting/handover.json and, when valid, hosting/host-record.json. Update the owning record and run npm run hosting:render.\n\n` +
    `Sign-in: ${staff}. Data region: ${h.residency}. Recovery allows up to ${h.recovery.max_data_loss_hours} hours of recent work to be lost and ${h.recovery.max_restore_hours} hours to restore the tool.\n\n` +
    `The requirements below describe what the tool needs. They do not confirm that a live copy exists.\n\n` +
    '| Requirement | Value |\n| --- | --- |\n' + requirements + '\n\n' + running + endMarker;
}
export function renderMasterplan(text, handover, host) {
  const first = text.indexOf(startMarker), last = text.indexOf(endMarker);
  if (first === -1 && last === -1) return `${text.trimEnd()}\n\n${hostingSection(handover, host)}\n`;
  if (first === -1 || last < first || text.indexOf(startMarker, first + 1) !== -1 || text.indexOf(endMarker, last + 1) !== -1) throw new Error('masterplan: invalid hosting markers');
  return text.slice(0, first) + hostingSection(handover, host) + text.slice(last + endMarker.length);
}
export function run(mode, root) {
  const handover = JSON.parse(readFileSync(resolve(root, 'hosting/handover.json'), 'utf8'));
  validateRecord(handover, schemaFor(root));
  checkCode(root, handover);
  const path = resolve(root, 'masterplan.md');
  const text = readFileSync(path, 'utf8');
  const host = hostRecordFor(root);
  if (!['valid', 'absent'].includes(host.status)) throw new Error(host.diagnostics.join('\n'));
  const rendered = renderMasterplan(text, handover, host);
  if (mode === 'render') writeFileSync(path, rendered);
  else if (mode === 'check') same(text, rendered, 'masterplan hosting section');
  else throw new Error('Use check or render');
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { run(process.argv[2], resolve(process.argv[3] ?? '.')); console.log('Handover and hosting section agree with the project'); }
  catch (error) { console.error(error instanceof SyntaxError ? 'handover: JSON could not be read' : error.message); process.exitCode = 1; }
}
