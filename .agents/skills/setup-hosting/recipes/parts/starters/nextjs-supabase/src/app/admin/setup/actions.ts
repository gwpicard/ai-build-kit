"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { setFirstAdminRole } from "@/lib/roles";

export async function claimFirstAdmin() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user?.email || user.email.toLowerCase() !== process.env.INITIAL_ADMIN_EMAIL?.toLowerCase()) {
    throw new Error("Sign in with the invited owner account to finish setup");
  }
  const admin = createAdminClient();
  await setFirstAdminRole(
    async () => {
      const { error } = await admin.from("roles").upsert({ user_id: user.id, role: "admin" });
      if (error) throw new Error("The first administrator could not be set up");
    },
    async () => {
      const { error } = await supabase.auth.refreshSession();
      if (error) throw new Error("The administrator role was saved, but the sign-in session could not be refreshed. Sign in again to continue.");
    },
  );
  redirect("/admin/invitations");
}
