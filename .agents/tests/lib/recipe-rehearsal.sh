#!/usr/bin/env sh
# recipe-rehearsal.sh: what the rehearsal of each recipe shares. Source it,
# call rr_init, then rr_locate, rr_shape and rr_stand_ins.
#
# rr_locate finds the recipe on the menu or waiting for its real run in
# .agents/tests/recipes-awaiting-run/, and refuses it in both. rr_shape runs
# the shipped shape check: on the menu it must pass, and waiting it must fail
# on its real run alone. rr_stand_ins runs every backticked command the recipe
# and its parts write against stand-ins that answer only what each tool
# documents, so a mistyped option or invented subcommand is refused, and every
# tool the recipe names must be used by some command.

rr_init() {
  # rr_init <title>
  RR_TMP=$(mktemp -d)
  trap 'rm -rf "$RR_TMP"' EXIT
  echo "$1:"
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

rr_locate() {
  # rr_locate <menu path of the recipe>: sets RR_RECIPE and RR_ON_MENU.
  rr_name=$(basename -- "$1")
  if [ -f "$1" ] && [ -f "$RR_WAITING/$rr_name" ]; then
    rr_fail "$rr_name is on the menu and still waiting for its real run; one copy has to go"
  fi
  if [ -f "$1" ]; then
    RR_RECIPE=$1
    RR_ON_MENU=yes
  elif [ -f "$RR_WAITING/$rr_name" ]; then
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
  rr_want="$RR_RECIPE: Real run is not a real date written YYYY-MM-DD: awaiting the first real run"
  if [ "$rr_out" != "$rr_want" ]; then
    printf '%s\n' "$rr_out" >&2
    rr_fail "$rr_name is waiting on something besides its real run"
  fi
  rr_ok "$rr_name has every part the format asks for and waits only on its real run"
}

# --- the stand-ins ---------------------------------------------------------

rr_write_stand_ins() {
  # rr_write_stand_ins <bin>: one stand-in per tool. Each writes what it was
  # asked to a log and refuses anything outside the documented surface.
  mkdir -p "$1"
  cat > "$1/vercel" <<'SH'
#!/usr/bin/env sh
echo "vercel $*" >> "$RR_CALLS"
refuse() { echo "vercel stand-in: not a documented command: vercel $*" >&2; exit 64; }
# One deployment, given as an address or an id, and only the options the
# command documents. A misspelt option is refused rather than taken for the
# deployment.
one_deployment() {
  command=$1
  shift
  target=""
  while [ "$#" -gt 0 ]; do
    case "$command $1" in
      "inspect --logs"|"inspect --wait"|"promote --yes"|"rollback --yes") shift ;;
      "inspect --timeout"|"promote --timeout"|"rollback --timeout")
        [ -n "${2:-}" ] || refuse "$command" "$@"; shift 2 ;;
      "$command -"*) refuse "$command" "$@" ;;
      *) [ -z "$target" ] || refuse "$command" "$@"; target=$1; shift ;;
    esac
  done
  [ -n "$target" ] || refuse "$command"
}
case "$1" in
  inspect) one_deployment "$@"; echo "status  Ready" ;;
  promote|rollback) one_deployment "$@" ;;
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
    echo '{"status":"ok","database":"ok"}' ;;
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
        done ;;
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
    done ;;
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
        done ;;
      *) refuse "$@" ;;
    esac ;;
  env)
    case "$2 ${3:-} ${4:-}" in
      "ls  "|"ls production "|"ls preview "|"pull  ") ;;
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
        done ;;
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
    done ;;
  *) refuse "$@" ;;
esac
SH
  cat > "$1/supabase" <<'SH'
