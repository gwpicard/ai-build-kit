#!/usr/bin/env sh
# recipes.sh: run the recipe shape check against good and broken recipe folders.
#
# If this breaks, a recipe missing a launch section, a script, an outcome line
# or a real dated run could reach the menu, and a recipe rehearsal that proves
# nothing could count as one.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
pass=0
ok() { echo "  ok: $1"; pass=$((pass + 1)); }
fail() { echo "FAIL: $1" >&2; exit 1; }

BLANK="$ROOT/.agents/skills/setup-hosting/templates/recipe.md"
CHECKER="$ROOT/.agents/tools/check-recipes.sh"
# The lines a recipe rehearsal must carry: it sources the shared recipe
# rehearsal and runs the recipe's scripts against the tool stand-ins.
HELPER_LINE='. "$ROOT/.agents/tests/lib/recipe-rehearsal.sh"'

# --- a recipe filled in from the blank ------------------------------------
GOOD="$WORK/recipes/example-pair"
mkdir -p "$GOOD/scripts" "$WORK/recipes/parts/scripts"
sed -e 's/YYYY-MM-DD/2024-02-29/' -e 's/^Who runs it: .*/Who runs it: a person looking/' \
  -e 's#^Script: .*#Script: scripts/check.sh#' -e 's#^Framework: .*#Framework: Next.js 16#' \
  -e 's#^Starter: .*#Starter: coming in part B at starters/example#' \
  -e 's#^Fits: .*#Fits: Project and task trackers#' \
  -e 's#^Shared stack: .*#Shared stack: [stack](../parts/stack.md)#' \
  -e 's/<[^>]*>/filled in/g' "$BLANK" > "$GOOD/recipe.md"
{
  for section in "Sign-in and roles" "Row rules" Files Jobs Email "Project check" Updates; do
    printf '## %s\nHow it works: example\nHow it is checked: example\nScript: coming in part D\nWho runs it: the kit\n\n' "$section"
  done
} > "$WORK/recipes/parts/stack.md"
printf '#!/usr/bin/env sh\nexit 0\n' > "$GOOD/scripts/check.sh"
cp "$GOOD/scripts/check.sh" "$GOOD/scripts/live-check.sh"
chmod +x "$GOOD/scripts/check.sh" "$GOOD/scripts/live-check.sh"
{
  echo "# Proven: example"
  echo
  echo "Real run: 2024-03-01"
  echo
  for section in Preview "Going live" Rollback Backup Restore Secrets Logs Health Access; do
    echo "$section: filled in"
  done
} > "$GOOD/PROVEN.md"

"$CHECKER" --template "$BLANK" >/dev/null
ok "the blank has the shape it asks for"
set +e
"$CHECKER" >/dev/null 2>&1
status=$?
set -e
[ "$status" -eq 2 ] || fail "the recipe shape checker did not report an unusable invocation as could not run"
ok "the recipe shape checker reports could not run for an unusable invocation"

mkdir -p "$WORK/blank/scripts"
cp "$BLANK" "$WORK/blank/recipe.md"
if "$CHECKER" "$WORK/blank" >/dev/null; then
  fail "an unfilled blank passed as a recipe"
fi
ok "an unfilled blank is refused as a recipe"

"$CHECKER" "$GOOD" >/dev/null
ok "a filled recipe folder passes, dated on a leap day"
"$CHECKER" "$GOOD/recipe.md" >/dev/null
ok "the same recipe passes when its recipe.md is named"

cp "$WORK/recipes/parts/stack.md" "$WORK/stack.before"
sed '/^## Email$/d' "$WORK/stack.before" > "$WORK/recipes/parts/stack.md"
if "$CHECKER" "$GOOD" >/dev/null; then
  fail "a recipe whose shared stack part is missing a required section passed"
fi
cp "$WORK/stack.before" "$WORK/recipes/parts/stack.md"
ok "a shared stack missing a required section is refused"

copy() {
  # copy: a fresh copy of the good recipe at $WORK/mutant, printed.
  rm -rf "$WORK/recipes/mutant"
  cp -R "$GOOD" "$WORK/recipes/mutant"
  printf '%s\n' "$WORK/recipes/mutant"
}

refused() {
  # refused <description> <file in the folder> <sed-program>: a copy with that
  # edit must fail.
  m=$(copy)
  sed -e "$3" "$GOOD/$2" > "$m/$2"
  if cmp -s "$GOOD/$2" "$m/$2"; then
    fail "the edit for '$1' changed nothing, so it proves nothing"
  fi
  if "$CHECKER" "$m" >/dev/null; then
    fail "a recipe with $1 passed"
  fi
  ok "a recipe with $1 is refused"
}

