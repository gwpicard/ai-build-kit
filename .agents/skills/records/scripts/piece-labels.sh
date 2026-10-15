#!/usr/bin/env sh
# piece-labels.sh: change a piece's labels at the start of a build and after
# its merge, and read them back.
#
# Usage:
#   sh piece-labels.sh start <issue number>    ready off, building on, assign
#                                             the person running the build
#   sh piece-labels.sh merged <issue number>   building and ready off
#
# GitHub can answer a label change and still show the old labels for a few
# seconds, so after each change the script reads the labels back, waiting 1,
# 2 and 3 seconds between reads. Only when they still read wrong does it
# repeat the change, up to three times.
#
# Exit 0: the labels read back as wanted.
# Exit 1: they still do not after three tries; the line printed says which.
# Exit 2: usage error, or GitHub could not be read.

set -u

usage() { echo "usage: piece-labels.sh start|merged <issue number>" >&2; exit 2; }
[ "$#" -eq 2 ] || usage
step=$1
number=${2#\#}
case "$number" in ''|*[!0-9]*) usage ;; esac
case "$step" in start|merged) ;; *) usage ;; esac

if [ "$step" = start ]; then
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "piece-labels: start must run inside the project" >&2
    exit 2
  fi
  dirty=$(git status --porcelain)
  if [ -n "$dirty" ]; then
    echo "piece-labels: save or set aside this work before starting a piece:" >&2
    printf '%s\n' "$dirty" >&2
    exit 1
  fi
fi

command -v gh >/dev/null 2>&1 || { echo "piece-labels: the GitHub command line tool is not installed" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "piece-labels: python3 is needed to read the labels" >&2; exit 2; }

labels() {
  gh issue view "$number" --json labels | python3 -c '
import json, sys
data = json.load(sys.stdin)
print(" ".join(l["name"] if isinstance(l, dict) else l for l in data.get("labels") or []))
'
}

has() { case " $current " in *" $1 "*) return 0 ;; esac; return 1; }
wanted() {
  if [ "$step" = start ]; then
    has building && ! has ready
  else
    ! has building && ! has ready
  fi
}

tries=0
while :; do
  current=$(labels) || { echo "piece-labels: could not read issue $number" >&2; exit 2; }
  wanted && break
  # After a change, give GitHub's reads time to catch up before repeating it.
  if [ "$tries" -gt 0 ]; then
    for wait in 1 2 3; do
      sleep "$wait"
      current=$(labels) || { echo "piece-labels: could not read issue $number" >&2; exit 2; }
      wanted && break 2
    done
  fi
  [ "$tries" -lt 3 ] || {
    echo "piece-labels: issue $number still reads \"$current\" after three tries"
    exit 1
  }
  tries=$((tries + 1))
  if [ "$step" = start ]; then
    if ! has building; then
      gh issue edit "$number" --add-label building --add-assignee @me >/dev/null 2>&1 ||
        gh issue edit "$number" --add-label building >/dev/null 2>&1 || true
    fi
  else
    ! has building || gh issue edit "$number" --remove-label building >/dev/null 2>&1 || true
  fi
  ! has ready || gh issue edit "$number" --remove-label ready >/dev/null 2>&1 || true
done

if [ "$step" = start ]; then
  echo "building: issue $number"
else
  echo "merged: issue $number carries neither building nor ready"
fi
exit 0
