#!/usr/bin/env sh
# recipe-rehearsal.sh: what the rehearsal of each recipe shares. Source it,
# call rr_init, then rr_locate, rr_shape, rr_case for each way a script is
# run, and rr_scripts last.
#
# rr_locate finds the recipe folder on the menu or waiting for its real run in
# .agents/tests/recipes-awaiting-run/, and refuses it in both. rr_shape runs
# the shipped shape check: on the menu it must pass, and waiting it must fail
# on its real run alone.
#
# rr_case runs one of the recipe's scripts, or a shared part's, in a fresh
# throwaway project against stand-ins for every tool, and requires the exit
# code the recipe's rehearsal names. The stand-ins answer only what each tool
# documents, so a mistyped option or an invented subcommand is refused. Each
# answers as one of three worlds: good, where everything holds; bad, where the
# thing the check exists to catch is there; and down, where the tool is
# installed but cannot reach anything.
#
# rr_scripts then requires that every script in the recipe's scripts/ folder,
# and every shared script the recipe names, was run at least once to a pass
# and once to something else, that every tool on the recipe's
# Command-line tools: line was called, and that the stand-ins still refuse
# what the tools do not document. Last it runs the shipped run-recipe.sh over
# the whole recipe in the good world and requires every section to pass.

rr_init() {
  # rr_init <title>
  RR_TMP=$(mktemp -d)
  RR_TMP=$(CDPATH= cd -- "$RR_TMP" && pwd -P)
  trap 'rm -rf "$RR_TMP"' EXIT
  RR_CALLS="$RR_TMP/calls"
  RR_RAN="$RR_TMP/ran"
  : > "$RR_CALLS"
  : > "$RR_RAN"
  export RR_CALLS
  echo "$1:"
  rr_setup
}
rr_ok() { echo "  ok: $1"; }
rr_fail() { echo "FAIL: $1" >&2; exit 1; }
rr_report() {
  # rr_report <description> <yes|no>
  if [ "$2" = yes ]; then rr_ok "$1"; else rr_fail "$1"; fi
}

RR_CHECKER="$ROOT/.agents/tools/check-recipes.sh"
RR_MENU="$ROOT/.agents/skills/setup-hosting/recipes"
RR_WAITING="$ROOT/.agents/tests/recipes-awaiting-run"
RR_PARTS="$ROOT/.agents/skills/setup-hosting/recipes/parts"
RR_RUNNER="$ROOT/.agents/skills/setup-hosting/scripts/run-recipe.sh"

rr_locate() {
  # rr_locate <menu folder of the recipe>: sets RR_RECIPE and RR_ON_MENU.
  rr_name=$(basename -- "$1")
  if [ -f "$1/recipe.md" ] && [ -f "$RR_WAITING/$rr_name/recipe.md" ]; then
    rr_fail "$rr_name is on the menu and still waiting for its real run; one copy has to go"
  fi
  if [ -f "$1/recipe.md" ]; then
    RR_RECIPE=$1
    RR_ON_MENU=yes
  elif [ -f "$RR_WAITING/$rr_name/recipe.md" ]; then
    RR_RECIPE="$RR_WAITING/$rr_name"
    RR_ON_MENU=no
  else
    rr_fail "$rr_name is neither on the menu nor waiting for its real run"
  fi
}

rr_shape() {
  if [ "$RR_ON_MENU" = yes ]; then
    "$RR_CHECKER" "$RR_RECIPE" >&2 ||
      rr_fail "$rr_name is on the menu without the shape the format asks for"
    rr_ok "$rr_name is on the menu with its real run recorded"
    return 0
  fi
  if rr_out=$("$RR_CHECKER" "$RR_RECIPE" 2>&1); then
    rr_fail "$rr_name passed the shape check while waiting, so a real run is recorded and it belongs on the menu"
  fi
  rr_want="$RR_RECIPE/PROVEN.md: Real run is not a real date written YYYY-MM-DD: awaiting the first real run"
  if [ "$rr_out" != "$rr_want" ]; then
    printf '%s\n' "$rr_out" >&2
    rr_fail "$rr_name is waiting on something besides its real run"
  fi
  rr_ok "$rr_name has every part the format asks for and waits only on its real run"
}

# --- the stand-ins ---------------------------------------------------------

