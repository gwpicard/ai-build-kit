import { createClient } from "@supabase/supabase-js";

export const dynamic = "force-dynamic";

export async function GET() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) {
    return Response.json({ status: "error", database: "unavailable" }, { status: 503 });
  }

  const supabase = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { error } = await supabase.from("roles").select("user_id").limit(1);
  if (error) {
    return Response.json({ status: "error", database: "unavailable" }, { status: 503 });
  }
  return Response.json({
    status: "ok",
    database: "reachable",
    commit: process.env.VERCEL_GIT_COMMIT_SHA ?? process.env.SOURCE_COMMIT ?? "unknown",
    project: new URL(url).hostname.split(".")[0],
  });
}
