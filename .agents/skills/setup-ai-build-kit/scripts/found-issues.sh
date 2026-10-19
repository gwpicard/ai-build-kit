#!/usr/bin/env sh
# found-issues.sh: prepare the project's GitHub repository for its pieces.
#
# Usage, from the project root:
#   sh found-issues.sh check     read only: which repository, and whether it is
#                                public or private
#   sh found-issues.sh prepare   the same read, then the kit's labels, the
#                                repository settings and the issue template
#   sh found-issues.sh refresh   print the plan once the issues are open
#
# Every mode first reads where origin points, and the repository is always the
# one origin names. The GitHub tool's own default is never used, since it can
# be another remote, such as the one a project was copied from. On the kit's
# own repository it changes nothing there, since a project's pieces must never
# land on it. An origin that is not on GitHub changes nothing either.
#
# prepare does this, in order:
#   - creates the fifteen labels the kit owns;
#   - deletes the nine labels GitHub makes on a new repository, only while the
#     repository holds no issue, since before that nobody can be using them;
#   - turns on deleting a merged branch and turns off squash and rebase
#     merges, so a merge keeps a piece's commits;
#   - copies the piece template to .github/ISSUE_TEMPLATE/piece.yml, unless a
#     file is already there.
#   - requires the project-check job on main, with admins included, when main
#     exists. A first upload applies it as soon as main is created.
#
# Output lines have fields separated by tabs:
#   repository  OWNER/NAME
#   visibility  private | public | internal | unknown
#   labels      created
#   removed     NAMES        GitHub's own labels deleted, or "none"
#   kept        NAMES        GitHub's own labels that could not be deleted
#   settings    set | not set
#   template    copied | kept
#
# Exit 0: done, or read. A label or setting GitHub refused is named in its
#         line and does not stop the rest.
# Exit 5: GitHub could not be read, so nothing was changed.
# Exit 6: origin is the kit's own repository, so nothing was changed.
# Exit 2: usage error, missing admin rights or refused protection settings.
#         An unreadable protection check is recorded and does not stop founding.

set -u

SKILL_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
KIT=gwpicard/ai-build-kit

mode=${1:-}
case "$mode" in check|prepare|refresh) ;; *) echo "usage: found-issues.sh check|prepare|refresh" >&2; exit 2 ;; esac
[ "$#" -eq 1 ] || { echo "usage: found-issues.sh check|prepare|refresh" >&2; exit 2; }

command -v gh >/dev/null 2>&1 || { echo "found-issues: the GitHub command line tool is not installed" >&2; exit 5; }
command -v python3 >/dev/null 2>&1 || { echo "found-issues: python3 is needed to read GitHub's answers" >&2; exit 5; }

lower() { printf '%s' "$1" | python3 -c 'import sys; print(sys.stdin.read().strip().lower())'; }

# The URL as written, before any insteadOf rewrite, names the repository.
origin=$(git config --get remote.origin.url 2>/dev/null || true)
repo=$(printf '%s' "$origin" | python3 -c '
import re, sys
m = re.search(r"github\.com[:/]+([^/\s]+)/([^/\s]+?)(?:\.git)?/?$", sys.stdin.read().strip(), re.I)
print("%s/%s" % (m.group(1), m.group(2)) if m else "")
')
if [ "$(lower "$repo")" = "$KIT" ]; then
  echo "repository	$KIT"
  echo "found-issues: origin is the kit's own repository, so nothing was changed there"
  exit 6
fi
[ -n "$repo" ] || {
  echo "found-issues: origin does not point at a GitHub repository, so nothing was changed" >&2
  exit 5
}

view=$(gh repo view "$repo" --json visibility 2>/dev/null) || {
  echo "found-issues: GitHub could not read $repo, so nothing was changed" >&2
  exit 5
}
visibility=$(printf '%s' "$view" | python3 -c 'import json, sys; print((json.load(sys.stdin).get("visibility") or "unknown").lower())' 2>/dev/null || echo unknown)
echo "repository	$repo"
echo "visibility	$visibility"

[ "$mode" = check ] && exit 0

if [ "$mode" = refresh ]; then
  [ -f .agents/tools/plan-refresh.sh ] || { echo "found-issues: .agents/tools/plan-refresh.sh is missing" >&2; exit 2; }
  sh .agents/tools/plan-refresh.sh
  exit $?
fi

protection_status=0
protection_could_not_run=0
protection_output=$(python3 "$SKILL_ROOT/../merge/scripts/protect-branch.py" --defer-missing "$repo" main 2>&1) || protection_status=$?
case "$protection_status" in
  0|3|6) printf '%s\n' "$protection_output" ;;
  4|5) printf 'protection\tdeferred until first upload creates main\n' ;;
  *)
    printf '%s\n' "$protection_output" >&2
    protection_could_not_run=1
    ;;