rr_write_stand_ins() {
  # rr_write_stand_ins <bin>: one stand-in per tool. Each writes what it was
  # asked to RR_CALLS, answers as the world RR_WORLD names, and refuses
  # anything outside the documented surface with exit 64.
  mkdir -p "$1"
  rr_real_git=$(command -v git)
  cat > "$1/vercel" <<'SH'
#!/usr/bin/env sh
echo "vercel $*" >> "$RR_CALLS"
refuse() { echo "vercel stand-in: not a documented command: vercel $*" >&2; exit 64; }
down() { [ "${RR_WORLD:-good}" != down ] || { echo "Error: could not reach Vercel" >&2; exit 1; }; }
bad() { [ "${RR_WORLD:-good}" = bad ]; }
main=$(cat "$RR_STATE/main" 2>/dev/null)
# One deployment, given as an address or an id, and only the options the
# command documents. A misspelt option is refused rather than taken for the
# deployment.
one_deployment() {
  command=$1
  shift
  target=""
  json=no
  while [ "$#" -gt 0 ]; do
    case "$command $1" in
      "inspect --logs"|"inspect --wait"|"promote --yes"|"rollback --yes") shift ;;
      "inspect --json") json=yes; shift ;;
      "inspect --format") [ "${2:-}" = json ] || refuse "$command" "$@"; json=yes; shift 2 ;;
      "inspect --timeout"|"promote --timeout"|"rollback --timeout")
        [ -n "${2:-}" ] || refuse "$command" "$@"; shift 2 ;;
      "$command -"*) refuse "$command" "$@" ;;
      *) [ -z "$target" ] || refuse "$command" "$@"; target=$1; shift ;;
    esac
  done
  [ -n "$target" ] || refuse "$command"
  RR_JSON=$json
}
case "$1" in
  inspect)
    one_deployment "$@"; down
    if [ "$RR_JSON" = yes ]; then echo '{"id":"dpl_live","target":"production","readyState":"READY"}'
    elif bad; then echo "status  ● Error"
    else echo "status  ● Ready"; fi ;;
  promote|rollback)
    one_deployment "$@"; down
    bad && { echo "Error: That deployment cannot be used." >&2; exit 1; }
    echo "Success!" ;;
  ls|list)
    shift
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --environment) case "${2:-}" in production|preview) shift 2 ;; *) refuse ls "$@" ;; esac ;;
        --format) [ "${2:-}" = json ] || refuse ls "$@"; shift 2 ;;
        --json|--yes|-y) shift ;;
        *) refuse ls "$@" ;;
      esac
    done
    down
    if bad; then
      echo '{"deployments":[{"uid":"dpl_live","state":"READY","target":"production","created":"2026-01-02T00:00:00Z"}]}'
    else
      echo '{"deployments":[{"uid":"dpl_live","state":"READY","target":"production","created":"2026-01-02T00:00:00Z"},{"uid":"dpl_earlier","state":"READY","target":"production","created":"2026-01-01T00:00:00Z"}]}'
    fi ;;
  curl)
    # A path, then only the options vercel curl documents. It is marked beta,
    # and it answers a protected deployment through a bypass token.
    shift
    path=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --yes|-y|--json|--trace) shift ;;
        --deployment|--protection-bypass) [ -n "${2:-}" ] || refuse curl "$@"; shift 2 ;;
        -*) refuse curl "$@" ;;
        *) [ -z "$path" ] || refuse curl "$@"; path=$1; shift ;;
      esac
    done
    [ -n "$path" ] || refuse curl
    down
    if bad; then echo '{"status":"error","database":"error","commit":"","project":"previewref"}'
    else echo '{"status":"ok","database":"ok","commit":"'"$main"'","project":"previewref"}'; fi ;;
  project)
    # Only the options vercel project documents: add takes a name and no
    # option, and update takes one name and the settings it lists.
    case "${2:-}" in
      add) [ "$#" -eq 3 ] && case "$3" in -*) false ;; *) true ;; esac || refuse "$@" ;;
      update)
        shift 2
        name=""
        while [ "$#" -gt 0 ]; do
          case "$1" in
            --yes|-y|--json) shift ;;
            --framework|--build-command|--install-command|--output-directory|--root-directory|--node-version)
              [ -n "${2:-}" ] || refuse project update "$@"; shift 2 ;;
            -*) refuse project update "$@" ;;
            *) [ -z "$name" ] || refuse project update "$@"; name=$1; shift ;;
          esac
        done
        down ;;
      *) refuse "$@" ;;
    esac ;;
  link)
    shift
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --yes|-y) shift ;;
        --project|-p|--team) [ -n "${2:-}" ] || refuse link "$@"; shift 2 ;;
        *) refuse link "$@" ;;
      esac
    done
    down
    printf '.vercel\n.env*\n' >> .gitignore ;;
  git)
    case "${2:-}" in
      connect)
        shift 2
        while [ "$#" -gt 0 ]; do
          case "$1" in
            --yes|-y|--confirm) shift ;;
            --project) [ -n "${2:-}" ] || refuse git connect "$@"; shift 2 ;;
            *) refuse git connect "$@" ;;
          esac
        done
        down
        bad && { echo "Error: Failed to connect. Do you have access to the repository, if it's private?" >&2; exit 1; }
        echo "Connected" ;;
      *) refuse "$@" ;;
    esac ;;
  env)
    case "$2 ${3:-} ${4:-}" in
      "ls production "|"ls preview ")
        [ "$#" -eq 3 ] || refuse "$@"
        down
        echo " name                         value       environments"
        for name in NEXT_PUBLIC_SUPABASE_URL NEXT_PUBLIC_SUPABASE_ANON_KEY SUPABASE_SERVICE_ROLE_KEY; do
          bad && [ "$name" = SUPABASE_SERVICE_ROLE_KEY ] && continue
          echo " $name   Encrypted   Production"
        done ;;
      "add "*" production"|"add "*" preview"|"add "*" production "*|"add "*" preview "*)
        # A name, an environment, then only documented options. The value
        # arrives on standard input, never as an argument.
        name=$3 environment=$4
        shift 4
        case "$name" in -*) refuse env add "$name" ;; esac
        while [ "$#" -gt 0 ]; do
          case "$1" in
            --yes|--sensitive|--no-sensitive|--force) shift ;;
            --type) case "${2:-}" in config|sensitive|encrypted|plain) shift 2 ;; *) refuse env add "$name" "$environment" "$@" ;; esac ;;
            *) refuse env add "$name" "$environment" "$@" ;;
          esac
        done
        value=$(cat)
        [ -n "$value" ] || { echo "Error: no value given" >&2; exit 1; }
        down
        bad && { echo "Error: the value was refused" >&2; exit 1; }
        echo "Added" ;;
      *) refuse "$@" ;;
    esac ;;
  logs)
    shift
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --environment) case "${2:-}" in production|preview) shift 2 ;; *) refuse logs "$@" ;; esac ;;
        --level) case "${2:-}" in error|warning|info|fatal) shift 2 ;; *) refuse logs "$@" ;; esac ;;
        --since|--until|--limit|--deployment|--query|--branch) [ -n "${2:-}" ] || refuse logs "$@"; shift 2 ;;
        --json|--expand|--follow|--no-branch) shift ;;
        *) refuse logs "$@" ;;
      esac
    done
    down
    bad && echo '{"level":"error","message":"TypeError: cannot read notices"}'
    true ;;
  *) refuse "$@" ;;
