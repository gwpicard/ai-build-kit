#!/usr/bin/env sh
# check-tooling.sh: say whether the tools the kit itself needs are ready, before
# setup leans on them.
#
# The kit keeps a project's pieces as GitHub issues and prints them with a small
# Python filter, so three tools have to be here before the pieces can be founded:
# Git, the GitHub command line tool, and python3. This reports which are ready
# and which are not, in plain words, and stops with a non-zero result when one
# that blocks founding is missing, so a gap is caught here rather than at the
# later step that creates the issues.
#
# It changes nothing. It reaches no further than the sign-in and repository
# lookups the report needs.
#
# jq is not required. The kit filters JSON with python3 on purpose, which is
# also what lets the test harness stand in for the GitHub command line tool.
#
# Run from anywhere inside the project.

set -eu

blocked=0

# 1. The tools the kit's own scripts run.
if command -v git >/dev/null 2>&1; then
  echo "Git is ready: the kit saves each project version with it."
else
  echo "Git is missing: install it so the kit can save project versions. See manual-setup.md."
  blocked=1
fi

if command -v python3 >/dev/null 2>&1; then
  echo "python3 is ready: the kit reads the issue list with it to print your pieces."
else
  echo "python3 is missing: install it so the kit can print your pieces. See manual-setup.md."
  blocked=1
fi

gh_ready=no
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    echo "The GitHub command line tool is ready: your pieces are kept as issues, and you are signed in."
    gh_ready=yes
  else
    echo "The GitHub command line tool is installed but nobody is signed in: sign in before the pieces are founded. See manual-setup.md."
    blocked=1
  fi
else
  echo "The GitHub command line tool is missing: install it and sign in, because the pieces are kept as issues. See manual-setup.md."
  blocked=1
fi

# 2. What the signed-in account can do on this repository, once one is set up.
# These need a repository and python3, so they run only when both are here. On a
# fresh project with no repository yet, they wait until one exists.
if [ "$gh_ready" = yes ] && command -v python3 >/dev/null 2>&1; then
  repo_json=$(gh repo view --json nameWithOwner,hasIssuesEnabled,viewerPermission 2>/dev/null || true)
  if [ -n "$repo_json" ]; then
    read_field() {
      printf '%s' "$repo_json" \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('$1',''))" 2>/dev/null \
        || true
    }
    issues_on=$(read_field hasIssuesEnabled)
    perm=$(read_field viewerPermission)

    if [ "$issues_on" = "True" ]; then
      echo "Issues are switched on for this repository."
    else
      echo "Issues are switched off for this repository: say so and offer to switch them on, and do not switch them on yourself."
    fi

    case "$perm" in
      ADMIN | MAINTAIN | WRITE)
        echo "Labels can be put in order: the signed-in account can create and delete labels here." ;;
      *)
        echo "Labels cannot be put in order: the signed-in account cannot create or delete labels here. Say which labels could not be made; a missing label costs a little clarity, it stops nothing." ;;
    esac
  else
    echo "No GitHub repository is set up yet, so the issue and label checks wait until one exists."
  fi
fi

if [ "$blocked" -ne 0 ]; then
  echo "A tool the kit needs to found your pieces is not ready. Set it up before going on." >&2
  exit 1
fi

echo "Every tool the kit needs to found your pieces is ready."
exit 0
