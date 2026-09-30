#!/usr/bin/env sh
# kit-owns-worktrees-rehearsal.sh: run the worktree script in a throwaway
# project and read what it did.
#
# kit-owns-worktrees.sh holds the rules as written. This half runs the shipped
# `worktree.sh` the rules name, because the promises that matter are about what
# happens on disk: git ignores the folder, the .env arrives as a link and never
# as a copy, the main folder never moves off its branch, and a worktree is
# removed after its pull request closes only when nothing in it is unsaved.
# Removing the wrong worktree loses somebody's work, and nothing would say so.
#
# A stand-in for the GitHub command line tool answers the pull request lookup
# from a small file, and a wrapper around git records every call, so a forced
# removal is caught even if it happened to succeed. No network, no account.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/implement/scripts/worktree.sh"
IGNORE="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/gitignore"

pass=0
fail() { echo "FAIL: $1" >&2; exit 1; }
ok() { echo "  ok: $1"; pass=$((pass + 1)); }
check() { if [ "$2" = yes ]; then ok "$1"; else fail "$1"; fi; }

[ -f "$SCRIPT" ] || fail "there is no worktree script at $SCRIPT"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

REAL_GIT=$(command -v git)
mkdir -p "$WORK/bin"
cat > "$WORK/bin/git" <<SH
#!/usr/bin/env sh
printf '%s\n' "\$*" >> "$WORK/git.log"
exec "$REAL_GIT" "\$@"
SH
chmod +x "$WORK/bin/git"

# The stand-in answers `gh pr list --head <branch> ...` from $WORK/prs, whose
# lines are "<branch> <state> <head commit>". GH_FAIL makes it fail, as a
# signed-out tool does.
cat > "$WORK/bin/gh" <<SH
#!/usr/bin/env sh
[ -z "\${GH_FAIL:-}" ] || exit 1
[ "\$1 \$2" = "pr list" ] || exit 1
head=""
while [ \$# -gt 0 ]; do
  [ "\$1" = "--head" ] && head=\$2
  shift
done
python3 - "\$head" "$WORK/prs" <<'PY'
import json, os, sys
head, path = sys.argv[1:3]
out = []
if os.path.exists(path):
    for line in open(path):
        parts = line.split()
        if len(parts) >= 2 and parts[0] == head:
            out.append({"state": parts[1], "headRefOid": parts[2] if len(parts) > 2 else ""})
print(json.dumps(out))
PY
SH
chmod +x "$WORK/bin/gh"
PATH="$WORK/bin:$PATH"
export PATH
: > "$WORK/prs"

run() {
  # run <project> <args...>: the script from the project's main folder.
  dir=$1
  shift
  (cd "$dir" && sh "$SCRIPT" "$@")
}
pr() { printf '%s\n' "$*" >> "$WORK/prs"; }
branch_of() { git -C "$1" symbolic-ref --short HEAD; }

# project <dir> <gitignore>: a project with a remote, main pushed, and a .env
# holding a secret the rehearsal never prints.
project() {
  git init -q --bare -b main "$1.git"
  git init -q -b main "$1"
  git -C "$1" config user.email "worktree@example.invalid"
  git -C "$1" config user.name "Worktree rehearsal"
  git -C "$1" config commit.gpgsign false
  cp "$2" "$1/.gitignore"
  # A Next.js project keeps its keys in .env.local, and ignores it.
  echo ".env.local" >> "$1/.gitignore"
  echo "tool" > "$1/tool.txt"
  echo "SAMPLE_KEY=" > "$1/.env.example"
  git -C "$1" add -A
  git -C "$1" commit -q -m "Project"
  git -C "$1" remote add origin "$1.git"
  git -C "$1" push -q -u origin main 2>/dev/null
  echo "SECRET_KEY=not-a-real-secret" > "$1/.env"
  echo "LOCAL_KEY=not-a-real-secret" > "$1/.env.local"
}

# commit_in <worktree> <file>: one saved change in a worktree.
commit_in() {
  echo "$2" > "$1/$2"
  git -C "$1" add "$2"
  git -C "$1" commit -q -m "Build $2"
}

P="$WORK/project"
project "$P" "$IGNORE"

echo "== Opening a worktree =="

out=$(run "$P" open 12-invoice-list 12-invoice-list origin/main)
W="$P/.agents/worktrees/12-invoice-list"
[ -d "$W" ] && r=yes || r=no
check "a run's piece gets a worktree at .agents/worktrees/<number>-<name>" "$r"
[ "$(branch_of "$W")" = 12-invoice-list ] && r=yes || r=no
check "the worktree is on the piece's branch" "$r"
[ "$(branch_of "$P")" = main ] && r=yes || r=no
check "the main folder stays on main" "$r"
git -C "$P" check-ignore -q .agents/worktrees/12-invoice-list && r=yes || r=no
check "git ignores the worktree folder" "$r"
[ -z "$(git -C "$P" status --porcelain)" ] && r=yes || r=no
check "nothing tracked changed in the main folder" "$r"
[ -z "$(git -C "$W" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)" ] && r=yes || r=no
check "the piece's branch does not track main" "$r"

[ -L "$W/.env" ] && [ -L "$W/.env.local" ] && r=yes || r=no
check "the worktree's .env and .env.local are links" "$r"
[ "$(readlink "$W/.env")" = "../../../.env" ] && \
  [ "$(cd "$W/../../.." && pwd -P)" = "$(cd "$P" && pwd -P)" ] && r=yes || r=no
check "the link leads to the main folder's .env" "$r"
cmp -s "$W/.env" "$P/.env" && r=yes || r=no
check "the worktree reads the main folder's secret through the link" "$r"
[ ! -L "$W/.env.example" ] && [ -f "$W/.env.example" ] && r=yes || r=no
check "a tracked .env.example is checked out, not linked" "$r"
copies=$(find "$WORK" -name '.env' -type f | grep -v "^$P/.env\$" || true)
[ -z "$copies" ] && r=yes || r=no
check "no copy of .env exists outside the main folder" "$r"
case $out in *"Linked"*) r=yes ;; *) r=no ;; esac
check "it says the .env was linked" "$r"
[ -z "$(git -C "$W" status --porcelain)" ] && r=yes || r=no
check "the links are not unsaved work" "$r"

