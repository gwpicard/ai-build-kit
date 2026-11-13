#!/usr/bin/env sh
# Seed two recorded instances of the same mistaken calendar assessment.
set -eu
project=${1:?project directory}
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sh "$here/calendar-feed.sh" "$project"
cat >> "$project/CHANGELOG.md" <<'MD'

## 2026-06-19

The agent said the calendar showed one event per loan after checking only the
booking records. Sam corrected it: the shared calendar still showed duplicates.
No application change was made.

## 2026-06-20

The agent again said the shared calendar was correct based only on booking
records. Priya checked the feed and found duplicates again. This was the same
assessment mistake twice; no application change was made.
MD
