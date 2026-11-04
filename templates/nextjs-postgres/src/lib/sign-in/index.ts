import "server-only";
import { after } from "next/server";
import { readConfig } from "./config";
import { sendSignInLink } from "./mail";
import { createSignIn } from "./service";
import { withDatabase } from "../db/with-database";
import { sql } from "kysely";

let service: ReturnType<typeof createSignIn> | undefined;
function signIn() {
  return service ??= createSignIn(readConfig(), async (email, url) => {
    after(async () => {
      try { await sendSignInLink(email, url); }
      catch { console.error("The sign-in email could not be sent"); }
    });
  });
}

export const signInHandler = (request: Request) => signIn().handler(request);
export const sessionIdentity = (headers: Headers) => signIn().identity(headers);

export async function inviteOutsider(headers: Headers, email: string, expiresAt: Date) {
  const identity = await sessionIdentity(headers);
  if (!identity || identity.role !== "admin") throw new Error("An administrator session is required");
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || !(expiresAt > new Date())) {
    throw new Error("An email address and future invitation expiry are required");
  }
  await withDatabase(identity, (db) => sql`insert into sign_in.invitations (email, "expiresAt")
    values (${email.trim().toLowerCase()}, ${expiresAt})
    on conflict (email) do update set "expiresAt"=excluded."expiresAt", revoked=false`.execute(db));
}
