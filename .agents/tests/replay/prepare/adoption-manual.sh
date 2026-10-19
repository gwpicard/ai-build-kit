#!/usr/bin/env sh
# Seed an existing project and a usable manual alternative for case 62.
set -eu
project=${1:?project directory}
mkdir -p "$project/operations"
cat > "$project/operations/manual-loan-log.csv" <<'CSV'
item,borrower,due_date,returned
Camera 2,Priya,2026-10-21,no
Microphone 4,Sam,2026-10-19,yes
CSV
cat > "$project/operations/README.md" <<'TXT'
The team uses this shared sheet to track kit loans. When the sheet is unavailable,
the paper sign-out board in the kit room is still usable.
TXT
