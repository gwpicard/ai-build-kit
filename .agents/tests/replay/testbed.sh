#!/usr/bin/env sh
# testbed.sh: found projects with tagged kits, keeping the records they wrote.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/../../.." && pwd)
output="$HOME/PROJECTS/abk-testbeds"
replace=no
list=no
tags=
fail() { echo "testbed: $*" >&2; exit 2; }
usage() {
  echo 'Usage: testbed.sh [--list] [--replace] [--output <folder>] [<release-tag> ...]'
  echo 'Defaults: v1.0.0 v1.1.2, in ~/PROJECTS/abk-testbeds.'
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --list) list=yes ;;
    --replace) replace=yes ;;
    --output)
      [ "$#" -ge 2 ] && [ -n "$2" ] || fail '--output needs a folder'
      output=$2; shift ;;
    --help|-h) usage; exit 0 ;;
    -*) fail "unknown option: $1" ;;
    *)
      printf '%s\n' "$1" | grep -Eq '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?$' \
        || fail "not a release tag: $1"
      case " $tags " in *" $1 "*) fail "duplicate tag: $1" ;; esac
      tags="${tags:+$tags }$1" ;;
  esac
  shift
done
tags=${tags:-v1.0.0 v1.1.2}
case "$output" in /*) : ;; *) output="$PWD/$output" ;; esac
# Check the whole request before spending model calls or moving any old output.
for tag in $tags; do
  git -C "$ROOT" rev-parse --verify "refs/tags/$tag^{commit}" >/dev/null 2>&1 \
    || fail "release tag is not available locally: $tag"
  for pair in '83 vercel' '84 coolify'; do
    set -- $pair
    name="tb-$tag-$2"
    if [ "$list" = yes ]; then
      printf '%s | tag %s | recipe %s | case %s | %s\n' "$name" "$tag" "$2" "$1" "$output/$name"
    elif [ "$replace" != yes ]; then
      for target in "$output/$name" "$output/$name.founding.md" "$output/$name.gh.json"; do
        [ ! -e "$target" ] && [ ! -L "$target" ] || fail "output exists: $target (use --replace)"
      done
    fi
  done
done
[ "$list" = no ] || exit 0
mkdir -p "$output/.runs"
output=$(CDPATH= cd -- "$output" && pwd -P)
source_tmp=
source_tree=
cleanup() {
  if [ -n "$source_tree" ] && [ -e "$source_tree/.git" ]; then
    git -C "$ROOT" worktree remove "$source_tree" || return 1
  fi
  [ -z "$source_tmp" ] || rmdir "$source_tmp"
  source_tree=
  source_tmp=
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for tag in $tags; do
  source_tmp=$(mktemp -d "${TMPDIR:-/tmp}/abk-testbed-source.XXXXXX")
  source_tree="$source_tmp/kit"
  git -C "$ROOT" worktree add --detach "$source_tree" "refs/tags/$tag" >/dev/null
  [ -x "$source_tree/.agents/tools/build-release.sh" ] \
    || fail "$tag cannot run with this harness: its release builder is missing"
  for pair in '83 vercel' '84 coolify'; do
    set -- $pair
    number=$1; recipe=$2; name="tb-$tag-$recipe"
    run=$(mktemp -d "$output/.runs/$name.XXXXXX")
    echo "Founding $name; run log: $run/run.log"
    status=0
    KIT_SRC="$source_tree" VERSION="$tag" REPLAY_WORK="$run/work" \
      REPLAY_RESULTS="$run/results" REPEATS=1 \
      sh "$HERE/run.sh" "$number" > "$run/run.log" 2>&1 || status=$?
    # Export the project and its saved issues. Logs stay in the retained run.
    # A failed run gets a report there, never a folder presented as founded.
    python3 "$HERE/testbed-export.py" "$run" "$output" "$name" "$tag" \
      "$recipe" "$number" "$status" "$replace" || {
        echo "testbed: $tag could not finish with the current harness (run exit $status); inspect $run/run.log. The old release was not changed." >&2
        exit 2
      }
  done
  cleanup
done
