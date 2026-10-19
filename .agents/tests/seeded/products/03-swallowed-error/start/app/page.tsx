import { lookupUnits } from "@/lib/supplier.ts";

export const dynamic = "force-dynamic";

const parts = ["BRK-100", "CHN-220", "TYR-330"];

export default async function Home() {
  const rows = await Promise.all(
    parts.map(async (code) => ({ code, result: await lookupUnits(code) })),
  );
  return (
    <main>
      <h1>Parts counter</h1>
      <table>
        <thead>
          <tr>
            <th>Part</th>
            <th>Units at the supplier</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.code}>
              <td>{row.code}</td>
              <td>{row.result.ok ? row.result.units : "?"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
