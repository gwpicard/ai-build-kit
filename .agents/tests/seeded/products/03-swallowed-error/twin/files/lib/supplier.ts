// Stock levels from the supplier's public stock service.
export type UnitsResult =
  | { ok: true; units: number }
  | { ok: false; reason: string };

export type FetchLike = (url: string) => Promise<{
  ok: boolean;
  status: number;
  json(): Promise<unknown>;
}>;

const base = process.env.SUPPLIER_URL ?? "https://stock.supplier.example";

// How many units of a part the supplier holds. The fetch is passed in so a
// test never calls the real service.
export async function lookupUnits(
  code: string,
  fetchImpl: FetchLike = fetch,
): Promise<UnitsResult> {
  try {
    const response = await fetchImpl(`${base}/parts/${encodeURIComponent(code)}`);
    if (response.status === 404) {
      return { ok: true, units: 0 };
    }
    if (!response.ok) {
      throw new Error(`the supplier answered ${response.status}`);
    }
    const body = (await response.json()) as { units?: unknown };
    if (typeof body.units !== "number") {
      throw new Error("the supplier's answer has no unit count");
    }
    return { ok: true, units: body.units };
  } catch {
    // The counter page must never break because of the supplier, and it must
    // not pretend either.
    return { ok: false, reason: "the supplier could not be reached" };
  }
}