echo "== A piece that stacks on another =="

commit_in "$W" days.txt
run "$P" open 13-overdue-list 13-overdue-list 12-invoice-list >/dev/null
S="$P/.agents/worktrees/13-overdue-list"
git -C "$S" merge-base --is-ancestor 12-invoice-list HEAD && r=yes || r=no
check "a stacked piece's worktree starts from its base piece's branch" "$r"
[ "$(branch_of "$P")" = main ] && r=yes || r=no
check "the main folder is still on main" "$r"

echo "== What counts as unsaved =="

run "$P" unsaved "$W" >/dev/null 2>&1 && r=no || r=yes
check "a commit missing from the remote is unsaved work" "$r"
git -C "$W" push -q -u origin 12-invoice-list 2>/dev/null
run "$P" unsaved "$W" >/dev/null 2>&1 && r=yes || r=no
check "once pushed, nothing is unsaved" "$r"
echo "draft" > "$W/draft.txt"
run "$P" unsaved "$W" >/dev/null 2>&1 && r=no || r=yes
check "a new file git does not ignore is unsaved work" "$r"
rm -f "$W/draft.txt"

echo "== A path already there =="

out=$(run "$P" open 12-invoice-list 12-invoice-list origin/main) && code=0 || code=$?
[ "$code" -eq 0 ] && case $out in *Reused*) true ;; *) false ;; esac && r=yes || r=no
check "a worktree on the same branch with nothing unsaved is reused" "$r"
out=$(run "$P" open 12-invoice-list 99-something-else origin/main) && code=0 || code=$?
[ "$code" -eq 1 ] && case $out in *"Skip this piece"*"12-invoice-list"*) true ;; *) false ;; esac && r=yes || r=no
check "a worktree on another branch is named and the piece skipped" "$r"
echo "half done" > "$W/half.txt"
out=$(run "$P" open 12-invoice-list 12-invoice-list origin/main) && code=0 || code=$?
[ "$code" -eq 1 ] && [ -f "$W/half.txt" ] && case $out in *"unsaved work"*) true ;; *) false ;; esac && r=yes || r=no
check "a worktree holding unsaved work is named, kept, and the piece skipped" "$r"
out=$(run "$P" open --resume 12-invoice-list 12-invoice-list origin/main) && code=0 || code=$?
[ "$code" -eq 1 ] && [ -f "$W/half.txt" ] && r=yes || r=no
check "a resumed piece with uncommitted changes is not reused over them" "$r"
rm -f "$W/half.txt"
commit_in "$W" more.txt
out=$(run "$P" open --resume 12-invoice-list 12-invoice-list origin/main) && code=0 || code=$?
[ "$code" -eq 0 ] && r=yes || r=no
check "a resumed piece reuses its worktree over its own unpushed commits" "$r"
git -C "$W" push -q origin 12-invoice-list 2>/dev/null
mkdir -p "$P/.agents/worktrees/14-stray"
echo x > "$P/.agents/worktrees/14-stray/file"
out=$(run "$P" open 14-stray 14-stray origin/main) && code=0 || code=$?
[ "$code" -eq 1 ] && [ -f "$P/.agents/worktrees/14-stray/file" ] && r=yes || r=no
check "a folder that is not a worktree is left alone and the piece skipped" "$r"

