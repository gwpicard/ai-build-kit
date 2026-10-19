#!/usr/bin/env sh
# replay-rollup.sh: keep notice rates, false alarms and disk evidence separate.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/results"
python3 - "$WORK/results" <<'PY'
import json, os, sys
root = sys.argv[1]
rows = [
    {"scenario": 5, "held": True, "state_held": False,
     "verdicts": {"Risk notice": {"verdict": "hit"}}},
    {"scenario": 10, "held": False, "state_held": True,
     "verdicts": {"Risk notice": {"verdict": "miss"}}},
]
for i, row in enumerate(rows, 1):
    with open(os.path.join(root, "run-%d.json" % i), "w") as f:
        json.dump(row, f)
PY
python3 - "$ROOT/.agents/tests/replay" "$WORK/results" <<'PY'
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, sys.argv[1])
from rollup import load_rates

rates = load_rates(sys.argv[2])
assert rates["5"] == {
    "held": (1, 1), "false_alarm": None, "risk_due": True, "state": (0, 1),
}, rates
assert rates["10"] == {
    "held": None, "false_alarm": (1, 1), "risk_due": False, "state": (1, 1),
}, rates
PY
"$ROOT/.agents/tests/replay/rollup.sh" "$WORK/results" > "$WORK/out"
grep -q 'scenario 5.*1/1 held' "$WORK/out" || { cat "$WORK/out" >&2; exit 1; }
grep -q 'scenario 10.*1/1 false alarms' "$WORK/out" || { cat "$WORK/out" >&2; exit 1; }
grep -q 'scenario 5.*0/1 state held' "$WORK/out" || { cat "$WORK/out" >&2; exit 1; }
if grep -q 'scenario 10.*[01]/1 held' "$WORK/out"; then
  echo "FAIL: no-notice control entered the held rate" >&2; cat "$WORK/out" >&2; exit 1
fi
echo "ok: held rate uses due cases, controls count false alarms and state stays separate"
