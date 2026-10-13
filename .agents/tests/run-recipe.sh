#!/usr/bin/env sh
# run-recipe.sh: drive the shipped runner over made-up recipes and read what it
# printed and what it wrote into the changelog.
#
# If this breaks, a launch check that failed or could not run could hold the
# launch, go unrecorded, or be said again in full on every run although the
# changelog already holds it. A tool with no record of its requests could go
# live with nobody told once, or be told again on every run. A run with no live
# address could be written up as a launch, and a rollback could be called
# tried when it was only seen to be possible.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
RUNNER="$ROOT/.agents/skills/setup-hosting/scripts/run-recipe.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
pass=0
ok() { echo "  ok: $1"; pass=$((pass + 1)); }
fail() { echo "FAIL: $1" >&2; exit 1; }

# --- a made-up recipe whose checks answer as told ---------------------------
# Each section's script exits with the code STUB_<SECTION> names, 0 by
# default, and says so in one line. Preview is a person looking and logs a
# companion's paste, so both carry the words the person hears.
R="$WORK/recipes/stub-on-nowhere"
mkdir -p "$R/scripts"
{
  echo "# Recipe: Stub on nowhere"
  echo
  for line in "Fits: a test" "Recommended when: never" "Build stack: none" "Deploy target: nowhere" \
    "Command-line tools: none" "Last checked: 2024-01-01"; do echo "$line"; done
  for section in Preview "Going live" Rollback Backup Restore Secrets Logs Health; do
    id=$(printf '%s' "$section" | tr 'A-Z ' 'a-z-')
    echo
    echo "## $section"
    echo
    echo "How it works: stub"
    echo "How it is checked: stub"
    echo "Script: scripts/$id.sh"
    case "$id" in
      preview) echo "Who runs it: a person looking"; echo "Ask: Open the preview and tell me." ;;
      logs) echo "Who runs it: a companion or the person, result read back"; echo "Ask: Paste the error lines." ;;
      *) echo "Who runs it: the kit" ;;
    esac
    var=$(printf '%s' "$id" | tr 'a-z-' 'A-Z_')
    cat > "$R/scripts/$id.sh" <<SH
#!/usr/bin/env sh
code=\${STUB_$var:-0}
[ "\${1:-}" != --pasted ] || code=\$(cat "\$2")
case "\$code" in
  0) echo "The $section stub passed." ;;
  1) echo "The $section stub failed." ;;
  *) echo "The $section stub could not run." ;;
esac
exit "\$code"
SH
    chmod +x "$R/scripts/$id.sh"
  done
} > "$R/recipe.md"
printf '#!/usr/bin/env sh\necho "Live copy against main: matches."\nexit "${STUB_LIVE:-0}"\n' > "$R/scripts/live-check.sh"
chmod +x "$R/scripts/live-check.sh"
printf '0\n' > "$WORK/paste-good"
printf '1\n' > "$WORK/paste-bad"

project() {
  # project <dir>: a project with a changelog holding one earlier entry.
  rm -rf "$1"
  mkdir -p "$1"
  printf '# Changelog\n\nNewest first.\n\n## 2024-01-01\n\nThe project started.\n' > "$1/CHANGELOG.md"
}

run() {
  # run <project> [option...]: the runner on the stub recipe, with a live
  # address. Its output goes to $WORK/out and its exit code to $code.
  p=$1
  shift
  code=0
  sh "$RUNNER" --project "$p" --set LIVE_ADDRESS=https://stub.example.test "$@" "$R" > "$WORK/out" 2>&1 || code=$?
}

# --- every check passes ----------------------------------------------------
P="$WORK/p1"
project "$P"
run "$P" --looked preview=yes --pasted logs="$WORK/paste-good"
[ "$code" = 0 ] || { cat "$WORK/out"; fail "a run where every check passed exited $code"; }
[ "$(grep -c ': yes\. ' "$WORK/out")" = 7 ] || fail "a passing run did not give seven sections a yes line"
grep -qx 'Rollback possible, not tried. The Rollback stub passed.' "$WORK/out" ||
  fail "a rollback seen to be possible was not reported as possible, not tried"
grep -qx 'Every check passed. The entry is in CHANGELOG.md.' "$WORK/out" || fail "a passing run did not close by saying so"
ok "a run where every check passes prints a line for each, and exits 0"

head -n 6 "$P/CHANGELOG.md" | grep -q "^## $(date +%Y-%m-%d)\$" ||
  fail "the run's entry is not the newest one, under the changelog's opening"
