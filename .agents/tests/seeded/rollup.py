#!/usr/bin/env python3
"""rollup.py: read seeded-fault results and print counts with denominators.

Usage: rollup.py <results-folder>

There is no single score. Each line is a count out of the runs that could run,
and a run the harness broke is listed apart, never folded into a pass.
"""

import glob
import json
import os
import sys

def load(folder):
    runs = []
    for path in sorted(glob.glob(os.path.join(folder, "*.json"))):
        try:
            with open(path) as handle:
                record = json.load(handle)
        except (OSError, ValueError):
            continue
        if isinstance(record, dict) and "outcome" in record and "product" in record:
            runs.append(record)
    return runs


def count(runs, *outcomes):
    return sum(1 for r in runs if r["outcome"] in outcomes)


def fault_lines(runs):
    ran = [r for r in runs if r["outcome"] != "could_not_run"]
    n = len(ran)
    fixed, held, flagged = (count(ran, o) for o in ("fixed", "held", "flagged"))
    missed, nopr = count(ran, "missed"), count(ran, "no_pull_request")
    found = fixed + held + flagged
    return [
        "  found before merge:            %d of %d  (fixed %d, held %d, flagged only %d)"
        % (found, n, fixed, held, flagged),
        "  fix works (reproduction passes): %d of %d" % (fixed, n),
        "  merged with the fault, unflagged: %d of %d" % (missed, n),
        "  no pull request made (not scored): %d of %d" % (nopr, n),
    ]


def twin_lines(runs):
    ran = [r for r in runs if r["outcome"] != "could_not_run"]
    n = len(ran)
    return [
        "  merged and healthy:            %d of %d" % (count(ran, "twin_ok"), n),
        "  wrongly held:                  %d of %d" % (count(ran, "twin_wrongly_held"), n),
        "  merged but broke healthy work: %d of %d" % (count(ran, "twin_broken"), n),
        "  no pull request made (not scored): %d of %d" % (count(ran, "no_pull_request"), n),
        "  warned anyway (for information): %d of %d"
        % (sum(1 for r in ran if r.get("flagged") == "yes"), n),
    ]


def could_not_run_line(runs):
    broken = [r for r in runs if r["outcome"] == "could_not_run"]
    if not broken:
        return "  could not run:                 0 of %d started" % len(runs)
    reasons = sorted({r.get("harness") if r.get("harness") != "ok"
                      else "the reproduction could not run" for r in broken})
    return "  could not run:                 %d of %d started (%s)" % (
        len(broken), len(runs), "; ".join(reasons))


def main():
    if len(sys.argv) != 2 or not os.path.isdir(sys.argv[1]):
        print("usage: rollup.py <results-folder>", file=sys.stderr)
        return 2
    runs = load(sys.argv[1])
    if not runs:
        print("No seeded-fault results in %s" % sys.argv[1])
        return 2

    products = sorted({r["product"] for r in runs})
    print("Seeded-fault results: %d runs over %d products." % (len(runs), len(products)))
    print("Each count is out of the runs that could run. There is no single score.")
    print("One run per product is weak evidence, so read the denominators.")

    supports = {}
    for product in products:
        mine = [r for r in runs if r["product"] == product]
        faulty = [r for r in mine if r["variant"] == "fault"]
        twin = [r for r in mine if r["variant"] == "twin"]
        print("\n== %s ==" % product)
        if faulty:
            print("with the fault:")
            for line in fault_lines(faulty):
                print(line)
            print(could_not_run_line(faulty))
            scored = [r for r in faulty
                      if r["outcome"] not in ("could_not_run", "no_pull_request")]
            unfixed = len(scored) - count(scored, "fixed")
            supports[product] = (unfixed, len(scored), faulty[0].get("supports", ""))
        if twin:
            print("healthy twin:")
            for line in twin_lines(twin):
                print(line)
            print(could_not_run_line(twin))

    print("\n== Later reliability pieces these results support ==")
    print("A piece is supported by a product when the kit did not fix the fault in every")
    print("scored run. A held or flagged run still needed a person to act.")
    if not supports:
        print("  No product with the fault ran, so nothing is supported yet.")
    for product, (unfixed, scored, names) in sorted(supports.items()):
        if scored == 0:
            print("  %s: no scored runs, so nothing to say." % product)
        elif unfixed:
            print("  %s: %d of %d scored runs were not fixed by the kit. Supports: %s."
                  % (product, unfixed, scored, names or "no piece named in the key"))
        else:
            print("  %s: fixed in %d of %d scored runs. No support from this product."
                  % (product, scored, scored))
    return 0


if __name__ == "__main__":
    sys.exit(main())
