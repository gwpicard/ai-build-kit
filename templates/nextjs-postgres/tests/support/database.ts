import pg from "pg";
import { localDatabaseUrls } from "../../scripts/local-database.mjs";

export async function inspect<T>(work: (client: pg.Client) => Promise<T>): Promise<T> {
  const { admin } = localDatabaseUrls();
  const client = new pg.Client({ connectionString: admin });
  await client.connect();
  try { return await work(client); }
  finally { await client.end(); }
}
