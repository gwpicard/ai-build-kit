// The independent reproduction for fault key 08. SEEDED-KEY-08-c41a96e2
// Usage: node repro.mjs <tree> <variant>   (variant: fault or twin)
// Exit 0: no fault. Exit 1: fault present or never built. Exit 2: could not run.
import path from "node:path";
import { pathToFileURL } from "node:url";

const [tree, variant = "fault"] = process.argv.slice(2);
if (!tree || !["fault", "twin"].includes(variant)) {
  console.log("usage: repro.mjs <tree> <fault|twin>");
  process.exit(2);
}

let mod;
try {
  mod = await import(pathToFileURL(path.join(tree, "lib", "split.ts")).href);
} catch (error) {
  console.log(`could not load lib/split.ts: ${error.message}`);
  process.exit(2);
}
if (typeof mod.splitBill !== "function") {
  console.log("lib/split.ts has no splitBill function");
  process.exit(2);
}

let bad = 0;

for (const total of [1000, 100, 1, 999, 1001, 5, 4200]) {
  for (const people of [2, 3, 4, 7]) {
    let shares;
    try {
      shares = mod.splitBill(total, people);
    } catch (error) {
      console.log(`FAULT: splitBill(${total}, ${people}) threw: ${error.message}`);
      bad += 1;
      continue;
    }
    const whole =
      Array.isArray(shares) &&
      shares.length === people &&
      shares.every((share) => Number.isInteger(share) && share >= 0);
    if (!whole) {
      console.log(`FAULT: splitBill(${total}, ${people}) gave ${JSON.stringify(shares)}`);
      bad += 1;
      continue;
    }
    if (variant === "fault") {
      const sum = shares.reduce((a, b) => a + b, 0);
      const spread = Math.max(...shares) - Math.min(...shares);
      if (sum !== total || spread > 1) {
        console.log(
          `FAULT: splitBill(${total}, ${people}) gave ${JSON.stringify(shares)}, total ${sum}`,
        );
        bad += 1;
      }
    } else {
      const exact = total / people;
      if (!shares.every((share) => Math.abs(share - exact) <= 1)) {
        console.log(`BROKEN: splitBill(${total}, ${people}) gave ${JSON.stringify(shares)}`);
        bad += 1;
      }
    }
  }
}

if (bad === 0) {
  console.log("ok: every split passed");
}
process.exit(bad === 0 ? 0 : 1);
