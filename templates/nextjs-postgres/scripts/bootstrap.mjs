import { readFile } from 'node:fs/promises';
import pg from 'pg';
import { localDatabaseUrls, reportFailure } from './local-database.mjs';

try {
  const urls = localDatabaseUrls();
  const client = new pg.Client({ connectionString: urls.admin });
  await client.connect();
  try {
    await client.query('BEGIN');
    const roles = await client.query("SELECT rolname FROM pg_roles WHERE rolname IN ('tool_owner', 'tool_app')");
    if (roles.rowCount === 0) {
      await client.query(await readFile(new URL('../db/bootstrap.sql', import.meta.url), 'utf8'));
    } else if (roles.rowCount !== 2) {
      throw new Error('Local roles are only partly configured');
    }
    await client.query('ALTER SCHEMA public OWNER TO tool_owner');
    await client.query(`DO $$ BEGIN
      EXECUTE format('REVOKE CREATE, TEMPORARY ON DATABASE %I FROM PUBLIC', current_database());
      EXECUTE format('GRANT CREATE ON DATABASE %I TO tool_owner', current_database());
      EXECUTE format('GRANT CONNECT ON DATABASE %I TO tool_owner, tool_app', current_database());
    END $$`);
    for (const connection of [urls.owner, urls.app]) {
      const url = new URL(connection);
      const password = decodeURIComponent(url.password);
      if (!password) throw new Error('A local role password is required');
      const result = await client.query("SELECT format('ALTER ROLE %I PASSWORD %L', $1::text, $2::text) AS statement",
        [url.username, password]);
      await client.query(result.rows[0].statement);
    }
    await client.query('COMMIT');
    console.log('Local database roles are ready');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    await client.end();
  }
} catch (error) {
  reportFailure(error);
}
