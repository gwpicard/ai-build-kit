#!/usr/bin/env sh
# found-issues.sh: run founding's GitHub preparation against a stand-in for the
# GitHub command line tool.
#
# If this breaks, a project's labels and settings land on the kit's own
# repository, a piece is merged by squashing and leaves the masterplan's mark
# outside main, GitHub's own labels are deleted from a repository somebody
# already uses, or the person is told the plan is private when it is public.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SKILL="$ROOT/.agents/skills/setup-ai-build-kit"
SCRIPT="$SKILL/scripts/found-issues.sh"

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

DEFAULTS='["bug", "documentation", "duplicate", "enhancement", "good first issue", "help wanted", "invalid", "question", "wontfix"]'

project() {
  rm -rf "$WORK/p"
  mkdir -p "$WORK/p/.agents/tools"
  git -C "$WORK/p" init -q
  git -C "$WORK/p" remote add origin "$1"
  printf '#!/bin/sh\necho "plan printed"\n' > "$WORK/p/.agents/tools/plan-refresh.sh"
}
state() {
  # state <repo> <visibility> <issues json> [refused labels json] [view fails] [branches json]
  python3 - "$STANDIN_GH_STATE" "$1" "$2" "$3" "${4:-[]}" "${5:-false}" "$DEFAULTS" "${6:-[]}" <<'PY'
import json, sys
path, repo, visibility, issues, refuse, fails, defaults, branches = sys.argv[1:]
json.dump({"repo": repo, "visibility": visibility, "issues": json.loads(issues),
           "labels": json.loads(defaults), "refuse": json.loads(refuse),
           "view_fails": fails == "true", "branches": json.loads(branches)}, open(path, "w"))
PY
  : > "$STANDIN_GH_LOG"
}
get() { python3 -c 'import json,sys; v=json.load(open(sys.argv[1])).get(sys.argv[2]); print(json.dumps(v, sort_keys=True))' "$STANDIN_GH_STATE" "$1"; }
run() { (cd "$WORK/p" && PATH="$WORK/bin:$PATH" sh "$SCRIPT" "$@"); }
changed() { grep -E '^(label|api|issue edit|repo edit)' "$STANDIN_GH_LOG" || true; }

echo "== The kit's own repository =="
for url in https://github.com/gwpicard/ai-build-kit.git git@github.com:GWPicard/AI-Build-Kit https://github.com/gwpicard/ai-build-kit; do
  project "$url"
  state gwpicard/ai-build-kit PUBLIC '{}'
  out=$(run prepare) && code=0 || code=$?
  [ "$code" -eq 6 ] && [ -z "$(changed)" ] && [ ! -e "$WORK/p/.github" ] \
    && pass "origin $url changes nothing on GitHub or in the project" \
    || fail "origin $url returned $code and asked: $(changed)"
done
project /somewhere/else.git
state gwpicard/ai-build-kit PUBLIC '{}'
out=$(run prepare 2>&1) && code=0 || code=$?
[ "$code" -eq 5 ] && [ -z "$(changed)" ] \
  && pass "an origin that is not on GitHub changes nothing, whatever the tool's default is" \
  || fail "an origin off GitHub returned $code and asked: $(changed)"
project https://github.com/someone/ai-build-kit-fork.git
state someone/ai-build-kit-fork PRIVATE '{}'
out=$(run check) && code=0 || code=$?
[ "$code" -eq 0 ] && pass "a name that only starts like the kit's is left alone" || fail "a lookalike name returned $code"

echo "== Reading =="
project https://github.com/someone/kit-log.git
state someone/kit-log PUBLIC '{}'
out=$(run check) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'repository	someone/kit-log' \
  && printf '%s\n' "$out" | grep -qx 'visibility	public' && [ -z "$(changed)" ] \
  && pass "check names the repository and says it is public, and changes nothing" \
  || fail "check returned $code: $out / $(changed)"
state someone/kit-log PRIVATE '{}' '[]' true
out=$(run prepare 2>&1) && code=0 || code=$?
[ "$code" -eq 5 ] && [ -z "$(changed)" ] \
  && pass "a GitHub that cannot be read changes nothing" \
  || fail "an unreadable GitHub returned $code: $(changed)"

