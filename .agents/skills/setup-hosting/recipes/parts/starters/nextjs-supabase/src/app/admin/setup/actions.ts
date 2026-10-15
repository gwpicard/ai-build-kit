"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";

export async function claimFirstAdmin() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user?.email || user.email.toLowerCase() !== process.env.INITIAL_ADMIN_EMAIL?.toLowerCase()) {
    throw new Error("Sign in with the invited owner account to finish setup");
  }
  const { error } = await createAdminClient().from("roles").upsert({ user_id: user.id, role: "admin" });
  if (error) throw new Error("The first administrator could not be set up");
  redirect("/admin/invitations");
}
