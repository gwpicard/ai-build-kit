# check-lib.sh: what every recipe script shares. Source it; do not run it.
#
# A recipe script is one check or one step of a recipe. It runs from the
# project's folder and decides by its exit code:
#
#   0  the check passed, or the step worked
#   1  the check ran and failed, or the step ran and did not work
#   2  it could not run here, such as a missing tool or an unknown location
#
# Its last line of output is one plain sentence saying what it found. The
# runner and the kit repeat that sentence; nobody has to read the rest.
#
# A secret never reaches the output. The database password is read inside the
# script from the file the masterplan records, and passed on in the
# environment of the one command that needs it.

# The change a step makes online is named by the script and its arguments,
# such as "promote dpl_abc 1a2b3c4". cl_approved spends the person's recorded
# yes for it, through the one approval gate, or stops with nothing changed.
cl_change="$(basename -- "$0" .sh)${*:+ $*}"

cl_approved() {
  cl_gate_script="$(CDPATH= cd -- "$(dirname -- "$0")/../../../.." && pwd)/records/scripts/approval.py"
  [ -f "$cl_gate_script" ] ||
    cl_cannot "The approval gate is missing, so nothing was changed."
  python3 "$cl_gate_script" use "$cl_change" >&2 ||
    cl_cannot "No yes is recorded for \"$cl_change\", so nothing was changed. Ask the person, record their words with approval.py yes, then run this again."
}

cl_pass() { printf '%s\n' "$1"; exit 0; }
cl_fail() { printf '%s\n' "$1"; exit 1; }
cl_cannot() { printf '%s\n' "$1"; exit 2; }

cl_need() {
  # cl_need <tool>...: could not run when one of them is not installed.
  for cl_tool in "$@"; do
    command -v "$cl_tool" >/dev/null 2>&1 ||
      cl_cannot "$cl_tool is not installed on this computer, so this check could not run."
  done
}

cl_value() {
  # cl_value <file> <NAME>: the value of NAME=... in an env file, unquoted.
  [ -f "$1" ] || return 0
  sed -n "s/^$2=//p" "$1" | tail -n 1 | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'\$/\1/"
}

cl_names() {
  # cl_names <file>: the variable names an env file lists, one to a line.
  [ -f "$1" ] || return 0
  sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' "$1"
}

cl_password() {
  # Put the database password into SUPABASE_DB_PASSWORD, read from the file
  # DB_PASSWORD_FILE names. The value is never printed. A password already in
  # the environment is used as it is.
  if [ -n "${SUPABASE_DB_PASSWORD:-}" ]; then
    export SUPABASE_DB_PASSWORD
    return 0
  fi
  [ -n "${DB_PASSWORD_FILE:-}" ] ||
    cl_cannot "The kit does not know where the database password is kept, so this check could not run."
  [ -r "$DB_PASSWORD_FILE" ] ||
    cl_cannot "The kit found nothing it could read at the location recorded for the database password, so this check could not run."
  SUPABASE_DB_PASSWORD=$(cat -- "$DB_PASSWORD_FILE")
  export SUPABASE_DB_PASSWORD
}

