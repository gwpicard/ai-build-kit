#!/usr/bin/env sh
# check-recipes.sh: check that each recipe file has the shape the format asks for.
#
# The format lives in .agents/skills/ship/references/recipe-format.md. A recipe
# is only worth offering if every one of the eight sections says how it works
# and how anybody would know it did, and if the file carries the dates that say
# when it was last read and when it was really run. A missing section is easy to
# miss by eye and costs the person a launch step nobody can check, so a machine
# reads for it.
#
# Usage: check-recipes.sh [--template] FILE...
#
# With --template the two dates may still read YYYY-MM-DD, since the blank has
# no date to give. Every other rule applies to the blank as well, so the blank
# cannot drift away from the format it is meant to be copied from.
#
# Prints each problem and exits 1 when any file has one. Writes nothing.

set -eu

template=0
if [ "${1:-}" = "--template" ]; then
  template=1
  shift
fi

[ "$#" -gt 0 ] || { echo "usage: check-recipes.sh [--template] FILE..." >&2; exit 2; }

today=$(date +%Y-%m-%d)
status=0

for file in "$@"; do
  if [ ! -f "$file" ]; then
    echo "$file: no such recipe file"
    status=1
    continue
  fi
  awk -v template="$template" -v today="$today" -v file="$file" '
    function problem(msg) { print file ": " msg; bad = 1 }
    function datecheck(label, value) {
      if (template && value == "YYYY-MM-DD") return
      if (value !~ /^[0-9][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]$/) {
        problem(label " is not a date written YYYY-MM-DD: " value)
      } else if (value > today) {
        problem(label " is in the future: " value)
      }
    }
    BEGIN {
      n = split("Preview|Going live|Rollback|Backup|Restore|Secrets|Logs|Health|Proven", order, "|")
      for (i = 1; i <= n; i++) want[order[i]] = i
    }
    /^## / {
      section = substr($0, 4)
      if (section in want) {
        seen[section] = 1
        pos[section] = ++count
      }
      next
    }
    /^Fits: ./          { if (section == "") head["Fits"] = 1 }
    /^Build stack: ./   { if (section == "") head["Build stack"] = 1 }
    /^Deploy target: ./ { if (section == "") head["Deploy target"] = 1 }
    /^Last checked:/ {
      if (section == "") { head["Last checked"] = 1; datecheck("Last checked", substr($0, 15)) }
    }
    /^How it works: ./      { if (section != "") works[section] = 1 }
    /^How it is checked: ./ { if (section != "") checked[section] = 1 }
    /^Real run:/ {
      if (section == "Proven") { realrun = 1; datecheck("Real run", substr($0, 11)) }
    }
    END {
      split("Fits|Build stack|Deploy target|Last checked", heads, "|")
      for (i = 1; i <= 4; i++)
        if (!(heads[i] in head)) problem("the opening lines lack \"" heads[i] ":\"")
      for (i = 1; i <= n; i++) {
        s = order[i]
        if (!(s in seen)) { problem("no \"## " s "\" section"); continue }
        if (pos[s] != i) problem("\"## " s "\" is out of order")
        if (s == "Proven") continue
        if (!(s in works)) problem("\"## " s "\" does not say \"How it works:\"")
        if (!(s in checked)) problem("\"## " s "\" does not say \"How it is checked:\"")
      }
      if ("Proven" in seen && !realrun) problem("\"## Proven\" does not open with \"Real run:\" and a date")
      exit bad
    }
  ' "$file" || status=1
done

exit "$status"
