#!/usr/bin/env sh
# recipes.sh: run the recipe shape check against good and broken recipes.
#
# If this breaks, a recipe missing a launch section, an outcome line or a real
# dated run could reach the menu, and a recipe rehearsal that proves nothing
# could count as one.

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
# rehearsal and runs the recipe's commands against the tool stand-ins.
HELPER_LINE='. "$ROOT/.agents/tests/lib/recipe-rehearsal.sh"'

# --- the shape check itself ----------------------------------------------
FILLED="$WORK/filled.md"
sed -e 's/YYYY-MM-DD/2024-02-29/' -e 's/^Who runs it: .*/Who runs it: a person looking/' \
  -e 's/<[^>]*>/filled in/g' "$BLANK" > "$FILLED"

"$CHECKER" --template "$BLANK" >/dev/null
ok "the blank has the shape it asks for"

if "$CHECKER" "$BLANK" >/dev/null; then
  fail "an unfilled blank passed as a recipe"
fi
ok "an unfilled blank is refused as a recipe"

"$CHECKER" "$FILLED" >/dev/null
ok "a filled recipe passes, dated on a leap day"

refused() {
  # refused <description> <sed-program>: a copy with that edit must fail.
  sed -e "$2" "$FILLED" > "$WORK/mutant.md"
  if cmp -s "$FILLED" "$WORK/mutant.md"; then
    fail "the edit for '$1' changed nothing, so it proves nothing"
  fi
  if "$CHECKER" "$WORK/mutant.md" >/dev/null; then
    fail "a recipe with $1 passed"
  fi
  ok "a recipe with $1 is refused"
}

for section in Preview "Going live" Rollback Backup Restore Secrets Logs Health Proven; do
  refused "no $section section" "/^## $section\$/d"
done
refused "no Fits line" '/^Fits:/d'
refused "no Recommended when line" '/^Recommended when:/d'
refused "no Build stack line" '/^Build stack:/d'
refused "no Deploy target line" '/^Deploy target:/d'
refused "no Command-line tools line" '/^Command-line tools:/d'
refused "no Last checked line" '/^Last checked:/d'
refused "a Last checked line that is not a date" 's/^Last checked: .*/Last checked: recently/'
refused "a Last checked date in the future" 's/^Last checked: .*/Last checked: 2999-01-01/'
refused "a Last checked date in month nineteen" 's/^Last checked: .*/Last checked: 2025-19-01/'
refused "a Last checked date on day thirty-two" 's/^Last checked: .*/Last checked: 2025-01-32/'
refused "a Last checked date on the thirtieth of February" 's/^Last checked: .*/Last checked: 2025-02-30/'
refused "a leap day in a year without one" 's/^Last checked: .*/Last checked: 2025-02-29/'
refused "no Real run line" '/^Real run:/d'
refused "a Real run line with no date" 's/^Real run: .*/Real run: soon/'
refused "no outcome line for one section" '/^Logs: /d'
refused "an empty outcome line" 's/^Rollback: .*/Rollback: /'
refused "one section that does not say how it works" '/^## Backup$/,/^## /{/^How it works:/d;}'
refused "one section that does not say how it is checked" '/^## Health$/,/^## /{/^How it is checked:/d;}'
refused "one section that does not say who runs it" '/^## Secrets$/,/^## /{/^Who runs it:/d;}'
refused "a Who runs it value outside the three" '/^## Preview$/,/^## /s/^Who runs it: .*/Who runs it: the service/'
refused "two sections out of order" 's/^## Backup$/## TEMP/; s/^## Restore$/## Backup/; s/^## TEMP$/## Restore/'

# The optional Plan terms line. Terms change without notice, so a line that
# does not say when and where it was read cannot be told from a current one.
TERMS="$WORK/terms.md"
sed '/^Last checked:/a\
Plan terms: The free plan is for personal use only, so a work team needs the paid plan (read 2024-03-01 at https://example.com/terms)
' "$FILLED" > "$TERMS"
grep -q '^Plan terms:' "$TERMS" || fail "the Plan terms line was not added, so the next checks prove nothing"
"$CHECKER" "$TERMS" >/dev/null
ok "a recipe with a dated Plan terms line passes"
terms_refused() {
  sed -e "$2" "$TERMS" > "$WORK/terms-mutant.md"
  if cmp -s "$TERMS" "$WORK/terms-mutant.md"; then
    fail "the edit for '$1' changed nothing, so it proves nothing"
  fi
  if "$CHECKER" "$WORK/terms-mutant.md" >/dev/null; then
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
  for offset in 1 2; do
    case "$offset" in
      1) value=$one_day ;;
      2) value=$two_days ;;
    esac
    awk -v label="$label" -v value="$value" '
      index($0, label ": ") == 1 {
        if (label == "Plan terms") sub(/read [0-9-]+ at/, "read " value " at")
        else $0 = label ": " value
      }
      { print }
    ' "$TERMS" > "$WORK/date-boundary.md"
    for zone in UTC Pacific/Kiritimati Etc/GMT+12; do
      if TZ="$zone" "$CHECKER" "$WORK/date-boundary.md" > "$WORK/date-result.txt"; then
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
mkdir -p "$WORK/parts"
printf '%s\n' 'How it works: filled in' 'How it is checked: filled in' 'Who runs it: the kit' \
  > "$WORK/parts/whole.md"
cp "$WORK/parts/whole.md" "$WORK/parts/shared.md"
# The backup section's own lines go, and a link to the part takes their place.
awk '
  /^## / { inbackup = ($0 == "## Backup") }
  inbackup && /^(How it|Who runs it)/ { next }
  { print }
  $0 == "## Backup" { print ""; print "Shared part: [shared](parts/shared.md)" }
