import { formatPence } from "@/lib/format.ts";
import { balance } from "@/lib/ledger.ts";
import { readLedger } from "@/lib/store.ts";

export const dynamic = "force-dynamic";

const regulars = ["ann", "ben", "cleo"];

export default function Home() {
  const ledger = readLedger();
  return (
    <main>
      <h1>Till credit</h1>
      <ul>
        {regulars.map((name) => (
          <li key={name}>
            {name}: {formatPence(balance(ledger, name))}
          </li>
        ))}
      </ul>
    </main>
  );
}