echo "== A branch that already exists =="

git -C "$P" branch -q --no-track 15-parked-before origin/main
run "$P" open 15-parked-before 15-parked-before origin/main >/dev/null
[ "$(branch_of "$P/.agents/worktrees/15-parked-before")" = 15-parked-before ] && r=yes || r=no
check "a piece whose branch exists continues on it" "$r"

echo "== Clearing worktrees away =="

# 12: merged, pushed, nothing unsaved. 13: closed with an uncommitted change.
# 15: merged, with a commit that never reached the remote. 16: open.
# 17: merged, its remote branch since deleted, its head the merged commit.
run "$P" open 16-open-piece 16-open-piece origin/main >/dev/null
run "$P" open 17-squashed 17-squashed origin/main >/dev/null
commit_in "$P/.agents/worktrees/17-squashed" squash.txt
pr "12-invoice-list MERGED $(git -C "$W" rev-parse HEAD)"
pr "13-overdue-list CLOSED"
echo "unsaved" > "$S/unsaved.txt"
commit_in "$P/.agents/worktrees/15-parked-before" local.txt
pr "15-parked-before MERGED $(git -C "$P" rev-parse origin/main)"
pr "16-open-piece OPEN"
pr "17-squashed MERGED $(git -C "$P/.agents/worktrees/17-squashed" rev-parse HEAD)"

out=$(GH_FAIL=1; export GH_FAIL; run "$P" tidy)
[ -d "$W" ] && case $out in *"Could not read"*) true ;; *) false ;; esac && r=yes || r=no
check "with no pull requests to read, nothing is removed" "$r"

