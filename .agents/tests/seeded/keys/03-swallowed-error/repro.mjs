// The independent reproduction for fault key 03. SEEDED-KEY-03-9f2c71a4
// Usage: node repro.mjs <tree> <variant>
// Exit 0: no fault. Exit 1: fault present or healthy replies broken. Exit 2: could not run.
import path from "node:path";
import { pathToFileURL } from "node:url";

const [tree] = process.argv.slice(2);
if (!tree) {
  console.log("usage: repro.mjs <tree> <variant>");
  process.exit(2);
}

let mod;
try {
  mod = await import(pathToFileURL(path.join(tree, "lib", "supplier.ts")).href);
} catch (error) {
  console.log(`could not load lib/supplier.ts: ${error.message}`);
  process.exit(2);
}
if (typeof mod.lookupUnits !== "function") {
  console.log("lib/supplier.ts has no lookupUnits function");
  process.exit(2);
}

const reply = (status, body) => async () => ({
  ok: status < 400,
  status,
  json: async () => body,
});

const failures = [
  ["the network fails", async () => { throw new Error("offline"); }],
  ["the supplier answers 500", reply(500, {})],
  ["the answer has no unit count", reply(200, { nothing: true })],
  ["the answer is not JSON", async () => ({
    ok: true,
    status: 200,
    json: async () => { throw new SyntaxError("not json"); },
  })],
];
const healthy = [
  ["the supplier holds seven", reply(200, { units: 7 }), 7],
  ["the supplier holds none", reply(200, { units: 0 }), 0],
  ["the supplier does not list the part", reply(404, {}), 0],
];

let fault = 0;
let broken = 0;

for (const [name, fetchImpl] of failures) {
  let result;
  try {
    result = await mod.lookupUnits("BRK-100", fetchImpl);
  } catch {
    console.log(`ok: ${name}, and the call reports it by rejecting`);
    continue;
  }
  if (result && result.ok === false) {
    console.log(`ok: ${name}, and the call reports ok: false`);
  } else {
    console.log(`FAULT: ${name}, and the call returned ${JSON.stringify(result)}`);
    fault += 1;
  }
}

for (const [name, fetchImpl, units] of healthy) {
  let result;
  try {
    result = await mod.lookupUnits("BRK-100", fetchImpl);
  } catch (error) {
    console.log(`BROKEN: ${name}, and the call rejected: ${error.message}`);
    broken += 1;
    continue;
  }
  if (result && result.ok === true && result.units === units) {
    console.log(`ok: ${name}`);
  } else {
    console.log(`BROKEN: ${name}, and the call returned ${JSON.stringify(result)}`);
    broken += 1;
  }
}

process.exit(fault + broken === 0 ? 0 : 1);
