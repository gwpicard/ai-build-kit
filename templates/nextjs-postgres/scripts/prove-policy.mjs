import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, unlink, rmdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import pg from 'pg';
import { localDatabaseUrls, reportFailure } from './local-database.mjs';

try {
  const { owner } = localDatabaseUrls();
  const client = new pg.Client({ connectionString: owner });
  await client.connect();
  try {
    const policy = await client.query(`SELECT qual FROM pg_policies
      WHERE schemaname='public' AND tablename='records' AND policyname='records_read'`);
    if (policy.rowCount !== 1) throw new Error('Expected the original read policy');
    const baseline = spawnSync(process.execPath, ['node_modules/vitest/vitest.mjs', 'run',
      'tests/roles.test.ts', '-t', 'member reads records'], { stdio: 'inherit', env: process.env });
    if (baseline.error || baseline.status !== 0) throw new Error('The original policy must pass first');
    const folder = await mkdtemp(path.join(tmpdir(), 'policy-fault-'));
    const report = path.join(folder, 'result.json');
    await client.query('DROP POLICY records_read ON public.records');
    try {
      const result = spawnSync(process.execPath, ['node_modules/vitest/vitest.mjs', 'run',
        'tests/roles.test.ts', '-t', 'member reads records', '--reporter=json', `--outputFile=${report}`],
      { stdio: 'inherit', env: process.env });
      if (result.error || result.signal || result.status !== 1) {
        throw new Error('The planted policy fault did not produce a test failure');
      }
      const evidence = JSON.parse(await readFile(report, 'utf8'));
      const failures = evidence.testResults.flatMap((file) => file.assertionResults)
        .filter((assertion) => assertion.status === 'failed');
      if (failures.length !== 1 || failures[0].title !== 'member reads records'
        || !failures[0].failureMessages.some((message) => message.includes('AssertionError: expected [] to deeply equal'))) {
        throw new Error('The generated read assertion must detect the fault');
      }
      console.log(failures[0].failureMessages.join('\n'));
      console.log('Planted policy fault detected');
    } finally {
      await client.query(`CREATE POLICY records_read ON public.records FOR SELECT TO tool_app USING (${policy.rows[0].qual})`);
      console.log('Original read policy restored');
      await unlink(report).catch(() => {});
      await rmdir(folder);
    }
  } finally {
    await client.end();
  }
} catch (error) {
  reportFailure(error);
}