out=$(run "$P" tidy)
[ ! -d "$W" ] && r=yes || r=no
check "a merged piece's worktree with nothing unsaved is removed" "$r"
git -C "$P" show-ref --verify -q refs/heads/12-invoice-list && r=yes || r=no
check "its branch is kept" "$r"
[ -f "$P/.env" ] && grep -q SECRET_KEY "$P/.env" && r=yes || r=no
check "the main folder's .env survives the removal" "$r"
[ -d "$S" ] && [ -f "$S/unsaved.txt" ] && case $out in *"Kept .agents/worktrees/13-overdue-list"*"unsaved"*) true ;; *) false ;; esac && r=yes || r=no
check "a closed piece's worktree holding an uncommitted change is kept and named" "$r"
[ -d "$P/.agents/worktrees/15-parked-before" ] && case $out in *"Kept .agents/worktrees/15-parked-before"*"commit"*) true ;; *) false ;; esac && r=yes || r=no
check "a merged piece's worktree holding an unpushed commit is kept and named" "$r"
[ -d "$P/.agents/worktrees/16-open-piece" ] && case $out in *16-open-piece*) false ;; *) true ;; esac && r=yes || r=no
check "an open pull request's worktree is left alone, and not mentioned" "$r"
[ ! -d "$P/.agents/worktrees/17-squashed" ] && r=yes || r=no
check "a merged piece whose remote branch is gone counts its merged commit as saved" "$r"
[ "$(branch_of "$P")" = main ] && [ -z "$(git -C "$P" status --porcelain)" ] && r=yes || r=no
check "the main folder is still on main, with nothing changed" "$r"

echo "== A run still building a piece =="

mkdir -p "$P/.agents/runs/2026-09-30-221500"
run "$P" open 18-in-a-run 18-in-a-run origin/main >/dev/null
pr "18-in-a-run CLOSED"
cat > "$P/.agents/runs/2026-09-30-221500/state.json" <<'JSON'
{"run": "2026-09-30-221500", "merge_preapproved": false, "pieces": [
 {"number": 18, "state": "building", "branch": "18-in-a-run", "base": "main",
  "worktree": ".agents/worktrees/18-in-a-run", "port": null, "pull_request": null,
  "attempts": 0, "flags": [], "reason": ""}]}
JSON
run "$P" tidy >/dev/null
[ -d "$P/.agents/worktrees/18-in-a-run" ] && r=yes || r=no
check "a worktree an unfinished run is building is never removed" "$r"
[ -z "$(git -C "$P" status --porcelain)" ] && r=yes || r=no
check "the run state in the main folder is not tracked" "$r"

echo "== Leftovers and removing one on a yes =="

rm -f "$S/unsaved.txt"
run "$P" open 19-never-opened 19-never-opened origin/main >/dev/null
out=$(run "$P" leftovers)
case $out in *13-overdue-list*"nothing in it is unsaved"*) r=yes ;; *) r=no ;; esac
check "a closed pull request's worktree is listed as a leftover" "$r"
case $out in *19-never-opened*"no pull request"*) r=yes ;; *) r=no ;; esac
check "a worktree with no pull request is listed as a leftover" "$r"
case $out in *15-parked-before*"unsaved work"*) r=yes ;; *) r=no ;; esac
check "a leftover holding unsaved work says so" "$r"
case $out in *16-open-piece*) r=no ;; *) r=yes ;; esac
check "an open pull request's worktree is not a leftover" "$r"
case $out in *18-in-a-run*) r=no ;; *) r=yes ;; esac
check "a worktree a run is building is not a leftover" "$r"
[ -d "$S" ] && [ -d "$P/.agents/worktrees/19-never-opened" ] && r=yes || r=no
check "listing leftovers removes nothing" "$r"

run "$P" remove "$S" >/dev/null
[ ! -d "$S" ] && git -C "$P" show-ref --verify -q refs/heads/13-overdue-list && r=yes || r=no
check "a leftover is removed on a yes, and its branch kept" "$r"
out=$(run "$P" remove "$P/.agents/worktrees/15-parked-before") && code=0 || code=$?
[ "$code" -eq 1 ] && [ -d "$P/.agents/worktrees/15-parked-before" ] && r=yes || r=no
check "a leftover holding unsaved work is kept, even on a yes" "$r"
out=$(run "$P" remove "$P/.agents/worktrees/16-open-piece") && code=0 || code=$?
[ "$code" -eq 1 ] && [ -d "$P/.agents/worktrees/16-open-piece" ] && r=yes || r=no
check "a worktree whose pull request is open is not removed" "$r"
out=$(run "$P" remove "$P/.agents/worktrees/18-in-a-run") && code=0 || code=$?
[ "$code" -eq 1 ] && [ -d "$P/.agents/worktrees/18-in-a-run" ] && r=yes || r=no
check "a worktree a run is building is not removed" "$r"
out=$(run "$P" remove "$P") && code=0 || code=$?
[ "$code" -eq 1 ] && [ -d "$P/.git" ] && r=yes || r=no
check "the main folder itself can never be removed" "$r"

