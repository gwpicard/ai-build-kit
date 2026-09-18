#!/usr/bin/env sh
# standing-instructions.sh: keep the project instructions short and preserve
# the person's choice before a trim.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

FOUNDATION="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"
MAINTAIN="$ROOT/.agents/skills/maintain/SKILL.md"
SETUP="$ROOT/.agents/skills/setup-ai-build-kit/SKILL.md"
VALIDATOR="$ROOT/.agents/tools/validate-kit.sh"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "Standing-instruction checks"

rs_rule "the template stays below the ceiling" 'keep this file under 200 lines'
rs_rule "the file holds only what code cannot show" 'hold only what the code cannot show: the save and review routes, conventions that differ from the default, and pointers to the records'
rs_rule "directory layouts stay out" 'never add a directory layout'
rs_rule "dependency lists stay out" 'dependency list, architecture'
rs_rule "architecture overviews stay out" 'architecture overview, or style rule'
rs_rule "lint rules stay out" 'style rule an automatic check could enforce'
rs_rule "the monthly read checks length and content separately" '`/maintain` measures it monthly and offers a trim when it reaches 200 lines or carries any of that content, even below the ceiling'
rs_rule "the person agrees before a cut" 'cut nothing without the person.s yes'
rs_guard "$FOUNDATION" "the foundation's short content rule"

rs_reset
rs_rule "every path gets a complete count" 'on every build path, count every line in the project.s agents\.md, including blank lines'
rs_rule "the read checks all four kinds of content" 'read it for a directory layout, dependency list, architecture overview or style rule an automatic check could enforce'
rs_rule "maintain holds the ceiling and content rule" 'it stays under 200 lines and holds only what the code cannot show: the save and review routes, conventions that differ from the default, and pointers to the records'
rs_rule "length or content triggers one measured offer" 'at 200 lines or more, or with any of the named content even below that count, offer a trim in one line, using the measured count and what can go'
rs_rule "the visible line asks for the trim" 'the standing instructions have reached 240 lines, and 30 of them describe the folder layout the code already shows\. shall i trim them\?'
rs_rule "length alone needs no invented content" 'where length alone triggers the offer, name that alone; never invent removable content to fill the example'
rs_rule "the monthly offer waits for the person's yes" 'cut nothing without the person.s yes'
rs_rule "a no preserves the file and continues the visit" 'a no leaves the file intact and the visit carries on'
rs_rule "a short file without redundant content stays quiet" 'if the file is short and carries none of that content, say nothing'
rs_rule "the full visit cannot repeat or override the choice" 'agents\.md was already checked in the monthly pass; do not repeat its trim offer or cut anything without the person.s yes'
rs_guard "$MAINTAIN" "the maintenance trim offer"

rs_require_order "the check sits in the monthly pass" "$MAINTAIN" '^## Monthly, light$' 'count every line'
rs_require_order "the check precedes the full-visit section" "$MAINTAIN" 'count every line' '^## Quarterly, or before a handover$'
rs_require_load_bearing "setup writes commands and exceptions within the rule" "$SETUP" 'record run and check commands and any non-standard conventions under agents\.md.s stack section, keeping its content rule and line ceiling'
rs_require_load_bearing "WORKFLOW explains the offer and the person's choice" "$WORKFLOW" 'one line saying how long it is and what can go\. nothing is cut without your yes'
rs_require_load_bearing "the validator counts the foundation template" "$VALIDATOR" 'foundation_agents="\$skills/setup-ai-build-kit/templates/foundation/agents\.md"'
rs_require_load_bearing "the validator enforces under rather than at the ceiling" "$VALIDATOR" 'if \[ "\$foundation_lines" -lt 200 \]'
rs_require_load_bearing "the rehearsal pads a disposable project" "$ROOT/.agents/tests/replay/cases/49.txt" 'pad its agents\.md to exactly 240 lines'
rs_require_load_bearing "the rehearsal declines the trim" "$ROOT/.agents/tests/replay/cases/49.txt" 'no, leave the standing instructions as they are'
rs_require_load_bearing "the rehearsal judges the observed offer and unchanged file" "$ROOT/.agents/tests/scenarios.md" 'the monthly visit reports the measured count in one trim offer and leaves the file unchanged after the person declines'

if [ -z "${RS_LIST:-}" ]; then
  # Run the count block from the real validator in isolation, so this check
  # cannot recurse when the validator runs the written-rule family.
  awk '/^foundation_agents=/ {copy=1} copy {print} copy && /^fi$/ {exit}' \
    "$VALIDATOR" > "$rs_dir/ceiling"
  [ -s "$rs_dir/ceiling" ] || rs_fail "the validator's ceiling block is missing"
  mkdir -p "$rs_dir/skills/setup-ai-build-kit/templates/foundation"
  padded="$rs_dir/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"
  count_passes() {
    sh -c 'SKILLS=$1; fail() { exit 1; }; pass() { :; }; . "$2"' \
      sh "$rs_dir/skills" "$rs_dir/ceiling"
  }
  cp "$FOUNDATION" "$padded"
  count_passes || rs_fail "the shipped foundation exceeds its ceiling"
  rs_ok "the shipped foundation passes the real count"
  awk 'BEGIN {for (i=1; i<=199; i++) print "line"}' > "$padded"
  count_passes || rs_fail "199 lines should pass"
  rs_ok "199 lines pass"
  printf 'line' >> "$padded"
  if count_passes; then rs_fail "200 lines passed without a final newline"; fi
  rs_ok "200 lines fail even without a final newline"
  awk 'BEGIN {for (i=1; i<=240; i++) print "line"}' > "$padded"
  if count_passes; then rs_fail "240 lines passed"; fi
  rs_ok "a padded project exceeds the ceiling"
fi

rs_done
