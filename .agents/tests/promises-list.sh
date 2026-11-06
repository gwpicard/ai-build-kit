#!/usr/bin/env sh
# promises-list.sh: named checks and scenario evidence in the promise list still exist.

set -eu
ROOT=${PROMISES_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}
LIST="$ROOT/docs/PROMISES.md"
SCENARIOS="$ROOT/.agents/tests/scenarios.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$LIST" ] || fail "docs/PROMISES.md is missing"
[ -f "$SCENARIOS" ] || fail ".agents/tests/scenarios.md is missing"

while IFS= read -r path; do
  [ -n "$path" ] || continue
  [ -f "$ROOT/$path" ] || fail "named checker is missing: $path"
done <<EOF
$(awk -F'`' '/^\|/ { for (i = 2; i <= NF; i += 2) if ($i ~ /^\.agents\/.*\.(sh|py)$/) print $i }' "$LIST")
EOF

python3 - "$ROOT" "$LIST" "$SCENARIOS" <<'PYTHON'
import pathlib
import re
import sys

root, list_path, scenarios_path = map(pathlib.Path, sys.argv[1:])
scenario_text = scenarios_path.read_text(encoding="utf-8")
markdown = list_path.read_text(encoding="utf-8")
manual_pattern = re.compile(r"manual scenarios?, not yet replayed:\s*(?:scenarios?\s+)?(\d+(?:\s*(?:,|and)\s*\d+)*)")
reference_pattern = re.compile(r"\bscenarios?\s+(\d+(?:\s*(?:(?:,|and|to)\s*)\d+)*)")
reported = set()
for line in markdown.splitlines():
    if not line.startswith("|") or line.startswith("|---"):
        continue
    cells = [cell.strip() for cell in line.strip("|").split("|")]
    if len(cells) != 2:
        continue
    evidence = cells[1]
    manual = {int(number) for found in manual_pattern.findall(evidence) for number in re.findall(r"\d+", found)}
    for match in reference_pattern.finditer(evidence):
        sequence = match.group(1)
        numbers = [int(number) for number in re.findall(r"\d+", sequence)]
        expanded = []
        if "to" in sequence and len(numbers) == 2:
            expanded = list(range(numbers[0], numbers[1] + 1))
        else:
            expanded = numbers
        for number in expanded:
            if not re.search(rf"(?m)^## {number}\. ", scenario_text):
                print(f"FAIL: named scenario contract is missing: {number}", file=sys.stderr)
                raise SystemExit(1)
            case = root / ".agents/tests/replay/cases" / f"{number:02}.txt"
            if number in manual and case.is_file():
                print(f"FAIL: scenario {number} is labelled manual but has a runnable replay case", file=sys.stderr)
                raise SystemExit(1)
            if number not in manual and not case.is_file():
                print(f"FAIL: scenario {number} is cited as replayed but has no runnable replay case; label it 'manual scenario, not yet replayed'", file=sys.stderr)
                raise SystemExit(1)
            if number not in reported:
                kind = "runnable replay case" if case.is_file() else "written scenario contract"
                print(f"promises-list.sh: scenario {number}: {kind}")
                reported.add(number)
print("promises-list.sh: named checkers and scenario contracts exist")
PYTHON