for section in Preview "Going live" Rollback Backup Restore Secrets Logs Health Access; do
  refused "no $section section" recipe.md "/^## $section\$/d"
done
refused "no Fits line" recipe.md '/^Fits:/d'
refused "no Recommended when line" recipe.md '/^Recommended when:/d'
refused "no Language line" recipe.md '/^Language:/d'
refused "Framework without a pinned major" recipe.md 's/^Framework: .*/Framework: Next.js/'
refused "no shared stack link" recipe.md '/^Shared stack:/d'
refused "no Deploy target line" recipe.md '/^Deploy target:/d'
refused "no Command-line tools line" recipe.md '/^Command-line tools:/d'
refused "no Last checked line" recipe.md '/^Last checked:/d'
refused "a Last checked line that is not a date" recipe.md 's/^Last checked: .*/Last checked: recently/'
refused "a Last checked date in the future" recipe.md 's/^Last checked: .*/Last checked: 2999-01-01/'
refused "a Last checked date in month nineteen" recipe.md 's/^Last checked: .*/Last checked: 2025-19-01/'
refused "a Last checked date on day thirty-two" recipe.md 's/^Last checked: .*/Last checked: 2025-01-32/'
refused "a Last checked date on the thirtieth of February" recipe.md 's/^Last checked: .*/Last checked: 2025-02-30/'
refused "a leap day in a year without one" recipe.md 's/^Last checked: .*/Last checked: 2025-02-29/'
refused "one section that does not say how it works" recipe.md '/^## Backup$/,/^## /{/^How it works:/d;}'
refused "one section that does not say what a pass means" recipe.md '/^## Health$/,/^## /{/^How it is checked:/d;}'
refused "one section that does not say who runs it" recipe.md '/^## Secrets$/,/^## /{/^Who runs it:/d;}'
refused "one section that names no script" recipe.md '/^## Logs$/,/^## /{/^Script:/d;}'
refused "a script that is not there" recipe.md '/^## Logs$/,/^## /s#^Script: .*#Script: scripts/missing.sh#'
refused "a script outside its scripts folder" recipe.md '/^## Logs$/,/^## /s#^Script: .*#Script: ../check.sh#'
refused "a section a person runs with no Ask line" recipe.md '/^## Preview$/,/^## /{/^Ask:/d;}'
refused "a Who runs it value outside the three" recipe.md '/^## Preview$/,/^## /s/^Who runs it: .*/Who runs it: the service/'
refused "two sections out of order" recipe.md 's/^## Backup$/## TEMP/; s/^## Restore$/## Backup/; s/^## TEMP$/## Restore/'
refused "a Proven section left in recipe.md" recipe.md '$a\
## Proven\
Real run: 2024-03-01'
refused "no Real run line" PROVEN.md '/^Real run:/d'
refused "a Real run line with no date" PROVEN.md 's/^Real run: .*/Real run: soon/'
refused "no outcome line for one section" PROVEN.md '/^Logs: /d'
refused "an empty outcome line" PROVEN.md 's/^Rollback: .*/Rollback: /'

m=$(copy)
rm "$m/PROVEN.md"
"$CHECKER" "$m" >/dev/null && fail "a recipe with no PROVEN.md passed"
ok "a recipe with no PROVEN.md is refused"
m=$(copy)
chmod -x "$m/scripts/check.sh"
"$CHECKER" "$m" >/dev/null && fail "a recipe whose script is not executable passed"
ok "a recipe whose script is not executable is refused"
m=$(copy)
rm "$m/scripts/live-check.sh"
"$CHECKER" "$m" >/dev/null && fail "a recipe with no live-check.sh passed"
ok "a recipe with no live-check.sh is refused"

