import path from 'node:path';
import { tmpdir } from 'node:os';
import { ESLint } from 'eslint';
import { beforeAll, expect, test } from 'vitest';
import databaseBoundary from '../scripts/database-boundary.mjs';

const eslint = new ESLint();
beforeAll(async () => {
  await eslint.calculateConfigForFile(path.resolve('src/lib/bypass.ts'));
}, 30000);
for (const file of ['lib/query.ts', 'src/lib/query.mts', 'src/lib/query.cts', 'src/nested/src/lib/db/with-database.ts']) {
  test(`lint confines the connection exemption to the exact helper: ${file}`, async () => {
    const [result] = await eslint.lintText('import { Pool } from "pg";', { filePath: path.resolve(file) });
    expect(result.messages.some((message) => message.ruleId === 'database/boundary')).toBe(true);
  });
}
for (const code of [
  'import { Pool } from "pg"; new Pool().query("select 1");',
  'import Client from "pg/lib/client.js";',
  'import Pool from "pg-pool";',
  'import type { Pool } from "pg";',
  'export { Pool } from "pg";',
  'const pg = await import("pg");',
  'const pg = require("pg");',
  'const pg = module.require("pg");',
  'import pg = require("pg");',
  'import { Kysely as RawDatabase } from "kysely";',
  'import * as raw from "kysely";',
  'import { pool } from "@/lib/db/pool";',
  'import { testIdentity } from "../../tests/support/identity";',
  'import "../../scripts/migrate.mjs";',
]) {
  test(`lint rejects bypass: ${code}`, async () => {
    const [result] = await eslint.lintText(code, { filePath: path.resolve('src/lib/bypass.ts') });
    expect(result.messages.some((message) => message.ruleId === 'database/boundary' && message.severity === 2)).toBe(true);
  });
}
const alternativeLoaders = [
  'import { createRequire } from "node:module"; const load = createRequire(import.meta.url); const { Pool } = load("pg"); export const pool = new Pool({ connectionString: process.env.DATABASE_URL });',
  'import { createRequire as makeLoader } from "module"; const load = makeLoader(import.meta.url); load("pg");',
  'import * as modules from "node:module"; const load = modules["createRequire"](import.meta.url); load("pg");',
  'import modules from "node:module"; const { createRequire: makeLoader } = modules; makeLoader(import.meta.url)("pg");',
  'const { createRequire: makeLoader } = await import("node:module"); makeLoader(import.meta.url)("pg");',
  'const { createRequire: makeLoader } = require("module"); makeLoader(import.meta.url)("pg");',
  'export { createRequire as makeLoader } from "node:module";',
  'const load = require; load("pg");',
  'const load = module.require.bind(module); load("pg");',
  'const { require: load } = module; load("pg");',
  'module["require"]("pg");',
  'const load = process.mainModule.require.bind(process.mainModule); load("pg");',
  'const { require: load } = process["mainModule"]; load("pg");',
  'import Client from "../node_modules/pg/lib/index.js";',
  'export { default } from "../../node_modules/pg-pool/index.js";',
  'const pg = await import("../../node_modules/pg/lib/index.js");',
  'const pg = require("../../node_modules/postgres/src/index.js");',
  'import Client from "@/../node_modules/pg-native/index.js";',
  'import Client from "file:///example/node_modules/pg/lib/index.js";',
];
for (const code of alternativeLoaders) {
  test(`lint rejects alternative loader or resolved driver: ${code}`, async () => {
    const [result] = await eslint.lintText(code, { filePath: path.resolve('src/lib/bypass.ts') });
    expect(result.messages.some((message) => message.ruleId === 'database/boundary' && message.severity === 2)).toBe(true);
  });
}

test('lint permits queries inside the helper callback and type-only imports', async () => {
  const [result] = await eslint.lintText(`import { sql, type Transaction } from "kysely";
    import { withDatabase } from "./db/with-database";
    export const query = (identity: never) => withDatabase(identity, db => sql\`select 1\`.execute(db));
    export type Query = Transaction<unknown>;`, { filePath: path.resolve('src/lib/query.ts') });
  expect(result.errorCount).toBe(0);
});

test('a parent folder named scripts does not make ordinary app imports privileged', async () => {
  const relocated = new ESLint({ cwd: tmpdir(), overrideConfigFile: true, overrideConfig: {
    plugins: { database: { rules: { boundary: databaseBoundary } } },
    rules: { 'database/boundary': 'error' },
  } });
  const [result] = await relocated.lintText('import { sql } from "kysely"; export { sql };', {
    filePath: path.join(tmpdir(), 'scripts/example-app/src/query.js'),
  });
  expect(result.errorCount).toBe(0);
});

test('the exact database helper may use a module loader', async () => {
  const [result] = await eslint.lintText(`import { createRequire as makeLoader } from "node:module";
    const load = makeLoader(import.meta.url);
    export const pool = load("pg");`, { filePath: path.resolve('src/lib/db/with-database.ts') });
  expect(result.messages.filter((message) => message.ruleId === 'database/boundary')).toEqual([]);
});
