import "server-only";
import { Pool } from "pg";

export function signInStorage(connectionString: string) {
  const pool = new Pool({ connectionString, options: "-c search_path=sign_in", max: 5,
    idleTimeoutMillis: 1000 });
  async function invited(email: string): Promise<boolean> {
    const result = await pool.query(`SELECT 1 FROM invitations
      WHERE email=$1 AND "expiresAt">now() AND NOT revoked`, [email.toLowerCase()]);
    return result.rowCount === 1;
  }
  async function prepareOutsider(email: string): Promise<boolean> {
    if (!await invited(email)) return false;
    await pool.query(`INSERT INTO "user" (id, name, email, "emailVerified", role, kind)
      VALUES (gen_random_uuid(), $1, $1, false, 'viewer', 'outsider')
      ON CONFLICT (email) DO NOTHING`, [email]);
    const result = await pool.query(`SELECT kind FROM "user" WHERE email=$1`, [email]);
    return result.rows[0]?.kind === "outsider";
  }
  async function allowedUser(userId: string) {
    const result = await pool.query(`SELECT email, kind FROM "user" WHERE id=$1`, [userId]);
    const user = result.rows[0];
    return !!user && (user.kind === "staff" || await invited(user.email));
  }
  return { pool, invited, prepareOutsider, allowedUser };
}
