import { invitePerson } from "./actions";
import { requireRole } from "@/lib/supabase/authorize";

export default async function InvitationsPage() {
  const access = await requireRole(["admin"]);
  if ("error" in access) {
    return <main className="mx-auto max-w-xl p-8">{access.error}</main>;
  }
  return (
    <main className="mx-auto max-w-xl p-8">
      <h1 className="text-2xl font-semibold">Invite a team member</h1>
      <form action={invitePerson} className="mt-6 flex gap-3">
        <label className="sr-only" htmlFor="email">Email address</label>
        <input id="email" name="email" type="email" required className="min-w-0 flex-1 rounded border border-slate-300 bg-white px-3 py-2" />
        <button className="rounded bg-slate-900 px-4 py-2 text-white" type="submit">Send invitation</button>
      </form>
    </main>
  );
}
