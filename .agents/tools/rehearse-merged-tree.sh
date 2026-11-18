#!/usr/bin/env sh
# rehearse-merged-tree.sh: assemble the branch's committed tree in a throwaway
# folder, and run the steps a hosted check runs against it.
#
# Run it before pushing a branch. The hosted checks must never fail, and a
# failure found after the push is already public and has used a hosted run.
# This finds it first, on this computer.
#
# What it builds is every tracked file, copied at its current mode, into a fresh
# repository holding one commit. The fresh repository matters. Several checks
# read what git recorded rather than what the disk says, and the release builder
# packs from the tracked file list, so an untracked file lying about here would
# quietly change the answer.
#
# What it then runs is what a hosted job runs, in the same order:
#   build-adapters.sh --check   the committed adapters match their source
#   validate-kit.sh             the source and the generated adapters
#   run-all.sh                  every rehearsal in .agents/tests/
# It also checks the sign-in review, runs the full Postgres starter job when
# that template differs from origin/main, and builds the site and checks its
# built pages, as the site job does. Each step runs under the Node.js version
# its hosted job pins, fetched once into ~/.cache/ai-build-kit/node.
#
# This lives here rather than in .agents/tests/ on purpose. run-all.sh runs
# every script in that folder, so a rehearsal that called run-all.sh would run
# the suite inside the suite, reach its own copy, and never finish. Run this one
# by hand.
#
# A dirty working tree stops it. This copies what is on disk, while the hosted
# checks read the commit, so an unsaved change makes the two measure different
# things and the rehearsal stops meaning what it claims. Pass --allow-dirty to
# rehearse before committing, which is worth doing and is how this tool caught
# its own untracked file the first time it ran.
#
# Usage:
#   rehearse-merged-tree.sh              build in a temporary folder and delete it
#   rehearse-merged-tree.sh <folder>     build in a new folder and keep it, so a
#                                        failure can be read where it happened
#   rehearse-merged-tree.sh --allow-dirty [folder]
#                                        rehearse unsaved work on purpose

unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)

command -v git >/dev/null 2>&1 || { echo "error: git is needed" >&2; exit 1; }

ALLOW_DIRTY=0
if [ "${1:-}" = "--allow-dirty" ]; then
  ALLOW_DIRTY=1
  shift
fi

KEEP=0
if [ "$#" -gt 1 ]; then
  echo "usage: $0 [folder]" >&2
  exit 2
