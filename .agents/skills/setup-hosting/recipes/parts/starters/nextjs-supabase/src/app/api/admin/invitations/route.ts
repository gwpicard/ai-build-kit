import { NextRequest } from "next/server";
import { requireRole } from "@/lib/supabase/authorize";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(request: NextRequest) {
  const access = await requireRole(["admin"]);
  if ("error" in access) {
    return Response.json({ error: access.error }, { status: access.status });
  }
  const body: unknown = await request.json().catch(() => null);
  const email = typeof body === "object" && body !== null && "email" in body
    ? String(body.email).trim()
    : "";
  if (!email || !email.includes("@")) {
    return Response.json({ error: "Enter a valid email address" }, { status: 400 });
  }
  const admin = createAdminClient();
  const { data, error } = await admin.auth.admin.inviteUserByEmail(email, {
    redirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/callback`,
  });
  if (error || !data.user) {
    return Response.json({ error: "The invitation could not be sent" }, { status: 502 });
  }
  const { error: roleError } = await admin.from("roles").upsert({ user_id: data.user.id, role: "member" });
  if (roleError) {
    return Response.json({ error: "The invitation was sent, but its role could not be saved" }, { status: 500 });
  }
  return Response.json({ invited: true }, { status: 201 });
}
