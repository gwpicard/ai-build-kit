#!/usr/bin/env sh
# replay-case-states.sh: prove each new case has a sensitive disk assertion.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
REPLAY="$ROOT/.agents/tests/replay"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
for number in 60 61 62 63; do
  project="$WORK/s$number"
  mkdir -p "$project"
  cp -R "$REPLAY/fixture/app" "$project/app"
  cp "$REPLAY/fixture/AGENTS-additions.md" "$project/AGENTS.md"
  cp "$REPLAY/fixture/masterplan.md" "$project/masterplan.md"
  cp "$REPLAY/fixture/CHANGELOG.md" "$project/CHANGELOG.md"
  cp "$REPLAY/fixture/issues.json" "$project/.gh-fixture.json"
  prepare=$(awk -F': *' '/^# prepare:/ { print $2; exit }' "$REPLAY/cases/$number.txt")
  sh "$REPLAY/prepare/$prepare.sh" "$project"
  if [ "$number" = 61 ]; then
    git -C "$project" init -q -b main
    git -C "$project" config user.email rehearsal@example.invalid
    git -C "$project" config user.name 'Replay rehearsal'
    git -C "$project" add -A
    git -C "$project" commit -q -m 'Starting project'
    git init -q --bare -b main "$project.git"
    git -C "$project" remote add origin "$project.git"
    git -C "$project" push -q origin main
    git -C "$project" checkout -q -b auto-merge-exceeds
    git -C "$project" commit -q --allow-empty -m 'Unmerged pull request'
    git -C "$project" push -q origin auto-merge-exceeds
    git -C "$project" checkout -q main
    cp "$project/.gh-fixture.json" "$project.gh.json"
  fi
  "$REPLAY/scenario-state-check.sh" "$number" "$project" | grep -q '^hit|' || {
    echo "FAIL: case $number state check rejected its prepared state" >&2; exit 1;
  }
  case "$number" in
    60) printf '%s\n' 'print("fixed")' > "$project/app/test_replay_failure.py" ;;
    61) sed -i.bak 's/passing project check/any change/' "$project/.auto-merge-approval.json"; rm -f "$project/.auto-merge-approval.json.bak" ;;
    62) rm "$project/operations/manual-loan-log.csv" ;;
    63) printf '\n# changed\n' >> "$project/app/payroll_export.py" ;;
  esac
  if "$REPLAY/scenario-state-check.sh" "$number" "$project" | grep -q '^hit|'; then
    echo "FAIL: case $number state check missed a deliberate state break" >&2; exit 1
  fi
  echo "ok: case $number state check detects a broken starting condition"
done
