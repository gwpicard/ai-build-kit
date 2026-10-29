#!/usr/bin/env sh
# compatibility-grades.sh: hold each agent's grade in docs/COMPATIBILITY.md to
# the replay record.
#
# If this breaks, an agent could be graded Tested by editing the page rather
# than by a recorded run, or sit in the coding agent map with no grade at all.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
pass=0
ok() { echo "  ok: $1"; pass=$((pass + 1)); }
fail() { echo "FAIL: $1" >&2; exit 1; }

COMPAT="$ROOT/docs/COMPATIBILITY.md"
PROVIDER="$ROOT/.agents/tests/replay/provider.sh"
RUNNER="$ROOT/.agents/tests/replay/run.sh"
BASELINE="$ROOT/.agents/tests/replay/baseline.md"

for f in "$COMPAT" "$PROVIDER" "$RUNNER" "$BASELINE"; do
  [ -f "$f" ] || fail "missing file $f"
done

# The providers the harness accepts, read from its own case statement, and the
# one it uses when none is named.
providers=$(sed -n '/^provider_check()/,/^}/p' "$PROVIDER" \
  | grep -oE '^    [a-z]+\)' | tr -d ' )')
default_provider=$(grep -oE 'REPLAY_PROVIDER=\$\{REPLAY_PROVIDER:-[a-z]+\}' "$RUNNER" \
  | head -1 | sed -E 's/.*:-([a-z]+)\}/\1/')
[ -n "$providers" ] || fail "could not read the replay providers from provider.sh"
[ -n "$default_provider" ] || fail "could not read the default replay provider from run.sh"

provider_for() {
  case "$1" in
    "Claude Code") echo claude ;;
    "Codex") echo codex ;;
    *) echo "" ;;
  esac
}

# recorded_run <provider> <baseline-file>: succeeds when the baseline carries a
# run header whose provider field names this provider.
recorded_run() {
  grep -qiE "^- \*\*provider:\*\* \`$1\`" "$2"
}

# grade_problems <compatibility-file> [<baseline-file>]: prints one line per
# problem, nothing when the grades hold.
grade_problems() {
  record=${2:-$BASELINE}
  grades=$(grep -E '^\| [^|]+ \| (Tested|Expected to work|Experimental) \|$' "$1" \
    | sed -E 's/^\| ([^|]+) \| ([^|]+) \|$/\1|\2/')
  # Every agent the coding agent map names needs a grade. Read the map rather than
  # a list written out here, so an agent added to the map is held too.
  sed -n '/^## Coding agent map/,/^## /p' "$1" \
    | grep -E '^\| [A-Z]' | grep -v '^| Coding agent |' \
    | sed -E 's/^\| ([^|,]+)[,|].*/\1/' | sed -E 's/ +$//' | sort -u \
    | while IFS= read -r agent; do
        printf '%s\n' "$grades" | grep -qF "$agent|" \
          || echo "$agent is in the coding agent map with no grade"
      done
  printf '%s\n' "$grades" | while IFS='|' read -r agent grade; do
    [ "$grade" = "Tested" ] || continue
    p=$(provider_for "$agent")
    if [ -z "$p" ] || ! printf '%s\n' "$providers" | grep -qx "$p"; then
      echo "$agent is graded Tested but the replay harness cannot drive it"
      continue
    fi
    if [ "$p" != "$default_provider" ] && ! recorded_run "$p" "$record"; then
      echo "$agent is graded Tested but no recorded run names it (baseline.md needs a run header with - **Provider:** \`$p\`)"
    fi
  done
}

problems=$(grade_problems "$COMPAT")
if [ -z "$problems" ]; then
  ok "every agent in the coding agent map carries a grade, and each Tested grade has a recorded run"
else
  printf '%s\n' "$problems" | sed 's/^/  /'
  fail "the grades in COMPATIBILITY.md do not rest on the record"
fi

# Prove the mechanical half can fail. Each copy breaks one thing.
copy="$WORK/compat-copy.md"

sed -E 's/^\| Codex \| Expected to work \|$/| Codex | Tested |/' "$COMPAT" > "$copy"
if grade_problems "$copy" | grep -q 'Codex is graded Tested but no recorded run names it'; then
  ok "promoting Codex to Tested with no recorded run is caught"
else
  fail "promoting Codex to Tested with no recorded run was not caught"
fi

# A sentence that names Codex only to say it was never run is not a run.
cp "$BASELINE" "$WORK/baseline-denial.md"
printf '\nNo Codex run has been recorded. The codex provider has not been driven.\n' \
  >> "$WORK/baseline-denial.md"
if grade_problems "$copy" "$WORK/baseline-denial.md" \
  | grep -q 'Codex is graded Tested but no recorded run names it'; then
  ok "a baseline that names Codex only to deny a run does not make it Tested"
else
  fail "a baseline that names Codex only to deny a run let Codex be Tested"
fi

# And the guard is not simply refusing everything: a real run header passes.
cp "$BASELINE" "$WORK/baseline-run.md"
printf '\n## A Codex run\n\n- **Provider:** `codex`\n' >> "$WORK/baseline-run.md"
if grade_problems "$copy" "$WORK/baseline-run.md" | grep -q 'Codex is graded Tested'; then
  fail "a recorded Codex run header was not accepted"
else
  ok "a recorded Codex run header is accepted"
fi

sed -E 's/^\| Cursor \| Experimental \|$/| Cursor | Tested |/' "$COMPAT" > "$copy"
if grade_problems "$copy" | grep -q 'Cursor is graded Tested but the replay harness cannot drive it'; then
  ok "promoting an agent the harness cannot drive is caught"
else
  fail "promoting an agent the harness cannot drive was not caught"
fi

grep -vE '^\| GitHub Copilot \| Experimental \|$' "$COMPAT" > "$copy"
if grade_problems "$copy" | grep -q 'GitHub Copilot is in the coding agent map with no grade'; then
  ok "an agent in the coding agent map with no grade is caught"
else
  fail "an agent in the coding agent map with no grade was not caught"
fi

echo
echo "$(basename -- "$0"): all $pass checks passed"
