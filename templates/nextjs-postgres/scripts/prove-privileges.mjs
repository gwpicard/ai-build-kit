import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import pg from 'pg';
import { localDatabaseUrls, reportFailure } from './local-database.mjs';

// Each fault changes only this disposable database and is restored before the next.
const faults = [
  ...['public.records', 'public.files', 'job_queue.job', 'job_runtime.heartbeats', 'sign_in."user"', 'sign_in.session',
    'sign_in.invitations', 'sign_in.account', 'sign_in.verification'].map((table) => ({
    name: `TRUNCATE on ${table}`,
    plant: `GRANT TRUNCATE ON ${table} TO tool_app`,
    restore: `REVOKE TRUNCATE ON ${table} FROM tool_app`,
    test: 'effective app privileges match every table, including privileges outside RLS',
  })),
  ...[
    ['auth session truncation', 'TRUNCATE ON sign_in.session TO tool_auth', 'TRUNCATE ON sign_in.session FROM tool_auth'],
    ['auth invitation column', 'INSERT (email) ON sign_in.invitations TO tool_auth', 'INSERT (email) ON sign_in.invitations FROM tool_auth'],
    ['public session column', 'SELECT (token) ON sign_in.session TO PUBLIC', 'SELECT (token) ON sign_in.session FROM PUBLIC'],
    ['auth business access', 'SELECT ON public.files TO tool_auth', 'SELECT ON public.files FROM tool_auth'],
    ['auth schema creation', 'CREATE ON SCHEMA public TO tool_auth', 'CREATE ON SCHEMA public FROM tool_auth'],
  ].map(([name, grant, revoke]) => ({ name, plant: `GRANT ${grant}`, restore: `REVOKE ${revoke}`,
    test: 'sign-in effective table and column privileges cover both roles and every schema' })),
  { name: 'auth callable audit function', plant: 'GRANT USAGE ON SCHEMA audit TO tool_auth; GRANT EXECUTE ON FUNCTION audit.record_change() TO tool_auth',
    restore: 'REVOKE EXECUTE ON FUNCTION audit.record_change() FROM tool_auth; REVOKE USAGE ON SCHEMA audit FROM tool_auth',
    test: 'tool_auth has no unreviewed views, materialised views, sequences or callable functions' },
  { name: 'unreviewed sign-in table', plant: 'ALTER TABLE sign_in.verification RENAME TO unreviewed_verification',
    restore: 'ALTER TABLE sign_in.unreviewed_verification RENAME TO verification',
    test: 'the sign-in table inventory forces row rules and separates app and auth grants' },
  { name: 'auth owner membership', plant: 'GRANT tool_owner TO tool_auth',
    restore: 'REVOKE tool_owner FROM tool_auth',
    test: 'the sign-in table inventory forces row rules and separates app and auth grants' },
  { name: 'file ownership column grant', plant: 'GRANT UPDATE (owner_id) ON public.files TO tool_app',
    restore: 'REVOKE UPDATE (owner_id) ON public.files FROM tool_app',
    test: 'effective file column grants permit insertion and title changes only' },
  { name: 'public file trigger grant', plant: 'GRANT TRIGGER ON public.files TO PUBLIC',
    restore: 'REVOKE TRIGGER ON public.files FROM PUBLIC',
    test: 'effective app privileges match every table, including privileges outside RLS' },
  { name: 'queue clock security definer', plant: 'ALTER FUNCTION job_queue.job_now() SECURITY DEFINER',
    restore: 'ALTER FUNCTION job_queue.job_now() SECURITY INVOKER',
    test: 'tool_app has no unreviewed views, materialised views, sequences or callable functions' },
  { name: 'runtime schema creation', plant: 'GRANT CREATE ON SCHEMA job_runtime TO tool_app',
    restore: 'REVOKE CREATE ON SCHEMA job_runtime FROM tool_app',
    test: 'the jobs catalogue contains only reviewed tables and queue statistics partitions' },
  { name: 'owner role membership', plant: 'GRANT tool_owner TO tool_app',
    restore: 'REVOKE tool_owner FROM tool_app',
    test: 'the app role owns no tables, bypasses no row rules and has no role memberships' },
];

let folder;
try {
  const { admin } = localDatabaseUrls();
  const client = new pg.Client({ connectionString: admin });
  await client.connect();
  folder = await mkdtemp(path.join(tmpdir(), 'privilege-fault-'));
  const run = (args = []) => spawnSync(process.execPath,
    ['node_modules/vitest/vitest.mjs', 'run', 'tests/boundaries.test.ts', 'tests/sign-in-permissions.test.ts', ...args],
    { stdio: 'inherit', env: process.env });
  try {
    if (run().status !== 0) throw new Error('The original privileges must pass first');
    for (const fault of faults) {
      const report = path.join(folder, 'result.json');
      await client.query(fault.plant);
      try {
        const result = run(['-t', fault.test, '--reporter=json', `--outputFile=${report}`]);
        if (result.error || result.signal || result.status !== 1) throw new Error('The planted privilege fault did not fail');
        const evidence = JSON.parse(await readFile(report, 'utf8'));
        const failures = evidence.testResults.flatMap((file) => file.assertionResults)
          .filter((assertion) => assertion.status === 'failed');
        if (failures.length !== 1 || failures[0].title !== fault.test
          || !failures[0].failureMessages.some((message) => message.includes('AssertionError'))) {
          throw new Error('The expected privilege assertion did not detect the fault');
        }
        console.log(`Planted fault detected: ${fault.name}`);
      } finally { await client.query(fault.restore); }
    }
    if (run().status !== 0) throw new Error('The restored privileges must pass');
    console.log('All planted privilege faults detected and original privileges restored');
  } finally { await client.end(); }
} catch (error) { reportFailure(error); }
finally { if (folder) await rm(folder, { recursive: true, force: true }); }