# The optional Plan terms line. Terms change without notice, so a line that
# does not say when and where it was read cannot be told from a current one.
TERMS="$WORK/recipes/terms"
cp -R "$GOOD" "$TERMS"
sed '/^Last checked:/a\
Plan terms: The free plan is for personal use only, so a work team needs the paid plan (read 2024-03-01 at https://example.com/terms)
' "$GOOD/recipe.md" > "$TERMS/recipe.md"
grep -q '^Plan terms:' "$TERMS/recipe.md" || fail "the Plan terms line was not added, so the next checks prove nothing"
"$CHECKER" "$TERMS" >/dev/null
ok "a recipe with a dated Plan terms line passes"
terms_refused() {
  rm -rf "$WORK/recipes/terms-mutant"
  cp -R "$TERMS" "$WORK/recipes/terms-mutant"
  sed -e "$2" "$TERMS/recipe.md" > "$WORK/recipes/terms-mutant/recipe.md"
  if cmp -s "$TERMS/recipe.md" "$WORK/recipes/terms-mutant/recipe.md"; then
    fail "the edit for '$1' changed nothing, so it proves nothing"
  fi
  if "$CHECKER" "$WORK/recipes/terms-mutant" >/dev/null; then
    fail "a recipe with $1 passed"
  fi
  ok "a recipe with $1 is refused"
}
terms_refused "a Plan terms line with no date" 's/ (read 2024-03-01 at https:\/\/example.com\/terms)$//'
terms_refused "a Plan terms line with no source page" 's/ at https:\/\/example.com\/terms)$/)/'
terms_refused "a Plan terms date in the future" 's/(read 2024-03-01/(read 2999-03-01/'
terms_refused "a Plan terms date that is not real" 's/(read 2024-03-01/(read 2025-02-29/'
terms_refused "a Plan terms line with no sentence" 's/^Plan terms: .* (read/Plan terms: (read/'

# All three dates use the same UTC limit, even on machines east or west of UTC.
utc_dates=$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone

today = datetime.now(timezone.utc).date()
print(today + timedelta(days=1), today + timedelta(days=2))
PY
)
one_day=${utc_dates% *}
two_days=${utc_dates#* }
for label in 'Last checked' 'Real run' 'Plan terms'; do
  file=recipe.md
  [ "$label" = 'Real run' ] && file=PROVEN.md
  for offset in 1 2; do
    case "$offset" in
      1) value=$one_day ;;
      2) value=$two_days ;;
    esac
    rm -rf "$WORK/recipes/date"
    cp -R "$TERMS" "$WORK/recipes/date"
    awk -v label="$label" -v value="$value" '
      index($0, label ": ") == 1 {
        if (label == "Plan terms") sub(/read [0-9-]+ at/, "read " value " at")
        else $0 = label ": " value
      }
      { print }
    ' "$TERMS/$file" > "$WORK/recipes/date/$file"
    for zone in UTC Pacific/Kiritimati Etc/GMT+12; do
      if TZ="$zone" "$CHECKER" "$WORK/recipes/date" > "$WORK/date-result.txt"; then
        [ "$offset" = 1 ] || fail "$label two days ahead of UTC passed in $zone"
      else
        [ "$offset" = 2 ] || fail "$label one day ahead of UTC was refused in $zone"
        grep -qF "$label is in the future: $value" "$WORK/date-result.txt" ||
          fail "$label was refused for a reason other than its future date in $zone"
      fi
    done
  done
  ok "$label one day ahead of UTC passes and two days ahead is refused in every time zone tested"
done

# --- shared parts ----------------------------------------------------------
PARTS="$WORK/recipes/parts"
printf '%s\n' 'How it works: filled in' 'How it is checked: filled in' 'Script: scripts/shared.sh' \
  'Who runs it: the kit' > "$PARTS/whole.md"
printf '#!/usr/bin/env sh\nexit 0\n' > "$PARTS/scripts/shared.sh"
chmod +x "$PARTS/scripts/shared.sh"
cp "$PARTS/whole.md" "$PARTS/shared.md"
LINKED="$WORK/recipes/linked"
cp -R "$GOOD" "$LINKED"
# The backup section's own lines go, and a link to the part takes their place.
awk '
  /^## / { inbackup = ($0 == "## Backup") }
  inbackup && /^(How it|Who runs it|Script|Ask)/ { next }
  { print }
  $0 == "## Backup" { print ""; print "Shared part: [shared](../parts/shared.md)" }
' "$GOOD/recipe.md" > "$LINKED/recipe.md"

"$CHECKER" --part "$PARTS/shared.md" >/dev/null
ok "a shared part with its four lines passes"
"$CHECKER" "$LINKED" >/dev/null
ok "a recipe that links a shared part in place of a section passes"

sed 's#\.\./parts/shared.md#../parts/missing.md#' "$LINKED/recipe.md" > "$WORK/linked-missing.md"
cp "$WORK/linked-missing.md" "$LINKED/recipe.md"
if "$CHECKER" "$LINKED" >/dev/null; then
  fail "a recipe linking a part that does not exist passed"
fi
ok "a recipe linking a part that does not exist is refused"
sed 's#\.\./parts/missing.md#../parts/shared.md#' "$WORK/linked-missing.md" > "$LINKED/recipe.md"

sed '/^Who runs it:/d' "$PARTS/whole.md" > "$PARTS/shared.md"
if "$CHECKER" --part "$PARTS/shared.md" >/dev/null; then
  fail "a shared part with no Who runs it line passed"
