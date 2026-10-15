import { sendSignInLink } from "./actions";

export default function LoginPage() {
  return (
    <main className="mx-auto max-w-xl p-8">
      <h1 className="text-2xl font-semibold">Sign in</h1>
      <p className="mt-3 text-slate-600">Enter your invited email address. We will send a sign-in link.</p>
      <form action={sendSignInLink} className="mt-6 flex gap-3">
        <label className="sr-only" htmlFor="email">Email address</label>
        <input id="email" name="email" type="email" required className="min-w-0 flex-1 rounded border border-slate-300 bg-white px-3 py-2" />
        <button className="rounded bg-slate-900 px-4 py-2 text-white" type="submit">Send link</button>
      </form>
    </main>
  );
}
