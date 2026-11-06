#!/usr/bin/env sh
# sensitive-area-map.sh: run the shipped risk-area check in a throwaway
# project. If this breaks, a project whose risky code moves, or gains a source
# folder nobody assigned, keeps a green tick while its map of where the money or
# personal data lives quietly goes stale, or an area the person already accepted
# keeps holding their work.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
CHECK="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-sensitive-areas.sh"
[ -f "$CHECK" ] || { echo "FAIL: missing $CHECK" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
check() {
  if [ "$2" = yes ]; then echo "  ok: $1"; else echo "FAIL: $1" >&2; exit 1; fi
}

echo "Risk-area map check:"
project="$tmp/project"
mkdir -p "$project/.agents/hooks" "$project/src/billing"
git -C "$project" init -q
git -C "$project" config user.name "Test User"
git -C "$project" config user.email "test@example.invalid"
cp "$CHECK" "$project/.agents/hooks/check-sensitive-areas.sh"
run_check() { (cd "$project" && sh .agents/hooks/check-sensitive-areas.sh "$@"); }
printf '%s\n' 'export const charge = true' > "$project/src/billing/charge.ts"
printf '%s\n' \
  '# Masterplan' \
  '## Risk record' \
  'Risk areas:' \
  '  money: refunds; caution: checked; not yet done' \
  '    paths: src/billing/' \
  '    boundary: reached only through src/billing/charge.ts' \
  > "$project/masterplan.md"
git -C "$project" add .
git -C "$project" commit -qm baseline
base=$(git -C "$project" rev-parse HEAD)

if run_check > "$tmp/out" 2>&1; then
  pass=yes
else
  pass=no
fi
check "a current map passes" "$pass"

# Each fixture isolates the reason a folder is skipped or rejected.
(
folder_case=0
folder_project() {
  folder_case=$((folder_case + 1))
  project="$tmp/folder-$folder_case"
  mkdir -p "$project/.agents/hooks" "$project/src/billing"
  git -C "$project" init -q
  cp "$CHECK" "$project/.agents/hooks/check-sensitive-areas.sh"
  cp "$tmp/project/masterplan.md" "$project/masterplan.md"
  printf '%s\n' 'export const charge = true' > "$project/src/billing/charge.ts"
  git -C "$project" add .
}
expect_exit() {
  expected=$1
  label=$2
  code=0
  run_check > "$tmp/out" 2>&1 || code=$?
  [ "$code" -eq "$expected" ] && matched=yes || matched=no
  check "$label (exit $code, expected $expected): $(cat "$tmp/out")" "$matched"
}
folder_project
mkdir -p "$project/ignored-src"
printf '%s\n' 'print("local helper")' > "$project/ignored-src/helper.py"
printf '%s\n' 'ignored-src/' > "$project/.gitignore"
# Git does not report a directory as ignored when it contains tracked files.
# Make a needless lookup fail so only the ignore branch can pass this case.
(
  export REAL_GIT=$(command -v git)
  mkdir -p "$tmp/ignore-bin"
  cat > "$tmp/ignore-bin/git" <<'SH'
#!/bin/sh
if [ "$1" = --literal-pathspecs ]; then shift; fi
if [ "$1" = ls-files ]; then
  for arg do
    if [ "$arg" = ignored-src ]; then exit 128; fi
  done
fi
exec "$REAL_GIT" "$@"
SH
  chmod +x "$tmp/ignore-bin/git"
  export PATH="$tmp/ignore-bin:$PATH"
  expect_exit 0 "an ignored source folder needs no file lookup"
)

for folder in venv .venv __pycache__; do
  folder_project
  mkdir -p "$project/$folder"
  printf '%s\n' 'print("environment helper")' > "$project/$folder/helper.py"
  git -C "$project" add -- "$folder/helper.py"
  expect_exit 0 "tracked source in $folder is skipped"
done

folder_project
mkdir -p "$project/new-source"
printf '%s\n' 'print("new source")' > "$project/new-source/helper.py"
expect_exit 1 "untracked source is checked before the first commit"

folder_project
mkdir -p "$project/services/nested"
printf '%s\n' 'print("nested source")' > "$project/services/nested/helper.py"
git -C "$project" add services/nested/helper.py
expect_exit 1 "nested tracked source without an area fails"

for folder in :source ':(bad)source'; do
  folder_project
  mkdir -p "$project/$folder"
  printf '%s\n' 'print("literal source")' > "$project/$folder/helper.py"
  git -C "$project" --literal-pathspecs add -- "$folder/helper.py"
  expect_exit 1 "tracked source in $folder is treated literally"
done

folder_project
mkdir -p "$project/local-data"
printf '%s\n' 'local-data/*.py' > "$project/.gitignore"
printf '%s\n' 'print("ignored file")' > "$project/local-data/helper.py"
expect_exit 0 "a folder containing only ignored files is skipped"

# Fail Git lookups independently without affecting the initial root lookup.
real_git=$(command -v git)
mkdir -p "$tmp/git-bin"
cat > "$tmp/git-bin/git" <<'SH'
#!/bin/sh
if [ "$1" = --literal-pathspecs ]; then shift; fi
if [ "$1" = "$FAIL_GIT_COMMAND" ]; then exit 128; fi
exec "$REAL_GIT" "$@"
SH
chmod +x "$tmp/git-bin/git"
for command in check-ignore ls-files; do
  (
    export REAL_GIT="$real_git" FAIL_GIT_COMMAND="$command"
    export PATH="$tmp/git-bin:$PATH"
    expect_exit 2 "a git $command error stops the check"
    grep -Fq "git $command failed" "$tmp/out" && named=yes || named=no
    check "the git $command error is named" "$named"
  )
done
)

if run_check --change "" > "$tmp/out" 2>&1; then
  empty_base=no
else
  code=$?
  [ "$code" -eq 2 ] && empty_base=yes || empty_base=no
fi
check "an empty base commit exits 2" "$empty_base"

git -C "$project" checkout -qb change
printf '%s\n' 'export const charge = false' > "$project/src/billing/charge.ts"
git -C "$project" add src/billing/charge.ts
git -C "$project" commit -qm changed
if run_check --change "$base" > "$tmp/out" 2>&1; then
  open=no
else
  open=yes
fi
check "a changed open area fails: $(cat "$tmp/out")" "$open"
grep -Fq 'This changes money, which still needs your decision.' "$tmp/out" && named=yes || named=no
check "the open area and decision are named" "$named"

# A date on the area line is not an acceptance. The record needs the person's words.
sed 's/caution: checked; not yet done/caution: waiting; accepted 2026-09-18/' "$project/masterplan.md" > "$tmp/masterplan"
cp "$tmp/masterplan" "$project/masterplan.md"
printf '%s\n' 'Accepted: none' >> "$project/masterplan.md"
git -C "$project" add -A
git -C "$project" commit -qm 'Date without words'
if run_check --change "$base" > "$tmp/out" 2>&1; then
  unrecorded=no
else
  unrecorded=yes
fi
check "a dated area with no recorded words still holds" "$unrecorded"
grep -Fq 'still needs your decision' "$tmp/out" && named=yes || named=no
check "the unrecorded acceptance is reported as open" "$named"
sed 's/caution: waiting; accepted 2026-09-18/caution: checked; not yet done/' "$project/masterplan.md" > "$tmp/masterplan"
cp "$tmp/masterplan" "$project/masterplan.md"
git -C "$project" add masterplan.md
git -C "$project" commit -qm 'Keep the area open until acceptance is copied'
# Shape keeps the decision on the piece, outside the project's working tree.
mkdir -p "$tmp/bin"
ln -s "$ROOT/.agents/tests/lib/stand-in-gh" "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH"
export STANDIN_GH_STATE="$tmp/piece.json" STANDIN_GH_LOG="$tmp/gh.log"
python3 - "$STANDIN_GH_STATE" <<'PY'
import json, sys
body = '''Risk areas: money
## Decided
Accepted: 2026-09-18, money; caution: owner checks first figures not done; "build it anyway"
'''
with open(sys.argv[1], 'w') as handle:
    json.dump({'labels': ['ready', 'building'],
               'issues': {'1': {'body': body, 'labels': ['ready']}}}, handle)
PY
[ -z "$(git -C "$project" status --porcelain)" ] && clean=yes || clean=no
check "shape acceptance on the piece leaves the working tree clean" "$clean"
if (cd "$project" && sh "$ROOT/.agents/skills/records/scripts/piece-labels.sh" start 1) > "$tmp/out" 2>&1; then
  started=yes
else
  started=no
fi
check "implement can start after shape records acceptance" "$started"
if run_check --change "$base" > "$tmp/out" 2>&1; then
  pending=no
else
  pending=yes
fi
check "the piece's acceptance alone does not clear the project check" "$pending"

# Implement copies the decision after start, before changing the flagged code.
(cd "$project" && gh issue view 1 --json body) > "$tmp/piece-body.json"
python3 - "$project/masterplan.md" "$tmp/piece-body.json" <<'PY'
import json, sys
from pathlib import Path
plan = Path(sys.argv[1])
body = json.loads(Path(sys.argv[2]).read_text())['body']
acceptance = body.split('## Decided\n', 1)[1].strip()
date = acceptance.split(': ', 1)[1].split(',', 1)[0]
text = plan.read_text().replace('not yet done', 'accepted ' + date).replace('Accepted: none', acceptance)
assert acceptance in text
plan.write_text(text)
assert date in text and '"build it anyway"' in text
PY
grep -Fq 'Accepted: 2026-09-18, money; caution: owner checks first figures not done; "build it anyway"' "$project/masterplan.md" \
  && copied=yes || copied=no
check "implement copies the original dated acceptance into the masterplan" "$copied"
git -C "$project" add -A
git -C "$project" commit -qm accepted
if run_check --change "$base" > "$tmp/out" 2>&1; then
  accepted=yes
else
  accepted=no
fi
check "a changed accepted area passes" "$accepted"
grep -Fq 'This changes money, which you accepted on 18 September 2026.' "$tmp/out" && named=yes || named=no
check "the accepted date is plain and named" "$named"

if run_check --bad > "$tmp/out" 2>&1; then
  usage=no
else
  code=$?
  [ "$code" -eq 2 ] && usage=yes || usage=no
fi
check "an invalid invocation exits 2" "$usage"

mv "$project/src/billing" "$project/src/payments"
if run_check > "$tmp/out" 2>&1; then
  moved=no
else
  moved=yes
fi
check "a moved listed folder fails" "$moved"
grep -Fq 'src/billing/ is listed but does not exist' "$tmp/out" && named=yes || named=no
check "the failure names the moved path" "$named"

sed 's@src/billing/@src/payments/@g' "$project/masterplan.md" > "$tmp/masterplan"
cp "$tmp/masterplan" "$project/masterplan.md"
sed 's@src/payments/@src/payments/*.ts@' "$project/masterplan.md" > "$tmp/masterplan"
cp "$tmp/masterplan" "$project/masterplan.md"
git -C "$project" add -A
git -C "$project" commit -qm 'Use a simple glob in the area map'
rename_base=$(git -C "$project" rev-parse HEAD)
git -C "$project" mv src/payments/charge.ts src/elsewhere.ts
git -C "$project" commit -qm 'Move a file out of the mapped area'
if run_check --change "$rename_base" > "$tmp/out" 2>&1; then
  changed=yes
else
  changed=no
fi
grep -Fq 'This changes money, which you accepted on 18 September 2026.' "$tmp/out" \
  && glob=yes || glob=no
check "a completed area passes after a rename" "$changed"
check "the changed path still names the accepted area" "$glob"
mkdir -p "$project/services"
printf '%s\n' 'export const send = true' > "$project/services/send.ts"
git -C "$project" add services/send.ts
git -C "$project" commit -qm 'Add an unassigned source folder'
if run_check > "$tmp/out" 2>&1; then
  unassigned=no
else
  unassigned=yes
fi
check "an unassigned source folder fails" "$unassigned"
grep -Fq 'services is a source folder with no area or none line' "$tmp/out" && named=yes || named=no
check "the failure names the unassigned folder" "$named"

sed 's/^Risk areas:$/Risk areas: none/' "$project/masterplan.md" > "$tmp/masterplan"
cp "$tmp/masterplan" "$project/masterplan.md"
if [ -z "$(run_check 2>&1)" ]; then
  silent=yes
else
  silent=no
fi
check "a project that names no risk area gets no map check" "$silent"
if run_check --change "$base" > "$tmp/out" 2>&1; then
  none_change=yes
else
  none_change=no
fi
check "a change in a project with no risk area passes" "$none_change"

mv "$project/masterplan.md" "$tmp/masterplan.saved"
if [ -z "$(run_check --change "$base" 2>&1)" ]; then
  no_map=yes
else
  no_map=no
fi
check "a project without a map passes silently" "$no_map"

echo "sensitive-area-map.sh: all checks passed"