esac

# The fifteen labels the kit owns, as name|colour|description.
failed=
while IFS='|' read -r name colour description; do
  [ -n "$name" ] || continue
  gh label create "$name" --color "$colour" --description "$description" --force --repo "$repo" >/dev/null 2>&1 ||
    failed="$failed${failed:+, }$name"
done <<'LABELS'
visual|1d76db|The interface, what people see and click
how it works|5319e7|The rules and logic
data|0e8a16|Information the tool stores
accounts and permissions|b60205|Who can get in and what they can see
finance|fbca04|Charging, refunds, pricing, invoices
external service|c5def5|Somebody else's system this piece needs
background automation|bfd4f2|Something that runs on its own
building|0052cc|Somebody is working on it
blocked|d93f0b|Something outside the project holds it up
parked|cccccc|An idea deliberately left out
broken|e11d21|Repairs something that used to work
needs-clarification|f9d0c4|Talking it through will settle it
needs-prototype|f9d0c4|Something to look at will settle it
needs-research|f9d0c4|A fact or existing work from outside will settle it
ready|0e8a16|Shaped and waiting to be built
LABELS
if [ -z "$failed" ]; then
  echo "labels	created"
else
  echo "labels	created, except	$failed"
fi

# GitHub's own nine labels go only while no issue can be wearing one.
issues=$(gh issue list --state all --limit 1 --json number --repo "$repo" 2>/dev/null || echo error)
removed=
kept=
case "$issues" in
  "[]"|"")
    for name in bug documentation duplicate enhancement "good first issue" "help wanted" invalid question wontfix; do
      if out=$(gh label delete "$name" --yes --repo "$repo" 2>&1); then
        removed="$removed${removed:+, }$name"
      else
        case "$out" in
          *"not found"*|*"Not Found"*|*404*) ;;
          *) kept="$kept${kept:+, }$name" ;;
        esac
      fi
    done
    echo "removed	${removed:-none}"
    [ -z "$kept" ] || echo "kept	$kept"
    ;;
  *)
    echo "removed	none	the repository already holds issues, so GitHub's own labels stay"
    ;;
esac

if gh api -X PATCH "repos/$repo" -F delete_branch_on_merge=true -F allow_squash_merge=false -F allow_rebase_merge=false >/dev/null 2>&1; then
  echo "settings	set"
else
  echo "settings	not set"
fi

if [ -e .github/ISSUE_TEMPLATE/piece.yml ] || [ -L .github/ISSUE_TEMPLATE/piece.yml ]; then
  echo "template	kept"
else
  mkdir -p .github/ISSUE_TEMPLATE &&
    cp "$SKILL_ROOT/templates/foundation/piece-issue.yml" .github/ISSUE_TEMPLATE/piece.yml &&
    echo "template	copied" || echo "template	not copied"
fi
# Missing admin rights or refused settings still stop founding after prepare.
[ "$protection_could_not_run" -eq 0 ] || exit 2
exit 0
