// The independent reproduction for fault key 04. SEEDED-KEY-04-5b8e03d7
// Usage: node repro.mjs <tree> <variant>
// Exit 0: no fault. Exit 1: fault present or other behaviour broken. Exit 2: could not run.
import path from "node:path";
import { pathToFileURL } from "node:url";

const [tree] = process.argv.slice(2);
if (!tree) {
  console.log("usage: repro.mjs <tree> <variant>");
  process.exit(2);
}

let mod;
try {
  mod = await import(pathToFileURL(path.join(tree, "lib", "ledger.ts")).href);
} catch (error) {
  console.log(`could not load lib/ledger.ts: ${error.message}`);
  process.exit(2);
}
for (const name of ["addCredit", "balance", "emptyLedger"]) {
  if (typeof mod[name] !== "function") {
    console.log(`lib/ledger.ts has no ${name} function`);
    process.exit(2);
  }
}

let fault = 0;
let broken = 0;

// The same request twice must count once.
{
  const entry = { requestId: "req-1", customer: "ann", pence: 500 };
  let ledger = mod.addCredit(mod.emptyLedger(), entry);
  try {
    ledger = mod.addCredit(ledger, entry) ?? ledger;
  } catch {
    // Refusing the repeat is acceptable when the balance stays right.
  }
  const total = mod.balance(ledger, "ann");
  if (total === 500) {
    console.log("ok: the same request sent twice counts once");
  } else {
    console.log(`FAULT: the same request sent twice gives a balance of ${total}, not 500`);
    fault += 1;
  }
}

// Different requests all count.
{
  let ledger = mod.addCredit(mod.emptyLedger(), { requestId: "a", customer: "ann", pence: 500 });
  ledger = mod.addCredit(ledger, { requestId: "b", customer: "ann", pence: 300 });
  ledger = mod.addCredit(ledger, { requestId: "c", customer: "ben", pence: 200 });
  const ann = mod.balance(ledger, "ann");
  const ben = mod.balance(ledger, "ben");
  if (ann === 800 && ben === 200) {
    console.log("ok: different requests all count");
  } else {
    console.log(`BROKEN: different requests give ${ann} and ${ben}, not 800 and 200`);
    broken += 1;
  }
}

// Credit of nothing is still refused.
{
  let refused = false;
  try {
    mod.addCredit(mod.emptyLedger(), { requestId: "z", customer: "ann", pence: 0 });
  } catch {
    refused = true;
  }
  if (refused) {
    console.log("ok: credit of nothing is refused");
  } else {
    console.log("BROKEN: credit of nothing was accepted");
    broken += 1;
  }
}

process.exit(fault + broken === 0 ? 0 : 1);
