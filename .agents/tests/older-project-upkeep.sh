#!/usr/bin/env sh
# older-project-upkeep.sh: guard what the monthly visit brings to an older project.
#
# Three things an update never reaches, because it refreshes skills and nothing
# else. A plan.md left from before pieces became issues, which used to be
# offered only on the one visit that first brought in /shape and /implement,
# so a project that missed it kept the file for good. Pointers in AGENTS.md and
# the masterplan that name a skill's file by a folder a Claude-Code-only or
# plugin install does not have. And the reminder script, which a visit copied
# in even after the person asked for no kit updates.
#
# The pointer rewrite runs a shipped script, so its half of this check runs it:
# an old project is offered the rewrite and a current one gets nothing, and a
# pattern too broad would rewrite a project's own skill or a passing mention.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

MAINTAIN="$ROOT/.agents/skills/maintain/SKILL.md"
SCRIPT="$ROOT/.agents/skills/maintain/scripts/old-skill-pointers.py"
WORKFLOW="$ROOT/WORKFLOW.md"
TEMPLATES="$ROOT/.agents/skills/setup-ai-build-kit/templates"

rs_init "Older-project upkeep rules"
rs_exists "$MAINTAIN" "$SCRIPT" "$WORKFLOW" "$TEMPLATES/foundation/AGENTS.md" "$TEMPLATES/masterplan.md"

# Both are decided by what is on disk, every visit.
rs_rule "the monthly step runs both on what is on disk" 'on every visit, run "pointing the records at a skill by name" below, and whenever a `plan\.md` is at the project root, run "moving a plan\.md into issues" below'
rs_rule "plan.md is offered for as long as it is there" 'run this on any visit that finds a `plan\.md` at the project root, for as long as it is there'
rs_rule "the shape migration points to it" 'move a `plan\.md` into issues, as "moving a plan\.md into issues" below says'
rs_rule "a plan.md of the person's own is left alone" 'where the file is plainly something else of the person.s, such as their own notes, leave it and say nothing'
rs_rule "plan.md is removed only after the move" 'name what moved, and only then remove `plan\.md`'
rs_rule "a no to the move comes back next visit" 'nothing records the no, so the offer comes back on the next visit that still finds the file'

# The pointer rewrite.
rs_rule "the pointer step runs every visit" 'pointing the records at a skill by name run this on every visit'
rs_rule "it runs the shipped script" 'scripts/old-skill-pointers\.py'
rs_rule "nothing to change says nothing" 'when it prints nothing, say nothing'
rs_rule "the rewrite waits for a yes" 'show one line before and after\. wait for the person.s yes'
rs_rule "the rewrite is read back" 'run it again without, and carry on only once it prints nothing'
rs_rule "a no changes nothing" 'where the person says no, leave both files as they are\. the offer comes back on the next visit that still finds an old pointer'

# The reminder script after a no to kit updates.
rs_rule "the hook is skipped after no kit updates" 'unless the person asked during this visit to leave kit updates alone'
rs_rule "the request is read, not matched" 'read what they asked, not a fixed phrase'
rs_rule "a skipped hook is said in one sentence" 'i left out the script that reminds a session when a visit is due, since you asked for no kit updates'

rs_guard "$MAINTAIN" "the maintain skill"

rs_require_load_bearing "WORKFLOW says plan.md is offered until moved" "$WORKFLOW" 'any visit that finds an older `plan\.md` list offers to move it into your project.s issues, and keeps offering until it is moved'
rs_require_load_bearing "WORKFLOW says the pointers are rewritten on a yes" "$WORKFLOW" 'offers to name the skill instead, changing only those lines, and only on your yes'
rs_require_load_bearing "WORKFLOW says the reminder is skipped after a no" "$WORKFLOW" 'if you ask a visit to leave kit updates alone, it does not add that reminder either, and says so'

# --- the script, run --------------------------------------------------------

WORK="$rs_dir/projects"
mkdir -p "$WORK/old" "$WORK/current" "$WORK/own"

