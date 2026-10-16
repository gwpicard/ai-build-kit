#!/usr/bin/env python3
"""Shared replay result loading and rate calculation."""

import collections
import json
import os
import sys


def load_rates(results):
    """Return scenario rates: held and optional state, as (hits, total)."""
    if not os.path.isdir(results):
        return {}

    by_scenario = collections.defaultdict(list)
    for name in sorted(os.listdir(results)):
        if not name.endswith(".json"):
            continue
        try:
            data = json.load(open(os.path.join(results, name)))
        except Exception:
            continue
        if data.get("error") or data.get("scenario") is None:
            continue
        by_scenario[data["scenario"]].append(data)

    rates = {}
    for scenario, entries in by_scenario.items():
        held = sum(1 for entry in entries if entry.get("held") is True)
        with_state = [entry for entry in entries
                      if entry.get("state_held") is not None]
        state = (sum(1 for entry in with_state
                     if entry.get("state_held") is True), len(with_state)) \
            if with_state else None
        rates[str(scenario)] = {"held": (held, len(entries)), "state": state}
    return rates


def main(results):
    if not os.path.isdir(results):
        print("No results directory yet at %s" % results)
        return

    runs = []
    for name in sorted(os.listdir(results)):
        if not name.endswith(".json"):
            continue
        try:
            runs.append((name, json.load(open(os.path.join(results, name)))))
        except Exception:
            print("unreadable: %s" % name)

    if not runs:
        print("No graded runs found in %s" % results)
        return

    broken = [(n, d["error"]) for n, d in runs if d.get("error")]
    runs = [(n, d) for n, d in runs if not d.get("error")]
    by_scenario = collections.defaultdict(list)
    for name, data in runs:
        by_scenario[data.get("scenario")].append(data)

    print()
    print("=" * 74)
    print("REPLAY ROLL-UP".center(74))
    print("=" * 74)

    held_rows = []
    state_rows = []
    pushback_rows = []
    for scenario in sorted(k for k in by_scenario if k is not None):
        entries = by_scenario[scenario]
        rates = load_rates_from_entries(entries)
        held, total = rates["held"]
        held_rows.append((scenario, held, total))
        state = rates["state"]
        if state:
            state_rows.append((scenario, state[0], state[1]))

        judged = [e for e in entries
                  if ((e.get("pushback") or {}).get("verdict")) in ("held", "withdrew")]
        if judged:
            withdrew = sum(1 for e in judged
                           if e["pushback"]["verdict"] == "withdrew")
            pushback_rows.append((scenario, withdrew, len(judged)))

        fields = collections.OrderedDict()
        for entry in entries:
            for field, verdict in (entry.get("verdicts") or {}).items():
                fields.setdefault(field, []).append(verdict.get("verdict"))
            for field, verdict in (entry.get("state_verdicts") or {}).items():
                fields.setdefault("state:" + field, []).append(verdict.get("verdict"))

        print()
        print("Scenario %s   held %s/%s" % (scenario, held, total))
        print("-" * 74)
        print("  %-24s %5s %6s %6s %14s" % ("field", "hit", "drift", "miss", "unobservable"))
        for field, verdicts in fields.items():
            counts = collections.Counter(verdicts)
            print("  %-24s %5s %6s %6s %14s" % (
                field[:24], counts.get("hit", 0), counts.get("drift", 0),
                counts.get("miss", 0), counts.get("unobservable", 0)))

    print()
    print("=" * 74)
    print("HELD RATE: did the kit give the notice when due and record the acceptance before the work")
    print("=" * 74)
    for scenario, held, total in held_rows:
        print("  scenario %-4s %s  %s/%s" % (
            scenario, "#" * held + "." * (total - held), held, total))

    if state_rows:
        print()
        print("=" * 74)
        print("STATE HELD: did the run leave the right result on disk")
        print("=" * 74)
        for scenario, held, total in state_rows:
            print("  scenario %-4s %s  %s/%s" % (
                scenario, "#" * held + "." * (total - held), held, total))

    if pushback_rows:
        print()
        print("=" * 74)
        print("NOTICE UNDER PUSHBACK: reported, and not counted in the rate above")
        print("=" * 74)
        for scenario, withdrew, judged in pushback_rows:
            print("  scenario %-4s %s  withdrew in %s of %s" % (
                scenario, "." * (judged - withdrew) + "!" * withdrew,
                withdrew, judged))

    if broken:
        print()
        print("Runs not graded, not counted above:")
        for name, reason in broken:
            print("  %s: %s" % (name, reason))
    print()


def load_rates_from_entries(entries):
    held = sum(1 for entry in entries if entry.get("held") is True)
    state = [entry for entry in entries if entry.get("state_held") is not None]
    return {"held": (held, len(entries)),
            "state": (sum(1 for entry in state if entry.get("state_held") is True),
                      len(state)) if state else None}


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: rollup.py <results-folder>", file=sys.stderr)
        raise SystemExit(2)
    main(sys.argv[1])
