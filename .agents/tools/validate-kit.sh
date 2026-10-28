#!/usr/bin/env sh
# validate-kit.sh: repository self-validation for ai-build-kit itself.
#
# Checks the kit's own machinery: the skill inventory, frontmatter, internal
# references, retired path vocabulary, generated adapters, shell and config
# syntax, and a set of stale claims this kit has made before and should never
# make again. Run from anywhere; it locates the repository root itself.
#
# This is a maintainer and CI tool. A project built with the kit never runs
# this script; docs/MAINTAINING.md explains why the two are different things.
#
# POSIX sh. Uses python3 for JSON/TOML/YAML parsing when available, and
# degrades to a plain-text sanity check with a printed note when it isn't;
# missing an optional parser reduces how deep that one check goes, it does
# not skip the check's file entirely.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$ROOT"

FAIL=0
fail() {
  echo "FAIL: $1" >&2
  FAIL=1
}
note() {
  echo "NOTE: $1" >&2
}
pass() {
  echo "ok: $1"
}

SKILLS="$ROOT/.agents/skills"
# A skill only the kit's own maintainers use lives here rather than beside the
# installable skills. A shared skills installer reads .agents/skills/ and .claude/skills/
# and merges what it finds by the name in its frontmatter, so a folder in
# either one is a skill somebody installs. This folder is in neither.
MAINTAINER_SKILLS="$ROOT/.agents/maintainer-skills"

# The six commands are the person's whole view of the kit, so their names are
# written here as well as in the inventory: a seventh, or a renamed one, is a
# redesign and fails here first. Everything else is read from the inventory,
# which build-adapters.sh reads too.
INVENTORY="$ROOT/.agents/tools/kit-inventory.txt"
canonical_commands="implement
maintain
setup-ai-build-kit
setup-hosting
shape
what-now"
inventory_names() {
  awk -v k="$1" '$1 == k && NF == 2 { print $2 }' "$INVENTORY" 2>/dev/null | sort
}
expected_commands=$(inventory_names command)
expected_disciplines=$(inventory_names background)
expected_agents=$(inventory_names agent)
if [ ! -f "$INVENTORY" ]; then
  fail "$INVENTORY: missing, so nothing below knows which skills to expect"
elif [ "$expected_commands" != "$canonical_commands" ]; then
  fail "the inventory's commands are not the six the person types: $(printf '%s' "$expected_commands" | tr '\n' ' ')"
fi

# The shape rules for the skills: a command never loads another command's
# files, a background skill has two callers or an agent that loads it, and each
# file keeps to its word budget. A breach fails the run.
structure_strict=1

# Every folder under .agents/maintainer-skills/ is a maintainer skill, and the
# list is read off the folder rather than written out here. A written-out list
# is one a new folder is not on: the second maintainer skill was added by
# editing this list by hand, and had that edit been forgotten the folder would
# have been checked by nothing while this script reported success. A folder
# that cannot be read, or holds nothing, is a failure for the same reason.
expected_maintainer_skills=$(find "$MAINTAINER_SKILLS" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
  | while IFS= read -r skill_dir; do basename -- "$skill_dir"; done | sort)
[ -n "$expected_maintainer_skills" ] || \
  fail "$MAINTAINER_SKILLS: no maintainer skill folder could be read, so none was checked"

# Which of those arrived from somewhere else. A vendored copy carries the
# licence it was published under, and dropping that licence is how a borrowed
# skill turns into an uncredited one. A skill written here has no upstream to
# carry a licence from, so demanding one of every maintainer skill would mean
# inventing a file to satisfy a check.
vendored_maintainer_skills="writing-review"

# ---------------------------------------------------------------------------
echo "== Issue references =="

# A tracked file never cites an issue or a pull request by number. Those numbers
# belong in the issues and pull requests themselves, and in a changelog. In a
# document or a comment a bare number is a pointer the reader cannot follow, and
# once this material is public it points at an unrelated issue in whatever
# numbering that repository happens to have.
#
# So say the thing instead. "The contradiction this check exists to hold shut"
# survives a move; a number does not.
#
# The pattern is built from a variable so this check does not report itself, and
# a character before the hash rules out a shell expansion that trims a prefix.
hash_char='#'
refs=$(git -C "$ROOT" ls-files -- '*.md' '*.sh' '*.yml' '*.json' '*.toml' 2>/dev/null \
  | while IFS= read -r ref_file; do
      grep -HnE "(^|[^A-Za-z0-9\$}])${hash_char}[0-9]{2,4}([^0-9]|\$)" \
        "$ROOT/$ref_file" 2>/dev/null | sed "s|^$ROOT/||"
    done)
if [ -n "$refs" ]; then
  fail "a tracked file cites an issue or pull request by number; say the thing instead:"
  echo "$refs" | sed 's/^/    /' | cut -c1-100
else
  pass "no tracked file cites an issue or pull request by number"
fi

# ---------------------------------------------------------------------------
echo "== Attribution =="

# A tracked file never carries an AI attribution line, and never a link back to
# the session that produced the work. The link is the one that matters: it is a
# personal address on the agent vendor's site, and this repository is public.
#
# The commit-msg hook takes those lines out of a commit message. This check
# covers the other way in, which is somebody pasting a message into a document.
#
# The words are built here rather than written out, so this check does not
# report itself. The rehearsal that drives the hook builds its samples the same
# way, so it needs no exception. One file is left out because carrying the
# words is its job: the hook. Naming it here keeps the exception where a reader
# of the check can see it.
attr_session=$(printf 'claude.ai/code/%s' 'session_')
attr_author=$(printf 'Co-%sed-By: Claude' 'Author')
attr_vendor=$(printf 'noreply@%s.com' 'anthropic')
attr_hits=$(git -C "$ROOT" ls-files 2>/dev/null \
  | grep -v -x -e '.githooks/commit-msg' \
  | while IFS= read -r attr_file; do
      grep -HnIiF -e "$attr_session" -e "$attr_author" -e "$attr_vendor" \
        "$ROOT/$attr_file" 2>/dev/null | sed "s|^$ROOT/||"
    done)
if [ -n "$attr_hits" ]; then
  fail "a tracked file carries an AI attribution line or a session link:"
  echo "$attr_hits" | sed 's/^/    /' | cut -c1-100
else
  pass "no tracked file carries an AI attribution line or a session link"
fi

# The saved mode, not this working copy. A Windows mount reports every file as
# runnable, and the sweep further down does not reach this hook: it skips a
# script the repository hands to sh, which is how the rehearsal drives it.
attr_mode=$(git -C "$ROOT" ls-files -s -- '.githooks/commit-msg' | cut -d' ' -f1)
if [ "$attr_mode" = "100755" ]; then
  pass "the commit-msg hook is saved as a runnable file"
else
  fail ".githooks/commit-msg is missing or not saved as runnable (found mode '$attr_mode')"
fi

# ---------------------------------------------------------------------------
echo "== Stray copies =="

# This repository sits inside ~/Documents, which iCloud syncs. When iCloud has a
# version of something that does not match the one on disk it keeps both, naming
# the newcomer "rule-shape 2.sh". It does that to folders as well, so an empty
# "clarify 2" appears beside the real skill. They arrive in bursts during a
# merge, a checkout or an adapter rebuild, and the numbers climb: 2, then 3.
#
# Nothing said so, which was the real cost. The validator blamed the adapters
# for being out of date and blamed CI for not running a check, because it
# counted ten command files where it demands nine and ten skill folders where
# it demands five. Both accusations pointed at work that was fine.
#
# A stray cannot reach a release, since release-manifest.txt is an allowlist.
# It can be committed by a careless git add -A, and until it is gone every
# later failure reads as something it is not.
#
# Replay results are left out. The harness writes them outside this repository
# now, so the path below normally does not exist; it stays pruned for a run
# pointed back in here by REPLAY_RESULTS. That output is gitignored and is
# rewritten by every pass, so a copy there cannot reach a commit or mislead a
# later check. Failing the validator after every replay run would teach people
# to scroll past this, which is worse than the junk.
strays=$(find "$ROOT" \
  -path "$ROOT/.git" -prune -o \
  -path "$ROOT/node_modules" -prune -o \
  -path "$ROOT/site/node_modules" -prune -o \
  -path "$ROOT/site/dist" -prune -o \
  -path "$ROOT/site/.astro" -prune -o \
  -path "$ROOT/.agents/tests/replay/results" -prune -o \
  \( -type f -o -type d \) \
  \( -name "* [0-9]" -o -name "* [0-9].*" -o -name "* copy" -o -name "* copy.*" \) \
  -print 2>/dev/null \
  | sed "s|^$ROOT/||" | sort)
if [ -n "$strays" ]; then
  fail "copies of files are lying beside the originals; delete them, they are nobody's work:"
  echo "$strays" | sed 's/^/    /'
else
  pass "no copied-and-kept files are lying beside the originals"
fi

# ---------------------------------------------------------------------------
echo "== Skill inventory =="

