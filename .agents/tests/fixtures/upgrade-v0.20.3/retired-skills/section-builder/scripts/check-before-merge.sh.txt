#!/usr/bin/env sh
# check-before-merge.sh: run a recipe's check before the merge, and say by its
# exit code whether it passed, failed or could not run.
#
# On a live project the merge is a deploy, and a recipe can name a check to
# run on this computer first, such as building the app the way the host will
# and reading its health. A check that cannot run here is a warning and the
# merge goes ahead. A check that runs and fails holds the merge, as a red
# project check does. Telling the two apart from a page of output was left to
# judgement, and judgement once held a merge for a check that never ran. So
# this script decides, and the kit acts on its exit code.
#
# Usage: sh check-before-merge.sh [--ready <command>] [--cleanup <command>] <command>...
#
#   --ready <command>    confirms the check's tool is there and running, such
#                        as asking a container engine for its status. When it
#                        fails, the check could not run.
#   --cleanup <command>  removes what the check started. It runs at the end
#                        whatever happened, and its result changes nothing.
#   <command>...         the check itself, in the recipe's order. Each one is
#                        run with sh. A command that reads something started
#                        in the background waits for it with its own retry
#                        option, and carries its own time limit, since a
#                        failure here holds the merge and a hang holds the
#                        build.
#
# Exit 0: the check passed.
# Exit 1: the check ran and failed. The merge waits until it passes.
# Exit 2: the check could not run here. That is a warning, and the merge is
#         not held for it.
# A wrong use of this script is also exit 2, since it is not a check that
# failed. So is a command the shell could not find or run, whatever its
# position on the line. The last line printed says which, in words. Each
# command's own output goes to stderr, read whole.

set -u

me=check-before-merge.sh
ready=
cleanup=
while [ $# -gt 0 ]; do
  case $1 in
    --ready|--cleanup)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "could not run: $1 needs a command"
        exit 2
      fi
      if [ "$1" = --ready ]; then ready=$2; else cleanup=$2; fi
      shift 2 ;;
    --) shift; break ;;
    --*) echo "could not run: $me has no option $1"; exit 2 ;;
    *) break ;;
  esac
done

if [ $# -eq 0 ]; then
  echo "could not run: no check command was given"
  exit 2
fi

tool_of() {
  # The program a command line starts: past a leading "!", "(" or "{", and
  # any NAME=value, with quotes taken off. Globbing is off, so a word such as
  # * stays a word. A program later on the line is caught by its exit code.
  set -f
  for word in $1; do
    word=$(printf '%s' "$word" | sed "s/^[({]*//; s/[\"']//g")
    case $word in
      ''|'!') continue ;;
      *=*) continue ;;
      *) set +f; printf '%s\n' "$word"; return ;;
    esac
  done
  set +f
}

# A tool that is not installed is a check that cannot run, never a failure.
for line in "$ready" "$@"; do
  [ -n "$line" ] || continue
  tool=$(tool_of "$line")
  [ -n "$tool" ] || continue
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "could not run: $tool is not installed on this computer"
    exit 2
  fi
done

if [ -n "$ready" ]; then
  sh -c "$ready" >&2
  code=$?
  if [ "$code" -ne 0 ]; then
    echo "could not run: $ready exited $code, so its tool is not running here"
    exit 2
  fi
fi

finish() {
  if [ -n "$cleanup" ]; then
    sh -c "$cleanup" >&2 || echo "$me: the cleanup command failed: $cleanup" >&2
  fi
}

# An interrupted check still removes what it started.
trap 'finish; echo "could not run: the check was interrupted"; exit 2' INT TERM

for line in "$@"; do
  sh -c "$line" >&2
  code=$?
  # 126 and 127 are the shell saying it could not find or run a program.
  if [ "$code" -eq 126 ] || [ "$code" -eq 127 ]; then
    finish
    echo "could not run: $line exited $code, so a program it needs is missing here"
    exit 2
  fi
  if [ "$code" -ne 0 ]; then
    finish
    echo "failed: $line exited $code"
    exit 1
  fi
done

finish
echo "passed"
exit 0
