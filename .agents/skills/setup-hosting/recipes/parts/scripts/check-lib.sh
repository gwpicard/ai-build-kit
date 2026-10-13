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

cl_main_commit() {
  # The commit `main` holds on GitHub, as this computer last fetched it.
  git rev-parse origin/main 2>/dev/null
}