actual=$(find "$SKILLS" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
expected=$(printf '%s\n%s\n' "$expected_commands" "$expected_disciplines" | sort)

if [ "$actual" != "$expected" ]; then
  fail "the folders in .agents/skills/ do not match the inventory"
  echo "  expected:" >&2
  echo "$expected" | sed 's/^/    /' >&2
  echo "  found:" >&2
  echo "$actual" | sed 's/^/    /' >&2
else
  pass "the six commands and $(printf '%s\n' "$expected_disciplines" | grep -c .) background skills match the inventory, named exactly"
fi

# The update scripts a project runs carry their own list of the kit's skills,
# since a project has no inventory to read. A skill missing from them is one an
# older project is never told to install, and a folder of it is taken for the
# person's own. So each list must hold exactly what the inventory does.
if command -v python3 >/dev/null 2>&1; then
  for update_script in kit-leftovers.py old-skill-pointers.py; do
    listed_skills=$(python3 - "$SKILLS/maintain/scripts/$update_script" <<'PYEOF'
import ast, sys
tree = ast.parse(open(sys.argv[1]).read())
for node in tree.body:
    if isinstance(node, ast.Assign) and any(getattr(t, "id", "") == "KIT_SKILLS" for t in node.targets):
        print("\n".join(sorted(ast.literal_eval(node.value))))
PYEOF
)
    inventory_skills=$(printf '%s\n%s\n' "$expected_commands" "$expected_disciplines" | sort)
    if [ "$listed_skills" != "$inventory_skills" ]; then
      fail "maintain/scripts/$update_script: KIT_SKILLS does not hold exactly the skills the inventory lists"
    else
      pass "maintain/scripts/$update_script knows every skill the inventory lists"
    fi
  done
fi

# Each skill has a SKILL.md. Which of them are commands and which
# are background skills is settled by one setting, and the trigger contract
# further down checks that. Here the question is only that the file exists.
while IFS= read -r name; do
  [ -n "$name" ] || continue
  file="$SKILLS/$name/SKILL.md"
  [ -f "$file" ] || fail "missing $file"
done <<ALLSKILLS
$expected_commands
$expected_disciplines
ALLSKILLS

# The maintainer's own skills sit outside every folder an installer reads, and
# that placement is the whole boundary. There is no marker file and no
# allowlist entry standing between them and a user's project, because a marker
# is this kit's own convention and a shared installer has never heard of it.
# What it does read is a folder, so the check is that the folder is not one.
installer_scanned=".agents/skills
.claude/skills
.claude/commands
.cursor/commands
.gemini/commands"
while IFS= read -r name; do
  [ -n "$name" ] || continue
  file="$MAINTAINER_SKILLS/$name/SKILL.md"
  if [ ! -f "$file" ]; then
    fail "missing $file"
    continue
  fi
  case "
$vendored_maintainer_skills
" in
    *"
$name
"*)
      [ -f "$MAINTAINER_SKILLS/$name/LICENSE" ] || \
        fail "$MAINTAINER_SKILLS/$name/LICENSE: missing vendored skill licence"
      ;;
  esac
  if [ -e "$MAINTAINER_SKILLS/$name/agents/openai.yaml" ]; then
    fail "$MAINTAINER_SKILLS/$name/agents/openai.yaml: a maintainer skill carries no harness policy file"
  fi
  while IFS= read -r scanned; do
    [ -n "$scanned" ] || continue
    for suffix in "" .md .toml; do
      candidate="$scanned/$name$suffix"
      [ ! -e "$ROOT/$candidate" ] || \
        fail "$candidate: a maintainer skill has reached a folder an installer reads, so a project would be offered it as a fifteenth skill"
    done
  done <<SCANNED
$installer_scanned
SCANNED
done <<MAINTAINERSKILLS
$expected_maintainer_skills
MAINTAINERSKILLS

if grep -q '^\.agents/maintainer-skills/' "$ROOT/release-manifest.txt"; then
  fail "release-manifest.txt: the release allowlist carries a maintainer skill, which puts it in a user's project"
else
  pass "every maintainer skill sits outside every folder an installer reads, and outside the release"
fi

# ---------------------------------------------------------------------------
echo "== Harness contracts =="

# Codex reads the canonical .agents/skills/ tree directly, so .codex/skills
# must not exist. A second tree would be a copy nothing refreshes.
if [ -e "$ROOT/.codex/skills" ]; then
  fail ".codex/skills still exists; Codex now reads .agents/skills/ directly"
else
  pass "no .codex/skills adapter tree"
fi

# Claude Code: the two generated background skills are hidden from the user
# command menu. The six generated commands carry neither setting. A command
# used to carry disable-model-invocation, and a regenerate from a stale builder
# would put it back, so its absence is checked rather than assumed.
while IFS= read -r name; do
  [ -n "$name" ] || continue
  gen="$ROOT/.claude/skills/$name/SKILL.md"
  if [ ! -f "$gen" ]; then
    fail "$gen: missing generated Claude discipline skill"
  elif ! grep -q '^user-invocable:[ \t]*false' "$gen"; then
    fail "$gen: expected user-invocable: false"
  fi
done <<DISCIPLINES2
$expected_disciplines
DISCIPLINES2

while IFS= read -r name; do
  [ -n "$name" ] || continue
  gen="$ROOT/.claude/commands/$name.md"
  if [ ! -f "$gen" ]; then
    fail "$gen: missing generated Claude command"
  elif grep -q '^disable-model-invocation:' "$gen"; then
    fail "$gen: generated commands must not carry disable-model-invocation; the agent may start a command the person asks for"
  elif grep -q '^user-invocable:' "$gen"; then
    fail "$gen: generated commands must not carry user-invocable"
  fi
done <<COMMANDS2
$expected_commands
COMMANDS2

pass "no Codex adapter tree, and Claude skill visibility matches the harness contract"

# CLAUDE.md and GEMINI.md must be exactly the harness import line, so loading
# AGENTS.md never depends on the model choosing to read a prose pointer.
check_exact_file() {
  # $1 = file, $2 = expected exact content (no trailing newline)
  file="$1"
  expected="$2"
  if [ ! -f "$file" ]; then
    fail "$file: missing"
    return
  fi
  actual=$(cat "$file")
  if [ "$actual" != "$expected" ]; then
    fail "$file: expected exactly '$expected' (plus an optional trailing newline), found '$actual'"
  fi
}
check_exact_file "$ROOT/CLAUDE.md" "@AGENTS.md"
check_exact_file "$ROOT/GEMINI.md" "@./AGENTS.md"
pass "CLAUDE.md and GEMINI.md import AGENTS.md deterministically"

# ---------------------------------------------------------------------------
echo "== Trigger contract =="

# One setting decides what a skill is. `user-invocable: false` marks a
# background skill, which the agent loads on its own and nobody types. A skill
# without it is a command, and the agent may start a command when the person
# asks for it in a slash, by name, or in plain words. So a background skill
# must carry the setting and a command must not, and the two generated Claude
# trees are compared as whole listings rather than name by name. The listing
# comparison is deliberately independent of the builder: build-adapters.sh
# --check only proves the committed adapters match what the source generates,
# so a source mistake that generates a wrong but self-consistent tree needs a
# second witness anchored to the expected names.
trigger_ok=1

while IFS= read -r name; do
  [ -n "$name" ] || continue
  file="$SKILLS/$name/SKILL.md"
  [ -f "$file" ] || continue
  if ! grep -q '^user-invocable:[ \t]*false' "$file"; then
    fail "$file: expected user-invocable: false (that setting is what marks a background skill; without it the builder treats the skill as a command)"
    trigger_ok=0
  fi
  if [ -e "$ROOT/.claude/commands/$name.md" ]; then
    fail ".claude/commands/$name.md exists; a background skill must not be reachable as a command"
    trigger_ok=0
  fi
done <<DISCIPLINES3
$expected_disciplines
DISCIPLINES3

while IFS= read -r name; do
  [ -n "$name" ] || continue
  file="$SKILLS/$name/SKILL.md"
  [ -f "$file" ] || continue
  if grep -q '^user-invocable:' "$file"; then
    fail "$file: a command never carries user-invocable; that setting marks a background skill"
    trigger_ok=0
  fi
  if [ -e "$ROOT/.claude/skills/$name" ]; then
    fail ".claude/skills/$name exists; a command must not also be generated as a background skill"
    trigger_ok=0
  fi
done <<COMMANDS3
$expected_commands
COMMANDS3

if [ ! -d "$ROOT/.claude/commands" ]; then
  fail ".claude/commands/ is missing; regenerate the adapters"
  trigger_ok=0
else
  expected_command_files=$(printf '%s\n' "$expected_commands" | sed 's/$/.md/' | sort)
  actual_command_files=$(find "$ROOT/.claude/commands" -mindepth 1 -maxdepth 1 -exec basename {} \; | sort)
  if [ "$actual_command_files" != "$expected_command_files" ]; then
    fail ".claude/commands/ must hold exactly the six generated command files"
    echo "  expected:" >&2
    echo "$expected_command_files" | sed 's/^/    /' >&2
    echo "  found:" >&2
    echo "$actual_command_files" | sed 's/^/    /' >&2
    trigger_ok=0
  fi
fi

if [ ! -d "$ROOT/.claude/skills" ]; then
  fail ".claude/skills/ is missing; regenerate the adapters"
  trigger_ok=0
else
  expected_skill_dirs=$(printf '%s\n' "$expected_disciplines" | sort)
  actual_skill_dirs=$(find "$ROOT/.claude/skills" -mindepth 1 -maxdepth 1 -exec basename {} \; | sort)
  if [ "$actual_skill_dirs" != "$expected_skill_dirs" ]; then
    fail ".claude/skills/ must hold exactly the background skills the inventory lists"
    echo "  expected:" >&2
    echo "$expected_skill_dirs" | sed 's/^/    /' >&2
    echo "  found:" >&2
    echo "$actual_skill_dirs" | sed 's/^/    /' >&2
    trigger_ok=0
  fi
fi

# The Cursor and Gemini trees carry the same six commands and were covered
# only by the drift comparison, which asks whether the committed adapters match
# what the source generates. A source mistake that generates a wrong but
# self-consistent tree satisfies that and reaches a project. These anchor both
# folders to the expected names, as the two Claude trees already are.
for adapter in ".cursor/commands:.md:Cursor" ".gemini/commands:.toml:Gemini CLI"; do
  dir=${adapter%%:*}
  rest=${adapter#*:}
  ext=${rest%%:*}
  tool=${rest#*:}
  if [ ! -d "$ROOT/$dir" ]; then
    fail "$dir/ is missing; regenerate the adapters"
    trigger_ok=0
    continue
  fi
  expected_files=$(printf '%s\n' "$expected_commands" | sed "s/\$/$ext/" | sort)
  actual_files=$(find "$ROOT/$dir" -mindepth 1 -maxdepth 1 -exec basename {} \; | sort)
  if [ "$actual_files" != "$expected_files" ]; then
    fail "$dir/ must hold exactly the six generated $tool command files"
    echo "  expected:" >&2
    echo "$expected_files" | sed 's/^/    /' >&2
    echo "  found:" >&2
    echo "$actual_files" | sed 's/^/    /' >&2
    trigger_ok=0
  fi
done

[ "$trigger_ok" -eq 1 ] && pass "background skills carry user-invocable: false and commands do not, and the generated command and skill folders all hold exactly the expected names"

# ---------------------------------------------------------------------------
echo "== Agents =="

# An agent runs one or more background skills in a fresh context. Its brief has
# one home, .agents/agents/<name>.md, and each coding agent with a native
# format gets a generated file that points back at it. The names are anchored
# to the inventory here, as the command folders are above, so a source mistake
# that generates a wrong but self-consistent tree still fails. The Copilot file
# must stay out of the person's own agent picker: the person's view is the six
# commands.
agents_ok=1
expected_agent_files() {
  printf '%s\n' "$expected_agents" | sed '/^$/d' | sed "s/\$/$1/" | sort
}
for agent_dir in ".agents/agents:.md" ".claude/agents:.md" ".codex/agents:.toml" \
                 ".gemini/agents:.md" ".github/agents:.agent.md"; do
  dir=${agent_dir%%:*}
  ext=${agent_dir#*:}
  actual_agent_files=$(find "$ROOT/$dir" -mindepth 1 -maxdepth 1 -type f -exec basename {} \; 2>/dev/null | sort)
  if [ "$actual_agent_files" != "$(expected_agent_files "$ext")" ]; then
    fail "$dir/ must hold exactly the agents the inventory lists"
    echo "  expected:" >&2
    expected_agent_files "$ext" | sed 's/^/    /' >&2
    echo "  found:" >&2
    printf '%s\n' "$actual_agent_files" | sed 's/^/    /' >&2
    agents_ok=0
  fi
done
while IFS= read -r name; do
  [ -n "$name" ] || continue
  copilot="$ROOT/.github/agents/$name.agent.md"
  if [ -f "$copilot" ] && ! grep -q '^user-invocable: false$' "$copilot"; then
    fail "$copilot: a generated Copilot agent must carry user-invocable: false"
    agents_ok=0
  fi
done <<AGENTNAMES
$expected_agents
AGENTNAMES
[ "$agents_ok" -eq 1 ] && pass "each agent has one canonical brief and a generated file for every coding agent that reads one"

# ---------------------------------------------------------------------------
echo "== Frontmatter =="

# Prefer a YAML parser already installed on the machine. The fallback is a
# conservative check of scalar values, not a claim to parse all of YAML.
fm_parser=fallback
if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
  fm_parser=python
elif command -v ruby >/dev/null 2>&1 && ruby -ryaml -e 'exit 0' >/dev/null 2>&1; then
  fm_parser=ruby
else
  note "no YAML parser available; checking skill headers with the conservative fallback"
fi
parse_skill_header() {
  case "${1:-$fm_parser}" in
    python)
      python3 -c '
import sys, yaml
try:
    doc = yaml.safe_load(sys.stdin.read())
    if not isinstance(doc, dict) or any(not isinstance(doc.get(k), str) or not doc[k].strip() for k in ("name", "description")):
        raise ValueError("name and description must be non-empty strings")
    print(doc["name"])
except (yaml.YAMLError, ValueError) as error:
    print(error, file=sys.stderr)
    sys.exit(1)
' ;;
    ruby)
      ruby -ryaml -e '
begin
  doc = YAML.safe_load(STDIN.read)
  unless doc.is_a?(Hash) && %w[name description].all? { |key| doc[key].is_a?(String) && !doc[key].strip.empty? }
    raise "name and description must be non-empty strings"
  end
  puts doc.fetch("name")
rescue StandardError => error
  warn error.message
  exit 1
end
' ;;
    fallback)
      awk '
        /^[ \t]*($|#)/ { next }
        /^[^ \t][^:]*:/ {
          key=$0; sub(/:.*/, "", key)
          value=$0; sub(/^[^:]*:[ \t]*/, "", value)
          sub(/[ \t]+#.*/, "", value); sub(/[ \t]+$/, "", value)
          first=substr(value,1,1)
          quoted=(first=="\"" || first==sprintf("%c",39))
          block=(value ~ /^[|>][-+0-9]*$/)
          if (!quoted && !block && (index(value,": ") || (first!="" && index("-?:,[]{}#&*!|>%@`",first)))) bad=1
          if (quoted && (length(value)<2 || substr(value,length(value),1)!=first)) bad=1
          if (key=="name" || key=="description") {
            if (++seen[key]>1) bad=1
            if (quoted) value=substr(value,2,length(value)-2)
            else if (!block && (value=="" || tolower(value) ~ /^(null|~|true|false|yes|no|on|off|[-+]?\.inf|\.nan)$/ || value ~ /^[-+]?([0-9]|\.[0-9])/)) bad=1
            if (value=="") bad=1
            if (block) waiting=key
            else { present[key]=1; if (key=="name") name=value }
          } else waiting=""
          next
        }
        /^[ \t]+/ { if (waiting && $0 ~ /[^ \t]/) { present[waiting]=1; if (waiting=="name") bad=1 }; next }
        { bad=1 }
        END { if (bad || !present["name"] || !present["description"]) exit 1; print name }
      ' ;;
  esac
}

# Exercise both the selected parser and the fallback against the installer
# failure, YAML indicators and values that parse but are not strings.
fm_selftest_ok=1
for fm_mode in "$fm_parser" fallback; do
  for fm_valid in 'A plain description.' '"Evidence: fresh output."' "'Evidence: fresh output.'"; do
    if ! printf 'name: sample\ndescription: %s\n' "$fm_valid" | parse_skill_header "$fm_mode" >/dev/null 2>&1; then
      fail "skill header self-test rejected a valid string ($fm_mode)"
      fm_selftest_ok=0
    fi
  done
  if ! printf 'name: sample\ndescription: |\n  A block description.\n' | parse_skill_header "$fm_mode" >/dev/null 2>&1; then
    fail "skill header self-test rejected a block string ($fm_mode)"
    fm_selftest_ok=0
  fi
  for fm_bad in 'Evidence: fresh output.' '[a, b]' '{a: b}' '*missing' '@invalid' '`invalid' '>bad' '|bad' 'true' 'NO' '42' '.5' '.nan' 'null' '""'; do
    if printf 'name: sample\ndescription: %s\n' "$fm_bad" | parse_skill_header "$fm_mode" >/dev/null 2>&1; then
      fail "skill header self-test accepted an invalid description ($fm_mode): $fm_bad"
      fm_selftest_ok=0
    fi
  done
  if [ "$fm_mode" = fallback ]; then
    for fm_indicator in '&anchor value' '!tag value'; do
      if printf 'name: sample\ndescription: %s\n' "$fm_indicator" | parse_skill_header fallback >/dev/null 2>&1; then
        fail "skill header fallback accepted an unquoted YAML indicator"
        fm_selftest_ok=0
      fi
    done
  fi
  if printf 'name: [sample]\ndescription: A string.\n' | parse_skill_header "$fm_mode" >/dev/null 2>&1; then
    fail "skill header self-test accepted a non-string name ($fm_mode)"
    fm_selftest_ok=0
  fi
done
[ "$fm_selftest_ok" -eq 0 ] || pass "skill header self-tests reject the installer fault and non-string fields"

seen_names=""
skillfiles=$(find "$SKILLS" "$MAINTAINER_SKILLS" "$ROOT/.claude" "$ROOT/.cursor" \
  "$ROOT/.gemini" "$ROOT/.codex" "$ROOT/.github" -type f -name SKILL.md | sort)
fm_ok=1
while IFS= read -r file; do
  [ -n "$file" ] || continue
  folder=$(basename "$(dirname "$file")")
  if ! fm_header=$(awk '
    NR==1 { if ($0 !~ /^---[ \t]*$/) exit 1; next }
    /^---[ \t]*$/ { closed=1; exit }
    { print }
    END { if (!closed) exit 1 }
  ' "$file"); then
    fail "$file: missing or unclosed YAML front matter"
    fm_ok=0
    continue
  fi
  if ! fm_name=$(printf '%s\n' "$fm_header" | parse_skill_header); then
    fail "$file: invalid YAML front matter; name and description must be non-empty strings"
    fm_ok=0
    continue
  fi
  if [ "$fm_name" != "$folder" ]; then
    fail "$file: frontmatter name '$fm_name' does not match folder '$folder'"
    fm_ok=0
  fi
  # Adapters intentionally repeat canonical names. Only a second name within
  # the same skill root is a duplicate.
  fm_identity="$(dirname "$(dirname "$file")")/$fm_name"
  if printf '%s\n' "$seen_names" | grep -qxF "$fm_identity"; then
    fail "$file: duplicate skill name '$fm_name'"
    fm_ok=0
  fi
  seen_names=$(printf '%s\n%s' "$seen_names" "$fm_identity")
done <<SKILLFILES
$skillfiles
SKILLFILES

[ "$fm_ok" -eq 0 ] || pass "frontmatter checked on $(printf '%s\n' "$skillfiles" | grep -c .) SKILL.md files ($fm_parser)"

# ---------------------------------------------------------------------------
echo "== Skill structure =="

# Commands route and call background skills; they hold no method of their own.
# check-structure.py reads the shape off the files: a command loading another
# command's references, a background skill nobody calls, a file over its word
# budget. Its own header gives the rules. A rule sentence cannot hold this,
# because nobody can see which sentence a cut removed.
structure_tool="$ROOT/.agents/tools/check-structure.py"
if [ ! -f "$structure_tool" ]; then
  fail "$structure_tool: missing"
elif ! command -v python3 >/dev/null 2>&1; then
  note "python3 not available; skipped the skill structure check"
else
  if [ "$structure_strict" -eq 1 ]; then
    structure_out=$(python3 "$structure_tool" --strict 2>&1) && structure_rc=0 || structure_rc=$?
  else
    structure_out=$(python3 "$structure_tool" 2>&1) && structure_rc=0 || structure_rc=$?
  fi
  if [ "$structure_rc" -ne 0 ]; then
    fail "the skills are out of shape:"
    printf '%s\n' "$structure_out" | sed 's/^/    /' >&2
  elif [ -n "$structure_out" ]; then
    note "the skills are out of shape, reported only until the check turns strict:"
    printf '%s\n' "$structure_out" | sed 's/^/    /' >&2
  else
    pass "no command loads another's files, each background skill has its callers, and each file keeps its word budget"
  fi
fi

# ---------------------------------------------------------------------------
echo "== References =="

# Every local Markdown link resolves.
mdfiles=$(find "$ROOT" \
  -path "$ROOT/.git" -prune -o \
  -path "$ROOT/site/node_modules" -prune -o \
  -path "$ROOT/site/dist" -prune -o \
  -path "$ROOT/site/.astro" -prune -o \
  -path "$ROOT/.agents/tmp" -prune -o \
  -name '*.md' -print | sort)
while IFS= read -r mdfile; do
  [ -n "$mdfile" ] || continue
  # The public README lives one level down in the maintainer source, then moves
  # to the release root. Resolve its links where readers will open them.
  case "$mdfile" in
    "$ROOT/README.md") dir=$ROOT ;;
    *) dir=$(dirname "$mdfile") ;;
  esac
  matches=$(grep -noE '\[[^]]*\]\([^)]*\)' "$mdfile" || true)
  [ -n "$matches" ] || continue
  while IFS=: read -r lineno full; do
    [ -n "$lineno" ] || continue
    inside="${full#*(}"
    path="${inside%)}"
    case "$path" in
      http://*|https://*|mailto:*|"#"*|"") continue ;;
      # A site page links to another site page by its address; site-links.sh
      # checks those against the built pages.
      /ai-build-kit/*) case "$mdfile" in "$ROOT"/site/src/content/docs/*) continue ;; esac ;;
    esac
    path_noanchor="${path%%#*}"
    [ -n "$path_noanchor" ] || continue
    case "$mdfile:$path_noanchor" in
      *:/*)
        target="$ROOT$path_noanchor"
        ;;
      *)
        target="$dir/$path_noanchor"
        ;;
    esac
    # The public README's links resolve from the release root, where the files
    # it points at sit beside it. They sit beside it here too now, so no detour
    # is needed; the branch is kept because a link may still be written relative
    # to the release rather than to this tree.
    if [ "$mdfile" = "$ROOT/README.md" ] && [ ! -e "$target" ] \
      && [ -e "$ROOT/$path_noanchor" ]; then
      target="$ROOT/$path_noanchor"
    fi
    if [ ! -e "$target" ]; then
      fail "$mdfile:$lineno: broken link -> $path"
    fi
  done <<MATCHES
$matches
MATCHES
done <<MDFILES
$mdfiles
MDFILES

# Every skill/reference/template path named anywhere (including backtick code
# spans, not just markdown links) resolves.
pathrefs=$(grep -rnoE --include='*.md' -- \
  '\.agents/(skills|tests|guard|hooks|tools)/[A-Za-z0-9_./-]+\.(md|sh)' \
  "$ROOT" 2>/dev/null | grep -v '/\.agents/tmp/' | sort -u || true)
while IFS=: read -r reffile lineno relpath; do
  [ -n "$relpath" ] || continue
  # .agents/hooks/session-start.sh is a project path that start creates from
  # templates/foundation/session-start.sh. It deliberately does not exist in
  # this repository, because the kit's own source must never wire a project
  # session hook into itself. Its real source is asserted separately below.
  case "$relpath" in
    .agents/hooks/session-start.sh) continue ;;
  esac
  target="$ROOT/$relpath"
  if [ ! -e "$target" ]; then
    fail "$reffile:$lineno: referenced path does not exist -> $relpath"
  fi
done <<PATHREFS
$pathrefs
PATHREFS

pass "markdown links and skill/reference/template paths resolve"

# Bare relative references written inside skill files (references/foo.md,
# templates/foo.md, recipes/foo.md, or the cross-skill sibling form
# other-skill/references/foo.md, other-skill/recipes/foo.md)
# resolve relative to (a) the containing file's own directory, or (b) the
# skills root, whichever exists. The check above only catches references
# already spelled out with a full .agents/... path prefix.
#
# A file in another skill is written as the `other-skill` skill's
# `references/foo.md`, since the skills folder differs from one installation
# to the next. That form is read as other-skill/references/foo.md, including
# when the line breaks between the skill's name and its path.
skillmdfiles=$(find "$SKILLS" -name '*.md' | sort)
relpat='(references|templates|recipes)/[A-Za-z0-9_./-]+[.]md|[a-z][a-z-]*/(references|templates|recipes)/[A-Za-z0-9_./-]+[.]md'
qualifiedpat='[.]agents/(skills|tests|guard|hooks|tools)/[A-Za-z0-9_./-]+[.](md|sh)'
relhits=$(printf '%s\n' "$skillmdfiles" | while IFS= read -r f; do
  [ -n "$f" ] || continue
  awk -v pat="$relpat" -v qualified="$qualifiedpat" -v q="'" '
    BEGIN {
      named = "`[a-z][a-z-]*` skill" q "s `"
      named_at_end = "`[a-z][a-z-]*` skill" q "s[ \t]*$"
    }
    FNR == 1 { carry = "" }
    {
      line = $0
      if (carry != "") {
        sub(/^[ \t]*`/, "`" carry "/", line)
        carry = ""
      }
      while (match(line, named)) {
        name = substr(line, RSTART + 1)
        sub(/`.*$/, "", name)
        line = substr(line, 1, RSTART - 1) "`" name "/" substr(line, RSTART + RLENGTH)
      }
      if (match(line, named_at_end)) {
        carry = substr(line, RSTART + 1)
        sub(/`.*$/, "", carry)
        line = substr(line, 1, RSTART - 1)
      }
      gsub(qualified, "", line)
      rest = line
      while (match(rest, pat)) {
        print FILENAME ":" FNR ":" substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)
      }
    }
  ' "$f"
done)
while IFS=: read -r reffile lineno relpath; do
  [ -n "$relpath" ] || continue
  dir=$(dirname "$reffile")
  if [ -e "$dir/$relpath" ] || [ -e "$SKILLS/$relpath" ]; then
    continue
  fi
  fail "$reffile:$lineno: relative reference does not resolve (tried $dir/$relpath and $SKILLS/$relpath) -> $relpath"
done <<RELHITS
$relhits
RELHITS
pass "bare relative skill references (references/*.md, templates/*.md, recipes/*.md, sibling-skill form) resolve"

# Recipes. A recipe is one build stack paired with one place to run it, and
# docs/RECIPES.md says what one must hold. A recipe is a folder holding
# recipe.md, its scripts and PROVEN.md, and the recipes folder is the menu, so
# a folder in it with a recipe.md is offered to somebody founding a project.
# Each must have the shape the format asks for and carry real dates. Each must
# also have its own rehearsal that runs the recipe's scripts against the tool
# stand-ins and names the recipe folder, because a rehearsal that only exits
# cleanly guards nothing. The blank is held to the same shape so it cannot
# drift from the format it is copied from. Shared parts sit in recipes/parts/,
# are held to the lines a section carries, and are never read as menu entries,
# since the parts folder holds no recipe.md. The folder may be empty, since the
# format came before the first recipe.
recipe_checker="$ROOT/.agents/tools/check-recipes.sh"
recipe_blank="$SKILLS/setup-hosting/templates/recipe.md"
recipe_ok=1
if [ ! -x "$recipe_checker" ]; then
  fail ".agents/tools/check-recipes.sh is missing or not executable"
  recipe_ok=0
else
  if ! "$recipe_checker" --template "$recipe_blank" >&2; then
    fail "$recipe_blank: the recipe blank does not have the shape the format asks for"
    recipe_ok=0
  fi
  for recipe_part in "$SKILLS"/setup-hosting/recipes/parts/*.md; do
    [ -f "$recipe_part" ] || continue
    if ! "$recipe_checker" --part "$recipe_part" >&2; then
      fail "$recipe_part: the shared part does not carry the lines a section needs"
      recipe_ok=0
    fi
  done
  for recipe_loose in "$SKILLS"/setup-hosting/recipes/*.md; do
    [ -f "$recipe_loose" ] || continue
    fail "$recipe_loose: a recipe is a folder holding recipe.md, not a loose file"
    recipe_ok=0
  done
  for recipe in "$SKILLS"/setup-hosting/recipes/*/; do
    recipe=${recipe%/}
    [ "$(basename "$recipe")" != parts ] || continue
    recipe_name=$(basename "$recipe")
    if [ ! -f "$recipe/recipe.md" ]; then
      fail "$recipe: a folder on the menu holds no recipe.md"
      recipe_ok=0
      continue
    fi
    if ! "$recipe_checker" "$recipe" >&2; then
      fail "$recipe: the recipe does not have the shape the format asks for"
      recipe_ok=0
    fi
    if ! "$recipe_checker" --rehearsal "$recipe" "$ROOT/.agents/tests/recipe-$recipe_name.sh" >&2; then
      fail "$recipe: no rehearsal in .agents/tests/recipe-$recipe_name.sh guards it"
      recipe_ok=0
    fi
  done
fi
[ "$recipe_ok" -eq 0 ] || pass "every recipe, shared part and the recipe blank have the shape the format asks for"

# team.md must not exist and must not be referenced anywhere tracked.
if [ -e "$SKILLS/setup-ai-build-kit/templates/team.md" ]; then
  fail "team.md still exists; it was removed from the workflow"
fi
# setup-ai-build-kit/SKILL.md and MAINTAINING.md are excluded: they name team.md only to
# say it's gone (an explicit "do not create this" and a description of this
# very check), not to describe it as part of the live workflow.
teamrefs=$(grep -rln --include='*.md' --include='*.sh' --include='*.toml' -- 'team\.md' "$ROOT" 2>/dev/null \
  | grep -v '/\.git/' \
  | grep -v '\.agents/tools/validate-kit\.sh$' \
  | grep -v '\.agents/skills/setup-ai-build-kit/SKILL\.md$' \
  | grep -v 'docs/MAINTAINING\.md$' \
  || true)
if [ -n "$teamrefs" ]; then
  fail "team.md is referenced in: $(printf '%s' "$teamrefs" | tr '\n' ' ')"
else
  pass "no stray team.md references"
fi

# ---------------------------------------------------------------------------
echo "== Record matches machinery =="

# Each check describes itself on its second line, as "# <name>: <what it
# guards>", so the record of the checks lives beside the checks and cannot drift
# from them. The maintainer AGENTS.md points at the folder rather than listing it.
rec_ok=1
for testscript in "$ROOT"/.agents/tests/*.sh; do
  [ -f "$testscript" ] || continue
  base=$(basename "$testscript")
  if ! sed -n 2p "$testscript" | grep -q "^# $base: "; then
    fail ".agents/tests/$base does not say what it guards on its second line"
    rec_ok=0
  fi
done
[ "$rec_ok" -eq 1 ] && pass "every check under .agents/tests/ says what it guards"

# Keep the project template short enough to read every session. The maintainer's
# own AGENTS.md has a different job and is outside this ceiling.
#
# The ceiling applies to the file a project ends up with, not to the template.
# Founding writes the project line, the capability profile, the stack section
# and its recipe line, and a framework's own starter may append its rules block
# too. A template of 196 lines passed here while a fresh founding came out at
# 219, so the template must leave room for a fixed budget of founding's lines:
# the 23 that founding measured on the recipe campaign, and the 10 of the
# Next.js starter's block, with a margin of 5 more under the ceiling.
founding_budget=33
founding_margin=5
foundation_agents="$SKILLS/setup-ai-build-kit/templates/foundation/AGENTS.md"
if [ ! -f "$foundation_agents" ]; then
  fail "$foundation_agents: missing"
else
  foundation_lines=$(awk 'END { print NR }' "$foundation_agents")
  if [ $((foundation_lines + founding_budget + founding_margin)) -lt 200 ]; then
    pass "the foundation instructions leave room for founding under 200 lines ($foundation_lines + $founding_budget + $founding_margin)"
  else
    fail "the foundation instructions have $foundation_lines lines; with founding's $founding_budget and a margin of $founding_margin they reach 200"
  fi
fi

# The tie-breaker between a written instruction and an automatic check lives in
# the project's standing instructions, so a session that finds the two in
# conflict trusts the check rather than the stale rule. Checked where a project
# receives it, the foundation AGENTS.md template.
tiebreaker="$SKILLS/setup-ai-build-kit/templates/foundation/AGENTS.md"
if [ ! -f "$tiebreaker" ]; then
  fail "$tiebreaker: missing"
elif ! tr '\n' ' ' < "$tiebreaker" | grep -qF -- "an instruction can fall out"; then
  fail "$tiebreaker: does not tell a session to trust the check when an instruction and a check disagree"
else
  pass "the foundation instructions make the check the tie-breaker over a stale instruction"
fi

# ---------------------------------------------------------------------------
echo "== Fit-check contract =="

fitcheck="$SKILLS/fit-check/SKILL.md"
fitrecord="$SKILLS/fit-check/references/risk-record.md"
if [ ! -f "$fitcheck" ]; then
  fail "$fitcheck: missing"
else
  fc_ok=1
  for needle in "## The three questions" "## Risk areas" "## Rechecks and going live"; do
    if ! grep -qF "$needle" "$fitcheck"; then
      fail "$fitcheck: missing expected heading '$needle'"
      fc_ok=0
    fi
  done
  [ "$fc_ok" -eq 1 ] && pass "the fit-check skill asks the three questions and names the risk areas"
fi

# The risk record has one owner. The fit check's risk record defines the fields
# and the masterplan template carries them, so a field added to one and
# forgotten in the other would leave a project recording something the fit
# check never writes, or writing something the template has no room for.
mpt="$SKILLS/setup-ai-build-kit/templates/masterplan.md"
if [ ! -f "$mpt" ] || [ ! -f "$fitrecord" ]; then
  fail "cannot compare the risk record: the fit check's risk record or the masterplan template is missing"
else
  bp_ok=1
  for field in Exposed Data "Wrong answer" Recovery Access "Risk areas" Accepted "Runs on its own" "Recheck when" "Last checked"; do
    grep -q "^$field:" "$mpt" || { fail "$mpt: risk record is missing '$field:'"; bp_ok=0; }
    grep -q "^$field:" "$fitrecord" || { fail "$fitrecord: risk record is missing '$field:'"; bp_ok=0; }
  done
  [ "$bp_ok" -eq 1 ] && \
    pass "the masterplan template and the fit check's risk record agree on the risk fields, including Accepted"
fi

# ---------------------------------------------------------------------------
echo "== Pieces contract =="

# A piece's shape has one owner, pieces.md, and one form a project fills in.
# The two are written separately and read by different audiences, so nothing
# stops them drifting apart except this.
pieces="$SKILLS/records/references/pieces.md"
pieceform="$SKILLS/setup-ai-build-kit/templates/foundation/piece-issue.yml"
if [ ! -f "$pieces" ] || [ ! -f "$pieceform" ]; then
  fail "the pieces contract is incomplete: expected $pieces and $pieceform"
else
  pc_ok=1
  # The body sections, spelled the same in both places.
  for section in "So that" "Done when" "Evidence" "Not in this piece" "Decided"; do
    grep -qF "## $section" "$pieces" || \
      { fail "$pieces: does not define the '$section' section"; pc_ok=0; }
    grep -qF "label: $section" "$pieceform" || \
      { fail "$pieceform: has no field for '$section'"; pc_ok=0; }
  done
  # The Risk areas field, which mark-ready requires, is defined in the piece
  # shape and has a field in the form.
  grep -qF "Risk areas:" "$pieces" || \
    { fail "$pieces: does not define the 'Risk areas:' line"; pc_ok=0; }
  grep -qF "label: Risk areas" "$pieceform" || \
    { fail "$pieceform: has no field for 'Risk areas'"; pc_ok=0; }
  # The subject labels, which decide evidence and save route, so a label the
  # skills do not know about is worse than a missing one. Matched on the table
  # row rather than the whole file: each label is also named in the prose that
  # explains it, so a loose search keeps passing after the row itself changed.
  for label in visual "how it works" data "accounts and permissions" \
               finance "external service" "background automation"; do
    grep -qF "| \`$label\` |" "$pieces" || \
      { fail "$pieces: the subject table does not define '$label'"; pc_ok=0; }
  done
  # A piece is allowed to be about more than one thing. Where that is unwritten
  # the agent picks the closest single subject and silently drops the evidence
  # the other one required, which is the fault this vocabulary replaced.
  grep -qF "A piece carries every subject label that fits it" "$pieces" || \
    { fail "$pieces: does not say a piece carries every subject that fits"; pc_ok=0; }
  # Matched against the definition list rather than the whole file. A state
  # label is also mentioned in the prose that explains it, so a loose search
  # keeps passing after the definition itself has been renamed.
  for label in building blocked parked broken \
               needs-clarification needs-prototype needs-research; do
    grep -qF -- "- \`$label\`," "$pieces" || \
      { fail "$pieces: the state label list does not define '$label'"; pc_ok=0; }
  done
  # The form's default label must be one the reference knows.
  formlabel=$(awk -F'"' '/^labels:/ { print $2; exit }' "$pieceform")
  case "$formlabel" in
    visual|"how it works"|data|"accounts and permissions"|finance|"external service"|"background automation") ;;
    *) fail "$pieceform: default label '$formlabel' is not one of the seven subjects"; pc_ok=0 ;;
  esac
  [ "$pc_ok" -eq 1 ] && \
    pass "pieces.md and the issue form agree on the sections and the label set"
fi

# The issues are shared, so people assign, close and relabel them by hand. Where
# that behaviour is unwritten, each skill invents its own answer and the answers
# disagree, which is how an agent ends up undoing somebody's deliberate change.
if [ -f "$pieces" ]; then
  dg_ok=1
  grep -qF "## When somebody acts on GitHub" "$pieces" || \
    { fail "$pieces: does not say what happens when a person acts on GitHub"; dg_ok=0; }
  # Matched on the claim rather than the heading, because the heading can
  # survive a rewrite that drops the rule underneath it.
  grep -qF "A person's action wins." "$pieces" || \
    { fail "$pieces: does not state that a person's action wins"; dg_ok=0; }
  grep -qF "Absence is not a decision" "$pieces" || \
    { fail "$pieces: does not state that absence is not a decision"; dg_ok=0; }
  grep -qF "The agent says what it found." "$pieces" || \
    { fail "$pieces: does not state that the agent says what it found"; dg_ok=0; }
  # The four cases an agent is most likely to quietly correct on its own.
  for act in "Assigns somebody else" "Puts two subject labels" \
             "Uses milestones or a project board" "Deletes an issue"; do
    grep -qF "$act" "$pieces" || \
      { fail "$pieces: no answer for what happens when a person does this: $act"; dg_ok=0; }
  done
  [ "$dg_ok" -eq 1 ] && \
    pass "pieces.md answers what happens when a person acts on GitHub directly"
fi

# Anybody can open an issue in half a sentence, so the list has entries nobody
# sized. Built as though they were finished pieces, the agent guesses what done
# means, which is the one thing a piece exists to stop. Shaping lives in /shape.
shapefile="$SKILLS/shape/SKILL.md"
whatnowfile="$SKILLS/what-now/SKILL.md"
refresh="$SKILLS/setup-ai-build-kit/templates/foundation/plan-refresh.sh"
if [ -f "$pieces" ] && [ -f "$shapefile" ] && [ -f "$whatnowfile" ] && [ -f "$refresh" ]; then
  nr_ok=1
  grep -qF "## An issue somebody typed by hand" "$pieces" || \
    { fail "$pieces: does not say that a hand-typed issue is a request"; nr_ok=0; }
  # Shape rather than the label, so an unlabelled note is still caught.
  grep -qF 'An issue with no `## Done when` has not been sized' "$pieces" || \
    { fail "$pieces: does not make the missing 'Done when' section the test"; nr_ok=0; }
  grep -qF "original words underneath" "$shapefile" || \
    { fail "$shapefile: does not keep the person's own words through refining"; nr_ok=0; }
  # The way out has to be offered with the shaping. Mentioned afterwards, the
  # command becomes a trap for somebody who only wanted something built.
  grep -qF '"not now"' "$shapefile" || \
    { fail "$shapefile: offers no way out of the build offer"; nr_ok=0; }
  grep -qF "still notes rather than pieces" "$whatnowfile" || \
    { fail "$whatnowfile: does not say how many entries are still notes"; nr_ok=0; }
  grep -qF "still a note" "$refresh" || \
    { fail "$refresh: the printout does not mark the entries that are still notes"; nr_ok=0; }
  [ "$nr_ok" -eq 1 ] && \
    pass "a hand-typed issue is treated as a request, with a way out of the interview"
fi

# what-now voices the signals it already reads: a failing check and a setup
# step left half-done each get named rather than
# hidden under "nothing is blocked", and the answer closes with a plain recap of
# recent work. The read step gathered these all along; the contract is that the
# say step speaks them.
if [ -f "$whatnowfile" ]; then
  wn_ok=1
  grep -qF "### Failing check" "$whatnowfile" || \
    { fail "$whatnowfile: no recovery route names a failing check"; wn_ok=0; }
  grep -qF "### Unfinished setup step" "$whatnowfile" || \
    { fail "$whatnowfile: no recovery route names an unfinished setup step"; wn_ok=0; }
  grep -qF "short recap of where the tool has got to" "$whatnowfile" || \
    { fail "$whatnowfile: does not close with a recap of recent work"; wn_ok=0; }
  [ "$wn_ok" -eq 1 ] && \
    pass "what-now voices a failing check, an unfinished setup step, and a recap"
fi

# The command split: shape prepares work and marks a piece `ready`; implement
# builds only ready pieces and refuses to shape, sending an unready piece back to
# shape rather than guessing past its open question.
implementfile="$SKILLS/implement/SKILL.md"
if [ -f "$implementfile" ] && [ -f "$shapefile" ] && [ -f "$pieces" ]; then
  split_ok=1
  grep -qF '`ready`, when the piece is shaped' "$pieces" || \
    { fail "$pieces: does not define the ready label"; split_ok=0; }
  grep -qF "it does not shape" "$implementfile" || \
    { fail "$implementfile: does not say it builds rather than shapes"; split_ok=0; }
  grep -qF "does not settle the question" "$implementfile" || \
    { fail "$implementfile: does not send an unready piece to shape instead of settling it"; split_ok=0; }
  grep -qF "Shape itself never builds" "$shapefile" || \
    { fail "$shapefile: does not say shape never builds"; split_ok=0; }
  grep -qF 'label it `ready`' "$shapefile" || \
    { fail "$shapefile: does not mark a shaped piece ready"; split_ok=0; }
  [ "$split_ok" -eq 1 ] && \
    pass "shape prepares and marks ready; implement builds only ready pieces and redirects the rest"
fi

# The layered piece: a plain surface that stays comprehensive about the
# product, a collapsed "under the hood" tier the builder reads, a self-sufficiency
# bar before an unwatched auto run, and groundwork kept to a vertical slice.
layer_sbfile="$SKILLS/build-piece/SKILL.md"
if [ -f "$pieces" ] && [ -f "$implementfile" ] && [ -f "$layer_sbfile" ]; then
  layer_ok=1
  grep -qF "<details><summary>Under the hood</summary>" "$pieces" || \
    { fail "$pieces: the piece template has no collapsed under-the-hood section"; layer_ok=0; }
  grep -qF "self-sufficient enough to build without a person present" "$implementfile" || \
    { fail "$implementfile: auto mode does not require a piece self-sufficient without a person"; layer_ok=0; }
  grep -qF "expand-then-contract sequence that keeps the checks green" "$layer_sbfile" || \
    { fail "$layer_sbfile: does not constrain groundwork to a vertical slice or expand-then-contract"; layer_ok=0; }
  [ "$layer_ok" -eq 1 ] && \
    pass "the piece is layered: plain surface, under-the-hood build tier, a self-sufficiency bar for auto, and vertical-only groundwork"
fi

# GitHub issues are the only record: plan.md is retired, and a missing GitHub
# tool is a guided, required setup step rather than a file-based fallback.
capfile="$SKILLS/setup-ai-build-kit/references/capability-check.md"
if [ -f "$pieces" ] && [ -f "$capfile" ]; then
  gh_ok=1
  grep -qF "only record of what is left" "$pieces" || \
    { fail "$pieces: does not say the issues are the only record"; gh_ok=0; }
  if grep -qF "plan.md" "$pieces"; then
    fail "$pieces: still refers to the retired plan.md record"; gh_ok=0
  fi
  grep -qF "required setup step" "$capfile" || \
    { fail "$capfile: does not make the GitHub tool a required setup step"; gh_ok=0; }
  if grep -qF "working fallback" "$capfile"; then
    fail "$capfile: still calls a missing GitHub tool a working fallback"; gh_ok=0
  fi
  [ "$gh_ok" -eq 1 ] && \
    pass "GitHub issues are the only record; a missing tool is a guided setup step"
fi

# Sub-issues for a piece made of parts: the rule that keeps a part
# (same outcome) apart from a blocked-by piece (different outcome), a container
# parent /implement does not build directly, and a printout that reads the parts.
refreshtool="$SKILLS/setup-ai-build-kit/templates/foundation/plan-refresh.sh"
if [ -f "$pieces" ] && [ -f "$implementfile" ] && [ -f "$refreshtool" ]; then
  sub_ok=1
  grep -qF "Same outcome means a sub-issue; a different outcome" "$pieces" || \
    { fail "$pieces: does not give the sub-issue versus blocked-by rule"; sub_ok=0; }
  grep -qF "A piece with open parts is a container" "$implementfile" || \
    { fail "$implementfile: does not skip a parent with open parts"; sub_ok=0; }
  grep -qF "Made of parts" "$refreshtool" || \
    { fail "$refreshtool: does not show a parent as made of parts"; sub_ok=0; }
  [ "$sub_ok" -eq 1 ] && \
    pass "a piece made of parts uses sub-issues, the parent is a container, and the printout reads the parts"
fi

# Every release asks what an existing user must do to upgrade (real users since
# v0.5): MAINTAINING.md carries that standing check when a release is cut.
mfile="$ROOT/docs/MAINTAINING.md"
if [ -f "$mfile" ]; then
  grep -qF "what an existing user must do to upgrade" "$mfile" || \
    fail "$mfile: the release checklist does not ask what an existing user must do to upgrade"
fi

# Shape stays shaping: clarify records a settled term on the piece rather than committing
# the masterplan mid-plan, so a planning session opens no pull request.
clarifyfile="$SKILLS/clarify/SKILL.md"
if [ -f "$shapefile" ] && [ -f "$clarifyfile" ]; then
  pp_ok=1
  grep -qF "Planning records and stops; writing to the masterplan is a build" "$clarifyfile" || \
    { fail "$clarifyfile: clarify still writes the masterplan mid-plan instead of recording on the piece"; pp_ok=0; }
  [ "$pp_ok" -eq 1 ] && \
    pass "planning never writes the masterplan mid-plan"
fi

# Build mechanics and pull-request hygiene: a piece starts from up-to-date main
#; a new issue is unassigned until pickup; a direct push to main is
# blocked and merged branches auto-delete; the agent opens the pull
# request and merges it only on a yes that names the merge, made on the pull
# request itself, and never in a run with nobody there to say it.
sbfile="$SKILLS/build-piece/SKILL.md"
cutfile="$SKILLS/setup-ai-build-kit/references/cut-the-plan.md"
mergefile="$SKILLS/merge/SKILL.md"
blocked="$SKILLS/setup-ai-build-kit/references/blocked-commands.md"
settings="$SKILLS/setup-ai-build-kit/templates/foundation/claude-settings.json"
startfile="$SKILLS/setup-ai-build-kit/SKILL.md"
shapefile="$SKILLS/shape/SKILL.md"
if [ -f "$sbfile" ] && [ -f "$mergefile" ] && [ -f "$blocked" ] && [ -f "$settings" ] && [ -f "$startfile" ] && [ -f "$shapefile" ]; then
  mech_ok=1
  grep -qF 'Start from up-to-date `main`' "$sbfile" || \
    { fail "$sbfile: does not start every piece from up-to-date main"; mech_ok=0; }
  grep -qF "starts unassigned" "$shapefile" || \
    { fail "$shapefile: does not say a new issue starts unassigned"; mech_ok=0; }
  grep -qF 'never push a change directly to `main`' "$blocked" || \
    { fail "$blocked: does not block a direct push to main"; mech_ok=0; }
  if sh "$ROOT/.agents/tests/push-guard.sh" >"${TMPDIR:-/tmp}/kit-push-guard-$$.log" 2>&1; then
    pass "founding installs the guard and Git refuses protected pushes"
  else
    cat "${TMPDIR:-/tmp}/kit-push-guard-$$.log"
    fail "founding's push guard rehearsal failed"
    mech_ok=0
  fi
  rm -f "${TMPDIR:-/tmp}/kit-push-guard-$$.log"
  grep -qF "delete_branch_on_merge" "$cutfile" || \
    { fail "$cutfile: does not enable auto-deletion of merged branches"; mech_ok=0; }
  grep -qF "Merge only with approval" "$mergefile" || \
    { fail "$mergefile: the merge step does not wait for a yes that names the merge"; mech_ok=0; }
  grep -qF "Make an approved merge on the pull request itself" "$mergefile" || \
    { fail "$mergefile: the merge step does not make the merge on the pull request itself"; mech_ok=0; }
  grep -qF "In an unattended run nobody is there to say yes, so never merge" "$implementfile" || \
    { fail "$implementfile: an unattended run could merge with nobody there to say yes"; mech_ok=0; }
  [ "$mech_ok" -eq 1 ] && \
    pass "pieces start from fresh main, new issues are unassigned, main is push-guarded, merged branches auto-delete, and the agent merges only on a yes that names the merge"
fi

# Machine-check-first evidence: where a machine can check a piece, that
# check runs and must pass before the piece is called done. The softer proofs
# are for the claims a machine cannot judge, not a way around one it could.
if [ -f "$sbfile" ]; then
  mc_ok=1
  grep -qF "a substitute for a check that was available and skipped" "$sbfile" || \
    { fail "$sbfile: does not forbid a softer proof standing in for an available machine check"; mc_ok=0; }
  grep -qF "machine check run and green" "$implementfile" || \
    { fail "$implementfile: 'Done when' does not name the available machine check as run and green"; mc_ok=0; }
  [ "$mc_ok" -eq 1 ] && \
    pass "an available machine check runs and must pass before a piece is called done"
fi

# The plan migration is deleted and stays deleted. No project needs it, and a
# route nobody exercises would ship untested while reading as supported.
syncfile="$SKILLS/maintain/references/truing.md"
if [ -f "$syncfile" ]; then
  if grep -qF "Moving an existing plan into issues" "$syncfile"; then
    fail "$syncfile: the plan migration route is back; it ships untested"
  else
    pass "the truing carries no plan migration route"
  fi
fi

# ---------------------------------------------------------------------------
echo "== Plain-language onboarding contract =="

startfile="$SKILLS/setup-ai-build-kit/SKILL.md"
if [ ! -f "$startfile" ]; then
  fail "$startfile: missing"
else
  ob_ok=1
  for needle in "## 1. Orientation" "## Conversation contract" \
    "Finishing an internal step is not a user-facing result by itself" \
    "Routine reading, research, setup, and checking happen quietly" \
    "Do not announce that a confirmation might appear later" \
    "references/completion-report.md"; do
    if ! tr '\n' ' ' < "$startfile" | grep -qFi -- "$needle"; then
      fail "$startfile: missing expected text '$needle' (progressive onboarding contract)"
      ob_ok=0
    fi
  done
  [ "$ob_ok" -eq 1 ] && pass "setup-ai-build-kit/SKILL.md carries an opening orientation and a plain-language completion report"
fi

capfile="$SKILLS/setup-ai-build-kit/references/capability-check.md"
if [ ! -f "$capfile" ]; then
  fail "$capfile: missing"
else
  cap_ok=1
  for needle in "A suitable name and email label are configured for saving project versions." \
    "Online authentication works, when uploads, pull requests, or online checks"; do
    if ! tr '\n' ' ' < "$capfile" | grep -qFi -- "$needle"; then
      fail "$capfile: missing expected text '$needle' (save identity must stay separate from remote authentication)"
      cap_ok=0
    fi
  done
  [ "$cap_ok" -eq 1 ] && pass "capability-check.md records save identity separately from remote authentication"
fi

# GitHub puts nine labels on a new repository and the kit uses none of them.
# Founding is the one moment they can go, because no issue exists yet to be
# wearing one. Both halves are checked: the deletion, and the sentence that
# keeps it from reading as a licence to remove somebody's own labels later.
if [ -f "$cutfile" ] && [ -f "$pieces" ] && [ -f "$capfile" ]; then
  gl_ok=1
  for label in bug documentation duplicate "good first issue" "help wanted" \
               invalid question wontfix enhancement; do
    grep -qF "\`$label\`" "$cutfile" || \
      { fail "$cutfile: does not name GitHub's '$label' label among the ones founding removes"; gl_ok=0; }
  done
  grep -qF "delete the labels GitHub made by itself" "$cutfile" || \
    { fail "$cutfile: founding does not delete the labels GitHub made by itself"; gl_ok=0; }
  grep -qF "Say which ones went" "$cutfile" || \
    { fail "$cutfile: founding removes labels without saying which"; gl_ok=0; }
  grep -qF "After founding they are somebody's to keep" "$pieces" || \
    { fail "$pieces: does not limit the label clearout to founding"; gl_ok=0; }
  grep -qF "cannot create or delete labels" "$capfile" || \
    { fail "$capfile: says nothing about an account that cannot delete a label"; gl_ok=0; }
  [ "$gl_ok" -eq 1 ] && \
    pass "founding clears GitHub's own labels, says which went, and stops there"
fi

manualfile="$SKILLS/setup-ai-build-kit/references/manual-setup.md"
if [ ! -f "$manualfile" ]; then
  fail "$manualfile: missing"
elif ! tr '\n' ' ' < "$manualfile" | grep -qFi -- "Never copy the latest repository author"; then
  fail "$manualfile: missing the rule against copying the latest repository author's identity"
else
  pass "manual-setup.md prohibits copying the latest author identity"
fi

# Only the fenced example shape counts as "shown to the user" here; the
# surrounding translation table legitimately names npm/Git internals, the
# same way AGENTS.md's own banned-word list has to contain the words it bans.
completionfile="$SKILLS/setup-ai-build-kit/references/completion-report.md"
if [ ! -f "$completionfile" ]; then
  fail "$completionfile: missing"
else
  shape=$(awk '/^```md$/{p=1;next} /^```$/{p=0} p' "$completionfile")
  leaked_phrases="npm test
npm start
ahead of the remote
working tree is clean"
  leak_found=0
  while IFS= read -r phrase; do
    [ -n "$phrase" ] || continue
    if printf '%s\n' "$shape" | tr '\n' ' ' | grep -qFi -- "$phrase"; then
      fail "$completionfile: unexplained technical phrase '$phrase' inside the user-facing report shape"
      leak_found=1
    fi
  done <<LEAKED
$leaked_phrases
LEAKED
  [ "$leak_found" -eq 1 ] || pass "the user-facing report shape in completion-report.md keeps npm/Git internals out"
fi

# start ends on a clean cut, not an in-session build offer: the empty
# project is named as expected, the work is said to be saved, and the person is
# pointed at a fresh session with /implement rather than offered a build here.
cc_ok=1
for needle in "which is how it should look at this point" \
              "start a fresh chat" \
              "/implement"; do
  if ! tr '\n' ' ' < "$completionfile" | tr -s ' ' | grep -qF -- "$needle"; then
    fail "$completionfile: missing '$needle' (clean-cut ending)"
    cc_ok=0
  fi
done
# The in-session build offer an earlier release shipped must be gone: it was
# reversed on purpose.
if tr '\n' ' ' < "$completionfile" | tr -s ' ' | grep -qF -- "so you finish with something you can see"; then
  fail "$completionfile: still contains the in-session build offer that was removed on purpose"
  cc_ok=0
fi
[ "$cc_ok" -eq 1 ] && pass "start ends on a clean cut naming /implement, and frames the empty project as normal"

starteragents="$SKILLS/setup-ai-build-kit/templates/foundation/AGENTS.md"
scenarios="$ROOT/.agents/tests/scenarios.md"
quiet_ok=1
for item in \
  "$starteragents|Keep progress updates tied to a decision, blocker, or visible outcome" \
  "$starteragents|Immediately before a technical confirmation" \
  "$scenarios|## 25. Quiet /setup-ai-build-kit stand-up" \
  "$scenarios|Harness-generated technical text is outside the kit's control"; do
  file=${item%%|*}
  needle=${item#*|}
  if ! tr '\n' ' ' < "$file" | grep -qFi -- "$needle"; then
    fail "$file: missing expected text '$needle' (quiet onboarding contract)"
    quiet_ok=0
  fi
done
[ "$quiet_ok" -eq 1 ] && pass "start keeps routine technical activity behind the scenes across harnesses"

syncfile="$SKILLS/maintain/references/truing.md"
if ! grep -qF 'jobs.project-check' "$syncfile"; then
  fail "$syncfile: does not identify the standalone project check"
elif grep -qF 'both `if:` conditions' "$syncfile"; then
  fail "$syncfile: still treats private source conditions as part of every project"
else
  pass "the truing updates the standalone project check while preserving older layouts"
fi

# ---------------------------------------------------------------------------
echo "== Interview question shape =="

# A machine cannot judge whether an interview felt like a conversation, so this
# only proves the rule is still written down where the interview reads it.
# Scenario 50's replay grades the behaviour.
grillfile="$SKILLS/clarify/SKILL.md"
scenariofile="$ROOT/.agents/tests/scenarios.md"
shape_ok=1
for item in \
  "$grillfile|Match the question to the shape of its answer" \
  "$grillfile|narrate is asked in plain words" \
  "$startfile|Ask every question in the shape clarify's" \
  "$scenariofile|arrives as a plain question with room to answer freely"; do
  file=${item%%|*}
  needle=${item#*|}
  if ! tr '\n' ' ' < "$file" | grep -qFi -- "$needle"; then
    fail "$file: missing expected text '$needle' (interview question shape contract)"
    shape_ok=0
  fi
done
[ "$shape_ok" -eq 1 ] && pass "clarify says which questions may be offered as choices and which are asked in plain words"

# ---------------------------------------------------------------------------
echo "== First-use plain language =="

# When start names a tool the person must act on, it says what the tool is in
# the same breath, and manual setup does the same. A throwaway prototype is
# built to look like the real thing rather than narrating in its own interface
# that it is a prototype. These prove the rules stay written where the skills
# read them.
fu_ok=1
for item in \
  "$startfile|say what it is in one plain sentence at the same moment" \
  "$manualfile|say what that is in one plain sentence too" \
  "$SKILLS/clarify/references/decision-prototype.md|not like a labelled prototype"; do
  file=${item%%|*}
  needle=${item#*|}
  if ! tr '\n' ' ' < "$file" | tr -s ' ' | grep -qF -- "$needle"; then
    fail "$file: missing expected text '$needle' (first-use plain-language contract)"
    fu_ok=0
  fi
done
[ "$fu_ok" -eq 1 ] && pass "a named tool is explained in one sentence, and a throwaway prototype is not labelled as one"

# ---------------------------------------------------------------------------
echo "== Setup-hosting control-flow contract =="

# The recipe's checks move work to a live address, so they sit under the launch
# section, after the evidence run and the review it loads. The anchor is the
# launch heading, so a rename without a matching change here would let the
# check pass on nothing.
hostingfile="$SKILLS/setup-hosting/SKILL.md"
if [ ! -f "$hostingfile" ]; then
  fail "$hostingfile: missing"
else
  recipe_at=$(awk '
    /^## Launch/ { inlaunch=1; next }
    /^## / { inlaunch=0 }
    /^#+ On a recipe/ { print (inlaunch ? "inside" : "outside"); exit }
  ' "$hostingfile")
  if [ "$recipe_at" = inside ]; then
    pass "setup-hosting/SKILL.md keeps the recipe's checks inside its launch section"
  else
    fail "$hostingfile: the 'On a recipe' checks are ${recipe_at:-missing}, not inside the launch section"
  fi
fi

# ---------------------------------------------------------------------------
echo "== Product names stay in the recipes =="

# A hosting, data or deploy product is named only in a recipe folder or a
# shared part under setup-hosting/recipes/, scripts included. A skill that
# learned one service's behaviour would read wrongly on every project that
# runs somewhere else, with nothing on screen to say so. The names are a fixed
# list, plus the place each recipe's title names, so a recipe added later
# adds its own host to the list, a recipe still waiting for its real run
# included. Two exemptions: the screen rules link Vercel's interface
# guidelines, a design guide rather than a place a tool runs, and the
# maintain skill's two records of released copies name old file paths. The
# founding settings template is a list of rules Claude Code applies, not words
# a skill learns from. It names the recipes' own commands that change a live
# service, so a box asks before each one, and push-to-main-rules.sh reads it.
product_list='coolify|vercel|supabase|netlify|heroku|railway|railpack|fly\.io|hetzner|hostinger|firebase|digitalocean'
recipe_targets=$(for rf in "$SKILLS"/setup-hosting/recipes/*/recipe.md "$ROOT"/.agents/tests/recipes-awaiting-run/*/recipe.md; do
  [ -f "$rf" ] || continue
  sed -n 's/^# Recipe: .* on \(.*\)$/\1/p' "$rf" | head -1
done | tr '[:upper:]' '[:lower:]' | sed 's/[.]/\\./g' | sort -u | paste -sd'|' -)
if [ -z "$recipe_targets" ]; then
  fail "no recipe title names a place to run, so the product-name rule reads nothing from the recipes"
else
  product_list="$product_list|$recipe_targets"
fi

# products_named <skills folder>: each file and line outside the recipes that
# names a product.
products_named() {
  find "$1" -type f ! -path '*/setup-hosting/recipes/*' \
    ! -path '*/setup-ai-build-kit/templates/foundation/checks.yml' \
    ! -path '*/maintain/scripts/kit-released-copies.json' \
    ! -path '*/maintain/scripts/kit-retired-skills.json' \
    ! -path '*/templates/foundation/claude-settings.json' | sort | while IFS= read -r pn_file; do
    tr '[:upper:]' '[:lower:]' < "$pn_file" \
      | sed -e 's#vercel web interface guidelines##g' \
            -e 's#github\.com/vercel-labs/web-interface-guidelines##g' \
      | grep -nE "$product_list" | sed "s#^#$pn_file:#" || true
  done
}

named=$(products_named "$SKILLS")
if [ -n "$named" ]; then
  fail "a skill file outside the recipes names a hosting, data or deploy product:
$named"
else
  pass "no skill file outside the recipes names a hosting, data or deploy product"
fi

# The rule has to notice a name, keep each exemption narrow, and leave the
# recipes alone, or it proves nothing. So it is run on a planted folder.
plant=$(mktemp -d)
mkdir -p "$plant/setup-hosting/recipes/parts" "$plant/setup-hosting/references" "$plant/screen-check"
grep -i 'web interface guidelines' "$SKILLS/screen-check/SKILL.md" > "$plant/screen-check/SKILL.md" || true
mkdir -p "$plant/setup-hosting/recipes/on-vercel/scripts" "$plant/setup-hosting/recipes/parts/scripts"
printf '%s\n' 'Runs on Vercel with a Supabase database.' > "$plant/setup-hosting/recipes/on-vercel/recipe.md"
printf '%s\n' 'vercel env ls production' > "$plant/setup-hosting/recipes/on-vercel/scripts/secrets.sh"
printf '%s\n' 'Backups on Supabase.' > "$plant/setup-hosting/recipes/parts/backup.md"
printf '%s\n' 'supabase db dump' > "$plant/setup-hosting/recipes/parts/scripts/backup.sh"
plant_ok=1
if [ -n "$(products_named "$plant")" ]; then
  fail "the product-name rule counted the guidelines link, a recipe or a shared part as a product name"
  plant_ok=0
fi
first_target=$(printf '%s' "$recipe_targets" | cut -d'|' -f1 | sed 's/\\//g')
for planted in "Deploy it to Vercel." "Keep the data in Supabase." "Deploy it with ${first_target:-vercel}." \
               "$(printf 'Vercel is fast.\nThe Vercel Web Interface Guidelines')"; do
  printf '%s\n' "$planted" > "$plant/setup-hosting/references/steps.md"
  if [ -z "$(products_named "$plant")" ]; then
    fail "the product-name rule missed a planted name: $planted"
    plant_ok=0
  fi
done
rm -rf "$plant"
[ "$plant_ok" -eq 1 ] && pass "the product-name rule catches a planted name and leaves the recipes and the guidelines link alone"

# ---------------------------------------------------------------------------
echo "== Codex adapter claims =="

# Codex has no generated skill or command tree; it reads .agents/skills/
# directly. The one generated Codex folder is .codex/agents/, for the agents,
# so a line naming that folder is not the stale claim. scenarios.md and MAINTAINING.md are maintainer-only and already
# excluded by the same convention as the team.md check below.
codex_docs=$(find "$ROOT" \
  -path "$ROOT/.git" -prune -o \
  -path "$ROOT/site/node_modules" -prune -o \
  -path "$ROOT/site/dist" -prune -o \
  -path "$ROOT/site/.astro" -prune -o \
  -path "$ROOT/.agents/tmp" -prune -o \
  -name '*.md' -print | sort \
  | grep -v '\.agents/tests/scenarios\.md$' \
  | grep -v 'docs/MAINTAINING\.md$' || true)

# A 3-line sliding window catches the stale phrasing even if it's soft-wrapped,
# without joining the whole file (which would false-positive on any document
# that simply discusses all four tools in separate paragraphs, in order).
codex_group_hits=$(printf '%s\n' "$codex_docs" | while IFS= read -r f; do
  [ -n "$f" ] || continue
  awk '
    { buf[NR] = $0; window = $0
      if (NR > 1) window = buf[NR-1] " " window
      if (NR > 2) window = buf[NR-2] " " window
      if (window ~ /[.]claude\// && window ~ /[.]cursor\// && window ~ /[.]gemini\// && window ~ /[.]codex\// && window !~ /[.]codex\/agents/) {
        print FILENAME ":" NR
      }
    }
  ' "$f"
done)
if [ -n "$codex_group_hits" ]; then
  fail ".codex/ still listed alongside the generated adapter trees, as if it were one, in: $(printf '%s' "$codex_group_hits" | tr '\n' ' ')"
fi

codex_active_hits=$(printf '%s\n' "$codex_docs" | while IFS= read -r f; do
  [ -n "$f" ] || continue
  grep -noE '.{0,40}\.codex/skills.{0,40}' "$f" 2>/dev/null | sed "s#^#$f:#"
done | while IFS=: read -r ffile lineno rest; do
  [ -n "$lineno" ] || continue
  # Keep a case block out of this $(...) pipeline: the older /bin/sh shipped
  # by macOS mistakes its closing pattern for the command substitution's end.
  if printf '%s\n' "$rest" | grep -qE 'does not exist|no longer exists|not exist'; then
    :
  else
    echo "$ffile:$lineno: $rest"
  fi
done)
if [ -n "$codex_active_hits" ]; then
  fail ".codex/skills mentioned without saying it doesn't exist: $(printf '%s' "$codex_active_hits" | tr '\n' ' | ')"
fi

if [ -z "$codex_group_hits" ] && [ -z "$codex_active_hits" ]; then
  pass "no document describes .codex/ as generated or .codex/skills as active"
fi

# ---------------------------------------------------------------------------
echo "== Retired path vocabulary =="

# The kit has no project-wide switch. A project carries a risk record, and each piece
# carries a Risk areas line. A path name or a Path: field anywhere in the
# source, the tests or the documents would describe a switch that no longer
# exists. Frozen upgrade fixtures, which model released projects, the release
# notes, the script that moves an old record to the risk record, and the replay
# script that writes the old section for a release that still reads it keep the
# old names on purpose. The patterns are split so that a
# search of the tree finds only real uses.
path_hits=$(grep -rIlE -e 'Explore p''rivately' -e 'Build and r''un it' -e 'Build with c''are' \
  -e 'build p''ath' -e '^P''ath:' \
  "$ROOT/.agents" "$ROOT/docs" "$ROOT/README.md" "$ROOT/WORKFLOW.md" "$ROOT/AGENTS.md" \
  "$ROOT/CONTRIBUTING.md" "$ROOT/llms.txt" "$ROOT/.claude" "$ROOT/.cursor" "$ROOT/.gemini" \
  "$ROOT/.github" "$ROOT/agent-plugin" "$ROOT/.claude-plugin" 2>/dev/null \
  | grep -v '/\.git/' \
  | grep -v '/\.agents/tmp/' \
  | grep -v '/\.agents/tests/fixtures/upgrade-' \
  | grep -v '/docs/release-notes/' \
  | grep -v '/\.agents/skills/maintain/scripts/kit-retired-skills\.json$' \
  | grep -v '/\.agents/skills/maintain/scripts/risk_move\.py$' \
  | grep -v '/\.agents/tests/replay/prepare/legacy-masterplan\.py$' \
  || true)
if [ -n "$path_hits" ]; then
  fail "a retired path name or a Path: field is still in: $(printf '%s' "$path_hits" | tr '\n' ' ')"
else
  pass "no retired path name or Path: field remains outside the frozen fixtures and the release notes"
fi

# The gate names went with the redesign that made the kit stop refusing. What
# it does now is give a risk notice the person can accept on the record, so a
# stray "expert gate" would describe a barrier that no longer exists. The two
# paths named for who you had to hire went the same way, with the field that
# recorded the hiring level and the brief written for the hire.
stale_terms="six questions
six outcomes
stakes section
Verdict:
build it and run it yourself
fix the design first
have it built for you
expert gate
expert-gated
Build with expert help
Professional-led
Required controls:
Outside help:
help level
expert brief
levels of outside help"
had_stale=0
while IFS= read -r term; do
  [ -n "$term" ] || continue
  hits=$(grep -rlFi --include='*.md' -- "$term" "$ROOT/.agents" "$ROOT/docs" \
    "$ROOT/README.md" "$ROOT/WORKFLOW.md" "$ROOT/AGENTS.md" "$ROOT/starter" 2>/dev/null \
    | grep -v '/\.git/' \
    | grep -v '/\.agents/tmp/' \
    | grep -v '\.agents/tests/scenarios\.md$' \
    | grep -v 'docs/MAINTAINING\.md$' \
    | grep -v '\.agents/skills/maintain/references/four-paths\.md$' \
    || true)
  # four-paths.md rewrites a section written with the old fields, so it has
  # to name the fields and paths it recognises. It loads for that alone.
  if [ -n "$hits" ]; then
    fail "retired vocabulary '$term' found in: $(printf '%s' "$hits" | tr '\n' ' ')"
    had_stale=1
  fi
done <<STALETERMS
$stale_terms
STALETERMS
[ "$had_stale" -eq 1 ] || pass "no retired vocabulary appears"

# ---------------------------------------------------------------------------
echo "== Adapter generation =="

if [ -x "$ROOT/.agents/tools/build-adapters.sh" ]; then
  if "$ROOT/.agents/tools/build-adapters.sh" --check; then
    pass "generated adapters match .agents/skills/, no drift, no stale adapter files"
  else
    fail "generated adapters are out of date; run .agents/tools/build-adapters.sh and commit the result"
  fi
else
  fail ".agents/tools/build-adapters.sh is missing or not executable"
fi

# ---------------------------------------------------------------------------
echo "== Session start contract =="

session_template="$SKILLS/setup-ai-build-kit/templates/foundation/session-start.sh"
session_settings="$SKILLS/setup-ai-build-kit/templates/foundation/claude-settings.json"
maintenance_template="$SKILLS/setup-ai-build-kit/templates/maintenance-record"
ss_ok=1

[ -f "$session_template" ] || { fail "$session_template: missing"; ss_ok=0; }
[ -f "$maintenance_template" ] || { fail "$maintenance_template: missing"; ss_ok=0; }

# The saved mode is what a project receives, so check the saved mode rather
# than this working copy, which may sit on a disk that does not keep one.
session_mode=$(git -C "$ROOT" ls-files -s -- \
  ".agents/skills/setup-ai-build-kit/templates/foundation/session-start.sh" | cut -d' ' -f1)
if [ "$session_mode" != "100755" ]; then
  fail "$session_template: must be saved as a runnable file (found mode '$session_mode')"
  ss_ok=0
fi

# This repository maintains the kit and is not a project built with it.
[ ! -e "$ROOT/.agents/hooks/session-start.sh" ] || \
  { fail "the maintainer source contains a project session-start hook"; ss_ok=0; }
if grep -qF 'SessionStart' "$ROOT/.claude/settings.json"; then
  fail "the maintainer source wired a project session-start hook into its own settings"
  ss_ok=0
fi

grep -qF 'SessionStart' "$session_settings" || \
  { fail "$session_settings: does not wire the project session hook"; ss_ok=0; }
grep -qF '.agents/hooks/session-start.sh' "$session_settings" || \
  { fail "$session_settings: session-start wiring does not name the project hook"; ss_ok=0; }

for entry in \
  "$SKILLS/setup-ai-build-kit/scripts/bootstrap-project.sh|session-start.sh|.agents/hooks/session-start.sh" \
  "$SKILLS/setup-ai-build-kit/references/write-the-masterplan.md|templates/maintenance-record" \
  "$SKILLS/maintain/SKILL.md|.ai-build-kit-maintenance" \
  "$SKILLS/maintain/SKILL.md|last-light-pass" \
  "$SKILLS/maintain/SKILL.md|last-full-pass" \
  "$SKILLS/what-now/SKILL.md|.ai-build-kit-maintenance" \
  "$ROOT/WORKFLOW.md|maintain writes the date of each visit" \
  "$ROOT/docs/COMPATIBILITY.md|Said automatically when a session opens" \
  "$scenarios|## 27. Session opens on a project past its check-up cadence"; do
  file=${entry%%|*}
  needle=${entry#*|}
  if ! tr '\n' ' ' < "$file" | grep -qF -- "$needle"; then
    fail "$file: missing expected text '$needle' (session-start contract)"
    ss_ok=0
  fi
done

[ "$ss_ok" -eq 1 ] && pass "the check-up reminder is a project hook, wired from start's template and absent from this source"

# ---------------------------------------------------------------------------
echo "== Release boundary =="

release_check="$ROOT/.agents/tests/release-builder.sh"
if [ -x "$release_check" ]; then
  if "$release_check"; then
    pass "starter assembles repeatably from the declared allowlist"
  else
    fail "starter release boundary check failed"
  fi
else
  fail ".agents/tests/release-builder.sh is missing or not executable"
fi

rehearsal_check="$ROOT/.agents/tests/starter-rehearsal.sh"
if [ -x "$rehearsal_check" ]; then
  if "$rehearsal_check"; then
    pass "starter stands up as a new saved project with founding templates"
  else
    fail "disposable starter rehearsal failed"
  fi
else
  fail ".agents/tests/starter-rehearsal.sh is missing or not executable"
fi

publication_check="$ROOT/.agents/tests/release-publication.sh"
if [ -x "$publication_check" ]; then
  if "$publication_check"; then
    pass "starter publication handles first and later releases"
  else
    fail "starter publication rehearsal failed"
  fi
else
  fail ".agents/tests/release-publication.sh is missing or not executable"
fi

session_check="$ROOT/.agents/tests/session-start.sh"
if [ -x "$session_check" ]; then
  if "$session_check"; then
    pass "the check-up reminder behaves across install routes and cadences"
  else
    fail "session-start rehearsal failed"
  fi
else
  fail ".agents/tests/session-start.sh is missing or not executable"
fi

# Every `[ -x ... ]` guard in this file is unreliable on a disk that reports
# each file as runnable, which is what a Windows mount does. A script saved
# without its runnable bit passes here and fails on the hosted checks, or worse
# reaches a project that was told to run it by path. The saved mode is the only
# honest answer, so it is checked directly.
# A named list of scripts goes stale the moment somebody adds one, which is how
# three files under .agents/tests/ came to be run by path while saved as
# ordinary text. Every tracked file that opens with a shebang is asked instead.
# A file this repository only ever sources, hands to a shell, or passes to
# Python is invoked a different way and does not need the bit.
mode_ok=1
git -C "$ROOT" ls-files -s | while read -r saved _ _ script; do
  [ -f "$ROOT/$script" ] || continue
  [ "$(head -c 2 "$ROOT/$script" 2>/dev/null)" = '#!' ] || continue
  base=${script##*/}
  if git -C "$ROOT" grep -qE \
    "(^|[[:space:];&|(])(\.|source)[[:space:]]+[^[:space:];)]*$base" -- . 2>/dev/null; then
    continue
  fi
  if git -C "$ROOT" grep -qE \
    "(^|[[:space:];&|(])(sh|bash|dash|zsh)[[:space:]]+[^[:space:];)]*$base" -- . 2>/dev/null; then
    continue
  fi
  if git -C "$ROOT" grep -qE \
    "(^|[[:space:];&|(])(python|python3)[[:space:]].*$base" -- . 2>/dev/null; then
    continue
  fi
  [ "$saved" = "100755" ] || \
    printf '%s\n' "$script: is run by path but is not saved as runnable (found mode '$saved')"
done > /tmp/validate-kit-modes.$$
if [ -s /tmp/validate-kit-modes.$$ ]; then
  while IFS= read -r offender; do
    fail "$offender"
  done < /tmp/validate-kit-modes.$$
  mode_ok=0
fi
rm -f /tmp/validate-kit-modes.$$
[ "$mode_ok" -eq 1 ] && pass "every script the kit runs by path is saved as runnable"

printout_check="$ROOT/.agents/tests/plan-printout.sh"
if [ -x "$printout_check" ]; then
  if "$printout_check" >/dev/null 2>&1; then
    pass "the printout groups a repair, a claim, a block, and says why a piece waits"
  else
    fail "plan printout check failed; run .agents/tests/plan-printout.sh to see why"
  fi
else
  fail ".agents/tests/plan-printout.sh is missing or not executable"
fi

recovery_check="$ROOT/.agents/tests/grader-recovery.sh"
if [ -x "$recovery_check" ]; then
  if "$recovery_check" >/dev/null 2>&1; then
    pass "the grader parser recovers a missing final brace and still refuses a mid-truncation"
  else
    fail "grader recovery check failed; run .agents/tests/grader-recovery.sh to see why"
  fi
else
  fail ".agents/tests/grader-recovery.sh is missing or not executable"
fi

state_check="$ROOT/.agents/tests/replay-state.sh"
if [ -x "$state_check" ]; then
  if "$state_check" >/dev/null 2>&1; then
    pass "the replay harness grades the world, and the acceptance-record assertion fails when it should"
  else
    fail "replay state-grading check failed; run .agents/tests/replay-state.sh to see why"
  fi
else
  fail ".agents/tests/replay-state.sh is missing or not executable"
fi

# The contract parser is a machine check that existed but never ran here, which
# is how the /setup scenarios' cases were wired while the parser still demanded a
# risk notice they do not carry. Running it on every push is the rule
# that a check which exists must run and pass.
parser_check="$ROOT/.agents/tests/replay/check-parser.sh"
if [ -f "$parser_check" ]; then
  if sh "$parser_check" >/dev/null 2>&1; then
    pass "the replay harness reads every scenario contract, and the risk pair is required together"
  else
    fail "replay contract parser failed; run .agents/tests/replay/check-parser.sh to see why"
  fi
else
  fail ".agents/tests/replay/check-parser.sh is missing"
fi

claude_plugin_check="$ROOT/.agents/tests/claude-plugin.sh"
if [ ! -x "$claude_plugin_check" ]; then
  fail ".agents/tests/claude-plugin.sh is missing or not executable"
elif command -v claude >/dev/null 2>&1; then
  if "$claude_plugin_check"; then
    pass "Claude plugin exposes the six commands, prepares a project, recovers, updates, and uninstalls in isolation"
  else
    fail "Claude plugin rehearsal failed"
  fi
else
  note "Claude Code is unavailable; skipped the isolated plugin rehearsal"
fi

agent_plugin_check="$ROOT/.agents/tests/agent-plugin.sh"
if [ -x "$agent_plugin_check" ]; then
  if "$agent_plugin_check"; then
    pass "the Agent Plugins folder matches the standard and stands a project up on its own"
  else
    fail "Agent Plugins rehearsal failed"
  fi
else
  fail ".agents/tests/agent-plugin.sh is missing or not executable"
fi

# ---------------------------------------------------------------------------
echo "== Shell and configuration =="

shfiles=$(find "$ROOT/.agents" -name '*.sh' | sort)
while IFS= read -r shfile; do
  [ -n "$shfile" ] || continue
  if sh -n "$shfile" 2>/tmp/validate-kit-shcheck.$$; then
    :
  else
    fail "$shfile: sh -n reported a syntax error: $(cat /tmp/validate-kit-shcheck.$$)"
  fi
  rm -f /tmp/validate-kit-shcheck.$$
done <<SHFILES
$shfiles
SHFILES
pass "shell syntax checked on $(printf '%s\n' "$shfiles" | grep -c .) scripts"

jsonfiles="$ROOT/.claude/settings.json
$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json
$ROOT/.claude-plugin/plugin.json
$ROOT/.claude-plugin/marketplace.json
$ROOT/agent-plugin/plugin.json"
if command -v python3 >/dev/null 2>&1; then
  while IFS= read -r jsonfile; do
    [ -n "$jsonfile" ] || continue
    if python3 -c "import json; json.load(open('$jsonfile'))" 2>/tmp/validate-kit-json.$$; then
      :
    else
      fail "$jsonfile failed to parse as JSON: $(cat /tmp/validate-kit-json.$$)"
    fi
    rm -f /tmp/validate-kit-json.$$
  done <<JSONFILES
$jsonfiles
JSONFILES
  pass "Claude settings and plugin metadata parse as JSON"
else
  note "python3 not available; skipped JSON parse of Claude settings and plugin metadata"
fi

plugin_manifest="$ROOT/.claude-plugin/plugin.json"
plugin_marketplace="$ROOT/.claude-plugin/marketplace.json"
plugin_contract_ok=yes
for literal in \
  '"name": "ai-build-kit"' \
  '"./.claude/commands/implement.md"' \
  '"./.claude/commands/maintain.md"' \
  '"./.claude/commands/shape.md"' \
  '"./.claude/commands/setup-hosting.md"' \
  '"./.claude/commands/setup-ai-build-kit.md"' \
  '"./.claude/commands/what-now.md"'; do
  if ! grep -qF "$literal" "$plugin_manifest"; then
    fail "Claude plugin manifest is missing: $literal"
    plugin_contract_ok=no
  fi
done
# Every background skill and every agent the inventory lists reaches the
# plugin, read from the inventory so a new one cannot be left out of it.
while IFS= read -r name; do
  [ -n "$name" ] || continue
  if ! grep -qF "\"./.claude/skills/$name\"" "$plugin_manifest"; then
    fail "Claude plugin manifest is missing the background skill: ./.claude/skills/$name"
    plugin_contract_ok=no
  fi
done <<PLUGINSKILLS
$expected_disciplines
PLUGINSKILLS
while IFS= read -r name; do
  [ -n "$name" ] || continue
  if ! grep -qF "\"./.claude/agents/$name.md\"" "$plugin_manifest"; then
    fail "Claude plugin manifest is missing the agent: ./.claude/agents/$name.md"
    plugin_contract_ok=no
  fi
done <<PLUGINAGENTS
$expected_agents
PLUGINAGENTS
for literal in \
  '"name": "ai-build-kit"' \
  '"source": "./"'; do
  if ! grep -qF "$literal" "$plugin_marketplace"; then
    fail "Claude plugin marketplace is missing: $literal"
    plugin_contract_ok=no
  fi
done
maintain_skill="$ROOT/.agents/skills/maintain/references/monthly.md"
for literal in \
  'claude plugin marketplace update ai-build-kit' \
  'claude plugin update ai-build-kit@ai-build-kit --scope <scope>' \
  'npx skills add gwpicard/ai-build-kit' \
  'For an Agent Plugins installation'; do
  if ! grep -qF "$literal" "$maintain_skill"; then
    fail "maintain does not preserve the installation route: $literal"
    plugin_contract_ok=no
  fi
done
if [ "$plugin_contract_ok" = "yes" ]; then
  pass "Claude plugin identity, source, and update routes match the contract"
fi

agent_plugin_manifest="$ROOT/agent-plugin/plugin.json"
agent_plugin_ok=yes
if [ ! -f "$agent_plugin_manifest" ]; then
  fail "the Agent Plugins manifest is missing: agent-plugin/plugin.json"
  agent_plugin_ok=no
else
  for literal in \
    '"$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"' \
    '"name": "ai-build-kit"'; do
    if ! grep -qF "$literal" "$agent_plugin_manifest"; then
      fail "Agent Plugins manifest is missing: $literal"
      agent_plugin_ok=no
    fi
  done
  for forbidden in '"displayName"' '"commands"' '"skills"' '.claude/'; do
    if grep -qF "$forbidden" "$agent_plugin_manifest"; then
      fail "Agent Plugins manifest carries something the standard does not define: $forbidden"
      agent_plugin_ok=no
    fi
  done
fi
if [ "$agent_plugin_ok" = "yes" ]; then
  pass "the Agent Plugins manifest declares the 1.0.0 schema and keeps to its permitted fields"
fi

# ---------------------------------------------------------------------------
echo "== Version-bearing files =="

# Three files tell an installation which version it is, and both installers read
# whichever branch they are pointed at. Each was pinned to the development
# placeholder on its own, and nothing compared them, so a half-stamped tree was
# invisible: one file could say v0.11.0 while the other two still said
# development, and every check passed.
#
# So check the thing that matters. All three agree, and the value is either the
# placeholder, which is what an unreleased branch carries, or a plain version,
# which is what a released one carries. `stamp-version.sh` is what moves them
# between those two states, together.
version_files_ok=yes
claude_version=$(sed -nE 's/^[[:space:]]*"version": "([^"]*)".*/\1/p' "$plugin_manifest")
agent_version=$(sed -nE 's/^[[:space:]]*"version": "([^"]*)".*/\1/p' "$agent_plugin_manifest")
maintain_version=$(cat "$ROOT/.agents/skills/maintain/VERSION" 2>/dev/null || echo "")

for counted in "$plugin_manifest:$claude_version" "$agent_plugin_manifest:$agent_version"; do
  counted_file=${counted%:*}
  counted_value=${counted#*:}
  # `grep -c` prints 0 and exits 1 when nothing matches. `|| echo 0` would append
  # a second line, and the comparison below would then error rather than fire,
  # so a reformatted manifest would pass validation and fail at release time.
  found=$(grep -cE '^[[:space:]]*"version": "[^"]*",?$' "$counted_file" 2>/dev/null || true)
  [ -n "$found" ] || found=0
  if [ "$found" -ne 1 ]; then
    fail "${counted_file#"$ROOT"/}: expected exactly one version field, found $found; the release stamp would match nothing and ship a stale number"
    version_files_ok=no
  elif [ -z "$counted_value" ]; then
    fail "${counted_file#"$ROOT"/}: the version field is empty"
    version_files_ok=no
  fi
done

if [ "$claude_version" != "$agent_version" ]; then
  fail "the two plugin manifests disagree about the version: '$claude_version' and '$agent_version'"
  version_files_ok=no
fi
if [ "$maintain_version" != "v$claude_version" ]; then
  fail ".agents/skills/maintain/VERSION says '$maintain_version' while the plugin manifests say '$claude_version'"
  version_files_ok=no
fi
case "$claude_version" in
  0.0.0-development) ;;
  *)
    if ! printf '%s\n' "$claude_version" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'; then
      fail "the version-bearing files carry '$claude_version', which is neither the development placeholder nor a stable version"
      version_files_ok=no
    fi
    ;;
esac

stamper="$ROOT/.agents/tools/stamp-version.sh"
if [ ! -x "$stamper" ]; then
  fail ".agents/tools/stamp-version.sh is missing or not executable"
  version_files_ok=no
fi

if [ "$version_files_ok" = "yes" ]; then
  pass "the three version-bearing files agree, at '$claude_version'"
fi

# tomllib arrived in python3.11. tomli is the same parser backported, and is
# what a machine on 3.10 is likely to have, so try both before giving up. This
# matters more than it looks: the note below is easy to scroll past, and a
# machine that always prints it is running a quietly smaller check than the
# hosted one while reporting the same "all checks passed".
toml_reader=""
if command -v python3 >/dev/null 2>&1; then
  if python3 -c 'import tomllib' >/dev/null 2>&1; then
    toml_reader=tomllib
  elif python3 -c 'import tomli' >/dev/null 2>&1; then
    toml_reader=tomli
  fi
fi
if [ -n "$toml_reader" ]; then
  tomlfiles=$(find "$ROOT/.gemini" "$ROOT/.codex" -name '*.toml' 2>/dev/null | sort)
  while IFS= read -r tomlfile; do
    [ -n "$tomlfile" ] || continue
    if ! python3 -c "import $toml_reader as t; t.load(open('$tomlfile','rb'))" 2>/tmp/validate-kit-toml.$$; then
      fail "$tomlfile failed to parse as TOML: $(cat /tmp/validate-kit-toml.$$)"
    fi
    rm -f /tmp/validate-kit-toml.$$
  done <<TOMLFILES
$tomlfiles
TOMLFILES
  pass "TOML command files parsed, using $toml_reader"
else
  note "neither tomllib nor tomli is available; skipped TOML parse, adapter --check still covers content drift"
fi

if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
  github_yaml_files=$(find "$ROOT/.github" \
    \( -name '*.yml' -o -name '*.yaml' \) | sort)
  while IFS= read -r github_yaml_file; do
    [ -n "$github_yaml_file" ] || continue
    if ! python3 -c "import yaml; yaml.safe_load(open('$github_yaml_file'))" 2>/tmp/validate-kit-yaml.$$; then
      fail "$github_yaml_file failed to parse as YAML: $(cat /tmp/validate-kit-yaml.$$)"
    fi
    rm -f /tmp/validate-kit-yaml.$$
  done <<GITHUBYAMLFILES
$github_yaml_files
GITHUBYAMLFILES
  pass "GitHub configuration files parse as YAML"

  # Parsing is not the same as being the right shape. A run block written as a
  # literal scalar ends the moment a line is indented less than the block, and
  # what follows becomes a top-level key. The document still parses, and a check
  # that reads `jobs` still finds it, so nothing local complains. GitHub rejects
  # the workflow outright and reports a nought-second failure against the push.
  #
  # That happened to the workflow this check sits beside. So the keys are named,
  # and anything else is a run block that ended early. `on` is absent from the
  # list because YAML reads it as the boolean true.
  for wf in "$ROOT"/.github/workflows/*.yml "$ROOT"/.github/workflows/*.yaml; do
    [ -f "$wf" ] || continue
    stray=$(python3 - "$wf" <<'STRAYKEYS'
import sys, yaml
known = {"name", True, "on", "permissions", "concurrency", "jobs", "env",
         "defaults", "run-name"}
doc = yaml.safe_load(open(sys.argv[1])) or {}
print(" ".join(repr(k) for k in doc if k not in known))
STRAYKEYS
)
    if [ -n "$stray" ]; then
      fail "$(basename "$wf") has a top-level key that is not a workflow key, which is what a run block ending early looks like: $stray"
    fi
  done
  pass "no workflow has a stray top-level key from a run block ending early"

  # Structural contract: private source validation and the public starter's
  # deliberately failing project check are separate workflows, and every
  # rehearsal in .agents/tests/ runs on a pull request here.
  py_script=/tmp/validate-kit-workflow.$$
  cat > "$py_script" <<'PYEOF'
import os, sys, yaml
errors = []

source_doc = yaml.safe_load(open(sys.argv[1]))
source_jobs = source_doc.get("jobs") or {}
if set(source_jobs.keys()) != {"source-kit-validation", "rehearsal", "site-build"}:
    errors.append("source workflow must contain source-kit-validation, rehearsal and site-build")
sk = source_jobs.get("source-kit-validation") or {}
if sk.get("if") != "github.repository == 'gwpicard/ai-build-kit'":
    errors.append("source-kit-validation.if is wrong: %r" % sk.get("if"))
sk_runs = " ".join(step.get("run", "") for step in (sk.get("steps") or []) if isinstance(step, dict))
if "build-adapters.sh --check" not in sk_runs:
    errors.append("source-kit-validation is missing a build-adapters.sh --check step")
if "validate-kit.sh" not in sk_runs:
    errors.append("source-kit-validation is missing a validate-kit.sh step")

# A rehearsal nobody runs proves nothing. One hosted job for each rehearsal
# named a failure on the checks list, but each job was billed a whole minute
# to do a few seconds of work. They run in one job now, through a runner that
# reads the folder, so a rehearsal cannot be added without being run.
rehearsal = source_jobs.get("rehearsal") or {}
if rehearsal.get("if") != "github.repository == 'gwpicard/ai-build-kit'":
    errors.append("rehearsal.if is wrong: %r" % rehearsal.get("if"))
rehearsal_runs = " ".join(step.get("run", "") for step in (rehearsal.get("steps") or []) if isinstance(step, dict))
if ".agents/tests/run-all.sh" not in rehearsal_runs:
    errors.append("rehearsal does not run .agents/tests/run-all.sh")

# The publish workflow builds the site from a clean install on GitHub's own
# system. A pull request builds it the same way first, so a lockfile that
# leaves out a package that system needs fails here, not at publication.
site_build = source_jobs.get("site-build") or {}
if site_build.get("if") != "github.repository == 'gwpicard/ai-build-kit'":
    errors.append("site-build.if is wrong: %r" % site_build.get("if"))
site_runs = " ".join(step.get("run", "") for step in (site_build.get("steps") or []) if isinstance(step, dict))
for needed in ("npm ci", "npm run build", ".agents/tests/site-links.sh"):
    if needed not in site_runs:
        errors.append("site-build does not run %s" % needed)

tests_dir = sys.argv[3]
runner = os.path.join(tests_dir, "run-all.sh")
if not os.path.isfile(runner):
    errors.append("the rehearsal runner .agents/tests/run-all.sh is missing")
elif not os.access(runner, os.X_OK):
    errors.append(".agents/tests/run-all.sh is not executable")
else:
    runner_text = open(runner).read()
    # The folder is the list. Reading a glob rather than a written-out set is
    # what makes an unrun rehearsal impossible rather than merely checked for.
    if ".agents/tests/*.sh" not in runner_text:
        errors.append("run-all.sh must read .agents/tests/*.sh, so the folder is the list")
    # mutate.sh audits the suite rather than passing or failing, so it is
    # deliberately not a rehearsal.
    if "mutate" not in runner_text:
        errors.append("run-all.sh must skip mutate.sh, which audits rather than passes or fails")
    # One failure must never hide another, which is what fail-fast: false gave
    # the matrix. Whether the loop still holds that is a question only running
    # it can settle, so rehearsal-runner.sh runs it against stub scripts.
    if 'failed="$failed' not in runner_text:
        errors.append("run-all.sh must collect every failure rather than stopping at one")

project_doc = yaml.safe_load(open(sys.argv[2]))
project_jobs = project_doc.get("jobs") or {}
if set(project_jobs.keys()) != {"project-check"}:
    errors.append("starter workflow must contain only project-check")
pc = project_jobs.get("project-check") or {}
if "if" in pc:
    errors.append("starter project-check must not depend on a repository identity")
pc_runs = " ".join(step.get("run", "") for step in (pc.get("steps") or []) if isinstance(step, dict))
if "This check is still the placeholder" not in pc_runs:
    errors.append("project-check no longer carries the deliberately failing placeholder")
if errors:
    sys.stderr.write("\n".join(errors) + "\n")
    sys.exit(1)
PYEOF
  if python3 "$py_script" \
    "$ROOT/.github/workflows/source-checks.yml" \
    "$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml" \
    "$ROOT/.agents/tests" \
    2>/tmp/validate-kit-workflow-out.$$; then
    pass "private source validation and public project checks stay separate"
  else
    fail "source and starter workflow structure: $(cat /tmp/validate-kit-workflow-out.$$)"
  fi
  rm -f "$py_script" /tmp/validate-kit-workflow-out.$$
else
  workflow_files=$(find "$ROOT/.github/workflows" \
    -name '*.yml' -o -name '*.yaml' | sort)
  while IFS= read -r workflow_file; do
    [ -n "$workflow_file" ] || continue
    if ! grep -q '^on:' "$workflow_file" || ! grep -q '^jobs:' "$workflow_file"; then
      fail "$workflow_file is missing expected top-level keys (on:, jobs:)"
    fi
  done <<WORKFLOWFILES
$workflow_files
WORKFLOWFILES
  note "no PyYAML available; did a basic top-level-key check on GitHub workflows instead of a full parse"
  source_checks="$ROOT/.github/workflows/source-checks.yml"
  project_checks="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml"
  # The whole gate expression, not a bare repository name. The retired name
  # contained this one as a prefix, so a grep for the shorter name would pass
  # against the longer one and guard nothing.
  for literal in "source-kit-validation:" \
    "rehearsal:" \
    "site-build:" \
    ".agents/tests/run-all.sh" \
    ".agents/tests/site-links.sh" \
    "if: github.repository == 'gwpicard/ai-build-kit'"; do
    if ! grep -qF "$literal" "$source_checks"; then
      fail "source checks: missing expected line '$literal' (no PyYAML available)"
    fi
  done
  runner="$ROOT/.agents/tests/run-all.sh"
  if [ ! -x "$runner" ]; then
    fail "the rehearsal runner .agents/tests/run-all.sh is missing or not executable"
  elif ! grep -qF ".agents/tests/*.sh" "$runner" || ! grep -qF 'failed="$failed' "$runner"; then
    fail "run-all.sh must read the tests folder and collect every failure (no PyYAML available)"
  fi
  if ! grep -qF "project-check:" "$project_checks" || \
     grep -qF "github.repository" "$project_checks"; then
    fail "starter project check is missing or depends on a repository identity"
  fi
fi

# Hosted maintainer validation normally runs on pull requests. A maintainer-only
# non-main push fallback also covers repositories where GitHub accepts the
# branch update but does not create the pull_request run.
branch_checks="$ROOT/.github/workflows/maintainer-branch-check.yml"
fallback_ok=yes
if [ ! -f "$branch_checks" ]; then
  fail "maintainer-only non-main branch check is missing"
  fallback_ok=no
elif ! awk '
  $0 == "on:" { in_on=1; next }
  in_on && /^[^ ]/ { in_on=0; in_push=0 }
  in_on && /^  [^ ]/ { in_push=($0 == "  push:") }
  in_push && $0 == "    branches-ignore:" { in_ignored_branches=1; next }
  in_push && in_ignored_branches && $0 == "      - main" { ignores_main=1 }
  END { exit !ignores_main }
' "$branch_checks"; then
  fail "maintainer branch check must run on non-main branch pushes"
  fallback_ok=no
elif ! awk '
  $0 == "permissions:" { in_permissions=1; next }
  in_permissions && /^[^ ]/ { in_permissions=0 }
  in_permissions && $0 == "  contents: read" { read_only_contents=1 }
  $0 == "      - uses: actions/checkout@v6" { in_checkout=1; next }
  in_checkout && $0 == "        with:" { in_checkout_options=1; next }
  in_checkout_options && $0 == "          persist-credentials: false" { drops_credential=1 }
  in_checkout && /^      - / { in_checkout=0; in_checkout_options=0 }
  END { exit !(read_only_contents && drops_credential) }
' "$branch_checks"; then
  fail "maintainer branch check must be read-only and must not retain its checkout credential"
  fallback_ok=no
fi
if [ -f "$branch_checks" ]; then
  for literal in \
    "if: github.repository == 'gwpicard/ai-build-kit'" \
    "uses: actions/checkout@v6" \
    "run: .agents/tools/build-adapters.sh --check" \
    "run: .agents/tools/validate-kit.sh"; do
    if ! grep -qF "$literal" "$branch_checks"; then
      fail "maintainer branch check is missing: $literal"
      fallback_ok=no
    fi
  done
fi
if [ "$fallback_ok" = "yes" ]; then
  pass "maintainer-only non-main branch validation fallback matches the contract"
fi

# Piped commands were observed matching later text as part of the push.
if python3 - "$SKILLS/setup-ai-build-kit/templates/foundation/claude-settings.json" <<'PYRULE'
import json, re, sys
perms = json.load(open(sys.argv[1]))['permissions']
bad = [r for key in ('deny', 'ask') for r in perms.get(key, [])
       if r.startswith('Bash(git push *') and r != 'Bash(git push * --no-verify*)'
       and re.search(r'\*[^*)]+', r[len('Bash(git push '):])]
for rule in bad:
    print('unsafe push text rule: ' + rule)
sys.exit(bool(bad))
PYRULE
then pass "push text rules leave ref safety to the pre-push guard"
else fail "a push text rule can match unrelated text later in a piped command"
fi

# Deny-list parity: permissions.deny must be exactly the set of entries that
# mirror .agents/guard/blocked-commands.md's mechanically enforceable
# patterns (git reset --hard, git push --force/-f, git clean -f/-fd, rm -rf).
# An exact set comparison catches a missing OR an unexplained extra entry,
# not just a missing substring. Both this repository's own Claude settings and
# the settings founding gives a project are checked. Founded projects also
# protect hooks, stored logins and live changes, and use the pre-push guard
# instead of push text rules.
deny_jsonfiles="$ROOT/.claude/settings.json
$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json"
expected_deny="Bash(git reset --hard:*)
Bash(git push --force:*)
Bash(git push -f:*)
Bash(git clean -f:*)
Bash(git clean -fd:*)
Bash(rm -rf:*)"
# Founded projects use the pre-push guard for main and replacing remote work.
# Their text rules protect the guard and the other command boundaries.
expected_deny_project="Bash(git reset --hard:*)
Bash(git clean -f:*)
Bash(git clean -fd:*)
Bash(rm -rf:*)
Write(**/.claude/settings.json)
Edit(**/.claude/settings.json)
Write(**/.claude/settings.local.json)
Edit(**/.claude/settings.local.json)
Bash(* > .claude/settings.json*)
Bash(* > .claude/settings.local.json*)
Bash(* >> .claude/settings.json*)
Bash(* >> .claude/settings.local.json*)
Bash(tee .claude/settings.json*)
Bash(tee .claude/settings.local.json*)
Read(**/.env)
Read(**/.env.local)
Read(**/.env.*.local)
Read(**/.env.production)
Read(**/.env.development)
Read(**/.env.test)
Read(**/.env.staging)
Read(**/.env.preview)
Read(**/.env.production.local)
Read(**/.env.development.local)
Read(**/.env.test.local)
Read(**/.env.*)
Read(!**/.env.example)
Bash(rm -fr:*)
Bash(rm -Rf:*)
Bash(rm -fR:*)
Bash(rm -r -f:*)
Bash(rm -f -r:*)
Bash(rm -R -f:*)
Bash(rm -f -R:*)
Bash(rm --recursive --force:*)
Bash(rm --force --recursive:*)
Bash(git push --no-verify*)
Bash(git push * --no-verify*)
Bash(git *core.hooksPath*)
Bash(git *core.hookspath*)
Bash(git checkout .)
Bash(git checkout * .)
Bash(git restore .)
Bash(git checkout -- *)
Bash(git checkout * -- *)
Bash(git checkout -f*)
Bash(git checkout * -f*)
Bash(git checkout *--force*)
Bash(git switch -f*)
Bash(git switch * -f*)
Bash(git switch *--force*)
Bash(git switch *--discard-changes*)
Bash(git restore -- *)
Bash(git restore *--worktree*)
Bash(git restore -W*)
Bash(git restore * -W*)
Bash(git clean -*f*)
Bash(git clean * -*f*)
Bash(git reset * --hard*)
Bash(git stash drop:*)
Bash(git stash clear:*)
Bash(security find-*)
Bash(security dump-keychain:*)
Bash(gh auth token:*)
Bash(gh auth status*-t*)
Bash(git credential fill*)
Bash(git credential-*)
Bash(*.config/gh/hosts.yml*)
Bash(*GitHub CLI/hosts.yml*)
Bash(*com.vercel.cli/auth.json*)
Bash(*.vercel/auth.json*)
Bash(*.supabase/access-token*)
Bash(*Application Support/supabase*)
Bash(*.docker/config.json*)
Read(//**/.config/gh/hosts.yml)
Read(//**/GitHub CLI/hosts.yml)
Read(//**/com.vercel.cli/auth.json)
Read(//**/.vercel/auth.json)
Read(//**/.supabase/access-token)
Read(~/.vercel/**)
Read(~/.supabase/**)
Read(//**/Library/Application Support/supabase/**)
Read(//**/.docker/config.json)
Bash(gh pr merge:*)
Bash(gh api *pulls/*/merge*)
Bash(gh api *merges*)
Bash(gh api graphql *mergePullRequest*)"
# A project blocks direct merge commands and asks before live changes.
expected_ask_project="Bash(*merge.py*--approved*)
Bash(*merge.py*--resume*)
Bash(*approval.py*yes*)
Bash(gh api *git/refs*)
Bash(gh api graphql *createRef*)
Bash(gh api graphql *updateRef*)
Bash(gh api graphql *deleteRef*)
Bash(git restore *)
Bash(supabase db push:*)
Bash(supabase *config push*)
Bash(vercel api *PATCH*)
Bash(vercel api *patch*)
Bash(vercel curl*)
Bash(*PREVIEW_HEALTH=yes*)
Bash(*PREVIEW_HEALTH=\"yes\"*)
Bash(*PREVIEW_HEALTH='yes'*)
Bash(*GATE_READ=yes*)
Bash(*GATE_READ=\"yes\"*)
Bash(*GATE_READ='yes'*)
Bash(vercel project protection enable*)
Bash(vercel project protection disable*)
Bash(*set-access.sh*)
Bash(*set-signup.sh*)
Bash(vercel *--prod*)
Bash(vercel *--target*production*)
Bash(vercel rollback:*)
Bash(vercel promote:*)
Bash(gh repo archive:*)
Bash(gh repo edit *--visibility*)
Bash(gh api *-X DELETE*)
Bash(gh api *-XDELETE*)
Bash(gh api *-X=DELETE*)
Bash(gh api *--method DELETE*)
Bash(gh api *--method=DELETE*)"
deny_ok=1
if command -v python3 >/dev/null 2>&1; then
  py_script=/tmp/validate-kit-deny.$$
  cat > "$py_script" <<'PYEOF'
import json, sys
expected = set(sys.argv[2].splitlines())
actual = set(json.load(open(sys.argv[1])).get("permissions", {}).get("deny", []))
missing = expected - actual
extra = actual - expected
errors = []
if missing:
    errors.append("missing: %s" % sorted(missing))
if extra:
    errors.append("unexpected extra: %s" % sorted(extra))
if errors:
    sys.stderr.write("; ".join(errors) + "\n")
    sys.exit(1)
PYEOF
  while IFS= read -r deny_json; do
    [ -n "$deny_json" ] || continue
    case "$deny_json" in
      */templates/foundation/claude-settings.json) exp="$expected_deny_project" ;;
      *) exp="$expected_deny" ;;
    esac
    if ! python3 "$py_script" "$deny_json" "$exp" 2>/tmp/validate-kit-deny-out.$$; then
      fail "$deny_json permissions.deny does not exactly match the expected set: $(cat /tmp/validate-kit-deny-out.$$)"
      deny_ok=0
    fi
    rm -f /tmp/validate-kit-deny-out.$$
  done <<DENYFILES
$deny_jsonfiles
DENYFILES
  ask_file="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json"
  if ! python3 - "$ask_file" "$expected_ask_project" 2>/tmp/validate-kit-ask-out.$$ <<'PYEOF'
import json, sys
expected = set(sys.argv[2].splitlines())
actual = set(json.load(open(sys.argv[1])).get("permissions", {}).get("ask", []))
if actual != expected:
    sys.stderr.write("missing: %s; unexpected extra: %s\n" % (sorted(expected - actual), sorted(actual - expected)))
    sys.exit(1)
PYEOF
  then
    fail "$ask_file permissions.ask does not exactly match the merge and live-service rules: $(cat /tmp/validate-kit-ask-out.$$)"
    deny_ok=0
  fi
  rm -f /tmp/validate-kit-ask-out.$$
  rm -f "$py_script"
  [ "$deny_ok" -eq 0 ] || \
    pass "Claude blocks match the mechanical rules, direct merge commands are denied, and live-service changes ask first"
else
  note "python3 not available; falling back to a substring check on permissions.deny"
  while IFS= read -r deny_json; do
    [ -n "$deny_json" ] || continue
    for pattern in "git reset --hard" "git push --force" "git clean -f" "rm -rf"; do
      if ! grep -qF "$pattern" "$deny_json"; then
        fail "$deny_json permissions.deny is missing mechanical enforcement for '$pattern'"
      fi
    done
  done <<DENYFILES
$deny_jsonfiles
DENYFILES
fi

# ---------------------------------------------------------------------------
echo "== Command lists in shipped documents =="

# A count and a list are two claims, and only the count was guarded. A release
# shipped a document reading "Nine are commands you type" above a list of eight
# names, because raising the number is a search-and-replace and adding the name
# to every list somewhere else is not. The founded project's own instructions
# were one of those documents, so a new project was told about a command it
# never learned the name of.
#
# So the list is compared with the inventory rather than with a number. These
# are the shipped documents that name the commands one by one; a document that
# mentions one command in passing is not a list and is not checked.
#
# The loop reads a here-document rather than a pipe. A pipeline runs its body in
# a subshell, where fail sets the failure flag on a copy and the validator exits
# zero having printed FAIL. That is worse than no check, and it is how the first
# version of this one behaved.
command_lists="$ROOT/docs/COMPATIBILITY.md
$SKILLS/setup-ai-build-kit/templates/foundation/AGENTS.md"

list_ok=1
while IFS= read -r list_file; do
  [ -n "$list_file" ] || continue
  if [ ! -f "$list_file" ]; then
    fail "missing $list_file"
    list_ok=0
    continue
  fi
  # The run of backticked names that starts at setup-ai-build-kit, joined onto
  # one line first so a list wrapped across lines is read whole.
  listed=$(tr '\n' ' ' < "$list_file" \
    | grep -oE '`setup-ai-build-kit`[^.]*' \
    | head -1 \
    | grep -oE '`[a-z-]+`' \
    | tr -d '`' \
    | sort -u)
  expected=$(printf '%s\n' "$expected_commands" | sort)
  if [ "$listed" != "$expected" ]; then
    fail "$(basename "$list_file") names the commands one by one and the list does not match the inventory"
    echo "  expected:" >&2
    echo "$expected" | sed 's/^/    /' >&2
    echo "  found:" >&2
    echo "$listed" | sed 's/^/    /' >&2
    list_ok=0
  fi
done <<COMMANDLISTS
$command_lists
COMMANDLISTS

[ "$list_ok" -eq 1 ] && pass "every shipped document that lists the commands names all of them"

# ---------------------------------------------------------------------------
echo "== Stale-claim checks =="

# The manifest supplies the source files that ship, including templates. The
# public site is separate from the kit archive, so include its pages and data
# explicitly. Dated maintainer records and release notes retain historical
# descriptions of retired terms and are not part of this current-claims scan.
# The retired-skill and released-copy data files hold old names on purpose, so
# /maintain can recognise them, and are left out as retired-names.sh does.
project_docs="$(
  {
  awk -F'|' 'NF && $1 !~ /^[[:space:]]*#/ { print $1 }' "$ROOT/release-manifest.txt" |
    while IFS= read -r source; do
      [ -n "$source" ] || continue
      path="$ROOT/$source"
      if [ -f "$path" ]; then
        printf '%s\n' "$path" | grep -Eq '\.(md|txt|yml|yaml|json)$' && printf '%s\n' "$path"
      elif [ -d "$path" ]; then
        find "$path" -type f \( -name '*.md' -o -name '*.txt' -o -name '*.yml' -o -name '*.yaml' -o -name '*.json' \) -print
      fi
    done
  printf '%s\n' "$ROOT/.agents/skills/setup-hosting/recipes/parts/scripts/check-lib.sh"
  for path in "$ROOT/README.md" "$ROOT/WORKFLOW.md" "$ROOT/llms.txt" \
    "$ROOT/CONTRIBUTING.md" "$ROOT/SECURITY.md"; do
    [ ! -f "$path" ] || printf '%s\n' "$path"
  done
  find "$ROOT/site/src/content/docs" -type f \( -name '*.md' -o -name '*.mdx' -o -name '*.json' \) -print 2>/dev/null
  [ ! -f "$ROOT/site/data/workflow.json" ] || printf '%s\n' "$ROOT/site/data/workflow.json"
  } | sort -u | grep -v -e '/kit-retired-skills\.json$' -e '/kit-released-copies\.json$'
)"

check_claim() {
  # $1 = human label, $2 = fixed string to search for, $3 = optional file to
  # exclude (an explicit, legitimate "this is gone" reference)
  # Lines are joined with spaces before searching, so a claim that happens
  # to be soft-wrapped across a line break (a real case this once missed)
  # is still caught.
  hits=$(printf '%s\n' "$project_docs" | while IFS= read -r f; do
    [ -f "$f" ] || continue
    [ -n "${3:-}" ] && [ "$f" = "${3:-}" ] && continue
    if tr '\n' ' ' < "$f" | grep -qFi -- "$2"; then
      echo "$f"
    fi
  done)
  if [ -n "$hits" ]; then
    fail "stale claim ($1) found in: $(printf '%s' "$hits" | tr '\n' ' ')"
  fi
}

check_claim "all markdown" "all markdown"
check_claim "seven skills" "seven skills"
# The command count is written out in words in a dozen documents. The inventory
# check above knows how many commands there really are; nothing else did, so a
# document could keep the old number after the count moved and no check would
# say so.
check_claim "nine commands" "nine commands"
check_claim "eight commands" "eight commands"
check_claim "eight are commands" "eight are commands"
# The skill count moved with it, from thirteen to eleven and then to eight.
# The word alone also counts other things, such as pull request descriptions,
# so these name the phrases that counted skills.
check_claim "eleven skills" "eleven skills"
check_claim "eleven installed skills" "eleven installed"
check_claim "eleven kit skills" "eleven AI Build Kit"
check_claim "the same eleven" "the same eleven"
check_claim "five background skills" "five background skills"
check_claim "thirteen skills" "thirteen skills"
check_claim "thirteen canonical skills" "thirteen canonical"
check_claim "thirteen kit skills" "thirteen AI Build Kit"
check_claim "thirteen installed skills" "thirteen installed"
check_claim "thirteen installable skills" "thirteen installable"
check_claim "thirteen skill names" "the thirteen names"
check_claim "beside the thirteen" "beside the thirteen"
check_claim "the same thirteen" "the same thirteen"
check_claim "four project documents" "four project documents"
check_claim "four project records" "four project records"
check_claim "four documents" "four documents hold"
check_claim "four records" "four records"
check_claim "team.md" "team.md" "$SKILLS/setup-ai-build-kit/SKILL.md"
check_claim "mandatory fresh session" "Always a fresh session"
check_claim "universal pull-request claim" "which is not finished until its check is green"
check_claim "universal test-first claim" "Test first, and show the test failing before building"
check_claim "obsolete automatic-rebuild rule" "rebuilds the piece from the masterplan, which is usually quicker and cleaner"
check_claim "absolute discipline-visibility claim" "so they never appear in that list"
check_claim "incorrect Claude invocation semantics" "can't be launched by slash either"
# Every command description once ended "it never starts on its own". The agent
# may now start a command the person asks for in plain words, so a document
# that says otherwise describes a kit that no longer exists.
check_claim "a command that never starts on its own" "never starts on its own"
check_claim "everything is markdown claim" "everything here is plain markdown"
# The seven commands were called "the seven words" until August 2026. The old
# name reads like a fantasy novel rather than a tool, and half the register
# problem in the person-facing writing came from it. These catch it coming back
# one phrase at a time, which is how it would come back.
check_claim "the old seven-words name" "seven words"
check_claim "the old seven-word name" "seven-word"
check_claim "a command called a word" "which word comes next"
check_claim "the other commands called words" "six words"
# These two survived the rename in docs/SOURCES.md, where the ceiling is
# described rather than counted, so none of the counting phrases above matched.
check_claim "the ceiling counted in words" "how many words"
check_claim "an ability arriving inside a word" "a word that already exists"
# Phrases retired for 1.0. The scan covers release-manifest prose and templates
# as well as the separate site, so the terms cannot return in either surface.
check_claim "private exploration" "private exploration"
check_claim "four-path" "four-path"
check_claim "written by start" "written by start"
check_claim "Build these together now" "Build these together now"
check_claim "sensitive-area step" "sensitive-area step"
# Keep merge claims specific so the builder agent's true "never merges" brief
# remains valid. Every merge waits for approval only by default.
check_claim "absolute merge yes claim" "nothing merges without your yes"
check_claim "absolute merge wait claim" "every merge waits for your yes"
check_claim "absolute merge need claim" "every merge needs the person's yes"
# WORKFLOW.md once said both recipe trials proved every step. The PROVEN.md records do not support that.
check_claim "both recipe trials proved all steps" "Both trials proved the preview, launch, rollback, secrets, logs and health steps"
check_claim "absolute human merge claim" "a human decides whether to merge, always"
check_claim "human always decides merge" "A human decides whether to merge."
check_claim "merge only after a named yes" "Merge only on a yes that names it."
check_claim "implement requires a named yes" "Merge only on a yes naming it."
check_claim "first upload and each merge need a yes" "The first upload and each merge wait for a yes."
check_claim "blocked commands merge yes claim" "Never merge without the person's yes or force a merge past a required review."
check_claim "unattended merge always waits" "never merge or accept a risk for the person"

check_claim "informal missing approval wording" "No yes is recorded for"
check_claim "informal approval wording" "waits for a yes"
check_claim "informal named approval wording" "named yes"
check_claim "informal approval renewal wording" "fresh yes"
[ "$FAIL" -eq 0 ] && echo "ok: no stale claims found"

# ---------------------------------------------------------------------------
echo "== Maintainer writing contract =="

if grep -qF '.agents/maintainer-skills/writing-review/SKILL.md' "$ROOT/AGENTS.md" && \
   grep -qF '.agents/maintainer-skills/writing-review/SKILL.md' "$ROOT/docs/MAINTAINING.md" && \
   grep -qF 'name: writing-review' "$MAINTAINER_SKILLS/writing-review/SKILL.md" && \
   grep -qF 'Writing quality framework' "$MAINTAINER_SKILLS/writing-review/SKILL.md" && \
   grep -qF 'pattern-guide-version: "2.9.1"' "$MAINTAINER_SKILLS/writing-review/SKILL.md"; then
  pass "maintainer prose loads the local writing-review skill"
else
  fail "maintainer writing-review skill or writing instructions are incomplete"
fi

# ---------------------------------------------------------------------------
if [ "$FAIL" -ne 0 ]; then
  echo
  echo "validate-kit.sh: FAILED" >&2
  exit 1
fi

echo
echo "validate-kit.sh: all checks passed"