# An old project, in the form the templates once wrote.
cat > "$WORK/old/AGENTS.md" <<'EOF'
When a skill says to run another skill, load that installed skill and follow
it. If native discovery is unavailable, open `.agents/skills/<name>/SKILL.md`
directly. Skills live in `.agents/skills/`.
The remaining work lives in this project's issues, one per piece, in the shape
`.agents/skills/setup-ai-build-kit/references/pieces.md` describes.
Our own deploy notes are in `.agents/skills/deploy-notes/SKILL.md`.
EOF
cat > "$WORK/old/masterplan.md" <<'EOF'
<!-- Rewritten only by re-running the fit check, which lives at
.agents/skills/setup-ai-build-kit/references/fit-check.md. The agent reads this section
first, every session. -->
EOF
cp "$WORK/old/AGENTS.md" "$WORK/old/AGENTS.before"

found=$(python3 "$SCRIPT" "$WORK/old")
rs_report "an old project's two pointers are both found" \
  "$([ "$(printf '%s\n' "$found" | grep -c .)" = 2 ] && echo yes || echo no)"
rs_report "each finding names its file, line and new form" \
  "$(printf '%s\n' "$found" | grep -qF "masterplan.md:2	.agents/skills/setup-ai-build-kit/references/fit-check.md	the \`setup-ai-build-kit\` skill's \`references/fit-check.md\`" && echo yes || echo no)"
rs_report "listing changes nothing" \
  "$(cmp -s "$WORK/old/AGENTS.md" "$WORK/old/AGENTS.before" && echo yes || echo no)"

python3 "$SCRIPT" --apply "$WORK/old" >/dev/null
rs_report "the rewrite gives the form the templates use now" \
  "$(grep -qF "the \`setup-ai-build-kit\` skill's \`references/pieces.md\` describes." "$WORK/old/AGENTS.md" && echo yes || echo no)"
rs_report "a placeholder, the folder and the project's own skill are left alone" \
  "$(grep -qF '`.agents/skills/<name>/SKILL.md`' "$WORK/old/AGENTS.md" \
     && grep -qF 'Skills live in `.agents/skills/`.' "$WORK/old/AGENTS.md" \
     && grep -qF '`.agents/skills/deploy-notes/SKILL.md`' "$WORK/old/AGENTS.md" && echo yes || echo no)"
rs_report "only the pointer lines changed" \
  "$([ "$(diff "$WORK/old/AGENTS.before" "$WORK/old/AGENTS.md" | grep -c '^<')" = 1 ] && echo yes || echo no)"
rs_report "a second run finds nothing" \
  "$([ -z "$(python3 "$SCRIPT" "$WORK/old")" ] && echo yes || echo no)"

# A project founded today, from the shipped templates, gets nothing.
cp "$TEMPLATES/foundation/AGENTS.md" "$WORK/current/AGENTS.md"
cp "$TEMPLATES/masterplan.md" "$WORK/current/masterplan.md"
rs_report "a project founded from today's templates gets no offer" \
  "$([ -z "$(python3 "$SCRIPT" "$WORK/current")" ] && echo yes || echo no)"

# A project whose only matching folder is its own skill gets nothing either.
printf '%s\n' 'See `.agents/skills/deploy-notes/SKILL.md`.' > "$WORK/own/AGENTS.md"
rs_report "a project's own skill is never offered" \
  "$([ -z "$(python3 "$SCRIPT" "$WORK/own")" ] && echo yes || echo no)"

# The script's list of the kit's skills has to be the kit's skills, or a
# renamed or added skill's pointers would be missed without a word.
listed=$(PYTHONDONTWRITEBYTECODE=1 python3 - "$SCRIPT" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("p", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
print("\n".join(sorted(module.KIT_SKILLS)))
PY
)
shipped=$(ls "$ROOT/.agents/skills" | sort)
rs_report "the script names exactly the kit's fourteen skills" \
  "$([ "$listed" = "$shipped" ] && [ "$(printf '%s\n' "$listed" | grep -c .)" = 14 ] && echo yes || echo no)"

rs_done