grep -q '^## 2024-01-01$' "$P/CHANGELOG.md" || fail "the earlier entry was lost"
grep -q '^- Preview up: yes\.' "$P/CHANGELOG.md" || fail "the entry lacks the preview line"
grep -qx 'Rollback possible, not tried. The Rollback stub passed.' "$P/CHANGELOG.md" ||
  fail "the entry lacks a rollback line of its own"
ok "the dated entry goes in newest first, with the rollback line on a line of its own"

# --- warnings never hold the launch, and are said once ------------------------
P="$WORK/p2"
project "$P"
run "$P" --request-record no --alerts none
[ "$code" = 1 ] || fail "a run with warnings exited $code, not 1"
grep -qx 'Preview up: warning, not checked. The Preview stub passed. Waiting for the person to look. Open the preview and tell me.' "$WORK/out" ||
  fail "a preview nobody has looked at is not a warning carrying the words the person hears"
grep -qx 'Logs readable: warning, not checked. Nothing was pasted back yet. Paste the error lines.' "$WORK/out" ||
  fail "a check waiting on a paste is not a warning carrying the words the person hears"
grep -qx 'Request record: warning. The tool keeps no record of what each request did, so a fault reported after launch cannot be traced. Adding the record is one piece whenever you want it.' "$WORK/out" ||
  fail "a tool with no request record was not given the warning once"
grep -q '^Monitoring caution given: ' "$WORK/out" || fail "nobody named for alerts, and no monitoring caution"
grep -qx 'Each warning is written in CHANGELOG.md, and none of them holds the launch. The entry is in CHANGELOG.md.' "$WORK/out" ||
  fail "a run with warnings did not say they hold nothing"
grep -q '^- Request record: warning\.' "$P/CHANGELOG.md" || fail "the missing request record is not in the changelog"
grep -q '^- Monitoring caution given: ' "$P/CHANGELOG.md" || fail "the monitoring caution is not recorded"
grep -iq 'sensitive area\|Accepted:' "$P/CHANGELOG.md" && fail "an operational gap was written as a sensitive area or an acceptance"
ok "a missing request record and a missing paste are warnings said once and written down, and the launch goes on"

# A second run finds them in the changelog and points to them instead.
sed -i.bak "s/^## $(date +%Y-%m-%d)\$/## 2024-02-02/" "$P/CHANGELOG.md"
run "$P" --request-record no --alerts none
grep -qx 'Request record: still a warning, as the changelog has recorded since 2024-02-02.' "$WORK/out" ||
  fail "the request record warning was said in full again although the changelog holds it"
grep -qx 'Preview up: still a warning, as the changelog has recorded since 2024-02-02.' "$WORK/out" ||
  fail "a warning the changelog holds was not a one-line pointer"
grep -q 'cannot be traced' "$WORK/out" && fail "the second run repeated the request record's reason"
grep -q '^Monitoring caution given' "$WORK/out" && fail "the monitoring caution was given again"
ok "on the next run each warning the changelog holds is a one-line pointer, and the caution is not repeated"

# A warning of another kind for the same section is new, and said in full.
run "$P" --looked preview=no --pasted logs="$WORK/paste-bad"
grep -qx 'Preview up: warning. The person looked, and it was not as expected.' "$WORK/out" ||
  fail "a preview that failed, after one that could not be checked, was not said in full"
grep -qx 'Logs readable: warning. The Logs stub failed.' "$WORK/out" ||
  fail "a pasted result that fails was not read back as a warning"
ok "a warning whose cause changed is said in full"

# --- the rollback line never claims more than was seen ----------------------
P="$WORK/p3"
project "$P"
STUB_ROLLBACK=1 run "$P" --looked preview=yes --pasted logs="$WORK/paste-good"
grep -qx 'Rollback possible: no. The Rollback stub failed.' "$WORK/out" || fail "no earlier build was not said as no"
STUB_ROLLBACK=2 run "$P" --looked preview=yes --pasted logs="$WORK/paste-good"
grep -qx 'Rollback possible: not checked. The Rollback stub could not run.' "$WORK/out" ||
  fail "a rollback list that could not be read was not said as not checked"
grep -i 'roll' "$P/CHANGELOG.md" | grep -Eiq 'tried\b' && ! grep -q 'not tried' "$P/CHANGELOG.md" &&
  fail "a rollback line claims a rollback was tried"