esac
SH
  cat > "$1/supabase" <<'SH'
#!/usr/bin/env sh
echo "supabase $*" >> "$RR_CALLS"
refuse() { echo "supabase stand-in: not a documented command: supabase $*" >&2; exit 64; }
down() { [ "${RR_WORLD:-good}" != down ] || { echo "failed to connect to postgres" >&2; exit 1; }; }
bad() { [ "${RR_WORLD:-good}" = bad ]; }
case "$*" in
  "init"|"start"|"stop"|"stop --no-backup") down; mkdir -p supabase ;;
  "db push --dry-run")
    down
    [ -n "${SUPABASE_DB_PASSWORD:-}" ] || { echo "password authentication failed" >&2; exit 1; }
    if bad; then printf 'Would push these migrations:\n • 20260101000000_pinned.sql\n'
    else echo "Remote database is up to date."; fi ;;
  "db push")
    down
    [ -n "${SUPABASE_DB_PASSWORD:-}" ] || { echo "password authentication failed" >&2; exit 1; }
    bad && { echo "ERROR: column already exists" >&2; exit 1; }
    echo "Finished supabase db push." ;;
  "link --project-ref "*) [ "$#" -eq 3 ] || refuse "$@"; down ;;
  "db dump"*)
    shift 2
    file=
    data=no
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --linked|--local|--role-only|--use-copy|--dry-run) shift ;;
        --data-only) data=yes; shift ;;
        -f|--file) [ -n "${2:-}" ] || refuse db dump "$@"; file=$2; shift 2 ;;
        -s|--schema|-x|--exclude|-p|--password) [ -n "${2:-}" ] || refuse db dump "$@"; shift 2 ;;
        *) refuse db dump "$@" ;;
      esac
    done
    down
    [ -n "${SUPABASE_DB_PASSWORD:-}" ] || { echo "password authentication failed" >&2; exit 1; }
    [ -n "$file" ] || refuse db dump
    if [ "$data" = yes ]; then
      if bad && [ -z "${RR_RESTORE:-}" ]; then : > "$file"
      else printf 'COPY "public"."notices" ("id", "title") FROM stdin;\n1\tone\n2\ttwo\n\\.\n' > "$file"; fi
    else
      echo "-- dump" > "$file"
    fi ;;
  *) refuse "$@" ;;