echo "== Preparing a new repository =="
state someone/kit-log PRIVATE '{}'
out=$(run prepare) && code=0 || code=$?
labels=$(get labels)
[ "$code" -eq 0 ] && [ "$(python3 -c 'import json,sys; print(len(json.loads(sys.argv[1])))' "$labels")" -eq 15 ] \
  && pass "the fifteen kit labels are created and GitHub's nine are gone" \
  || fail "the repository has $labels after prepare, exit $code: $out"
printf '%s\n' "$out" | grep -q '^removed	bug, documentation' \
  && pass "it names the labels it deleted" || fail "the deleted labels were not named: $out"
[ "$(get settings)" = '{"allow_rebase_merge": "false", "allow_squash_merge": "false", "delete_branch_on_merge": "true"}' ] \
  && pass "merged branches go, and squash and rebase merges are off" \
  || fail "the settings were $(get settings)"
[ "$(get protection)" = null ] && printf '%s\n' "$out" | grep -qx 'protection\tdeferred until first upload creates main' \
  && ! grep -q 'branches/main/protection' "$STANDIN_GH_LOG" \
  && pass "protection waits until the first upload creates main" \
  || fail "protection ran before main existed: $(get protection) / $out"

body='{"required_status_checks":{"strict":true,"contexts":["project-check"]},"enforce_admins":true,"required_pull_request_reviews":null,"restrictions":null}'
out=$(printf '%s' "$body" | PATH="$WORK/bin:$PATH" gh api -X PUT repos/someone/kit-log/branches/main/protection --input - 2>&1) && code=0 || code=$?
[ "$code" -ne 0 ] && printf '%s' "$out" | grep -q 'HTTP 404: Branch not found' \
  && pass "the GitHub stand-in rejects protection for a branch that does not exist" \
  || fail "the stand-in accepted a missing branch: $out"
