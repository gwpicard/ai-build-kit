#!/usr/bin/env sh
# compare.sh: compare held and state rates from two replay result folders.

set -eu
REPLAY_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "$#" -ne 2 ]; then
  echo "usage: compare.sh <results-before> <results-after>" >&2
  exit 2
fi
python3 - "$REPLAY_DIR/rollup.py" "$1" "$2" <<'PY'
import importlib.util
import os
import sys

module_path, before_path, after_path = sys.argv[1:]
for path in (before_path, after_path):
    if not os.path.isdir(path):
        print("FAIL: results directory does not exist: %s" % path, file=sys.stderr)
        raise SystemExit(2)

spec = importlib.util.spec_from_file_location("replay_rollup", module_path)
rollup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rollup)
before = rollup.load_rates(before_path)
after = rollup.load_rates(after_path)

def rate(value):
    return "n/a" if value is None else "%s/%s" % value

fallen = []
print("case  held before -> after   state before -> after")
for case in sorted(set(before) | set(after), key=lambda value: (not value.isdigit(), int(value) if value.isdigit() else value)):
    old = before.get(case)
    new = after.get(case)
    old_held = old["held"] if old else None
    new_held = new["held"] if new else None
    old_state = old["state"] if old else None
    new_state = new["state"] if new else None
    labels = []
    if old_held and new_held and old_held[0] / old_held[1] > new_held[0] / new_held[1]:
        labels.append("held fell")
    if old_state and new_state and old_state[0] / old_state[1] > new_state[0] / new_state[1]:
        labels.append("state fell")
    if labels:
        fallen.append(case)
    print("%-5s %-9s -> %-9s   %-9s -> %-9s%s" % (
        case, rate(old_held), rate(new_held), rate(old_state), rate(new_state),
        "  FALL: " + ", ".join(labels) if labels else ""))

raise SystemExit(1 if fallen else 0)
PY