esac
SH
  cat > "$1/psql" <<'SH'
#!/usr/bin/env sh
echo "psql $*" >> "$RR_CALLS"
refuse() { echo "psql stand-in: not an option psql has: $*" >&2; exit 64; }
command=
while [ "$#" -gt 0 ]; do
  case "$1" in
    --single-transaction|--tuples-only) shift ;;
    --command) [ -n "${2:-}" ] || refuse "$@"; command=$2; shift 2 ;;
    --variable|--file|--dbname) [ -n "${2:-}" ] || refuse "$@"; shift 2 ;;
    *) refuse "$@" ;;
  esac
done
[ "${RR_WORLD:-good}" != down ] || { echo "psql: error: connection failed" >&2; exit 2; }
case "$command" in
  "select tablename from pg_tables"*) [ "${RR_WORLD:-good}" = bad ] && echo " notices" ;;
  "select count(*) from"*) if [ "${RR_WORLD:-good}" = bad ]; then echo " 1"; else echo " 2"; fi ;;
esac
true
SH
  cat > "$1/curl" <<'SH'
#!/usr/bin/env sh
echo "curl $*" >> "$RR_CALLS"
refuse() { echo "curl stand-in: not an address or option a recipe may use: $*" >&2; exit 64; }
url=""
headers=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -fsS) shift ;;
    --retry|--retry-delay|--max-time) [ -n "${2:-}" ] || refuse "$@"; shift 2 ;;
    --retry-connrefused) shift ;;
    -H) [ -n "${2:-}" ] || refuse "$@"; headers="$headers|$2"; shift 2 ;;
    https://*|http://localhost:3000/*) [ -z "$url" ] || refuse "$@"; url=$1; shift ;;
    *) refuse "$@" ;;
  esac
done
world=${RR_WORLD:-good}
main=$(cat "$RR_STATE/main" 2>/dev/null)
case "$url" in
  https://api.supabase.com/v1/projects/*/database/backups)
    [ "$world" != down ] || exit 6
    if [ "$world" = bad ]; then echo '{"backups":[]}'
    else echo '{"backups":[{"inserted_at":"'"$(date -u +%Y-%m-%dT%H:%M:%S)"'Z"}]}'; fi ;;
  https://api.supabase.com/v1/projects/*/advisors/security) echo '{"lints":[]}' ;;
  # The sign-in settings answer to the public key alone, sent as apikey. A
  # bearer token is how a secret key or a signed-in session would be sent, and
  # a settings read must never carry one. Each secret key has a value of its
  # own, so a read sending one as apikey is refused by what it sent.
  https://*.supabase.co/auth/v1/settings)
    case "$headers" in "|apikey: "?*) ;; *) refuse "$url" "headers$headers" ;; esac
    case "$headers" in *"|apikey: "*"|"*) refuse "$url" "headers$headers" ;; esac
    case "$headers" in *service-role-stand-in*|*secret-stand-in*) refuse "$url" "a secret key sent as apikey" ;; esac
    [ "$world" != down ] || exit 6
    if [ "$world" = bad ]; then echo '{}'
    else echo '{"external":{"email":true},"disable_signup":false,"mailer_autoconfirm":false}'; fi ;;
  http://localhost:3000/api/health)
    [ "$world" != down ] || exit 7
    image=$(cat "$RR_STATE/image" 2>/dev/null)
    case "$world:$image" in
      *:app-check-nowhere) echo "curl: (22) The requested URL returned error: 503" >&2; exit 22 ;;
      bad:*) echo "curl: (22) The requested URL returned error: 503" >&2; exit 22 ;;
    esac
    echo '{"status":"ok","database":"ok","commit":"","project":"liveref"}' ;;
  https://*/api/health)
    [ "$world" != down ] || exit 6
    if [ "$world" = bad ]; then echo '{"status":"error","database":"error","commit":"0000000","project":"liveref"}'
    else echo '{"status":"ok","database":"ok","commit":"'"$main"'","project":"liveref"}'; fi ;;
  *) refuse "$url" ;;