cl_db_url() {
  # Put the session pooler address, with the password added, into
  # SUPABASE_DB_URL. The address comes from what `supabase link` left.
  cl_password
  [ -f supabase/.temp/pooler-url ] ||
    cl_cannot "The project is not linked to its database on this computer, so this check could not run."
  SUPABASE_DB_URL=$(python3 -c '
import os, sys, urllib.parse
url = open("supabase/.temp/pooler-url").read().strip()
scheme, rest = url.split("://", 1)
user, host = rest.split("@", 1)
user = user.split(":", 1)[0]
print("%s://%s:%s@%s" % (scheme, user, urllib.parse.quote(os.environ["SUPABASE_DB_PASSWORD"], safe=""), host))
') || cl_cannot "The database address on this computer could not be read, so this check could not run."
  export SUPABASE_DB_URL
}

cl_ref() {
  # The linked project's reference: from `supabase link`, or the project's
  # public address in .env.local.
  if [ -f supabase/.temp/project-ref ]; then
    tr -d ' \n' < supabase/.temp/project-ref
    return 0
  fi
  cl_value .env.local NEXT_PUBLIC_SUPABASE_URL | sed -n 's#^https://\([^.]*\)\.supabase\.co.*#\1#p'
}

cl_health_fields() {
  # cl_health_fields <file>: read a health answer and print four lines:
  # status, database, commit, project. A file with no health answer in it
  # prints nothing.
  python3 - "$1" <<'PY'
import json, re, sys
text = open(sys.argv[1], errors="replace").read()
for found in re.finditer(r"\{[^{}]*\}", text):
    try:
        body = json.loads(found.group(0))
    except ValueError:
        continue
    if "database" in body:
        for key in ("status", "database", "commit", "project"):
            print(str(body.get(key, "")))
        break
PY
}

cl_ask() {
  # cl_ask <recipe.md> <heading>: the fixed words a section asks with.
  sed -n "/^## $2\$/,/^## /s/^Ask: //p" "$1"
}

cl_newest_status() {
  # cl_newest_status <file>: the status of the first deployment a paste
  # names, the newest, as finished, failed or another word. Nothing when the
  # paste names none.
  awk '{ l = tolower($0) }
    match(l, /finished|failed|in progress|queued|cancell?ed|building/) { print substr(l, RSTART, RLENGTH); exit }' "$1"
}

cl_main_commit() {
  # The commit `main` holds on GitHub, as this computer last fetched it.
  git rev-parse origin/main 2>/dev/null
}

cl_public_key() {
  # The Supabase key the tool sends to every browser, from .env.local: the
  # publishable key a project made today shows, or the older anon key. Never
  # print it.
  cl_key=$(cl_value .env.local NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY)
  [ -n "$cl_key" ] || cl_key=$(cl_value .env.local NEXT_PUBLIC_SUPABASE_ANON_KEY)
  printf '%s' "$cl_key"
}

cl_access() {
  # The masterplan's Access: line as two words: the setting, and whether
  # sign-up is open or closed. private is always closed. open, for "open
  # address, invitation only", lets anyone reach the address and keeps
  # sign-up closed. public is open. Nothing when the masterplan records no
  # setting.
  [ -f masterplan.md ] || return 0
  sed -n 's/^Access:[[:space:]]*//p' masterplan.md | head -n 1 | tr 'A-Z' 'a-z' | awk '
    /^private/ { print "private closed"; exit }
    /^open address/ || /invitation only/ { print "open closed"; exit }
    /^public/ { print "public open"; exit }'
}

cl_access_declined() {
  # True when the person said no to recording an access setting: the
  # check-up record's upgrade-declined line names the access step.
  [ -f .ai-build-kit-maintenance ] || return 1
  sed -n 's/^upgrade-declined|[^|]*|//p' .ai-build-kit-maintenance |
    tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -qx access
}

cl_access_unrecorded() {
  # What an access check says when the masterplan records no setting: a pass
  # when the person chose not to record one, and could not run otherwise.
  cl_access_declined && cl_pass "Access: not recorded, by your choice."
  cl_cannot "The masterplan records no access setting, so there is nothing to compare the live tool with."
}

cl_gate() {
  # cl_gate <address> [file]: what a request signed in to nothing gets from
  # the address's health route: open (200), gated (401 or 403, or sent to
  # another host to sign in) or unknown. The body goes to file, if named.
  cl_got=$(curl -sS -o "${2:-/dev/null}" -w '%{http_code} %{redirect_url}' "$1/api/health" 2>/dev/null)
  cl_host=$(printf '%s' "$1" | sed -E 's#^https?://##; s#/.*##')
  case "$cl_got" in
    200*) echo open ;;
    401*|403*) echo gated ;;
    3[0-9][0-9]\ http*)
      cl_to=$(printf '%s' "${cl_got#* }" | sed -E 's#^https?://##; s#[/?#].*##')
      if [ "$cl_to" = "$cl_host" ]; then echo unknown; else echo gated; fi ;;
    *) echo unknown ;;
  esac
}

cl_bypass_key() {
  # True when the linked Vercel project holds an automation bypass key, so
  # `vercel curl` reads through Vercel's sign-in without making a new one.
  # The key itself is never printed.
  vercel project protection --format json 2>/dev/null | python3 -c '
import json, sys
try:
    keys = json.load(sys.stdin).get("protectionBypass") or {}
except ValueError:
    sys.exit(1)
sys.exit(0 if any(isinstance(v, dict) and v.get("scope") == "automation-bypass"
                  for v in keys.values()) else 1)'
}

cl_live_health() {
  # cl_live_health <address> <file>: the live health answer into file. Behind
  # Vercel's sign-in it is read with `vercel curl`, which uses the project's
  # bypass key. Making that key changes who can get past the sign-in, so
  # without one it is read only with GATE_READ=yes, after the person's yes.
  # Returns 0 when read, 1 when the address did not answer 200, 3 when it is
  # behind a sign-in the kit may not read through yet.
  case $(cl_gate "$1" "$2") in
    open) return 0 ;;
    gated) ;;
    *) return 1 ;;
  esac
  command -v vercel >/dev/null 2>&1 || return 3
  [ "${GATE_READ:-}" = yes ] || cl_bypass_key || return 3
  vercel curl /api/health --deployment "$1" --yes >"$2" 2>/dev/null || return 1
  [ -n "$(cl_health_fields "$2")" ] || return 1
}
