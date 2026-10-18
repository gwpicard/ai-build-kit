import { formatPence } from "@/lib/format.ts";
import { splitBill } from "@/lib/split.ts";

export const dynamic = "force-dynamic";

// One bill for now. A form to enter others comes later.
const bill = { totalPence: 4200, people: 3 };

export default function Home() {
  const shares = splitBill(bill.totalPence, bill.people);
  return (
    <main>
      <h1>Bill splitter</h1>
      <p>
        {formatPence(bill.totalPence)} between {bill.people} people
      </p>
      <ol>
        {shares.map((share, index) => (
          <li key={index}>{formatPence(share)}</li>
        ))}
      </ol>
    </main>
  );
}
