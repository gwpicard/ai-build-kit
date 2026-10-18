import { test } from "node:test";
import assert from "node:assert/strict";
import { addCredit, balance, emptyLedger } from "./ledger.ts";

test("credit added for a customer shows in their balance", () => {
  const ledger = addCredit(emptyLedger(), { requestId: "r1", customer: "ann", pence: 500 });
  assert.equal(balance(ledger, "ann"), 500);
  assert.equal(balance(ledger, "ben"), 0);
});

test("two different requests both count", () => {
  let ledger = addCredit(emptyLedger(), { requestId: "r1", customer: "ann", pence: 500 });
  ledger = addCredit(ledger, { requestId: "r2", customer: "ann", pence: 300 });
  assert.equal(balance(ledger, "ann"), 800);
});

test("credit of nothing, or less, is refused", () => {
  assert.throws(() => addCredit(emptyLedger(), { requestId: "r1", customer: "ann", pence: 0 }));
  assert.throws(() => addCredit(emptyLedger(), { requestId: "r2", customer: "ann", pence: -50 }));
});
