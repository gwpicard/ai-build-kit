import { test } from "node:test";
import assert from "node:assert/strict";
import { lookupUnits, type FetchLike } from "./supplier.ts";

const answer = (status: number, body: unknown): FetchLike => async () => ({
  ok: status < 400,
  status,
  json: async () => body,
});

test("reports the units the supplier holds", async () => {
  assert.deepEqual(await lookupUnits("BRK-100", answer(200, { units: 7 })), {
    ok: true,
    units: 7,
  });
});

test("a part the supplier does not list has none", async () => {
  assert.deepEqual(await lookupUnits("ZZZ-000", answer(404, {})), {
    ok: true,
    units: 0,
  });
});

test("says so when the supplier cannot be reached", async () => {
  const down: FetchLike = async () => {
    throw new Error("offline");
  };
  assert.equal((await lookupUnits("BRK-100", down)).ok, false);
});
