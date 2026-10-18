// Prepaid drink credit. The card payment is taken on the cafe's own card
// terminal, and this records the credit that payment bought.
export type Entry = { requestId: string; customer: string; pence: number };
export type Ledger = { entries: Entry[] };

export function emptyLedger(): Ledger {
  return { entries: [] };
}

// Adds credit for a customer. Each request carries its own id.
export function addCredit(ledger: Ledger, entry: Entry): Ledger {
  if (!Number.isInteger(entry.pence) || entry.pence <= 0) {
    throw new Error("credit must be a positive whole number of pence");
  }
  if (ledger.entries.some((existing) => existing.requestId === entry.requestId)) {
    return ledger;
  }
  return { entries: [...ledger.entries, entry] };
}

export function balance(ledger: Ledger, customer: string): number {
  return ledger.entries
    .filter((entry) => entry.customer === customer)
    .reduce((total, entry) => total + entry.pence, 0);
}
