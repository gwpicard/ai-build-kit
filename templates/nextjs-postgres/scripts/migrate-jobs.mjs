import { PgBoss } from 'pg-boss';

export async function migrateJobs(client) {
  await client.query("select pg_advisory_lock(hashtext('tool-job-migrations'))");
  try { await installJobs(client); }
  finally { await client.query("select pg_advisory_unlock(hashtext('tool-job-migrations'))"); }
}

async function installJobs(client) {
  const boss = new PgBoss({ schema: 'job_queue', db: {
    executeSql: async (text, values) => {
      await client.query('BEGIN');
      try {
        await client.query("select set_config('app.role', 'system', true), set_config('app.user_id', '00000000-0000-4000-8000-000000000001', true)");
        const result = await client.query(text, values);
        await client.query('COMMIT');
        return result;
      } catch (error) { await client.query('ROLLBACK'); throw error; }
    },
  }, schedule: false, supervise: false, registerInstance: false });
  boss.on('error', () => {});
  try {
    await boss.start();
    for (const name of ['weekly-reminder', 'slow-document']) {
      await boss.createQueue(name, { retryLimit: 5, retryDelay: 1, retryBackoff: true, expireInSeconds: 30 });
    }
  } finally { await boss.stop(); }
  await client.query('BEGIN');
  try {
    await client.query('REVOKE ALL ON SCHEMA job_queue FROM PUBLIC; GRANT USAGE ON SCHEMA job_queue TO tool_app');
    await client.query('REVOKE ALL ON ALL FUNCTIONS IN SCHEMA job_queue FROM PUBLIC');
    // Functions manage queue DDL as invoker. Runtime cannot call them or create partitions.
    await client.query('GRANT EXECUTE ON FUNCTION job_queue.job_now() TO tool_app');
    const { rows } = await client.query("SELECT tablename FROM pg_tables WHERE schemaname='job_queue'");
    for (const { tablename } of rows) {
      const table = `job_queue."${tablename.replaceAll('"', '""')}"`;
      await client.query(`ALTER TABLE ${table} ENABLE ROW LEVEL SECURITY; ALTER TABLE ${table} FORCE ROW LEVEL SECURITY`);
      await client.query(`GRANT SELECT, INSERT, UPDATE, DELETE ON ${table} TO tool_app`);
      const policy = await client.query("SELECT 1 FROM pg_policies WHERE schemaname='job_queue' AND tablename=$1 AND policyname='queue_system'", [tablename]);
      if (!policy.rowCount) await client.query(`CREATE POLICY queue_system ON ${table} TO tool_owner, tool_app
        USING (current_setting('app.role', true) = 'system' AND current_setting('app.user_id', true) = '00000000-0000-4000-8000-000000000001')
        WITH CHECK (current_setting('app.role', true) = 'system' AND current_setting('app.user_id', true) = '00000000-0000-4000-8000-000000000001')`);
    }
    await client.query('COMMIT');
  } catch (error) { await client.query('ROLLBACK'); throw error; }
}
