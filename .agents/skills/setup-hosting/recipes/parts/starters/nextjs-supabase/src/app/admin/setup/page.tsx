import { claimFirstAdmin } from "./actions";

export default function SetupPage() {
  return (
    <main className="mx-auto max-w-xl p-8">
      <h1 className="text-2xl font-semibold">Set up the first administrator</h1>
      <p className="mt-3 text-slate-600">Sign in with the invited owner account named in INITIAL_ADMIN_EMAIL.</p>
      <form action={claimFirstAdmin} className="mt-6">
        <button className="rounded bg-slate-900 px-4 py-2 text-white" type="submit">Finish owner setup</button>
      </form>
    </main>
  );
}
