#!/usr/bin/env sh
# skill-structure.sh: run check-structure.py on a planted tree and prove each of
# its three rules fires, and stays quiet on a tree that keeps them.
#
# If this breaks, a command can grow its own copy of a shared rule, or reach
# into another command's references, and nothing says so. That is how a cut to
# one command dropped the merge safeguards three others relied on: nobody could
# see which file carried which rule.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
TOOL="$ROOT/.agents/tools/check-structure.py"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }
pass() { echo "ok: $1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

# words N: a line of N words.
words() {
  python3 -c "import sys; print(' '.join(['word'] * int(sys.argv[1])))" "$1"
}

# A tree that keeps every rule: two commands, two background skills each
# called by both commands, and one agent.
plant() {
  T="$1"
  mkdir -p "$T/.agents/tools" "$T/.agents/agents"
  printf '%s\n' "command alpha" "command beta" "background gamma" "background delta" \
    "agent helper" > "$T/.agents/tools/kit-inventory.txt"
  for skill in alpha beta; do
    mkdir -p "$T/.agents/skills/$skill/references"
    printf -- '---\nname: %s\ndescription: A command.\n---\nLoad the `gamma` skill, then the `delta` skill.\n' \
      "$skill" > "$T/.agents/skills/$skill/SKILL.md"
    printf 'Its own reference. See its own `references/own.md`.\n' > "$T/.agents/skills/$skill/references/own.md"
  done
  for skill in gamma delta; do
    mkdir -p "$T/.agents/skills/$skill/references"
    printf -- '---\nname: %s\ndescription: A background skill.\nuser-invocable: false\n---\nOne job.\n' \
      "$skill" > "$T/.agents/skills/$skill/SKILL.md"
  done
  printf -- '---\nname: helper\ndescription: An agent.\nskills: [gamma]\n---\nLoad the gamma skill.\n' \
    > "$T/.agents/agents/helper.md"
}

run() {
  python3 "$TOOL" "$@"
}

CLEAN="$WORK/clean"
plant "$CLEAN"
out=$(run --strict "$CLEAN") && rc=0 || rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "a tree that keeps every rule passes in strict mode and prints nothing"
else
  fail "a tree that keeps every rule was reported (exit $rc): $out"
fi

# 1. A command loads another command's reference, and a named section.
T="$WORK/loads"
plant "$T"
printf 'Follow the `beta` skill'"'"'s\n`references/own.md` here.\n' >> "$T/.agents/skills/alpha/SKILL.md"
printf 'Follow the `alpha` skill'"'"'s "Rolling back" first.\n' >> "$T/.agents/skills/beta/references/own.md"
out=$(run --strict "$T") && rc=0 || rc=$?
if [ "$rc" -eq 1 ] \
  && printf '%s\n' "$out" | grep -q "^loads	.agents/skills/alpha/SKILL.md:6	loads the beta command's \`references/own.md\`" \
  && printf '%s\n' "$out" | grep -q "^loads	.agents/skills/beta/references/own.md:2	loads the alpha command's \"Rolling back\""; then
  pass "a command reaching into another command's reference or section is named, line break included"
else
  fail "a cross-command load was missed (exit $rc): $out"
fi

# The same reach written as a path, with or without a leading folder, and a
# command's SKILL.md named directly.
for form in '.agents/skills/beta/references/own.md' 'skills/beta/references/own.md' \
            '../beta/references/own.md' '`beta/SKILL.md`'; do
  T="$WORK/path"
  rm -rf "$T"
  plant "$T"
  printf 'Read %s first.\n' "$form" >> "$T/.agents/skills/alpha/SKILL.md"
  out=$(run --strict "$T") && rc=0 || rc=$?
  if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q "^loads	.agents/skills/alpha/SKILL.md:6	loads the beta command's"; then
    pass "a command reaching into another as $form is named"
  else
    fail "a command reaching into another as $form was missed (exit $rc): $out"
  fi
done

# A file named on its own that no skill has points at nothing.
T="$WORK/bare"
plant "$T"
printf 'Follow fit-check.md for the notice, and `own.md` for the rest.\n' >> "$T/.agents/skills/beta/references/own.md"
out=$(run --strict "$T") && rc=0 || rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q "^missing	.agents/skills/beta/references/own.md:2	names fit-check.md, which no skill has" \
  && ! printf '%s\n' "$out" | grep -q "names own.md"; then
  pass "a file named on its own that no skill has is reported, and one a skill has is not"
else
  fail "a bare file name was misjudged (exit $rc): $out"
fi

# A background skill's reference may be loaded by anyone, and a command's own
# reference by itself.
T="$WORK/allowed"
plant "$T"
printf 'Follow the `gamma` skill'"'"'s `references/x.md`, and this skill'"'"'s `references/own.md`.\n' \
  >> "$T/.agents/skills/alpha/SKILL.md"
out=$(run --strict "$T") && rc=0 || rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "a background skill's reference and a command's own stay allowed"
else
  fail "an allowed load was reported (exit $rc): $out"
fi

# 2. A background skill with one caller and no agent.
T="$WORK/callers"
plant "$T"
printf -- '---\nname: beta\ndescription: A command.\n---\nLoad the `gamma` skill.\n' \
  > "$T/.agents/skills/beta/SKILL.md"
out=$(run --strict "$T") && rc=0 || rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q "^callers	delta	called by alpha, and loaded by no agent"; then
  pass "a background skill with one caller and no agent is named"
else
  fail "a background skill short of callers was missed (exit $rc): $out"
fi
# gamma keeps one caller too, but the agent loads it.
if printf '%s\n' "$out" | grep -q "^callers	gamma"; then
  fail "a background skill an agent loads was reported as short of callers"
else
  pass "a background skill an agent loads needs no second caller"
fi

# 3. Word budgets: command, background skill, reference. Frontmatter is free.
T="$WORK/words"
plant "$T"
printf -- '---\nname: alpha\ndescription: %s\n---\n%s\n' "$(words 300)" "$(words 401)" \
  > "$T/.agents/skills/alpha/SKILL.md"
printf -- '---\nname: beta\ndescription: A command.\n---\n%s\nLoad the `gamma` skill and the `delta` skill.\n' \
  "$(words 390)" > "$T/.agents/skills/beta/SKILL.md"
printf -- '---\nname: gamma\ndescription: x\nuser-invocable: false\n---\n%s\nCalls the `delta` skill.\n' \
  "$(words 801)" > "$T/.agents/skills/gamma/SKILL.md"
words 601 > "$T/.agents/skills/delta/references/long.md"
out=$(run --strict "$T") && rc=0 || rc=$?
if [ "$rc" -eq 1 ] \
  && printf '%s\n' "$out" | grep -q "^words	.agents/skills/alpha/SKILL.md	401 words, over the command budget of 400" \
  && printf '%s\n' "$out" | grep -q "^words	.agents/skills/gamma/SKILL.md	805 words, over the background budget of 800" \
  && printf '%s\n' "$out" | grep -q "^words	.agents/skills/delta/references/long.md	601 words, over the reference budget of 600" \
  && ! printf '%s\n' "$out" | grep -q "beta/SKILL.md"; then
  pass "each kind of file is held to its own budget, and frontmatter is not counted"
else
  fail "a word budget was misread (exit $rc): $out"
fi

# Without --strict it reports and passes, which is how a slice lands the check
# before the tree meets it.
out=$(run "$T") && rc=0 || rc=$?
if [ "$rc" -eq 0 ] && [ -n "$out" ]; then
  pass "without --strict the findings print and the exit stays 0"
else
  fail "the report-only mode changed its exit or printed nothing (exit $rc)"
fi

# An unreadable inventory is exit 2, never a pass.
T="$WORK/noinventory"
plant "$T"
rm "$T/.agents/tools/kit-inventory.txt"
run --strict "$T" >/dev/null 2>&1 && rc=0 || rc=$?
if [ "$rc" -eq 2 ]; then
  pass "a missing inventory stops the check with exit 2"
else
  fail "a missing inventory gave exit $rc"
fi

exit "$FAIL"
