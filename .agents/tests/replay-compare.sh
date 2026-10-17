#!/usr/bin/env sh
# replay-compare.sh: rehearse noise, a real fall and run counts.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
COMPARE="$ROOT/.agents/tests/replay/compare.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/noise-before" "$WORK/noise-after" "$WORK/fall-before" "$WORK/fall-after"
python3 - "$WORK" <<'PY'
import json, os, sys
root = sys.argv[1]
sets = {
    "noise-before": [True, True, True],
    "noise-after": [True, True, False],
    "fall-before": [True, True, True],
    "fall-after": [False, False, False],
}
for folder, values in sets.items():
    for i, held in enumerate(values, 1):
        row = {"scenario": 5, "held": held, "state_held": held}
        with open(os.path.join(root, folder, "run-%d.json" % i), "w") as f:
            json.dump(row, f)
PY

"$COMPARE" "$WORK/noise-before" "$WORK/noise-after" > "$WORK/noise.out"
grep -q '3/3 (n=3).*2/3 (n=3)' "$WORK/noise.out" || {
  echo "FAIL: run counts or 3-to-2 rates were not shown" >&2; cat "$WORK/noise.out" >&2; exit 1;
}
if grep -q 'FALL:' "$WORK/noise.out"; then
  echo "FAIL: chance noise was called a fall" >&2; cat "$WORK/noise.out" >&2; exit 1
fi
echo "ok: a 3-to-2 move is reported as noise with its run counts"

if "$COMPARE" "$WORK/fall-before" "$WORK/fall-after" > "$WORK/fall.out"; then
  echo "FAIL: a 3-to-0 move returned success" >&2; exit 1
fi
grep -q 'FALL: p=0.050' "$WORK/fall.out" || {
  echo "FAIL: a chance-exceeding fall was not flagged" >&2; cat "$WORK/fall.out" >&2; exit 1;
}
echo "ok: a 3-to-0 move is flagged as a real fall"

mkdir -p "$WORK/missing-after"
set +e
"$COMPARE" "$WORK/noise-before" "$WORK/missing-after" > "$WORK/missing.out"
status=$?
set -e
[ "$status" -eq 2 ] || { echo "FAIL: missing evidence returned $status, not 2" >&2; exit 1; }
grep -q '5 .*INCOMPLETE: case missing' "$WORK/missing.out" || {
  echo "FAIL: a missing case was not reported as incomplete" >&2; cat "$WORK/missing.out" >&2; exit 1;
}
echo "ok: missing evidence is unable to compare, not a regression"