esac
SH
  cat > "$1/docker" <<'SH'
#!/usr/bin/env sh
echo "docker $*" >> "$RR_CALLS"
refuse() { echo "docker stand-in: not a command a recipe may use: docker $*" >&2; exit 64; }
case "$1" in
  info) [ "$#" -eq 1 ] || refuse "$@"; [ "${RR_WORLD:-good}" != down ] || exit 1 ;;
  build)
    shift
    tag=
    while [ "$#" -gt 1 ]; do
      case "$1" in
        -t) [ -n "${2:-}" ] || refuse build "$@"; tag=$2; shift 2 ;;
        --build-arg) [ -n "${2:-}" ] || refuse build "$@"; shift 2 ;;
        *) refuse build "$@" ;;
      esac
    done
    [ "${1:-}" = . ] && [ -n "$tag" ] || refuse build "$@" ;;
  run)
    [ "$#" -eq 9 ] && [ "$2 $3 $5 $6 $7" = "-d --name -p 3000:3000 --env-file" ] || refuse "$@"
    printf '%s\n' "$9" > "$RR_STATE/image" ;;
  rm) [ "$#" -eq 3 ] && [ "$2" = -f ] || refuse "$@" ;;
  rmi) [ "$#" -eq 2 ] || refuse "$@" ;;
  *) refuse "$@" ;;
esac
SH
  # Git is the real one, so the scripts' reads of the throwaway repository
  # mean what they say. The stand-in only notes the call.
  cat > "$1/git" <<SH
#!/usr/bin/env sh
echo "git \$*" >> "\$RR_CALLS"
exec "$rr_real_git" "\$@"
SH
  chmod +x "$1/vercel" "$1/supabase" "$1/psql" "$1/curl" "$1/docker" "$1/git"
}

rr_project() {
  # rr_project <dir>: a throwaway Next.js and Supabase project, saved in its
  # own repository with a remote next door, as a project on a recipe is.
  mkdir -p "$1/supabase/.temp" "$1/supabase/migrations"
  (
    cd "$1"
    printf 'NEXT_PUBLIC_SUPABASE_URL=\nNEXT_PUBLIC_SUPABASE_ANON_KEY=\nSUPABASE_SERVICE_ROLE_KEY=\n' > .env.example
    printf 'NEXT_PUBLIC_SUPABASE_URL=https://liveref.supabase.co\nNEXT_PUBLIC_SUPABASE_ANON_KEY=public-stand-in\n' > .env.local
    printf 'NEXT_PUBLIC_SUPABASE_URL=https://liveref.supabase.co\nNEXT_PUBLIC_SUPABASE_ANON_KEY=public-stand-in\nSUPABASE_SERVICE_ROLE_KEY=service-role-stand-in\n' > .env.container
    printf 'FROM node:22-alpine\nENV HOSTNAME=0.0.0.0 PORT=3000\nCMD ["node", "server.js"]\n' > Dockerfile
    # What linking and keep-out-of-git.sh leave, as a launched project has it.
    printf '.vercel\n.env*\n!.env.example\nsupabase/.temp\n' > .gitignore
    printf 'liveref\n' > supabase/.temp/project-ref
    printf 'postgresql://postgres.liveref@pooler.example.test:5432/postgres\n' > supabase/.temp/pooler-url
    printf '17.4\n' > supabase/.temp/postgres-version
    printf '# Changelog\n\nNewest first.\n' > CHANGELOG.md
    "$rr_real_git" init -q -b main
    "$rr_real_git" config user.name "Recipe rehearsal"
    "$rr_real_git" config user.email rehearsal@example.invalid
    "$rr_real_git" config commit.gpgsign false
    "$rr_real_git" add -A
    "$rr_real_git" commit -q -m "Project on the recipe"
    "$rr_real_git" init -q --bare "$1.git"
    "$rr_real_git" remote add origin "$1.git"
    "$rr_real_git" push -q origin main
  )
}

