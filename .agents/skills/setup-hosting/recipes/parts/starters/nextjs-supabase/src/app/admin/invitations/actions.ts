"use server";

import { revalidatePath } from "next/cache";
import { requireRole } from "@/lib/supabase/authorize";
import { createAdminClient } from "@/lib/supabase/admin";

export async function invitePerson(formData: FormData) {
  const access = await requireRole(["admin"]);
  if ("error" in access) throw new Error(access.error);
  const email = String(formData.get("email") ?? "").trim();
  if (!email || !email.includes("@")) throw new Error("Enter a valid email address");

  const admin = createAdminClient();
  const { data, error } = await admin.auth.admin.inviteUserByEmail(email, {
    redirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/callback`,
  });
  if (error || !data.user) throw new Error("The invitation could not be sent");
  const { error: roleError } = await admin.from("roles").upsert({ user_id: data.user.id, role: "member" });
  if (roleError) throw new Error("The invitation was sent, but the role could not be saved");
  revalidatePath("/admin/invitations");
}