#!/usr/bin/env sh
echo "supabase $*" >> "$RR_CALLS"
refuse() { echo "supabase stand-in: not a documented command: supabase $*" >&2; exit 64; }
case "$*" in
  "init"|"start"|"stop"|"stop --no-backup"|"link"|"db push"|"db push --dry-run") ;;
  "link --project-ref "*) [ "$#" -eq 3 ] || refuse "$@" ;;
  "db dump"*)
    shift 2
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --linked|--local|--role-only|--data-only|--use-copy|--dry-run) shift ;;
        -f|--file|-s|--schema|-x|--exclude|-p|--password) [ -n "${2:-}" ] || refuse db dump "$@"; shift 2 ;;
        *) refuse db dump "$@" ;;
      esac
    done ;;
  *) refuse "$@" ;;
esac
SH
  cat > "$1/psql" <<'SH'
#!/usr/bin/env sh
echo "psql $*" >> "$RR_CALLS"
refuse() { echo "psql stand-in: not an option psql has: $*" >&2; exit 64; }
while [ "$#" -gt 0 ]; do
  case "$1" in
    --single-transaction|--tuples-only) shift ;;
    --variable|--file|--command|--dbname) [ -n "${2:-}" ] || refuse "$@"; shift 2 ;;
    *) refuse "$@" ;;
  esac
done
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
    -H) [ -n "${2:-}" ] || refuse "$@"; headers="$headers|$2"; shift 2 ;;
    https://*|http://localhost:3000/*) url=$1; shift ;;
    *) refuse "$@" ;;
  esac
done
case "$url" in
  https://api.supabase.com/v1/projects/*/database/backups) echo '{"backups":[]}' ;;
  https://api.supabase.com/v1/projects/*/advisors/security) echo '{"lints":[]}' ;;
  # The sign-in settings answer to the public key alone, sent as apikey. A
  # bearer token is how a secret key or a signed-in session would be sent, and
  # a settings read must never carry one. The run gives each secret key a value
  # of its own, so a read sending one as apikey is refused by what it sent.
  https://*.supabase.co/auth/v1/settings)
    case "$headers" in "|apikey: "?*) ;; *) refuse "$url" "headers$headers" ;; esac
    case "$headers" in *"|apikey: "*"|"*) refuse "$url" "headers$headers" ;; esac
    case "$headers" in *service-role-stand-in*|*secret-stand-in*) refuse "$url" "a secret key sent as apikey" ;; esac
    echo '{"external":{"email":true},"disable_signup":false,"mailer_autoconfirm":false}' ;;
  https://*/api/health|http://localhost:3000/api/health) echo '{"status":"ok","database":"ok"}' ;;
  *) refuse "$url" ;;
esac
SH
  cat > "$1/docker" <<'SH'
#!/usr/bin/env sh
echo "docker $*" >> "$RR_CALLS"
case "$*" in
  "info"|"build ."|"build -t "*" .") ;;
  "run -d --name "*" -p 3000:3000 --env-file .env.container "*) [ "$#" -eq 9 ] || { echo "docker stand-in: not a command a recipe may use: docker $*" >&2; exit 64; } ;;
  "rm -f "*) [ "$#" -eq 3 ] || { echo "docker stand-in: not a command a recipe may use: docker $*" >&2; exit 64; } ;;
  *) echo "docker stand-in: not a command a recipe may use: docker $*" >&2; exit 64 ;;
esac
SH
  cat > "$1/git" <<'SH'
#!/usr/bin/env sh
echo "git $*" >> "$RR_CALLS"
case "$*" in
  "rev-parse origin/main") echo 0000000 ;;
  "check-ignore supabase/.temp") echo supabase/.temp ;;
  "check-ignore .vercel .env.local") printf '.vercel\n.env.local\n' ;;
  # Right after vercel link, before the kit lets the file back in.
  "check-ignore --no-index -v .env.example") printf '.gitignore:10:.env*\t.env.example\n' ;;
  # Once the kit has let it back in: nothing named, and status 1, which is how
  # git check-ignore says no path is ignored.
  "check-ignore --no-index .env.example") exit 1 ;;
  "add .env.example") ;;
  *) echo "git stand-in: not a command a recipe may use: git $*" >&2; exit 64 ;;
esac
SH
  cat > "$1/npx" <<'SH'