rr_setup() {
  [ -n "${RR_STATE:-}" ] && return 0
  rr_real_git=$(command -v git)
  RR_STATE="$RR_TMP/state"
  mkdir -p "$RR_STATE" "$RR_TMP/backups"
  export RR_STATE
  rr_write_stand_ins "$RR_TMP/bin"
  rr_project "$RR_TMP/fixture"
  "$rr_real_git" -C "$RR_TMP/fixture" rev-parse main > "$RR_STATE/main"
  printf 'stand-in-password\n' > "$RR_TMP/db-password"
  rr_paste_files
}

rr_paste_files() {
  # What a person or a companion pastes back from Coolify, in each world.
  rr_main=$(cat "$RR_STATE/main")
  rr_p="$RR_TMP/pasted"
  mkdir -p "$rr_p"
  printf 'Deployment status: Finished\n{"status":"ok","database":"ok","commit":"%s","project":"previewref"}\n' "$rr_main" > "$rr_p/good-preview"
  printf 'Deployment status: Finished\n{"status":"ok","database":"ok","commit":"%s","project":"liveref"}\n' "$rr_main" > "$rr_p/bad-preview"
  printf 'Deployment status: Finished\nHealth check: on, path /api/health, port 3000, host 127.0.0.1\nContainer: Running (healthy)\n{"status":"ok","database":"ok","commit":"%s","project":"liveref"}\n' "$rr_main" > "$rr_p/good-going-live"
  printf 'Deployment status: Finished\nHealth check: on, path /api/health, port 3000, host localhost\nContainer: Running (healthy)\n{"status":"ok","database":"ok","commit":"%s","project":"liveref"}\n' "$rr_main" > "$rr_p/bad-going-live"
  printf 'Images kept:\n%s  live\nab12cd3  2026-01-01 10:00\n' "$rr_main" > "$rr_p/good-rollback"
  printf 'Images kept:\n%s  live  2026-01-02 10:00\n' "$rr_main" > "$rr_p/bad-rollback"
  printf 'NEXT_PUBLIC_SUPABASE_URL\nNEXT_PUBLIC_SUPABASE_ANON_KEY\nSUPABASE_SERVICE_ROLE_KEY\n' > "$rr_p/good-secrets"
  printf 'NEXT_PUBLIC_SUPABASE_URL\nNEXT_PUBLIC_SUPABASE_ANON_KEY\n' > "$rr_p/bad-secrets"
  printf 'NEXT_PUBLIC_SUPABASE_URL=https://liveref.supabase.co\n' > "$rr_p/value-secrets"
  printf 'Coolify: build helper container missing\nready on port 3000\n' > "$rr_p/good-logs"
  printf 'ready on port 3000\nError: cannot read notices\n' > "$rr_p/bad-logs"
  printf '{"status":"ok","database":"ok","commit":"%s","project":"liveref"}\n' "$rr_main" > "$rr_p/good-live-health"
  printf '{"status":"ok","database":"error","commit":"0000000","project":"liveref"}\n' > "$rr_p/bad-live-health"
  cp "$rr_p/good-secrets" "$rr_p/good-live-names"
  cp "$rr_p/bad-secrets" "$rr_p/bad-live-names"
}

rr_paste() {
  # rr_paste <world> <section>: the file a person would have pasted.
  printf '%s\n' "$RR_TMP/pasted/$1-$2"
}

rr_script() {
  # rr_script <name>: the script, in the recipe's scripts/ or the shared ones.
  if [ -f "$RR_RECIPE/scripts/$1" ]; then printf '%s\n' "$RR_RECIPE/scripts/$1"
  elif [ -f "$RR_PARTS/scripts/$1" ]; then printf '%s\n' "$RR_PARTS/scripts/$1"
  else rr_fail "no script called $1 in the recipe or its shared parts"; fi
}

