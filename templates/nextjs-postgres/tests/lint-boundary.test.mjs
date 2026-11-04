import path from 'node:path';
import { ESLint } from 'eslint';
import { beforeAll, expect, test } from 'vitest';

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
test('lint permits queries inside the helper callback and type-only imports', async () => {
  const [result] = await eslint.lintText(`import { sql, type Transaction } from "kysely";
    import { withDatabase } from "./db/with-database";
    export const query = (identity: never) => withDatabase(identity, db => sql\`select 1\`.execute(db));
    export type Query = Transaction<unknown>;`, { filePath: path.resolve('src/lib/query.ts') });
  expect(result.errorCount).toBe(0);
});
