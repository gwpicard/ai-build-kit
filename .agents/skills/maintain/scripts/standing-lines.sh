#!/usr/bin/env sh
# standing-lines.sh: count the lines in a project's standing instructions
# against the kit's 200-line ceiling.
#
# Usage: sh standing-lines.sh [file]     (default: AGENTS.md)
#
# Counts every line, blank lines included, and a last line with no newline.
# Prints "lines <n>".
#
# Exit 0: under 200 lines.
# Exit 1: 200 lines or more; the monthly visit offers a trim.
# Exit 2: the file could not be read.

set -u

file=${1:-AGENTS.md}
if [ ! -f "$file" ] || [ ! -r "$file" ]; then
  echo "standing-lines: cannot read $file" >&2
  exit 2
fi
count=$(awk 'END { print NR }' "$file")
echo "lines $count"
[ "$count" -lt 200 ] || exit 1
exit 0
