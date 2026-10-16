#!/usr/bin/env sh
# replay-compare.sh: prove comparison reports rates and catches falls.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
COMPARE="$ROOT/.agents/tests/replay/compare.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

mkdir -p "$WORK/fall-before" "$WORK/fall-after" "$WORK/steady-before" "$WORK/steady-after"
python3 - "$WORK" <<'PY'
import json
import os
import sys

root = sys.argv[1]
data = {
    "fall-before": [
        {"scenario": 1, "held": True, "state_held": True},
        {"scenario": 1, "held": True, "state_held": False},
    ],
    "fall-after": [
        {"scenario": 1, "held": True, "state_held": False},
        {"scenario": 1, "held": False, "state_held": False},
    ],
    "steady-before": [{"scenario": 7, "held": False, "state_held": False}],
    "steady-after": [{"scenario": 7, "held": True, "state_held": True}],
}
for folder, rows in data.items():
    for index, row in enumerate(rows, 1):
        with open(os.path.join(root, folder, "run-%s.json" % index), "w") as handle:
            json.dump(row, handle)
PY

if "$COMPARE" "$WORK/fall-before" "$WORK/fall-after" > "$WORK/fall.out"; then
  echo "FAIL: falling rates returned success" >&2
  exit 1
fi
grep -q '1 .*FALL: held fell, state fell' "$WORK/fall.out" || {
  echo "FAIL: held and state falls were not reported" >&2
  cat "$WORK/fall.out" >&2
  exit 1
}
grep -q '2/2 .*-> 1/2' "$WORK/fall.out" || {
  echo "FAIL: held rates were not printed side by side" >&2
  cat "$WORK/fall.out" >&2
  exit 1
}
echo "ok: falling held and state rates are printed and fail the comparison"

"$COMPARE" "$WORK/steady-before" "$WORK/steady-after" > "$WORK/steady.out"
grep -q '7 .*0/1.* -> 1/1' "$WORK/steady.out" || {
  echo "FAIL: a non-falling case was not printed" >&2
  cat "$WORK/steady.out" >&2
  exit 1
}
if grep -q 'FALL:' "$WORK/steady.out"; then
  echo "FAIL: a non-falling comparison was flagged" >&2
  cat "$WORK/steady.out" >&2
  exit 1
fi
echo "ok: a non-falling comparison returns success"

mkdir -p "$WORK/missing-after"
if "$COMPARE" "$WORK/steady-before" "$WORK/missing-after" > "$WORK/missing.out"; then
  echo "FAIL: a missing after scenario returned success" >&2
  exit 1
fi
grep -q '7 .*FALL: held missing, state missing' "$WORK/missing.out" || {
  echo "FAIL: a missing after scenario was not reported" >&2
  cat "$WORK/missing.out" >&2
  exit 1
}
echo "ok: a missing after scenario fails the comparison"
