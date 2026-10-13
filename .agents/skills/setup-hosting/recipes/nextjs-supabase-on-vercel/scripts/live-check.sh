#!/usr/bin/env sh
# live-check.sh: compare the live copy on Vercel with main, read-only.
#
# Usage: live-check.sh [--address <live address>] [--password-file <file>]
#                      [--needs NAME,NAME] [--only <read>]
#
# The five reads a later /setup-hosting run and every /maintain visit make.
# Each prints one line, and none changes anything:
#
#   commit     the live copy runs the latest merge on main: its health route's
#              commit against `git rev-parse origin/main`
#   hold       the live copy is not held on an earlier version since a
#              rollback: the masterplan's hold line, and the newest Ready
#              production build against the one the live address serves
#   migration  main holds no migration the live database lacks, read with
#              the shared migrate.sh's dry run and the password passed by its
#              location
#   secrets    every name in .env.example, and each name given with --needs,
#              is set on Vercel, by name only
#   health     the health route answers 200 with the database reachable
#
# --only runs one of them. The address and the password's location also come
# from LIVE_ADDRESS and DB_PASSWORD_FILE.
#
# Exit 0 when every read matches, 1 when any read found a gap, 2 when none
# found a gap but at least one could not be made.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../../scripts/check-lib.sh"

only=
needs=
while [ $# -gt 0 ]; do
  case $1 in
    --address) LIVE_ADDRESS=${2:-}; shift 2 ;;
    --password-file) DB_PASSWORD_FILE=${2:-}; export DB_PASSWORD_FILE; shift 2 ;;
    --needs) needs=${2:-}; shift 2 ;;
    --only) only=${2:-}; shift 2 ;;
    *) cl_cannot "live-check.sh does not know the option $1." ;;
  esac
done
case "$only" in ''|commit|hold|migration|secrets|health) ;; *) cl_cannot "live-check.sh has no read called $only." ;; esac
[ -n "${LIVE_ADDRESS:-}" ] || cl_cannot "No live address is recorded, so there is no live copy to compare."
address=${LIVE_ADDRESS%/}
case "$address" in https://*|http://*) ;; *) address="https://$address" ;; esac

gap=0
unread=0
say() { printf '%s\n' "$1"; }
gapped() { gap=1; say "$1"; }
unreadable() { unread=1; say "$1"; }
wanted() { [ -z "$only" ] || [ "$only" = "$1" ]; }

health=$(mktemp)
list=$(mktemp)
live=$(mktemp)
trap 'rm -f "$health" "$list" "$live"' EXIT
healthy=no
if command -v curl >/dev/null 2>&1 && curl -fsS "$address/api/health" >"$health" 2>/dev/null; then
  healthy=yes
fi
fields=$(cl_health_fields "$health")

if wanted commit; then
  git fetch -q origin main 2>/dev/null || true
  main=$(cl_main_commit)
  commit=$(printf '%s\n' "$fields" | sed -n 3p)
  if [ "$healthy" != yes ] || [ -z "$commit" ]; then
    unreadable "Live copy against main: could not be read, since the health route did not answer with a commit."
  elif [ -z "$main" ]; then
    unreadable "Live copy against main: could not be read, since this computer does not know main's latest commit on GitHub."
  elif [ "$commit" = "$main" ]; then
    say "Live copy against main: the live copy runs the latest merge on main."
  else
    gapped "Live copy against main: the live copy runs an older commit than the latest merge on main."
  fi
fi

if wanted hold; then
  recorded=no
  [ -f masterplan.md ] && grep -qi 'held on an earlier version' masterplan.md && recorded=yes
  if command -v vercel >/dev/null 2>&1 &&
     vercel ls --environment production --format json >"$list" 2>/dev/null &&
     vercel inspect "${address#https://}" --format json >"$live" 2>/dev/null; then
    newer=$(python3 - "$list" "$live" <<'PY'
import json, sys
deps = json.load(open(sys.argv[1])).get("deployments", [])
live = json.load(open(sys.argv[2]))
live_id = live.get("id") or live.get("uid")
ready = [d for d in deps if (d.get("readyState") or d.get("state")) == "READY"
         and d.get("target") == "production"]
ready.sort(key=lambda d: str(d.get("created", "")), reverse=True)
print("yes" if ready and (ready[0].get("uid") or ready[0].get("id")) != live_id else "no")
PY
)
    if [ "$newer" = yes ] || [ "$recorded" = yes ]; then
      gapped "Held since a rollback: the live copy stays on an earlier version, and a newer build waits to be promoted."
    else
      say "Held since a rollback: no, new merges go live by themselves."
    fi
  elif [ "$recorded" = yes ]; then
    gapped "Held since a rollback: the masterplan records the live copy held on an earlier version."
  else
    unreadable "Held since a rollback: could not be read, since Vercel's list of deployments did not answer."
  fi
fi

if wanted migration; then
  result=$(sh "$here/../../parts/scripts/migrate.sh" 2>/dev/null)
  case $? in
    0) say "Migrations: the live database has every migration on main." ;;
    1) gapped "Migrations: the live database lacks these migrations on main: ${result#*: }" ;;
    *) unreadable "Migrations: could not be read. $result" ;;
  esac
fi

if wanted secrets; then
  if command -v vercel >/dev/null 2>&1 && listed=$(vercel env ls production 2>/dev/null); then
    missing=
    for name in $(cl_names .env.example) $(printf '%s' "$needs" | tr ',' ' '); do
      printf '%s\n' "$listed" | grep -Eq "^[[:space:]]*$name([[:space:]]|\$)" || missing="$missing $name"
    done
    if [ -z "$missing" ]; then
      say "Settings on the host: Vercel holds every name the tool needs."
    else
      gapped "Settings on the host: Vercel is missing$missing."
    fi
  else
    unreadable "Settings on the host: could not be read, since Vercel's list of settings did not answer."
  fi
fi

if wanted health; then
  if [ "$healthy" != yes ]; then
    gapped "Health: the live address did not answer its health route with 200."
  elif [ "$(printf '%s\n' "$fields" | sed -n 2p)" = ok ]; then
    say "Health: the live copy answers, and reaches its database."
  else
    gapped "Health: the live copy answers, but cannot reach its database."
  fi
fi

[ "$gap" -eq 0 ] || exit 1
[ "$unread" -eq 0 ] || exit 2
exit 0
