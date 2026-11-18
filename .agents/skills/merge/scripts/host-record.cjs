const { readFileSync } = require('node:fs');
const { resolve, join } = require('node:path');

// Report schema fields and array indices without exposing arbitrary input keys.
function fieldPath(parts, schema) {
  let result = '', current = schema;
  for (const part of parts) {
    if (typeof part === 'number' || (current?.type === 'array' && /^\d+$/.test(part))) {
      result += `[${part}]`; current = current?.items;
    } else {
      current = current?.properties ? current : current?.anyOf?.find(s => s.type === 'object');
      const known = Object.hasOwn(current?.properties ?? {}, part);
      result += (result ? '.' : '') + (known ? part : '<unknown field>');
      current = known ? current.properties[part] : undefined;
    }
  }
  return result || '$';
}
function possibleSecret(value, path) {
  if (path.length === 3 && path[0] === 'rollback_targets' && path[2] === 'image') value = value.replace(/(?:@sha256:[0-9a-f]{64}|:[0-9a-f]{40})$/, '');
  if (/(?:^|[^a-z0-9])(?:key|token|sig|password)\s*[:=]/i.test(value) || /-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----/.test(value)) return true;
  return (value.match(/[A-Za-z0-9+/_=-]{32,}/g) ?? []).some(run => {
    const counts = new Map();
    for (const c of run) counts.set(c, (counts.get(c) ?? 0) + 1);
    const entropy = -[...counts.values()].reduce((sum, n) => sum + n / run.length * Math.log2(n / run.length), 0);
    return entropy >= (/^[0-9a-fA-F]{40,}$/.test(run) ? 3.5 : 4);
  });
}
function timestamp(value) {
  if (typeof value !== 'string') return true;
  const match = /^(\d{4})-(\d\d)-(\d\d)[Tt](\d\d):(\d\d):(\d\d)(?:\.\d+)?(?:[Zz]|[+-](\d\d):(\d\d))$/.exec(value);
  if (!match) return false;
  const [, y, m, d, h, min, s, zh, zm] = match.map(part => part === undefined ? 0 : Number(part));
  const days = [31, y % 4 === 0 && (y % 100 !== 0 || y % 400 === 0) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  return y > 0 && m >= 1 && m <= 12 && d >= 1 && d <= days[m - 1] && h < 24 && min < 60 && s < 60 && zh < 24 && zm < 60;
}
function schemaFor() {
  for (const path of [join(__dirname, '../contracts/ai-host-kit/host-record.schema.json'), join(__dirname, 'host-record.schema.json')]) {
    try { return JSON.parse(readFileSync(path, 'utf8')); } catch (error) { if (error.code !== 'ENOENT') throw error; }
  }
  throw new Error('schema unavailable');
}
function duplicatePaths(text) {
  // JSON.parse checks syntax first. Retain object keys here to detect ambiguity.
  const tokens = text.match(/"(?:[^"\\]|\\.)*"|[{}\[\],:]|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?|true|false|null/g);
  const duplicates = [];
  let index = 0;
  function walk(path) {
    const token = tokens[index++];
    if (token === '{') {
      const keys = new Set();
      while (tokens[index] !== '}') {
        const key = JSON.parse(tokens[index++]); index++;
        if (keys.has(key)) duplicates.push([...path, key]);
        keys.add(key); walk([...path, key]);
        if (tokens[index] !== ',') break;
        index++;
      }
      index++;
    } else if (token === '[') {
      let item = 0;
      while (tokens[index] !== ']') {
        walk([...path, item++]);
        if (tokens[index] !== ',') break;
        index++;
      }
      index++;
    }
  }
  walk([]);
  return duplicates;
}
function readHostRecord(root, text, expectedTool) {
  if (text === undefined) {
    try { text = readFileSync(resolve(root, 'hosting/host-record.json'), 'utf8'); }
    catch (error) { return { status: error.code === 'ENOENT' ? 'absent' : 'invalid', diagnostics: ['hosting/host-record.json: ' + (error.code === 'ENOENT' ? 'absent' : 'could not read the record')] }; }
  }
  let record;
  try { record = JSON.parse(text); } catch { return { status: 'invalid', diagnostics: ['hosting/host-record.json: invalid JSON'] }; }
  let schema, validate;
  try { schema = schemaFor(); }
  catch { return { status: 'could-not-read', diagnostics: ['hosting/host-record.json: the pinned schema could not be read'] }; }
  let duplicates;
  try { duplicates = duplicatePaths(text); }
  catch { return { status: 'invalid', diagnostics: ['hosting/host-record.json: could not read the record structure'] }; }
  if (duplicates.length) return { status: 'invalid', diagnostics: [...new Set(duplicates.map(path => `${fieldPath(path, schema)}: duplicate field`))] };
  if (record && typeof record === 'object' && typeof record.schema_version === 'string' && record.schema_version !== '1.0') {
    return { status: 'unknown-version', diagnostics: ['schema_version: unsupported version; update AI Build Kit to a reader that supports this record'] };
  }
  try {
    validate = require('./host-record-validator.cjs');
  } catch { return { status: 'could-not-read', diagnostics: ['hosting/host-record.json: the bundled validator could not be read'] }; }
  const diagnostics = new Set();
  if (!validate(record)) for (const error of validate.errors) {
    const parts = error.instancePath.split('/').slice(1).map(p => p.replaceAll('~1', '/').replaceAll('~0', '~'));
    if (error.keyword === 'required') parts.push(error.params.missingProperty);
    if (error.keyword === 'additionalProperties') parts.push(error.params.additionalProperty);
    const reason = { required: 'required field is missing', additionalProperties: 'field is not allowed', type: 'has the wrong type', format: 'has the wrong form', pattern: 'has the wrong form', enum: 'choose a supported option', minLength: 'must not be empty', minimum: 'is below the minimum' }[error.keyword] ?? 'does not meet the schema rule';
    diagnostics.add(`${fieldPath(parts, schema)}: ${reason}`);
  }
  function scan(value, path = []) {
    if (typeof value === 'string' && possibleSecret(value, path)) diagnostics.add(`${fieldPath(path, schema)}: contains possible secret content; use a name or reference`);
    else if (value && typeof value === 'object') for (const [key, child] of Object.entries(value)) scan(child, [...path, Array.isArray(value) ? Number(key) : key]);
  }
  scan(record);
  if (diagnostics.size) return { status: 'invalid', diagnostics: [...diagnostics].sort() };
  if (expectedTool === undefined) {
    try { expectedTool = JSON.parse(readFileSync(resolve(root, 'hosting/handover.json'), 'utf8')).tool?.name; }
    catch { /* Report the missing identity without exposing handover content. */ }
  }
  if (typeof expectedTool !== 'string' || !expectedTool) return { status: 'invalid', diagnostics: ['tool: could not read the tool name from hosting/handover.json; the host record is not used'] };
  if (record.tool !== expectedTool) return { status: 'invalid', diagnostics: ['tool: does not match hosting/handover.json; the host record is not used'] };
  return { status: 'valid', record, diagnostics: ['hosting/host-record.json: valid structure; live behaviour is not checked'] };
}
function mergeEffect(result) {
  if (result.status !== 'valid') return [...result.diagnostics, 'Use the existing recipe and masterplan merge setting.'].join('\n');
  return result.record.deploys_on_merge === true ? 'This will go live when the pull request merges.' : 'This merge will not deploy the tool. A separate release is needed.';
}
module.exports = { readHostRecord, mergeEffect, timestamp };
if (require.main === module) {
  const [mode, root = '.', ...options] = process.argv.slice(2);
  const stdin = options[0] === '--stdin';
  const rest = stdin ? options.slice(1) : options;
  const tool = rest[0] === '--tool' && rest.length === 2 ? rest[1] : undefined;
  if (!['check', 'merge'].includes(mode) || (rest.length && tool === undefined)) {
    console.error('Use host-record.cjs check|merge [project] [--stdin] [--tool name]'); process.exitCode = 2;
  } else {
    const result = readHostRecord(resolve(root), stdin ? readFileSync(0, 'utf8') : undefined, tool);
    console.log(mode === 'merge' ? mergeEffect(result) : result.diagnostics.join('\n'));
    process.exitCode = ['valid', 'absent'].includes(result.status) ? 0 : result.status === 'could-not-read' ? 2 : 1;
  }
}
