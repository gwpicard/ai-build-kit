import assert from "node:assert/strict";
import test from "node:test";

import { formatTime } from "../src/time.js";

test("formats a 12-hour analog clock time with a padded minute", () => {
  assert.equal(formatTime({ hour: 3, minute: 5 }), "3:05");
});
