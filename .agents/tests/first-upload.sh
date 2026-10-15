#!/usr/bin/env sh
# first-upload.sh: run implement's first-upload.py against a real bare
# remote and a stand-in for the GitHub command line tool.
#
# Founding tells the person nothing will be uploaded. If this breaks, a piece
# pushes the whole project with no question, pushes it onto a repository
# holding something else, reads a failed listing as an empty repository, or
# writes main with a push the project's guard is meant to stop. The first of
# those happened in a real run.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/merge/scripts/first-upload.py"
HOOK="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/pre-push"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }
pass() { echo "ok: $1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin"
ln -s "$ROOT/.agents/tests/lib/stand-in-gh" "$WORK/bin/gh"
STANDIN_GH_STATE="$WORK/state.json"
STANDIN_GH_LOG="$WORK/gh.log"
export STANDIN_GH_STATE STANDIN_GH_LOG
export GIT_CONFIG_NOSYSTEM=1

P="$WORK/project"
R="$WORK/remote.git"

# A founded project: main with the founding checkpoint, and a piece branch with
# one more commit. The push guard is on, as founding leaves it.
setup() {
  rm -rf "$P" "$R"
  mkdir -p "$P/.agents/hooks/git"
  git -C "$P" init -q -b main
  git -C "$P" config user.name Rehearsal
  git -C "$P" config user.email rehearsal@example.invalid
  git -C "$P" config commit.gpgsign false
  cp "$HOOK" "$P/.agents/hooks/git/pre-push"
  cp "$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/scan-secrets.sh" "$P/.agents/hooks/scan-secrets.sh"
  cp "$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/scan-secrets.py" "$P/.agents/hooks/scan-secrets.py"
  git -C "$P" config core.hooksPath .agents/hooks/git
  printf 'founding\n' > "$P/masterplan.md"
  git -C "$P" add -A
  git -C "$P" commit -q -m "Found the project"
  git -C "$P" checkout -q -b sign-out
  printf 'sign out\n' > "$P/app.txt"
  git -C "$P" add app.txt
  git -C "$P" commit -q -m "Sign an item out"
  git init -q --bare "$R"
  # origin names the GitHub repository, and Git reaches the bare remote next
  # door in its place, so the name comes from origin as it would for real.
  git -C "$P" remote add origin https://github.com/someone/kit-log.git
  git -C "$P" config url."$R".insteadOf https://github.com/someone/kit-log.git
  python3 - "$STANDIN_GH_STATE" "$R" "${1:-PRIVATE}" <<'PY'
import json, sys
json.dump({"repo": "someone/kit-log", "visibility": sys.argv[3], "remote": sys.argv[2],
           "issues": {}, "labels": []}, open(sys.argv[1], "w"))
PY
  : > "$STANDIN_GH_LOG"
}
run() { (cd "$P" && PATH="$WORK/bin:$PATH" python3 "$SCRIPT" "$@"); }
heads() { git -C "$R" for-each-ref --format='%(refname:short)' refs/heads/ | tr '\n' ' '; }
set_state() {
  python3 - "$STANDIN_GH_STATE" "$1" "$2" <<'PY'
import json, sys
state = json.load(open(sys.argv[1]))
state[sys.argv[2]] = json.loads(sys.argv[3])
json.dump(state, open(sys.argv[1], "w"))
PY
}

echo "== The first upload =="
setup
out=$(run) && code=0 || code=$?
[ "$code" -eq 3 ] && printf '%s\n' "$out" | grep -qx 'state	first-upload' \
  && printf '%s\n' "$out" | grep -qx 'repository	someone/kit-log' && printf '%s\n' "$out" | grep -qx 'visibility	private' \
  && pass "an empty repository is the first upload, named with its visibility" \
  || fail "an empty repository read as $code: $out"
[ -z "$(heads)" ] && ! grep -q 'git/refs' "$STANDIN_GH_LOG" \
  && pass "without --approved nothing is pushed or created" \
  || fail "a read uploaded something: $(heads)"

setup PUBLIC
out=$(run) && code=0 || code=$?
printf '%s\n' "$out" | grep -qx 'visibility	public' && pass "a public repository says so" || fail "visibility read as: $out"

setup
base=$(git -C "$P" rev-parse main)
out=$(run --approved) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(heads)" = "main sign-out " ] \
  && pass "on a yes the piece's branch is pushed and main is created" \
  || fail "the approved upload returned $code with remote heads '$(heads)': $out"
[ "$(git -C "$R" rev-parse main)" = "$base" ] \
  && pass "main is created at the commit the piece's branch was cut from, not at the piece" \
  || fail "main on the remote is $(git -C "$R" rev-parse main), not $base"
grep -q 'repos/someone/kit-log/git/refs -f ref=refs/heads/main' "$STANDIN_GH_LOG" \
  && grep -q 'repo edit someone/kit-log --default-branch main' "$STANDIN_GH_LOG" \
  && grep -q 'repos/someone/kit-log/branches/main/protection --input -' "$STANDIN_GH_LOG" \
  && python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["protection"]["required_status_checks"]["contexts"]==["project-check"] and p["protection"]["enforce_admins"] and all(k in p["protection"] for k in ("required_status_checks","enforce_admins","required_pull_request_reviews","restrictions"))' "$STANDIN_GH_STATE" \
  && pass "main is written through the API and made the default branch, with the push guard on" \
  || fail "main was not created through the API: $(cat "$STANDIN_GH_LOG")"

out=$(run) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'state	online' \
  && pass "once a remote branch shares history with main, the code is online" \
  || fail "after the upload the state read $code: $out"
: > "$STANDIN_GH_LOG"
out=$(run --approved) && code=0 || code=$?
[ "$code" -eq 0 ] && ! grep -q 'git/refs' "$STANDIN_GH_LOG" \
  && pass "--approved on a project already online creates nothing" \
  || fail "--approved online created something: $(cat "$STANDIN_GH_LOG")"

echo "== Not the first upload =="
setup
other="$WORK/other"
rm -rf "$other"
git init -q -b main "$other"
git -C "$other" -c user.name=x -c user.email=x@example.invalid -c commit.gpgsign=false commit -q --allow-empty -m "Initial commit"
git -C "$other" push -q "$R" main
out=$(run --approved) && code=0 || code=$?
[ "$code" -eq 4 ] && [ "$(heads)" = "main " ] && ! grep -q 'git/refs' "$STANDIN_GH_LOG" \
  && pass "a repository holding unrelated work gets nothing pushed, even with --approved" \
  || fail "a repository holding other work returned $code, heads '$(heads)'"

setup
git -C "$P" config --unset url."$R".insteadOf
git -C "$P" config url."$WORK/missing.git".insteadOf https://github.com/someone/kit-log.git
out=$(run --approved 2>&1) && code=0 || code=$?
[ "$code" -eq 5 ] && printf '%s\n' "$out" | grep -q '^state	unknown' \
  && pass "a remote that cannot be listed is unknown, never an empty repository" \
  || fail "an unreachable remote returned $code: $out"

setup
git -C "$P" remote remove origin
out=$(run 2>&1) && code=0 || code=$?
[ "$code" -eq 5 ] && pass "no origin is unknown" || fail "no origin returned $code"

setup
git -C "$P" remote set-url origin https://github.com/gwpicard/ai-build-kit.git
out=$(run --approved 2>&1) && code=0 || code=$?
[ "$code" -eq 6 ] && ! grep -q 'git/refs' "$STANDIN_GH_LOG" \
  && pass "the kit's own repository gets nothing" \
  || fail "the kit's repository returned $code"

echo "== A push that fails =="
setup
printf '#!/bin/sh\nexit 1\n' > "$R/hooks/pre-receive"
chmod +x "$R/hooks/pre-receive"
out=$(run --approved 2>&1) && code=0 || code=$?
[ "$code" -eq 7 ] && ! grep -q 'git/refs' "$STANDIN_GH_LOG" \
  && pass "a refused push creates no main" \
  || fail "a refused push returned $code: $out"

setup
git -C "$P" checkout -q main
out=$(run --approved 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && [ -z "$(heads)" ] \
  && pass "standing on main, nothing is pushed" \
  || fail "an upload from main returned $code, heads '$(heads)'"

echo "== The repository is the one origin names =="
setup
set_state default_repo '"upstream/kit-log"'
out=$(run --approved) && code=0 || code=$?
printf '%s\n' "$out" | grep -qx 'repository	someone/kit-log' \
  && grep -q 'repos/someone/kit-log/git/refs' "$STANDIN_GH_LOG" && ! grep -q 'upstream/kit-log' "$STANDIN_GH_LOG" \
  && pass "the repository comes from origin, not from the tool's own default" \
  || fail "with another default repository the script named: $out / $(cat "$STANDIN_GH_LOG")"

setup
git -C "$P" remote set-url origin https://gitlab.com/someone/kit-log.git
out=$(run --approved 2>&1) && code=0 || code=$?
[ "$code" -eq 5 ] && [ -z "$(heads)" ] && ! grep -q 'git/refs' "$STANDIN_GH_LOG" \
  && pass "an origin that is not on GitHub is unknown, and nothing is pushed" \
  || fail "an origin off GitHub returned $code: $out"

echo "== GitHub is checked before anything is pushed =="
setup
set_state view_fails true
out=$(run --approved 2>&1) && code=0 || code=$?
[ "$code" -eq 5 ] && [ -z "$(heads)" ] \
  && pass "a signed-out tool gets nothing pushed, so main is never left uncreated" \
  || fail "a signed-out tool returned $code with remote heads '$(heads)': $out"

setup
set_state permission '"READ"'
out=$(run --approved 2>&1) && code=0 || code=$?
[ "$code" -eq 5 ] && [ -z "$(heads)" ] \
  && pass "an account that cannot write to the repository gets nothing pushed" \
  || fail "a read-only account returned $code with remote heads '$(heads)': $out"

echo "== A branch online but no main =="
setup
set_state api_fails true
base=$(git -C "$P" rev-parse main)
out=$(run --approved 2>&1) && code=0 || code=$?
[ "$code" -eq 8 ] && [ "$(heads)" = "sign-out " ] \
  && pass "when main cannot be created after the push, it says so" \
  || fail "a failed main returned $code with remote heads '$(heads)': $out"
out=$(run 2>&1) && code=0 || code=$?
[ "$code" -eq 9 ] && printf '%s\n' "$out" | grep -q '^state	no-main' \
  && pass "a retry reads the branch online with no main as a state of its own, not online" \
  || fail "the retry read $code: $out"
set_state api_fails false
out=$(run --approved 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(heads)" = "main sign-out " ] && [ "$(git -C "$R" rev-parse main)" = "$base" ] \
  && pass "on a yes, main is created where the piece's branch was cut, with no push" \
  || fail "creating the missing main returned $code with heads '$(heads)': $out"
out=$(run) && code=0 || code=$?
[ "$code" -eq 0 ] && pass "after that the code is online" || fail "after creating main the state read $code: $out"

echo "== Protection can be unavailable after a successful upload =="
for reason in plan admin network; do
  setup
  set_state protection_status "\"$reason\""
  out=$(run --approved 2>&1) && code=0 || code=$?
  [ "$code" -eq 0 ] && [ "$(heads)" = "main sign-out " ] \
    || fail "$reason protection failure treated the upload as failed ($code): $out"
  if [ "$reason" = plan ]; then
    printf '%s\n' "$out" | grep -q 'kit will hold the merge itself' \
      && pass "a GitHub Free plan restriction leaves the upload complete and says the kit holds merges" \
      || fail "the plan restriction did not explain the merge hold: $out"
  else
    printf '%s\n' "$out" | grep -q 'protection could not be set' \
      && pass "$reason protection failure leaves the upload complete with a reason" \
      || fail "$reason protection failure had no explanation: $out"
  fi
done

[ "$FAIL" -eq 0 ] || exit 1
echo "first-upload.sh: all checks passed"