rr_case() {
  # rr_case <expected exit> <world> [NAME=VALUE...] <script> [argument...]
  # Run one script in a fresh copy of the throwaway project, with the
  # stand-ins first on PATH, and require its exit code. A NAME= with no value
  # takes that name out of the script's environment.
  rr_setup
  rr_want=$1 rr_world=$2
  shift 2
  rr_env="LIVE_ADDRESS=https://app.example.test DB_PASSWORD_FILE=$RR_TMP/db-password BACKUP_DIR=$RR_TMP/backups LIVE_REF=liveref"
  while [ "$#" -gt 0 ]; do
    case "$1" in
      *=*) rr_env="$rr_env $1"; shift ;;
      *) break ;;
    esac
  done
  rr_file=$1
  shift
  rr_path=$(rr_script "$rr_file")
  rm -rf "$RR_TMP/work" "$RR_TMP/work.git"
  cp -R "$RR_TMP/fixture" "$RR_TMP/work"
  cp -R "$RR_TMP/fixture.git" "$RR_TMP/work.git"
  "$rr_real_git" -C "$RR_TMP/work" remote set-url origin "$RR_TMP/work.git"
  rm -f "$RR_STATE/image"
  rr_got=0
  # shellcheck disable=SC2086
  (cd "$RR_TMP/work" && env -u SUPABASE_DB_PASSWORD -u SUPABASE_ACCESS_TOKEN \
      PATH="$RR_TMP/bin:$PATH" RR_WORLD="$rr_world" $rr_env sh "$rr_path" "$@" \
      < "${RR_STDIN:-/dev/null}") > "$RR_TMP/out" 2> "$RR_TMP/err" || rr_got=$?
  rr_last=$(grep . "$RR_TMP/out" | tail -n 1)
  if grep -q 'stand-in: not' "$RR_TMP/err"; then
    sed 's/^/    /' "$RR_TMP/err" >&2
    rr_fail "$rr_file asked a tool for something it does not document"
  fi
  if [ "$rr_got" != "$rr_want" ]; then
    sed 's/^/    /' "$RR_TMP/out" "$RR_TMP/err" >&2
    rr_fail "$rr_file in the $rr_world world exited $rr_got, not $rr_want"
  fi
  if grep -q 'stand-in-password\|service-role-stand-in' "$RR_TMP/out"; then
    rr_fail "$rr_file printed a secret"
  fi
  printf '%s %s\n' "$rr_file" "$rr_got" >> "$RR_RAN"
  rr_ok "$rr_file in the $rr_world world exits $rr_want: $rr_last"
}

rr_tools() {
  # rr_tools <recipe folder>: the command-line tools it names, one to a line.
  sed -n 's/^Command-line tools: //p' "$1/recipe.md" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^none$' || true
}

rr_named_scripts() {
  # Every script the recipe owns, and every shared script it names.
  for rr_s in "$RR_RECIPE"/scripts/*.sh; do basename -- "$rr_s"; done
  rr_parts=$(sed -n 's/^Shared part: .*](\.\.\/parts\/\([^)]*\)).*/\1/p' "$RR_RECIPE/recipe.md")
  for rr_part in $rr_parts; do
    sed -n 's#^Script: scripts/##p' "$RR_PARTS/$rr_part"
  done
  grep -o 'parts/scripts/[a-z-]*\.sh' "$RR_RECIPE/recipe.md" | sed 's#parts/scripts/##'
}

