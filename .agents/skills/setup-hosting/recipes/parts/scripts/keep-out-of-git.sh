#!/usr/bin/env sh
# keep-out-of-git.sh: keep what `supabase init` and `supabase link` leave out
# of the repository.
#
# Usage: keep-out-of-git.sh
#
# `supabase init` does not add `supabase/.temp` to `.gitignore`, and that
# folder holds the project reference and the pooler address. This adds it, once,
# before the first commit. Running it again changes nothing.
#
# Exit 0 when the folder is kept out, 1 when git still does not ignore it,
# 2 when this is not a git folder.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/check-lib.sh"

cl_need git
git rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
  cl_cannot "This folder is not a git repository, so nothing could be kept out of it."

if ! git check-ignore -q supabase/.temp 2>/dev/null; then
  [ ! -s .gitignore ] || [ -z "$(tail -c 1 .gitignore)" ] || printf '\n' >> .gitignore
  printf 'supabase/.temp\n' >> .gitignore
fi
git check-ignore -q supabase/.temp ||
  cl_fail "Git still does not ignore supabase/.temp, so the database address could be committed."
cl_pass "Git ignores supabase/.temp, so the database address stays on this computer."