elif [ "$#" -eq 1 ]; then
  KEEP=1
  [ ! -e "$1" ] || { echo "error: $1 already exists" >&2; exit 1; }
  parent=$(dirname -- "$1")
  [ -d "$parent" ] || { echo "error: no such folder: $parent" >&2; exit 1; }
  TREE=$(CDPATH= cd -- "$parent" && pwd -P)/$(basename -- "$1")
  case "$TREE" in
    "$ROOT" | "$ROOT"/*)
      echo "error: build the merged tree outside this repository" >&2
      exit 1
      ;;
  esac
else
  SCRATCH=$(mktemp -d)
  TREE="$SCRATCH/merged"
  trap 'rm -R "$SCRATCH"' EXIT INT TERM
fi

if [ -n "$(git -C "$ROOT" status --porcelain)" ]; then
  if [ "$ALLOW_DIRTY" -eq 0 ]; then
    echo "error: this working tree has unsaved changes." >&2
    echo "       The rehearsal copies what is on disk while the hosted checks read the" >&2
    echo "       commit, so a green result here would not be about the tree that" >&2
    echo "       gets pushed. Save the work, or pass --allow-dirty on purpose." >&2
    echo >&2
    git -C "$ROOT" status --short >&2
    exit 1
  fi
  echo "note: rehearsing unsaved work, because --allow-dirty was passed. This is"
  echo "      not the tree a push would send."
  echo
fi

# Compare in the source repository: the clean copy has no upstream history.
FULL_STARTER=1
if git -C "$ROOT" rev-parse --verify origin/main >/dev/null 2>&1; then
  if git -C "$ROOT" diff --quiet origin/main -- templates/nextjs-postgres/; then
    FULL_STARTER=0
  fi
else
  echo "note: origin/main is unavailable; the full Postgres starter job is required."
fi

echo "Assembling the merged tree at $TREE"
mkdir -p "$TREE"
git -C "$ROOT" -c core.quotePath=false ls-files > "$TREE/.tracked-files"
while IFS= read -r tracked; do
  [ -n "$tracked" ] || continue
  mkdir -p "$TREE/$(dirname -- "$tracked")"
  cp -Pp "$ROOT/$tracked" "$TREE/$tracked"
done < "$TREE/.tracked-files"
rm -f "$TREE/.tracked-files"

git -C "$TREE" init --quiet
git -C "$TREE" add -A
git -C "$TREE" \
  -c user.name="merged tree rehearsal" \
  -c user.email="rehearsal@example.invalid" \
  commit --quiet -m "The end state, as one commit"

echo "Committed $(git -C "$TREE" ls-files | wc -l | tr -d ' ') files."

# Each hosted job pins its Node.js version, and a newer or older local Node can
# pass or fail where the job would not. job_node prints the version a job pins;
# node_path prints a PATH with that exact version first, fetched once into a
# cache and checked against the published checksums.
job_node() {
  awk -v job="$2" '$0 ~ "^  " job ":" {f=1; next} f && /^  [A-Za-z]/ {f=0}
    f && /node-version:/ {print $2; exit}' "$TREE/.github/workflows/$1"
}
node_path() {
  version=$1
  if [ -z "$version" ]; then
    echo "note: this job pins no Node.js version; using the local one" >&2
    printf '%s' "$PATH"
    return 0
  fi
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) platform=darwin-arm64 ;; Darwin-x86_64) platform=darwin-x64 ;;
    Linux-x86_64) platform=linux-x64 ;; Linux-aarch64) platform=linux-arm64 ;;
    *) echo "could not run: no Node.js build for $(uname -s) $(uname -m)" >&2; return 1 ;;
  esac
  cache=${XDG_CACHE_HOME:-$HOME/.cache}/ai-build-kit/node
  dir="$cache/node-v$version-$platform"
  if [ ! -x "$dir/bin/node" ]; then
    mkdir -p "$cache"
    download=$(mktemp -d "$cache/download.XXXXXX")
    base="https://nodejs.org/dist/v$version"
    if ! (cd "$download" &&
          curl -fsSLO "$base/node-v$version-$platform.tar.gz" &&
          curl -fsSL "$base/SHASUMS256.txt" | grep " node-v$version-$platform.tar.gz\$" | shasum -a 256 -c - >/dev/null &&
          tar -xzf "node-v$version-$platform.tar.gz" &&
          mv "node-v$version-$platform" "$dir"); then
      rm -f "$download/node-v$version-$platform.tar.gz"
      echo "could not run: Node.js $version could not be fetched and checked" >&2
      return 1
    fi
    rm -f "$download/node-v$version-$platform.tar.gz"
    rmdir "$download"
  fi
  printf '%s/bin:%s' "$dir" "$PATH"
}

# Each step is an independent opinion, so one failure must not hide another and
# the run carries on to the end.
failed=""
for step in \
  ".agents/tools/build-adapters.sh --check" \
  ".agents/tools/validate-kit.sh" \
  ".agents/tests/run-all.sh"; do
  name=${step%% *}
  printf '\n########## %s ##########\n' "$name"
  case "$name" in
    .agents/tests/run-all.sh) step_path=$(node_path "$(job_node source-checks.yml rehearsal)") || step_path= ;;
    *) step_path=$PATH ;;
  esac
  if [ -n "$step_path" ] && (cd "$TREE" && PATH=$step_path sh -c "$step"); then
    printf '  passed: %s\n' "$name"
  else
    printf '  FAILED: %s\n' "$name"
    failed="$failed $name"
  fi
done

name="postgres-starter/sign-in-review"
printf '\n########## %s ##########\n' "$name"
starter_path=$(node_path "$(job_node postgres-starter.yml build-check)") || starter_path=
if [ -n "$starter_path" ] && (cd "$TREE/templates/nextjs-postgres" && PATH=$starter_path &&
    npm ci && npm run check:sign-in-review); then
  printf '  passed: %s\n' "$name"
else
  printf '  FAILED: %s\n' "$name"
  failed="$failed $name"
fi

if [ "$FULL_STARTER" -eq 1 ]; then
  name="postgres-starter/build-check"
  printf '\n########## %s ##########\n' "$name"
  if ! docker info >/dev/null 2>&1; then
    printf '  could not run: %s: Docker is unavailable or is not running\n' "$name"
    failed="$failed $name"
  elif [ -z "$starter_path" ]; then
    printf '  could not run: %s: its Node.js version could not be prepared\n' "$name"
    failed="$failed $name"
  elif (
    cd "$TREE/templates/nextjs-postgres"
    PATH=$starter_path
    export CI=true NEXT_TELEMETRY_DISABLED=1
    npx --no-install playwright install --with-deps chromium &&
    sh scripts/docker-run.sh -- node scripts/test-database.mjs sh -c '
  npm run check && npm run test:policy-fault &&
  npm run test:privilege-fault && npm test
' &&
    npm run test:image
  ); then
    printf '  passed: %s\n' "$name"
  else
    printf '  FAILED: %s\n' "$name"
    failed="$failed $name"
  fi
else
  echo "Skipped the full Postgres starter job: templates/nextjs-postgres/ matches origin/main."
fi

# The site job builds the site and checks the built pages. Without a build,
# site-links.sh skips its built-page check, so run the job's own steps here.
name="site-build"
printf '\n########## %s ##########\n' "$name"
site_path=$(node_path "$(job_node source-checks.yml site-build)") || site_path=
if [ -n "$site_path" ] && (cd "$TREE/site" && PATH=$site_path && npm ci && npm run build) &&
   (cd "$TREE" && PATH=$site_path sh .agents/tests/site-links.sh); then
  printf '  passed: %s\n' "$name"
else
  printf '  FAILED: %s\n' "$name"
  failed="$failed $name"
fi

printf '\n===================================\n'
if [ -n "$failed" ]; then
  printf 'The merged tree is not green. These steps failed:\n'
  for name in $failed; do
    printf -- '  - %s\n' "$name"
  done
  [ "$KEEP" -eq 1 ] && printf '\nThe tree is at %s\n' "$TREE"
  exit 1
fi

printf 'The merged tree is green: all required steps passed.\n'
[ "$KEEP" -eq 1 ] && printf 'The tree is at %s\n' "$TREE"
exit 0
