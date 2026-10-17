#!/usr/bin/env sh
# Put one red pull request in the local remote for case 61.
set -eu
project=${1:?project directory}
git -C "$project" checkout -q -B main
git -C "$project" push -q origin main
git -C "$project" checkout -q -b auto-merge-exceeds
printf '%s\n' 'change awaiting merge' > "$project/app/overdue-list.txt"
git -C "$project" add app/overdue-list.txt
git -C "$project" commit -q -m 'Show days late on overdue list'
git -C "$project" push -q origin auto-merge-exceeds
git -C "$project" checkout -q main