fi
if "$CHECKER" "$LINKED" >/dev/null; then
  fail "a recipe linking a part with no Who runs it line passed"
fi
ok "a shared part missing a line is refused, on its own and through the recipe"

sed 's#^Script: .*#Script: scripts/absent.sh#' "$PARTS/whole.md" > "$PARTS/shared.md"
if "$CHECKER" "$LINKED" >/dev/null; then
  fail "a recipe linking a part whose script is not there passed"
fi
ok "a shared part whose script is not there is refused"
cp "$PARTS/whole.md" "$PARTS/shared.md"

# --- the settings section --------------------------------------------------
# The one section a recipe may add. It sits after health and carries the
# lines the others do, so a read the launch review relies on is never a bare
# claim.
SET="$WORK/recipes/settings"
cp -R "$GOOD" "$SET"
printf '\n## Settings the kit can read\n\nShared part: [shared](../parts/shared.md)\n' >> "$SET/recipe.md"
echo "Settings the kit can read: filled in" >> "$SET/PROVEN.md"
"$CHECKER" "$SET" >/dev/null
ok "a recipe with a settings section after health, and its outcome line, passes"

sed '/^Settings the kit can read: /d' "$SET/PROVEN.md" > "$WORK/proven" && cp "$WORK/proven" "$SET/PROVEN.md"
if "$CHECKER" "$SET" >/dev/null; then
  fail "a settings section with no outcome line in PROVEN.md passed"
fi
ok "a settings section with no outcome line in PROVEN.md is refused"
echo "Settings the kit can read: filled in" >> "$SET/PROVEN.md"

awk '
  $0 == "## Health" { print "## Settings the kit can read"; print ""; print "Shared part: [shared](../parts/shared.md)"; print "" }
  /^## Settings the kit can read$/ && seen { exit }
  $0 == "## Health" { seen = 1 }
  { print }
' "$GOOD/recipe.md" > "$SET/recipe.md"
if "$CHECKER" "$SET" >/dev/null; then
  fail "a settings section before health passed"
fi
ok "a settings section out of place is refused"

# --- the rehearsal a recipe needs ----------------------------------------
printf '%s\n' '#!/usr/bin/env sh' 'exit 0' > "$WORK/empty.sh"
if "$CHECKER" --rehearsal "$GOOD" "$WORK/empty.sh" >/dev/null; then
  fail "a rehearsal that only exits cleanly counted"
fi
ok "a rehearsal that only exits cleanly is refused"

printf '%s\n' '#!/usr/bin/env sh' "$HELPER_LINE" 'rr_scripts' > "$WORK/unnamed.sh"
if "$CHECKER" --rehearsal "$GOOD" "$WORK/unnamed.sh" >/dev/null; then
  fail "a rehearsal that never names its recipe counted"
fi
ok "a rehearsal that never names its recipe is refused"

printf '%s\n' '#!/usr/bin/env sh' 'rr_scripts' \
  'RECIPE=setup-hosting/recipes/example-pair' > "$WORK/unhelped.sh"
if "$CHECKER" --rehearsal "$GOOD" "$WORK/unhelped.sh" >/dev/null; then
  fail "a rehearsal that does not source the recipe rehearsal counted"
fi
ok "a rehearsal that does not source the recipe rehearsal is refused"

printf '%s\n' '#!/usr/bin/env sh' "$HELPER_LINE" \
  'RECIPE=setup-hosting/recipes/example-pair' > "$WORK/no-scripts.sh"
if "$CHECKER" --rehearsal "$GOOD" "$WORK/no-scripts.sh" >/dev/null; then
  fail "a rehearsal that never runs the scripts counted"
fi
ok "a rehearsal that never runs the scripts is refused"

if "$CHECKER" --rehearsal "$GOOD" "$WORK/absent.sh" >/dev/null; then
  fail "a recipe with no rehearsal at all passed"
fi
ok "a recipe with no rehearsal at all is refused"

printf '%s\n' '#!/usr/bin/env sh' "$HELPER_LINE" 'rr_scripts' \
  'RECIPE=setup-hosting/recipes/example-pair' > "$WORK/real.sh"
"$CHECKER" --rehearsal "$GOOD" "$WORK/real.sh" >/dev/null ||
  fail "a rehearsal that sources the recipe rehearsal, runs the scripts and names its recipe was refused"
ok "a rehearsal that sources the recipe rehearsal, runs the scripts and names its recipe counts"

echo
echo "$(basename -- "$0"): all $pass checks passed"