out=$(PATH="$WORK/bin:$PATH" STANDIN_GH_STATE="$STANDIN_GH_STATE" python3 "$ROOT/.agents/skills/merge/scripts/protect-branch.py" someone/kit-log main 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && printf '%s' "$out" | grep -Fq 'GitHub says main does not exist, so the check could not be required.' \
  && pass "a missing branch has its own protection error and exits 2" \
  || fail "a missing branch returned $code: $out"

state someone/kit-log PRIVATE '{}' '[]' false '["main"]'
out=$(printf '%s' '{"required_status_checks":{"strict":true,"contexts":["project-check"]}}' | PATH="$WORK/bin:$PATH" gh api -X PUT repos/someone/kit-log/branches/main/protection --input - 2>&1) && code=0 || code=$?
[ "$code" -ne 0 ] && printf '%s' "$out" | grep -q 'HTTP 422: missing required branch protection keys' \
  && pass "the GitHub stand-in rejects a protection body missing required keys" \
  || fail "the stand-in accepted an incomplete body: $out"

state someone/kit-log PRIVATE '{}' '[]' false '["main"]'
out=$(run prepare) && code=0 || code=$?
[ "$code" -eq 0 ] \
  && [ "$(get protection)" = '{"enforce_admins": true, "required_pull_request_reviews": null, "required_status_checks": {"contexts": ["project-check"], "strict": true}, "restrictions": null}' ] \
  && grep -q '^api -X PUT repos/someone/kit-log/branches/main/protection --input -' "$STANDIN_GH_LOG" \
  && pass "an existing main gets the complete four-key protection body" \
  || fail "full branch protection was not required: $(get protection) / $out"

python3 - "$STANDIN_GH_STATE" <<'PY'
import json, sys
p = sys.argv[1]
s = json.load(open(p))
s["protection"] = {"required_status_checks": {"strict": False, "contexts": ["other-check"]},
                   "enforce_admins": False, "required_pull_request_reviews": {"required_approving_review_count": 2},
                   "restrictions": None, "other_setting": "kept"}
json.dump(s, open(p, "w"))
PY
: > "$STANDIN_GH_LOG"
out=$(run prepare) && code=0 || code=$?
[ "$code" -eq 0 ] \
  && [ "$(get protection)" = '{"enforce_admins": true, "other_setting": "kept", "required_pull_request_reviews": {"required_approving_review_count": 2}, "required_status_checks": {"contexts": ["other-check", "project-check"], "strict": false}, "restrictions": null}' ] \
  && grep -q 'POST repos/someone/kit-log/branches/main/protection/required_status_checks/contexts' "$STANDIN_GH_LOG" \
  && grep -q 'POST repos/someone/kit-log/branches/main/protection/enforce_admins' "$STANDIN_GH_LOG" \
  && ! grep -q 'api -X PUT' "$STANDIN_GH_LOG" \
  && pass "existing protection is preserved while the check and admins are added" \
  || fail "existing protection was replaced or not updated: $(get protection) / $out"
cmp -s "$SKILL/templates/foundation/piece-issue.yml" "$WORK/p/.github/ISSUE_TEMPLATE/piece.yml" \
  && pass "the piece template is copied into the project" || fail "the piece template was not copied"

state someone/kit-log PRIVATE '{}' '[]' false '["main"]'
python3 -c 'import json,sys; p=sys.argv[1]; s=json.load(open(p)); s["protection_status"]="plan"; json.dump(s,open(p,"w"))' "$STANDIN_GH_STATE"
out=$(run prepare 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && printf '%s\n' "$out" | grep -Fq 'GitHub cannot require the check on this private repository with this plan, so the kit will hold the merge itself.' \
  && pass "a plan that cannot protect a private repository names the script hold and exits 2" \
  || fail "a refused branch protection returned $code: $out"

for status_line in 'admin|GitHub could not require the check because this account does not have admin rights.' '422|GitHub rejected the branch protection settings (422), so the check could not be required.' 'network|GitHub could not apply branch protection because of a network error.'; do
  status=${status_line%%|*}
  expected=${status_line#*|}
  state someone/kit-log PRIVATE '{}' '[]' false '["main"]'
  python3 - "$STANDIN_GH_STATE" "$status" <<'PY'
import json, sys
p, status = sys.argv[1:]
s = json.load(open(p)); s["protection_status"] = status; json.dump(s, open(p, "w"))
PY
  out=$(run prepare 2>&1) && code=0 || code=$?
  [ "$code" -eq 2 ] && printf '%s\n' "$out" | grep -Fq "$expected" \
    && pass "${status} protection failure has its own plain line and exits 2" \
    || fail "${status} protection failure returned $code: $out"
done

printf 'mine\n' > "$WORK/p/.github/ISSUE_TEMPLATE/piece.yml"
state someone/kit-log PRIVATE '{"1": {"body": "", "labels": ["bug"]}}' '["wontfix"]'
out=$(run prepare) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s' "$(get labels)" | grep -q '"bug"' && ! grep -q '^label delete' "$STANDIN_GH_LOG" \
  && pass "once an issue exists, GitHub's own labels are left alone" \
  || fail "labels were deleted from a repository already in use: $(get labels)"
[ "$(cat "$WORK/p/.github/ISSUE_TEMPLATE/piece.yml")" = mine ] && printf '%s\n' "$out" | grep -qx 'template	kept' \
  && pass "an issue template already there is kept" || fail "an existing template was replaced"

state someone/kit-log PRIVATE '{}' '["wontfix"]'
out=$(run prepare) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'kept	wontfix' \
  && pass "a label GitHub will not delete is named and the rest carries on" \
  || fail "a refused delete was not reported: $code $out"

echo "== The repository is the one origin names =="
python3 -c 'import json,sys; s=json.load(open(sys.argv[1])); s["default_repo"]="upstream/kit-log"; json.dump(s,open(sys.argv[1],"w"))' "$STANDIN_GH_STATE"
: > "$STANDIN_GH_LOG"
out=$(run prepare) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'repository	someone/kit-log' \
  && grep -q '^api -X PATCH repos/someone/kit-log ' "$STANDIN_GH_LOG" \
  && ! grep -q 'upstream/kit-log' "$STANDIN_GH_LOG" \
  && ! grep -E '^(label|issue list)' "$STANDIN_GH_LOG" | grep -vq -- '--repo someone/kit-log' \
  && pass "labels, issues and settings go to the repository origin names, not the tool's default" \
  || fail "with another default repository, prepare used: $out / $(cat "$STANDIN_GH_LOG")"

out=$(run refresh) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s' "$out" | grep -q 'plan printed' \
  && pass "refresh prints the plan" || fail "refresh returned $code: $out"

[ "$FAIL" -eq 0 ] || exit 1
echo "found-issues.sh: all checks passed"