' "$FILLED" > "$WORK/linked.md"

"$CHECKER" --part "$WORK/parts/shared.md" >/dev/null
ok "a shared part with the three lines passes"
"$CHECKER" "$WORK/linked.md" >/dev/null
ok "a recipe that links a shared part in place of a section passes"

sed 's#parts/shared.md#parts/missing.md#' "$WORK/linked.md" > "$WORK/mutant.md"
if "$CHECKER" "$WORK/mutant.md" >/dev/null; then
  fail "a recipe linking a part that does not exist passed"
fi
ok "a recipe linking a part that does not exist is refused"

sed '/^Who runs it:/d' "$WORK/parts/whole.md" > "$WORK/parts/shared.md"
if "$CHECKER" --part "$WORK/parts/shared.md" >/dev/null; then
  fail "a shared part with no Who runs it line passed"
fi
if "$CHECKER" "$WORK/linked.md" >/dev/null; then
  fail "a recipe linking a part with no Who runs it line passed"
fi
ok "a shared part missing a line is refused, on its own and through the recipe"

sed 's/^Who runs it: .*/Who runs it: nobody/' "$WORK/parts/whole.md" > "$WORK/parts/shared.md"
if "$CHECKER" "$WORK/linked.md" >/dev/null; then
  fail "a recipe linking a part with a Who runs it value outside the three passed"
fi
ok "a shared part with a Who runs it value outside the three is refused"

# --- the settings section --------------------------------------------------
# The one section a recipe may add. It sits between health and the proven
# section and carries the lines the others do, so a read the launch review
# relies on is never a bare claim.
cp "$WORK/parts/whole.md" "$WORK/parts/shared.md"
awk '
  $0 == "## Proven" { print "## Settings the kit can read"; print ""; print "Shared part: [shared](parts/shared.md)"; print "" }
  { print }
  END { print "Settings the kit can read: filled in" }
' "$FILLED" > "$WORK/settings.md"
"$CHECKER" "$WORK/settings.md" >/dev/null
ok "a recipe with a settings section after health, and its outcome line, passes"

sed '/^Settings the kit can read: /d' "$WORK/settings.md" > "$WORK/mutant.md"
if "$CHECKER" "$WORK/mutant.md" >/dev/null; then
  fail "a settings section with no outcome line in the proven section passed"
fi
ok "a settings section with no outcome line in the proven section is refused"

sed '/^Who runs it:/d' "$WORK/parts/whole.md" > "$WORK/parts/shared.md"
if "$CHECKER" "$WORK/settings.md" >/dev/null; then
  fail "a settings section whose part has no Who runs it line passed"
fi
ok "a settings section missing a line is refused"
cp "$WORK/parts/whole.md" "$WORK/parts/shared.md"

awk '
  $0 == "## Health" { print "## Settings the kit can read"; print ""; print "Shared part: [shared](parts/shared.md)"; print "" }
  { print }
' "$FILLED" > "$WORK/mutant.md"
if "$CHECKER" "$WORK/mutant.md" >/dev/null; then
  fail "a settings section before health passed"
fi
ok "a settings section out of place is refused"

# --- the rehearsal a recipe needs ----------------------------------------
mkdir -p "$WORK/recipes"
RECIPE="$WORK/recipes/example-pair.md"
cp "$FILLED" "$RECIPE"

printf '%s\n' '#!/usr/bin/env sh' 'exit 0' > "$WORK/empty.sh"
if "$CHECKER" --rehearsal "$RECIPE" "$WORK/empty.sh" >/dev/null; then
  fail "a rehearsal that only exits cleanly counted"
fi
ok "a rehearsal that only exits cleanly is refused"

printf '%s\n' '#!/usr/bin/env sh' "$HELPER_LINE" 'rr_stand_ins' > "$WORK/unnamed.sh"
if "$CHECKER" --rehearsal "$RECIPE" "$WORK/unnamed.sh" >/dev/null; then
  fail "a rehearsal that never names its recipe counted"
fi
ok "a rehearsal that never names its recipe is refused"

printf '%s\n' '#!/usr/bin/env sh' 'rr_stand_ins' \
  'RECIPE=setup-hosting/recipes/example-pair.md' > "$WORK/unhelped.sh"
if "$CHECKER" --rehearsal "$RECIPE" "$WORK/unhelped.sh" >/dev/null; then
  fail "a rehearsal that does not source the recipe rehearsal counted"
fi
ok "a rehearsal that does not source the recipe rehearsal is refused"

printf '%s\n' '#!/usr/bin/env sh' "$HELPER_LINE" \
  'RECIPE=setup-hosting/recipes/example-pair.md' > "$WORK/no-stand-ins.sh"
if "$CHECKER" --rehearsal "$RECIPE" "$WORK/no-stand-ins.sh" >/dev/null; then
  fail "a rehearsal that never runs the stand-ins counted"
fi
ok "a rehearsal that never runs the stand-ins is refused"

if "$CHECKER" --rehearsal "$RECIPE" "$WORK/absent.sh" >/dev/null; then
  fail "a recipe with no rehearsal at all passed"
fi
ok "a recipe with no rehearsal at all is refused"

printf '%s\n' '#!/usr/bin/env sh' "$HELPER_LINE" 'rr_stand_ins' \
  'RECIPE=setup-hosting/recipes/example-pair.md' > "$WORK/real.sh"
"$CHECKER" --rehearsal "$RECIPE" "$WORK/real.sh" >/dev/null ||
  fail "a rehearsal that sources the recipe rehearsal, runs the stand-ins and names its recipe was refused"
ok "a rehearsal that sources the recipe rehearsal, runs the stand-ins and names its recipe counts"

echo
echo "$(basename -- "$0"): all $pass checks passed"