ok "the rollback line says no or not checked when that is all that was seen"

# --- no live address is not a launch -----------------------------------------
P="$WORK/p4"
project "$P"
code=0
sh "$RUNNER" --project "$P" --looked preview=yes --pasted logs="$WORK/paste-good" "$R" > "$WORK/out" 2>&1 || code=$?
[ "$code" = 3 ] || fail "a run with no live address exited $code, not 3"
grep -qx 'The tool is not live yet: no live address is recorded. The entry is in CHANGELOG.md.' "$WORK/out" ||
  fail "a run with no live address did not say the tool is not live"
grep -q '^Not live yet: no address is recorded\.' "$P/CHANGELOG.md" ||
  fail "a run with no live address was written up as a launch"
ok "a run with no live address says the tool is not live, and the entry says so"

# --- off a recipe: the eight names, as warnings, and nothing more -------------
P="$WORK/p5"
project "$P"
code=0
sh "$RUNNER" --project "$P" --set LIVE_ADDRESS=https://stub.example.test none > "$WORK/out" 2>&1 || code=$?
[ "$code" = 1 ] || fail "a run off a recipe exited $code, not 1"
[ "$(grep -c 'The project is on no recipe, so the kit cannot check this\.$' "$WORK/out")" = 8 ] ||
  fail "a run off a recipe did not give the eight sections one warning line each"
[ "$(wc -l < "$WORK/out" | tr -d ' ')" = 9 ] || fail "a run off a recipe said more than the eight lines and its closing"
grep -q '^/setup-hosting ran on no recipe' "$P/CHANGELOG.md" || fail "the entry off a recipe does not say so"
code=0
sh "$RUNNER" --project "$P" --set LIVE_ADDRESS=https://stub.example.test none > "$WORK/out" 2>&1 || code=$?
[ "$(grep -c 'still a warning\|still no' "$WORK/out")" = 8 ] ||
  fail "a second run off a recipe repeated the eight warnings in full"
ok "off a recipe the eight section names are one-line warnings, and pointers the next time"

# --- a later run compares first, and keeps the notes ---------------------------
P="$WORK/p6"
project "$P"
run "$P" --later --note "Applied the pinned notices migration after the person's yes." --looked preview=yes --pasted logs="$WORK/paste-good"
grep -q '^- Live copy against main: matches\.$' "$P/CHANGELOG.md" || fail "a later run's entry lacks what it compared"
grep -q '^- No gap between the live copy and main\.$' "$P/CHANGELOG.md" || fail "a later run with no gap did not say so"
grep -q "^- Applied the pinned notices migration after the person's yes\.\$" "$P/CHANGELOG.md" ||
  fail "a later run's entry lacks the repair it was given"
grep -q '^/setup-hosting compared the live copy with main' "$P/CHANGELOG.md" || fail "a later run's entry does not say it compared"
ok "a later run's entry holds what it compared, no gap when there is none, and the repairs made"

# --- reading without writing ---------------------------------------------------
P="$WORK/p7"
project "$P"
cp "$P/CHANGELOG.md" "$WORK/before"
code=0
sh "$RUNNER" --project "$P" --asks "$R" > "$WORK/out" 2>&1 || code=$?
[ "$code" = 0 ] || fail "--asks exited $code"
[ "$(cat "$WORK/out")" = "$(printf 'Ask for preview: Open the preview and tell me.\nAsk for logs: Paste the error lines.')" ] ||
  fail "--asks did not print exactly the words for the two sections the kit does not run"
run "$P" --no-record
cmp -s "$WORK/before" "$P/CHANGELOG.md" || fail "--asks or --no-record changed the changelog"
ok "--asks prints only the fixed questions, and --no-record writes nothing"

# An older project's Recipe: line names the file, with .md. It still finds the
# folder on the menu.
code=0
sh "$RUNNER" --asks nextjs-supabase-on-vercel.md > "$WORK/out" 2>&1 || code=$?
[ "$code" = 0 ] && grep -q '^Ask for preview: ' "$WORK/out" ||
  fail "a recipe named with .md, as an older project's Recipe: line has it, was not found"
code=0
sh "$RUNNER" --asks no-such-recipe > "$WORK/out" 2>&1 || code=$?
[ "$code" = 2 ] || fail "a recipe that is not on the menu exited $code, not 2"
ok "a recipe named with .md is found, and one not on the menu could not run"

echo
echo "$(basename -- "$0"): all $pass checks passed"
