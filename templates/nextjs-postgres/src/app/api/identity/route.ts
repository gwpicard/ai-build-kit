import { sessionIdentity } from "@/lib/sign-in";
import { withDatabase } from "@/lib/db/with-database";
import { sql } from "kysely";

export async function GET(request: Request) {
  const identity = await sessionIdentity(request.headers);
  if (!identity) return Response.json({ error: "Sign in to continue" }, { status: 401 });
  const result = await withDatabase(identity, (db) => sql<{ userId: string; role: string }>`
    select current_setting('app.user_id') as "userId", current_setting('app.role') as role`.execute(db));
  return Response.json(result.rows[0], { headers: { "Cache-Control": "no-store" } });
}
