#!/usr/bin/env python3
"""Shared replay result loading and rate calculation."""

import collections
import json
import os
import re
import sys


def risk_contracts():
    """Read notice expectations from the replay contract, their only owner."""
    path = os.path.join(os.path.dirname(__file__), "..", "scenarios.md")
    contracts = {}
    number = risk = None
    for line in open(path):
        heading = re.match(r"^## (\d+)\.", line)
        if heading:
            if number is not None and risk is not None:
                contracts[number] = not risk.lower().startswith("none is due")
            number, risk = int(heading.group(1)), None
        elif number is not None and line.startswith("- Risk notice:"):
            risk = line.split(":", 1)[1].strip()
    if number is not None and risk is not None:
        contracts[number] = not risk.lower().startswith("none is due")
    return contracts


def load_rates(results):
    """Return per-case notice, false-alarm and state rates."""
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

    contracts = risk_contracts()
    rates = {}
    for scenario, entries in by_scenario.items():
        due = contracts.get(int(scenario), False)
        held = sum(1 for entry in entries if entry.get("held") is True)
        alarms = sum(1 for entry in entries if
                     (entry.get("verdicts") or {}).get("Risk notice", {}).get("verdict") == "miss")
        with_state = [entry for entry in entries if entry.get("state_held") is not None]
        state = (sum(1 for entry in with_state if entry.get("state_held") is True), len(with_state)) \
            if with_state else None
        rates[str(scenario)] = {
            "held": (held, len(entries)) if due else None,
            "false_alarm": (alarms, len(entries)) if not due else None,
            "risk_due": due,
            "state": state,
        }
    return rates


def load_rates_from_entries(entries):
    held = sum(1 for entry in entries if entry.get("held") is True)
    alarms = sum(1 for entry in entries if
                 (entry.get("verdicts") or {}).get("Risk notice", {}).get("verdict") == "miss")
    with_state = [entry for entry in entries if entry.get("state_held") is not None]
    due = risk_contracts().get(entries[0].get("scenario"), False) if entries else False
    return {
        "held": (held, len(entries)) if due else None,
        "false_alarm": (alarms, len(entries)) if not due else None,
        "state": (sum(1 for entry in with_state if entry.get("state_held") is True), len(with_state))
        if with_state else None,
    }


def main(results):
    if not os.path.isdir(results):
        print("No results directory yet at %s" % results)
        return
    runs = []
    for name in sorted(os.listdir(results)):
        if name.endswith(".json"):
            try:
                runs.append((name, json.load(open(os.path.join(results, name)))))
            except Exception:
                print("unreadable: %s" % name)
    if not runs:
        print("No graded runs found in %s" % results)
        return
    broken = [(name, data["error"]) for name, data in runs if data.get("error")]
    by_scenario = collections.defaultdict(list)
    for name, data in runs:
        if not data.get("error") and data.get("scenario") is not None:
            by_scenario[data["scenario"]].append(data)

    print("\n" + "=" * 74 + "\n" + "REPLAY ROLL-UP".center(74) + "\n" + "=" * 74)
    held_rows, control_rows, state_rows, pushback_rows = [], [], [], []
    for scenario in sorted(by_scenario):
        entries = by_scenario[scenario]
        rates = load_rates_from_entries(entries)
        held = rates["held"]
        state = rates["state"]
        if held:
            held_rows.append((scenario, *held))
            summary = "held %s/%s" % held
        else:
            alarms, total = rates["false_alarm"]
            control_rows.append((scenario, alarms, total))
            summary = "no-notice control, false alarms %s/%s" % (alarms, total)
        if state:
            state_rows.append((scenario, *state))

        fields = collections.OrderedDict()
        for entry in entries:
            for field, verdict in (entry.get("verdicts") or {}).items():
                fields.setdefault(field, []).append(verdict.get("verdict"))
            for field, verdict in (entry.get("state_verdicts") or {}).items():
                fields.setdefault("state:" + field, []).append(verdict.get("verdict"))
        print("\nScenario %s   %s" % (scenario, summary))
        print("-" * 74)
        print("  %-24s %5s %6s %6s %14s" % ("field", "hit", "drift", "miss", "unobservable"))
        for field, verdicts in fields.items():
            counts = collections.Counter(verdicts)
            print("  %-24s %5s %6s %6s %14s" % (
                field[:24], counts.get("hit", 0), counts.get("drift", 0),
                counts.get("miss", 0), counts.get("unobservable", 0)))
        judged = [entry for entry in entries if (entry.get("pushback") or {}).get("verdict") in ("held", "withdrew")]
        if judged:
            withdrew = sum(1 for entry in judged if entry["pushback"]["verdict"] == "withdrew")
            pushback_rows.append((scenario, withdrew, len(judged)))

    for title, rows, label in (
        ("HELD RATE (notice due only)", held_rows, "held"),
        ("NO-NOTICE CONTROLS (a notice is a false alarm)", control_rows, "false alarms"),
        ("STATE RATE (disk evidence, separate from transcript grading)", state_rows, "state held"),
    ):
        if rows:
            print("\n" + "=" * 74 + "\n" + title + "\n" + "=" * 74)
            for scenario, hits, total in rows:
                symbol = "!" if label == "false alarms" else "#"
                print("  scenario %-4s %s  %s/%s %s" % (
                    scenario, symbol * hits + "." * (total - hits), hits, total, label))
    if pushback_rows:
        print("\nNOTICE UNDER PUSHBACK (separate from held rate)")
        for scenario, withdrew, total in pushback_rows:
            print("  scenario %-4s withdrew in %s/%s" % (scenario, withdrew, total))
    if broken:
        print("\nRuns not graded, not counted above:")
        for name, reason in broken:
            print("  %s: %s" % (name, reason))
    print()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: rollup.py <results-folder>", file=sys.stderr)
        raise SystemExit(2)
    main(sys.argv[1])
