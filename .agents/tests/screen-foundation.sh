#!/usr/bin/env sh
# screen-foundation.sh: guard the screen foundation recorded at founding.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SETUP="$ROOT/.agents/skills/setup-ai-build-kit/SKILL.md"
FOUNDATION="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"
WORKFLOW="$ROOT/WORKFLOW.md"
REPORT="$ROOT/.agents/skills/setup-ai-build-kit/references/completion-report.md"
TASTE="$ROOT/.agents/skills/setup-ai-build-kit/templates/screen-foundation/frontend-design/frontend-design.md"
LICENCE="$ROOT/.agents/skills/setup-ai-build-kit/templates/screen-foundation/frontend-design/LICENSE.txt"

rs_init "Screen-foundation checks"

rs_rule "only a project with a screen gets the foundation" \
  'when the project has a screen'
rs_rule "a project without a screen records nothing" \
  'when the project has no screen, do not add or record either'
rs_rule "the taste skill comes from the vendored copy" \
  'copy the vendored .frontend-design.md.'
rs_rule "the vendored licence stays beside the skill" \
  'copy its .license.txt. beside it'
rs_rule "React takes the shadcn and tweakcn route" \
  'react.*shadcn/ui.*tweakcn theme'
rs_rule "another screen stack takes DaisyUI" \
  'not react.*daisyui'
rs_rule "the person is asked once in plain words" \
  'ask once, in plain words'
rs_rule "the question comes before the installation command" \
  'before adding the foundation or running the one install command'
rs_rule "consent is checked before the installation command" \
  'only after the person says yes, run exactly one of these commands'
rs_rule "React installs a chosen tweakcn theme through shadcn" \
  'npx shadcn.latest add .\$theme_url.'
rs_rule "another screen stack installs the DaisyUI dependency" \
  'npm install --save-dev daisyui.latest'
rs_rule "declining keeps and records the default" \
  'if they say no.*add neither part.*default.*stack section'
rs_rule "the stack section records both choices" \
  'record the design-taste skill and component route'
rs_rule "the stack section says how to swap both choices" \
  'where to replace either one later'
rs_rule "founding does not create DESIGN.md" \
  'do not create .design.md.'
rs_guard "$SETUP" "the setup skill's screen-foundation step"

rs_require_order "the question comes before the vendored copy" \
  "$SETUP" '^Ask once, in plain words' '^Then copy the vendored `frontend-design.md`'

rs_require_order "consent comes before the route commands" \
  "$SETUP" 'Only after the person says yes' 'For React, set `THEME_URL`'

rs_require "the project stack template names the two records" \
  "$FOUNDATION" 'design-taste skill and component route'
rs_require "the project stack template says both can be swapped there" \
  "$FOUNDATION" 'replace either choice here'
rs_require "WORKFLOW explains the one founding choice" \
  "$WORKFLOW" 'asked once before anything is added'
rs_require "WORKFLOW says a no keeps the default" \
  "$WORKFLOW" 'keep the default'
rs_require "the completion report names what a screen project received" \
  "$REPORT" 'design taste and component route'
rs_require "the vendored taste skill is present" "$TASTE" '# frontend design'
rs_require "the Apache licence travels with it" \
  "$LICENCE" 'apache license.*version 2\.0'

# Exercise the two recorded commands without reaching the network. These
# stand-ins log the command that would run, so the cases below can check both
# the route and the point at which it ran.
mkdir -p "$rs_dir/bin"
cat >"$rs_dir/bin/npx" <<'SH'
#!/usr/bin/env sh
printf 'npx %s\n' "$*" >>"$ROUTE_LOG"
SH
cat >"$rs_dir/bin/npm" <<'SH'
#!/usr/bin/env sh
printf 'npm %s\n' "$*" >>"$ROUTE_LOG"
SH
chmod +x "$rs_dir/bin/npx" "$rs_dir/bin/npm"

ROUTE_LOG="$rs_dir/route.log"
export ROUTE_LOG

run_foundation() {
  has_screen=$1
  answer=$2
  stack=$3

  : >"$ROUTE_LOG"
  [ "$has_screen" = yes ] || return 0
  printf 'asked\n' >>"$ROUTE_LOG"
  printf 'answer:%s\n' "$answer" >>"$ROUTE_LOG"
  [ "$answer" = yes ] || return 0

  case "$stack" in
    react)
      grep -q 'npx shadcn@latest add "$THEME_URL"' "$SETUP" || return 1
      PATH="$rs_dir/bin:$PATH" npx shadcn@latest add \
        https://tweakcn.com/r/themes/claude.json
      ;;
    other)
      grep -q 'npm install --save-dev daisyui@latest' "$SETUP" || return 1
      PATH="$rs_dir/bin:$PATH" npm install --save-dev daisyui@latest
      ;;
  esac
}

run_foundation yes yes react || true
[ "$(sed -n '1p' "$ROUTE_LOG")" = asked ] && \
  [ "$(sed -n '2p' "$ROUTE_LOG")" = answer:yes ] && \
  [ "$(sed -n '3p' "$ROUTE_LOG")" = \
    'npx shadcn@latest add https://tweakcn.com/r/themes/claude.json' ] && \
  [ "$(wc -l <"$ROUTE_LOG" | tr -d ' ')" -eq 3 ] && r=yes || r=no
rs_report "React waits for consent, then runs its one route command" "$r"

run_foundation yes yes other || true
[ "$(sed -n '1p' "$ROUTE_LOG")" = asked ] && \
  [ "$(sed -n '2p' "$ROUTE_LOG")" = answer:yes ] && \
  [ "$(sed -n '3p' "$ROUTE_LOG")" = \
    'npm install --save-dev daisyui@latest' ] && \
  [ "$(wc -l <"$ROUTE_LOG" | tr -d ' ')" -eq 3 ] && r=yes || r=no
rs_report "another screen stack waits for consent, then runs its one route command" "$r"

run_foundation yes no react || true
[ "$(cat "$ROUTE_LOG")" = "asked
answer:no" ] && r=yes || r=no
rs_report "declining runs no route command" "$r"

run_foundation no yes react || true
[ ! -s "$ROUTE_LOG" ] && r=yes || r=no
rs_report "a project without a screen runs no route command" "$r"

rs_done
