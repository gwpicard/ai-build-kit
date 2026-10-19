import { emptyLedger, type Ledger } from "./ledger.ts";

// Held in memory until the database piece is built.
let ledger: Ledger = emptyLedger();

export function readLedger(): Ledger {
  return ledger;
}

export function writeLedger(next: Ledger): void {
  ledger = next;
}
