import { test } from "node:test";
import assert from "node:assert/strict";
import { formatPence } from "./format.ts";

test("pence are shown as pounds", () => {
  assert.equal(formatPence(250), "£2.50");
  assert.equal(formatPence(5), "£0.05");
});