rr_scripts() {
  # The checks that hold for every recipe, once its cases have run.
  rr_setup
  for rr_s in $(rr_named_scripts | sort -u); do
    grep -q "^$rr_s 0\$" "$RR_RAN" ||
      rr_fail "$rr_s is never run to a pass in this rehearsal"
    grep -Eq "^$rr_s [12]\$" "$RR_RAN" ||
      rr_fail "$rr_s is never run to a fail or a could-not-run in this rehearsal"
  done
  rr_ok "every script the recipe names was run to a pass and to something else"

  for rr_tool in $(rr_tools "$RR_RECIPE"); do
    grep -q "^$rr_tool " "$RR_CALLS" ||
      rr_fail "the recipe names $rr_tool, and none of its scripts calls it"
  done
  rr_ok "every tool on the recipe's Command-line tools line is called by one of its scripts"

  # A misspelt option must fail rather than be taken for the deployment, and
  # the options each command documents must still pass. vercel project add
  # documents no framework option, so a script that sets the framework there
  # is refused and has to use project update.
  for rr_probe in "rollback --timout 5m stand-in" "inspect --wiat stand-in" "promote --yse stand-in" \
    "rollback" "inspect one two" "project add stand-in --framework nextjs" \
    "project update stand-in --framwork nextjs" "link --projet stand-in" "git connect --yse" \
    "curl" "curl /api/health --deploymnet stand-in" "curl /api/health --deployment" \
    "env ls production --json" "ls --format yaml"; do
    # shellcheck disable=SC2086
    if PATH="$RR_TMP/bin:$PATH" vercel $rr_probe >/dev/null 2>&1 </dev/null; then
      rr_fail "the vercel stand-in accepted 'vercel $rr_probe'"
    fi
  done
  rr_ok "the vercel stand-in refuses a misspelt option, and never lists setting values"

  # The settings read goes out with the public key alone. Without it, with a
  # bearer token beside it, or at an address the service does not answer in
  # public, the stand-in refuses.
  rr_settings=https://stand-in.supabase.co/auth/v1/settings
  PATH="$RR_TMP/bin:$PATH" curl -fsS -H "apikey: stand-in" "$rr_settings" >/dev/null 2>&1 ||
    rr_fail "the curl stand-in refused the settings read with the public key"
  for rr_probe in "" "Authorization: Bearer stand-in"; do
    if [ -z "$rr_probe" ]; then
      set -- curl -fsS "$rr_settings"
    else
      set -- curl -fsS -H "apikey: stand-in" -H "$rr_probe" "$rr_settings"
    fi
    if PATH="$RR_TMP/bin:$PATH" "$@" >/dev/null 2>&1; then
      rr_fail "the curl stand-in accepted a settings read '$*'"
    fi
  done
  if PATH="$RR_TMP/bin:$PATH" curl -fsS -H "apikey: stand-in" https://stand-in.supabase.co/auth/v1/admin/users >/dev/null 2>&1; then
    rr_fail "the curl stand-in accepted a read of the admin address"
  fi
  rr_ok "the curl stand-in answers the settings read with the public key alone"

  # The whole recipe through the shipped runner, in the good world: every
  # section passes, the entry is written, and its rollback line says
  # possible, not tried.
  rm -rf "$RR_TMP/work" "$RR_TMP/work.git"
  cp -R "$RR_TMP/fixture" "$RR_TMP/work"
  cp -R "$RR_TMP/fixture.git" "$RR_TMP/work.git"
  "$rr_real_git" -C "$RR_TMP/work" remote set-url origin "$RR_TMP/work.git"
  set --
  for rr_section in preview going-live rollback secrets logs; do
    if grep -A6 "^## $(rr_heading "$rr_section")\$" "$RR_RECIPE/recipe.md" | grep -q '^Who runs it: a companion'; then
      set -- "$@" --pasted "$rr_section=$RR_TMP/pasted/good-$rr_section"
    fi
  done
  rr_got=0
  (cd "$RR_TMP/work" && env -u SUPABASE_DB_PASSWORD -u SUPABASE_ACCESS_TOKEN \
      PATH="$RR_TMP/bin:$PATH" RR_WORLD=good sh "$RR_RUNNER" "$@" --looked preview=yes \
      --set LIVE_ADDRESS=https://app.example.test --set DB_PASSWORD_FILE="$RR_TMP/db-password" \
      --set BACKUP_DIR="$RR_TMP/backups" --set PREVIEW_ADDRESS=https://preview.example.test \
      --set LIVE_REF=liveref "$RR_RECIPE") > "$RR_TMP/out" 2> "$RR_TMP/err" || rr_got=$?
  if [ "$rr_got" != 0 ]; then
    sed 's/^/    /' "$RR_TMP/out" >&2
    rr_fail "run-recipe.sh did not pass every section of $rr_name in the good world (exit $rr_got)"
  fi
  grep -q '^Rollback possible, not tried\.' "$RR_TMP/work/CHANGELOG.md" ||
    rr_fail "run-recipe.sh wrote no rollback line saying possible, not tried"
  rr_ok "run-recipe.sh passes all eight sections of $rr_name and records them in the changelog"
}

rr_heading() {
  case "$1" in
    preview) echo Preview ;; going-live) echo "Going live" ;; rollback) echo Rollback ;;
    secrets) echo Secrets ;; logs) echo Logs ;;
  esac
}