if grep -E 'worktree remove.*(--force|(^| )-f( |$))' "$WORK/git.log" >/dev/null; then
  fail "a worktree was removed by force"
fi
ok "no worktree was ever removed by force"
if grep -E '^(branch -[dD]|push .*--delete)' "$WORK/git.log" >/dev/null; then
  fail "a branch was deleted"
fi
ok "no branch was ever deleted"
if grep -E '^(checkout|switch) ' "$WORK/git.log" >/dev/null; then
  fail "a branch was checked out"
fi
ok "the script never checks a branch out"

echo "== No .env, and no ignore line =="

Q="$WORK/bare-project"
grep -v '^\.agents/worktrees/$' "$IGNORE" > "$WORK/gitignore-older"
project "$Q" "$WORK/gitignore-older"
rm -f "$Q/.env" "$Q/.env.local"
out=$(run "$Q" open 21-first 21-first origin/main)
[ ! -e "$Q/.agents/worktrees/21-first/.env" ] && case $out in *"nothing was linked"*) true ;; *) false ;; esac && r=yes || r=no
check "with no .env in the main folder, nothing is linked" "$r"
git -C "$Q" check-ignore -q .agents/worktrees/21-first && [ -f "$Q/.agents/worktrees/.gitignore" ] && r=yes || r=no
check "an older project with no ignore line gets a folder that ignores itself" "$r"
[ -z "$(git -C "$Q" status --porcelain)" ] && r=yes || r=no
check "and nothing tracked changes" "$r"

echo "== A link that cannot be made =="

mkdir -p "$WORK/noln"
printf '#!/usr/bin/env sh\nexit 1\n' > "$WORK/noln/ln"
chmod +x "$WORK/noln/ln"
echo "SECRET_KEY=not-a-real-secret" > "$Q/.env"
out=$(PATH="$WORK/noln:$PATH"; export PATH; run "$Q" open 22-no-link 22-no-link origin/main) && code=0 || code=$?
[ "$code" -eq 0 ] && [ ! -e "$Q/.agents/worktrees/22-no-link/.env" ] && r=yes || r=no
check "where the link cannot be made, no copy is made either" "$r"
case $out in *"runs without secrets"*"flag anything"*) r=yes ;; *) r=no ;; esac
check "it says the piece runs without secrets and to flag what needs a key" "$r"

echo "== A free port =="

port=$(run "$Q" port 12)
case $port in '' | *[!0-9]*) r=no ;; *) r=yes ;; esac
check "the port step prints a port" "$r"
python3 - "$port" "$WORK/listening" <<'PY' &
import socket, sys, time
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", int(sys.argv[1])))
s.listen(1)
open(sys.argv[2], "w").write("ready")
time.sleep(20)
PY
listener=$!
tries=0
while [ ! -f "$WORK/listening" ] && [ $tries -lt 50 ]; do
  python3 -c 'import time; time.sleep(0.1)'
  tries=$((tries + 1))
done
second=$(run "$Q" port 12)
kill "$listener" 2>/dev/null || true
[ -n "$second" ] && [ "$second" != "$port" ] && r=yes || r=no
check "a port something is listening on is never given" "$r"

echo
echo "kit-owns-worktrees-rehearsal.sh: all $pass checks passed"