#!/usr/bin/env sh
echo "npx $*" >> "$RR_CALLS"
case "$*" in
  "next build"|"next start") ;;
  *) echo "npx stand-in: not a command a recipe may use: npx $*" >&2; exit 64 ;;
esac
SH
  chmod +x "$1/vercel" "$1/supabase" "$1/psql" "$1/curl" "$1/docker" "$1/git" "$1/npx"
}

rr_tools() {
  # rr_tools <recipe>: the command-line tools it names, one to a line.
  sed -n 's/^Command-line tools: //p' "$1" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^none$' || true
}

rr_commands() {
  # rr_commands <recipe>: every backticked command in the recipe and the parts
  # it links whose first word is one of its tools, placeholders filled in.
  rr_dir=$(dirname -- "$1")
  rr_files=$1
  for rr_part in $(sed -n 's/^Shared part: .*](\(parts\/[^)]*\)).*/\1/p' "$1"); do
    rr_files="$rr_files $rr_dir/$rr_part"
  done
  rr_tools "$1" > "$RR_TMP/tools"
  # shellcheck disable=SC2086
  awk '
    NR == FNR { tool[$0] = 1; next }
    {
      rest = $0
      while (match(rest, /`[^`]+`/)) {
        span = substr(rest, RSTART + 1, RLENGTH - 2)
        rest = substr(rest, RSTART + RLENGTH)
        # A tool named on its own, such as `curl`, is a mention, not a command.
        if (split(span, word, " ") < 2) continue
        # A value piped in with printf counts when the command it feeds is one
        # of the tools, since that is how a recipe keeps a value off the
        # command line.
        first = word[1]
        if (first == "printf" && split(span, piece, "[|] ") == 2) { split(piece[2], word, " "); first = word[1] }
        if (first in tool) { gsub(/<[^>]*>/, "stand-in", span); print span }
      }
    }
  ' "$RR_TMP/tools" $rr_files
}

rr_run_commands() {
  # rr_run_commands <recipe>: 0 when every command is accepted and every tool
  # is used; otherwise names what went wrong and returns 1.
  RR_CALLS="$RR_TMP/calls"
  export RR_CALLS
  : > "$RR_CALLS"
  rr_write_stand_ins "$RR_TMP/bin"
  mkdir -p "$RR_TMP/work"
  rr_status=0
  rr_commands "$1" > "$RR_TMP/commands"
  [ -s "$RR_TMP/commands" ] || { echo "  no command in the recipe uses one of its tools"; return 1; }
  while IFS= read -r rr_cmd; do
    rr_exit=0
    (cd "$RR_TMP/work" && PATH="$RR_TMP/bin:$PATH" SUPABASE_ACCESS_TOKEN=stand-in SUPABASE_DB_URL=stand-in VALUE=stand-in \
      NEXT_PUBLIC_SUPABASE_ANON_KEY=public-stand-in SUPABASE_SERVICE_ROLE_KEY=service-role-stand-in \
      SUPABASE_SECRET_KEY=secret-stand-in sh -c "$rr_cmd") >/dev/null 2>"$RR_TMP/refusal" || rr_exit=$?
    # git check-ignore answers status 1 when no path is ignored, which is the
    # answer a recipe's check can ask for. Every other command must succeed.
    case "$rr_exit $rr_cmd" in "1 git check-ignore "*) rr_exit=0 ;; esac
    if [ "$rr_exit" -ne 0 ]; then
      echo "  refused: $rr_cmd"
      sed 's/^/    /' "$RR_TMP/refusal"
      rr_status=1
    fi
  done < "$RR_TMP/commands"
  while IFS= read -r rr_tool; do
    grep -q "^$rr_tool " "$RR_CALLS" || grep -qx "$rr_tool" "$RR_CALLS" || {
      echo "  the recipe names $rr_tool, and no command it writes uses it"
      rr_status=1
    }
  done < "$RR_TMP/tools"
  return $rr_status
}

rr_stand_ins() {
  # rr_stand_ins: run the recipe's commands, then prove the run notices an
  # invented subcommand and a named tool that nothing uses.
  if ! rr_run_commands "$RR_RECIPE"; then
    rr_fail "$rr_name writes a command its tools do not have"
  fi
  rr_count=$(wc -l < "$RR_TMP/commands" | tr -d ' ')
  rr_ok "every one of the $rr_count commands $rr_name writes is one its tools document"

  mkdir -p "$RR_TMP/copy"
  ln -s "$RR_PARTS" "$RR_TMP/copy/parts"
  awk '!done && sub(/`supabase db push`/, "`supabase db advisors --type security`") { done = 1 } { print }' \
    "$RR_RECIPE" > "$RR_TMP/copy/$rr_name"
  cmp -s "$RR_RECIPE" "$RR_TMP/copy/$rr_name" && rr_fail "the invented-command copy changed nothing"
  rr_run_commands "$RR_TMP/copy/$rr_name" >/dev/null &&
    rr_fail "a copy writing a subcommand nobody documents was not refused"
  rr_ok "a copy writing a subcommand nobody documents is refused"

  sed 's/^Command-line tools: .*/&, flyctl/' "$RR_RECIPE" > "$RR_TMP/copy/$rr_name"
  rr_run_commands "$RR_TMP/copy/$rr_name" >/dev/null &&
    rr_fail "a copy naming a tool no command uses was not refused"
  rr_ok "a copy naming a tool no command uses is refused"

  # A misspelt option must fail rather than be taken for the deployment, and
  # the options each command documents must still pass. vercel project add
  # documents no framework option, so a recipe that sets the framework there
  # is refused and has to use project update.
  for rr_probe in "rollback --timout 5m stand-in" "inspect --wiat stand-in" "promote --yse stand-in" \
    "rollback" "inspect one two" "project add stand-in --framework nextjs" \
    "project update stand-in --framwork nextjs" "link --projet stand-in" "git connect --yse" \
    "curl" "curl /api/health --deploymnet stand-in" "curl /api/health --deployment"; do
    # shellcheck disable=SC2086
    if PATH="$RR_TMP/bin:$PATH" vercel $rr_probe >/dev/null 2>&1; then
      rr_fail "the vercel stand-in accepted 'vercel $rr_probe'"
    fi
  done
  for rr_probe in "rollback --timeout 5m stand-in" "inspect --wait stand-in" "promote --yes stand-in" \
    "project update stand-in --framework nextjs --yes" "link --project stand-in --yes" "git connect --yes" \
    "curl /api/health --deployment stand-in --yes"; do
    # shellcheck disable=SC2086
    PATH="$RR_TMP/bin:$PATH" vercel $rr_probe >/dev/null 2>&1 ||
      rr_fail "the vercel stand-in refused 'vercel $rr_probe'"
  done
  rr_ok "the vercel stand-in refuses a misspelt option and keeps the documented ones"

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

  # And a recipe whose settings read carried a secret instead is refused as a
  # whole, which proves the read is among the commands the run tries.
  if grep -qF 'parts/supabase-settings.md' "$RR_RECIPE"; then
    mkdir -p "$RR_TMP/secret/parts"
    cp "$RR_PARTS"/*.md "$RR_TMP/secret/parts/"
    cp "$RR_RECIPE" "$RR_TMP/secret/$rr_name"
    for rr_secret in SUPABASE_SERVICE_ROLE_KEY SUPABASE_SECRET_KEY; do
      sed "s#apikey: \$NEXT_PUBLIC_SUPABASE_ANON_KEY#apikey: \$$rr_secret#" \
        "$RR_PARTS/supabase-settings.md" > "$RR_TMP/secret/parts/supabase-settings.md"
      cmp -s "$RR_PARTS/supabase-settings.md" "$RR_TMP/secret/parts/supabase-settings.md" &&
        rr_fail "the secret-key copy of the settings part changed nothing"
      rr_run_commands "$RR_TMP/secret/$rr_name" >/dev/null &&
        rr_fail "a settings read sending $rr_secret was not refused"
    done
    rr_ok "a settings read sending the service role key or a secret key is refused"
  fi
}
