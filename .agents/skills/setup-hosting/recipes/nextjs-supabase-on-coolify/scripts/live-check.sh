#!/usr/bin/env sh
# live-check.sh: compare the live copy on Coolify with main, read-only. The
# kit never contacts the server, so what only the server knows is pasted.
#
# Usage: live-check.sh [--pasted-health <file>] [--pasted-names <file>]
#                      [--password-file <file>] [--needs NAME,NAME]
#                      [--only <read>]
#
# The five reads a later /setup-hosting run and every /maintain visit make.
# Each prints one line, and none changes anything:
#
#   commit     the live copy runs the latest merge on main: the pasted health
#              answer's commit against `git rev-parse origin/main`
#   hold       Coolify keeps no hold after a rollback, since a later deploy of
#              main rolls forward, so only a hold line in the masterplan counts
#   migration  main holds no migration the live database lacks, read with
#              the shared migrate.sh's dry run and the password passed by its
#              location
#   secrets    every name in .env.example, and each name given with --needs,
#              is on the pasted list of names Coolify holds
#   health     the pasted health answer shows the database reachable
#
# A read with nothing pasted for it could not be made, and its line says what
# to ask for.
#
# Exit 0 when every read matches, 1 when any read found a gap, 2 when none
# found a gap but at least one could not be made.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../../scripts/check-lib.sh"

only=
needs=
health=
names=
while [ $# -gt 0 ]; do
  case $1 in
    --pasted-health) health=${2:-}; shift 2 ;;
    --pasted-names) names=${2:-}; shift 2 ;;
    --password-file) DB_PASSWORD_FILE=${2:-}; export DB_PASSWORD_FILE; shift 2 ;;
    --needs) needs=${2:-}; shift 2 ;;
    --only) only=${2:-}; shift 2 ;;
    --address) shift 2 ;;
    *) cl_cannot "live-check.sh does not know the option $1." ;;
  esac
done
case "$only" in ''|commit|hold|migration|secrets|health) ;; *) cl_cannot "live-check.sh has no read called $only." ;; esac

gap=0
unread=0
say() { printf '%s\n' "$1"; }
gapped() { gap=1; say "$1"; }
unreadable() { unread=1; say "$1"; }
wanted() { [ -z "$only" ] || [ "$only" = "$1" ]; }
fields=
[ -n "$health" ] && [ -f "$health" ] && fields=$(cl_health_fields "$health")
ask_health="ask the person or the companion to paste the answer from the live address's /api/health"

if wanted commit; then
  git fetch -q origin main 2>/dev/null || true
  main=$(cl_main_commit)
  commit=$(printf '%s\n' "$fields" | sed -n 3p)
  if [ -z "$commit" ]; then
    unreadable "Live copy against main: could not be read; $ask_health."
  elif [ -z "$main" ]; then
    unreadable "Live copy against main: could not be read, since this computer does not know main's latest commit on GitHub."
  elif [ "$commit" = "$main" ]; then
    say "Live copy against main: the live copy runs the latest merge on main."
  else
    gapped "Live copy against main: the live copy runs an older commit than the latest merge on main."
  fi
fi

if wanted hold; then
  if [ -f masterplan.md ] && grep -qi 'held on an earlier version' masterplan.md; then
    gapped "Held since a rollback: the masterplan records the live copy held on an earlier version."
  else
    say "Held since a rollback: no, a deploy of main rolls the live copy forward."
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
  if [ -n "$names" ] && [ -f "$names" ]; then
    missing=
    for name in $(cl_names .env.example) $(printf '%s' "$needs" | tr ',' ' '); do
      grep -Eq "(^|[^A-Za-z0-9_])$name([^A-Za-z0-9_]|\$)" "$names" || missing="$missing $name"
    done
    if [ -z "$missing" ]; then
      say "Settings on the host: Coolify holds every name the tool needs."
    else
      gapped "Settings on the host: Coolify is missing$missing."
    fi
  else
    unreadable "Settings on the host: could not be read; ask the person or the companion to paste the names of the settings Coolify holds, with no values."
  fi
fi

if wanted health; then
  if [ -z "$fields" ]; then
    unreadable "Health: could not be read; $ask_health."
  elif [ "$(printf '%s\n' "$fields" | sed -n 2p)" = ok ]; then
    say "Health: the live copy answers, and reaches its database."
  else
    gapped "Health: the live copy answers, but cannot reach its database."
  fi
fi

[ "$gap" -eq 0 ] || exit 1
[ "$unread" -eq 0 ] || exit 2
exit 0
