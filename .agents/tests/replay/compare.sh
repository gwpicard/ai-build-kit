#!/usr/bin/env sh
# compare.sh: compare replay outcome rates with a small-sample chance rule.

set -eu
REPLAY_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "$#" -ne 2 ]; then
  echo "usage: compare.sh <results-before> <results-after>" >&2
  exit 2
fi
python3 - "$REPLAY_DIR/rollup.py" "$1" "$2" <<'PY'
import importlib.util
import math
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
before, after = rollup.load_rates(before_path), rollup.load_rates(after_path)
if not before and not after:
    print("INCOMPLETE: neither folder contains graded cases")
    raise SystemExit(2)

def rate(value):
    return "n/a" if value is None else "%s/%s" % value

def lower_tail_fisher(old, new):
    """Exact one-sided test: probability of at most this many after hits."""
    a, n_a = old
    b, n_b = new
    total_hits, total = a + b, n_a + n_b
    low = max(0, n_b - (total - total_hits))
    high = min(n_b, total_hits)
    denominator = math.comb(total, n_b)
    return sum(math.comb(total_hits, k) * math.comb(total - total_hits, n_b - k)
               for k in range(low, min(b, high) + 1)) / denominator

def fields(item):
    if item is None:
        return {}
    out = {}
    if item.get("held") is not None:
        out["held"] = item["held"]
    if item.get("false_alarm") is not None:
        hits, total = item["false_alarm"]
        out["no-notice"] = (total - hits, total)
    if item.get("state") is not None:
        out["state"] = item["state"]
    return out

print("Rule: flag a fall only when the exact one-sided Fisher test gives p <= 0.10.")
print("case  measure       before (runs) -> after (runs)                 result")
fallen = []
incomplete = False
for case in sorted(set(before) | set(after), key=lambda v: (not v.isdigit(), int(v) if v.isdigit() else v)):
    old_item, new_item = before.get(case), after.get(case)
    if old_item is None or new_item is None:
        incomplete = True
        print("%-5s %-13s %-24s -> %-24s INCOMPLETE: case missing" % (case, rate(None), rate(None), rate(None)))
        continue
    old_fields, new_fields = fields(old_item), fields(new_item)
    for name in sorted(set(old_fields) | set(new_fields)):
        old, new = old_fields.get(name), new_fields.get(name)
        label = ""
        if old is None or new is None:
            label = "INCOMPLETE: evidence missing"
            incomplete = True
        elif old[0] / old[1] > new[0] / new[1] and lower_tail_fisher(old, new) <= 0.10:
            label = "FALL: p=%.3f" % lower_tail_fisher(old, new)
        if label:
            fallen.append(case)
        print("%-5s %-13s %-24s -> %-24s %s" % (case, name,
              "%s (n=%s)" % (rate(old), old[1]) if old else "n/a",
              "%s (n=%s)" % (rate(new), new[1]) if new else "n/a", label))
if incomplete:
    raise SystemExit(2)
raise SystemExit(1 if fallen else 0)
PY
