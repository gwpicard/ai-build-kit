import { createClient } from "@/lib/supabase/server";

export async function requireRole(allowed: string[]) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "Sign in is required", status: 401 as const };
  const role = user.app_metadata.role;
  if (typeof role !== "string" || !allowed.includes(role)) {
    return { error: "You do not have access", status: 403 as const };
  }
  return { user, role };
}
