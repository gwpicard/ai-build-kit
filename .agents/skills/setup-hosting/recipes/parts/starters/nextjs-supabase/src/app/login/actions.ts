"use server";

import { createClient } from "@/lib/supabase/server";

export async function sendSignInLink(formData: FormData) {
  const email = String(formData.get("email") ?? "").trim();
  if (!email || !email.includes("@")) throw new Error("Enter a valid email address");
  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      shouldCreateUser: false,
      emailRedirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/callback`,
    },
  });
  if (error) throw new Error("A sign-in link could not be sent. Ask an administrator to invite you.");
}
