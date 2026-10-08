#!/usr/bin/env sh
# recipe-menu.sh: print the recipe menu founding shows, and its default.
#
# Founding reads the menu from the recipes folder of the setup-hosting skill
# installed beside this one. A founding with one recipe on the menu kept
# choosing it quietly and naming it only once the project was stood up, in four
# runs out of five, although the written rules said to show it. So the lines
# that have to reach the person are printed here, the same every time, and
# founding puts them in its reply as given.
#
# Usage: sh recipe-menu.sh [--recommend <file>] [--none] [--record <file>] [<file>...]
#
#   <file>...           the menu files that fit the tool, by file name. With
#                       none named, every file on the menu is shown.
#   --recommend <file>  the one to recommend, where several fit. Several
#                       with none chosen print what each recipe says, so the
#                       choice can be made, and leave out the lines to say.
#   --none              no recipe fits the tool, so no menu is shown.
#   --record <file>     write the founding-menu line into this file, replacing
#                       any earlier one. It is the project's check-up record.
#
# It reads the menu and writes only the file named by --record.
#
# Exit 0 with the menu printed, 3 when several recipes fit and none was
# chosen, 4 when an argument names a file that is not on the menu, so the name
# can be corrected, and 1 when the recipes folder is missing.

set -eu

me=recipe-menu.sh
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
folder="$here/../../setup-hosting/recipes"

recommend=
record=
none=no
fits=
while [ $# -gt 0 ]; do
  case $1 in
    --recommend) recommend=${2:?--recommend needs a file name}; shift 2 ;;
    --record) record=${2:?--record needs a file}; shift 2 ;;
    --none) none=yes; shift ;;
    --*) echo "$me: unknown option $1" >&2; exit 4 ;;
    *) fits="$fits $1"; shift ;;
  esac
done

if [ ! -d "$folder" ]; then
  echo "$me: no recipes folder beside this skill, at $folder" >&2
  exit 1
fi
folder=$(CDPATH= cd -- "$folder" && pwd -P)

# The menu is the files directly in the folder. The parts folder is not on it.
menu=$(find "$folder" -mindepth 1 -maxdepth 1 -type f -name '*.md' -exec basename {} \; | LC_ALL=C sort)

on_menu() {
  printf '%s\n' "$menu" | grep -qxF -- "$1"
}

line_of() {
  # line_of <file> <label>: the text after "<label>: " on its own line.
  sed -n "s/^$2: //p" "$folder/$1" | head -n 1
}

name_of() {
  title=$(sed -n 's/^# Recipe: //p' "$folder/$1" | head -n 1)
  printf '%s\n' "${title:-${1%.md}}"
}

# The file names stay words: a name such as *.md is not expanded here.
set -f
for f in $fits; do
  on_menu "$f" || { echo "$me: $f is not on the menu; the menu holds: $(printf '%s\n' "$menu" | paste -sd' ' -)" >&2; exit 4; }
done
if [ -n "$recommend" ] && ! on_menu "$recommend"; then
  echo "$me: $recommend is not on the menu" >&2
  exit 4
fi

if [ "$none" = yes ]; then
  shown=
elif [ -n "$fits" ]; then
  shown=$(printf '%s\n' $fits | LC_ALL=C sort -u)
else
  shown=$menu
fi
set +f

if [ -n "$shown" ]; then
  if [ -n "$recommend" ]; then
    printf '%s\n' "$shown" | grep -qxF -- "$recommend" || {
      echo "$me: $recommend is recommended but not among the recipes that fit" >&2
      exit 4
    }
  elif [ "$(printf '%s\n' "$shown" | grep -c .)" -eq 1 ]; then
    recommend=$shown
  fi
fi

today=$(date +%Y-%m-%d)
menu_list=$(printf '%s\n' "$menu" | grep . | paste -sd, - || true)
record_line="founding-menu|$today|$menu_list"

if [ -n "$menu" ]; then
  echo "Menu: $(printf '%s\n' "$menu" | paste -sd' ' -)"
else
  echo "Menu: none"
fi
echo "Record: $record_line"

if [ -n "$record" ]; then
  tmp="$record.recipe-menu.$$"
  if [ -f "$record" ]; then
    grep -v '^founding-menu|' "$record" > "$tmp" || true
  else
    : > "$tmp"
  fi
  printf '%s\n' "$record_line" >> "$tmp"
  mv "$tmp" "$record"
  echo "Recorded in: $record"
fi

if [ -z "$shown" ]; then
  echo
  echo "Say this in your reply, as written:"
  echo "No recipe the kit knows fits this tool, so I will set it up on a common stack, and the kit cannot check its launch steps for you."
  exit 0
fi

count=$(printf '%s\n' "$shown" | grep -c .)
if [ -n "$recommend" ]; then
  echo "Recommended: $recommend"
  echo "Recipe file: $folder/$recommend"
fi

echo
echo "What each recipe says, to put in plain words beside it:"
printf '%s\n' "$shown" | while IFS= read -r f; do
  echo "$f"
  echo "  Name: $(name_of "$f")"
  for label in Fits 'Recommended when' 'Deploy target' 'Plan terms'; do
    value=$(line_of "$f" "$label")
    [ -z "$value" ] || echo "  $label: $value"
  done
done

if [ -z "$recommend" ]; then
  echo
  echo "Several recipes fit. Choose the one whose Recommended when: line best matches the interview, or the first by file name when none or several match, and run this again with --recommend <file>."
  exit 3
fi

echo
echo "Say this in your reply, as written, before the stand-up begins:"
if [ "$count" -eq 1 ]; then
  echo "The kit has one recipe for a tool like this: a way to build it and run it that the kit can check at launch."
else
  echo "The kit has $count recipes for a tool like this. Each is a way to build it and run it that the kit can check at launch."
fi
n=0
printf '%s\n' "$shown" | while IFS= read -r f; do
  n=$((n + 1))
  if [ "$f" = "$recommend" ]; then
    echo "$n. $(name_of "$f") (recommended)"
  else
    echo "$n. $(name_of "$f")"
  fi
done
echo "$(name_of "$recommend") is the default. Founding carries on with it unless you pick another recipe, and you may bring your own stack instead."
