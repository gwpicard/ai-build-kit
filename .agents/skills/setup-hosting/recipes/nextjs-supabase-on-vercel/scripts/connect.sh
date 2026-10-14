#!/usr/bin/env sh
# connect.sh: set up the Vercel project on a first launch, before anything is
# pushed, and connect it to the project's GitHub repository.
#
# Usage: connect.sh <project name>
#
# In order: `vercel project add <project>`, which sets no framework, then
# `vercel project update <project> --framework nextjs --yes`, since a project
# with no framework fails its first build. `vercel link --project <project>
# --yes` links the folder, and writes `.vercel` and `.env*` into `.gitignore`.
# The `.env*` line also matches `.env.example`, which the repository needs, so
# when `git check-ignore --no-index -v .env.example` names it, `!.env.example`
# goes on the line below. `supabase/.temp` is kept out of git too. Last,
# `vercel git connect --yes` connects the repository, so that each push to
# GitHub builds. The kit never deploys from a local copy in place of it.
#
# Where the repository is private, Vercel's GitHub app has to be allowed to
# see it first, which only its owner can do. Until then the connection fails,
# and this says what the person does.
#
# Exit 0 when the project is connected, 1 when a step failed, 2 when it could
# not run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

project=${1:-}
[ -n "$project" ] || cl_cannot "No name was given for the Vercel project, so it was not set up."
cl_need vercel git

out=$(mktemp)
trap 'rm -f "$out"' EXIT

vercel project add "$project" >&2 || true
vercel project update "$project" --framework nextjs --yes >&2 ||
  cl_fail "Vercel would not set the project's framework to Next.js, so its first build would fail."
vercel link --project "$project" --yes >&2 ||
  cl_fail "This folder could not be linked to the Vercel project."

if git check-ignore --no-index -v .env.example >"$out" 2>/dev/null && ! grep -q ':!\.env\.example' "$out"; then
  # The line below the last `.env*` lets the file back in.
  python3 - <<'PY'
lines = open(".gitignore").read().splitlines()
last = max(i for i, line in enumerate(lines) if line.strip() == ".env*")
lines.insert(last + 1, "!.env.example")
open(".gitignore", "w").write("\n".join(lines) + "\n")
PY
fi
git check-ignore --no-index .env.example >/dev/null 2>&1 &&
  cl_fail "Git still ignores .env.example after linking, so it would be left out of the next commit."
sh "$here/../../parts/scripts/keep-out-of-git.sh" >&2 ||
  cl_fail "Git does not ignore supabase/.temp, so the database address could be committed."

if ! vercel git connect --yes >"$out" 2>&1; then
  cat "$out" >&2
  if grep -q 'Failed to connect' "$out"; then
    cl_fail "Vercel cannot see the GitHub repository yet. On GitHub, open Settings, then Applications, then Installed GitHub Apps, choose Configure beside Vercel, add the repository under Only select repositories, and save. For a repository an organisation owns, the page is the organisation's Settings, then Third-party Access, then GitHub Apps. Never remove the repositories already chosen there."
  fi
  cl_fail "The Vercel project could not be connected to the GitHub repository."
fi
cat "$out" >&2
cl_pass "The Vercel project is set up for Next.js and connected to the GitHub repository, so each push to main builds."
