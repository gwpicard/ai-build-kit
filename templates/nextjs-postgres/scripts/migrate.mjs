import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import pg from 'pg';
import { migrateJobs } from './migrate-jobs.mjs';
import { reportFailure } from './local-database.mjs';

try {
  if (!process.env.MIGRATION_DATABASE_URL) throw new Error('MIGRATION_DATABASE_URL is required');
  const client = new pg.Client({ connectionString: process.env.MIGRATION_DATABASE_URL });
  await client.connect();
  try {
    await client.query('BEGIN');
    const role = await client.query('SELECT current_user AS name');
    if (role.rows[0].name !== 'tool_owner') throw new Error('Migrations require tool_owner');
    await client.query("SELECT pg_advisory_xact_lock(hashtext('tool-migrations'))");
    await client.query(`CREATE SCHEMA IF NOT EXISTS private AUTHORIZATION tool_owner;
      CREATE TABLE IF NOT EXISTS private.schema_migrations (name text PRIMARY KEY, checksum text NOT NULL);
      ALTER TABLE private.schema_migrations ENABLE ROW LEVEL SECURITY;
      ALTER TABLE private.schema_migrations FORCE ROW LEVEL SECURITY;`);
    const policy = await client.query("SELECT 1 FROM pg_policies WHERE schemaname='private' AND tablename='schema_migrations'");
    if (!policy.rowCount) await client.query(`CREATE POLICY migrations_owner ON private.schema_migrations
      TO tool_owner USING (true) WITH CHECK (true)`);
    const folder = new URL('../db/migrations/', import.meta.url);
    for (const name of (await readdir(folder)).filter((name) => name.endsWith('.sql')).sort()) {
      const migration = await readFile(new URL(name, folder), 'utf8');
      const checksum = createHash('sha256').update(migration).digest('hex');
      const previous = await client.query('SELECT checksum FROM private.schema_migrations WHERE name=$1', [name]);
      if (previous.rowCount) {
        if (previous.rows[0].checksum !== checksum) throw new Error('An applied migration has changed');
        continue;
      }
      await client.query(migration);
      await client.query('INSERT INTO private.schema_migrations VALUES ($1, $2)', [name, checksum]);
      console.log(`Applied ${name}`);
    }
    await client.query('COMMIT');
    await migrateJobs(client);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    await client.end();
  }
} catch (error) {
  reportFailure(error);
}
