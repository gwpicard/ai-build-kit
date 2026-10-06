#!/usr/bin/env sh
# whole-copy-leftovers.sh: guard the tidy step for a project founded from a
# whole copy of the kit.
#
# A project founded that way carries the kit's own generated adapters under
# .claude/commands/, .cursor/commands/ and .gemini/commands/. The shared
# installer never refreshes them, because it does not know they exist, and its
# own symlinks under .claude/skills/ already do the job. So Claude Code shows
# every command twice, and after the rename of plan to shape the project still
# offers /plan from a file nothing will ever remove. The retired skill folder
# survives the same way, because the lockfile no longer lists it.
#
# The obvious fix is to delete the files by hand, and that was refused: it
# fixes one project and leaves the next one to be found the same way. So the
# tidy is a step in maintain, and this check reads its rules back. The two
# that matter keep it safe: an adapter is recognised by its generated marker
# and never by its name, so a command file the person wrote survives, and a
# retired skill folder only by the kit's former names and absence from the
# lockfile, so the person's own skills survive.
#
# The move to six commands added four former names, `fix`, `queue`,
# `sync` and `ship`, and a shipped script that lists the leftovers by those
# rules and removes only what it listed. The second half of this check runs it
# in a throwaway whole copy of the last nine-command release, after the update
# registered the eleven.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

MAINTAIN="$ROOT/.agents/skills/maintain/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"
LEFTOVERS="$ROOT/.agents/skills/maintain/scripts/kit-leftovers.py"

rs_init "Whole-copy-leftovers checks"
rs_exists "$MAINTAIN" "$WORKFLOW" "$LEFTOVERS"

# Why the step exists, and why it is a step rather than advice.
rs_rule "the installer never refreshes the adapters" \
  'never refreshes them because it does not know they exist'
rs_rule "a hand deletion fixes one project" \
  'deleting the files by hand in one project fixes one project'

# The two rules that keep it safe.
rs_rule "an adapter is recognised by its marker" \
  'recognised only by the generated marker on its first lines'
rs_rule "and never by its name" \
  'never by its name: a command file the person wrote'
rs_rule "retired folders are looked for in both skill folders" \
  'look in both .\.agents/skills/. and .\.claude/skills/.'
rs_rule "a retired folder is one of the former names" \
  'one of the kit.s former names, .build., .start., .plan., .grilling., .fix., .queue., .sync. or .ship.'
rs_rule "and its SKILL.md is the kit's own" \
  'its .skill\.md. carries that name and a description one of the kit.s releases gave it'
rs_rule "the person's own skill under a former name is kept" \
  'a skill of theirs under one of those names included'
rs_rule "a generated skill folder for a dropped name is an adapter" \
  'is an adapter too, when its .skill\.md. carries the marker and its name is one the kit no longer has'
rs_rule "nothing outside the project, and no link followed" \
  'nothing whose real place is outside the project is listed for removal, and a link is never followed: at most the link itself goes'
rs_rule "and absent from the lockfile under any source" \
  'and the lockfile does not list it under any source'
rs_rule "any other folder is the person's own" \
  'any other folder there is the person.s own and is left alone'

# The step is offered, applied on approval, and recorded.
rs_rule "the list is shown with what removing it does" \
  'show the list and say what removing it does'
rs_rule "a former name the lockfile lists is the installer's" \
  'a former name the lockfile lists as the kit.s is the installer.s to remove'
rs_rule "the script lists the leftovers by these rules" \
  'its .adapter. and .folder. lines are the two lists above, found by these rules'
rs_rule "a retired command's file goes on every route" \
  'a generated command file for a retired command is listed on every route, since it opens nothing'
rs_rule "a current command's file only on the shared route" \
  'one for a current command is listed only on the shared route'
rs_rule "and removed on approval, only what was listed" \
  'remove on approval, by running the script with .--remove., which removes only what it listed'
rs_rule "the removal is read back" 'carry on only once it lists neither kind'
rs_rule "the old session-end hook is named and left" \
  'a .hook. line means its message still names a retired command'
rs_rule "the hook alone is never said again" \
  'say this only in a visit that also offers a removal, so a later visit that finds only the hook says nothing'
rs_rule "a manual update runs the tidy too" \
  'on the shared route, or after a manual update, that finds the leftovers below'
rs_rule "and recorded" 'a changelog line saying what was removed and why'

# It runs from the monthly pass and does nothing on a clean project.
rs_rule "the monthly pass calls it on the shared route" \
  'on the shared route, also run .tidying a project founded from a whole copy'
rs_rule "the manual fallback calls it" \
  'retired, so run "tidying a project founded from a whole copy of the kit" afterwards too'
rs_rule "a project without the leftovers gets nothing" \
  'a project that has none of them gets nothing here'
rs_guard "$MAINTAIN" "the maintain skill"

rs_require "WORKFLOW.md says the visit offers to remove the kit's command files" \
  "$WORKFLOW" 'the visit offers to remove those and leaves anything you wrote yourself alone'

# --- the script, run ----------------------------------------------------------

# A whole copy of the last nine-command release. It carries the kit's own
# command files for every tool and the old session-end hook, and the update has
# just registered the eleven with the installer. The person added a skill and a
# command of their own. The copy's retired skills carry the descriptions the
# kit's releases gave them, read from the record the script uses.
KNOWN="$ROOT/.agents/skills/maintain/scripts/kit-retired-skills.json"
kit_skill() {
  # kit_skill <folder> <name>: a SKILL.md as a kit release wrote it.
  mkdir -p "$1"
  python3 - "$KNOWN" "$2" > "$1/SKILL.md" <<'PY'
import json, sys
description = json.load(open(sys.argv[1]))["skills"][sys.argv[2]][-1]
print("---\nname: %s\ndescription: %s\n---\n" % (sys.argv[2], description))
PY
}
P="$rs_dir/copy"
nine="setup-ai-build-kit shape implement queue fix ship sync maintain what-now"
eleven="setup-ai-build-kit shape implement setup-hosting maintain what-now clarify change-triage screen-check section-builder second-opinion"
mkdir -p "$P/.agents/skills" "$P/.agents/hooks" "$P/.claude/commands" "$P/.cursor/commands" "$P/.gemini/commands"
for name in $eleven my-notes; do
  mkdir -p "$P/.agents/skills/$name"
  printf -- '---\nname: %s\n---\n' "$name" > "$P/.agents/skills/$name/SKILL.md"
done
for name in queue fix ship sync; do kit_skill "$P/.agents/skills/$name" "$name"; done
# The person's own skill under a former name, in no lockfile.
mkdir -p "$P/.agents/skills/build"
printf -- '---\nname: build\ndescription: my own build notes\n---\n' > "$P/.agents/skills/build/SKILL.md"
# The kit's generated background skill folders: four under current names, one
# under the name `clarify` once had, and one the person added a file to.
for name in clarify change-triage grilling plan; do
  mkdir -p "$P/.claude/skills/$name"
  printf -- '---\nname: %s\n---\n<!-- GENERATED from .agents/skills/%s/. Do not edit here; regenerate with .agents/tools/build-adapters.sh -->\n' "$name" "$name" > "$P/.claude/skills/$name/SKILL.md"
done
printf '%s\n' 'My notes.' > "$P/.claude/skills/plan/notes.md"
for name in $nine; do
  marker="GENERATED from .agents/skills/$name/. Do not edit here; regenerate with .agents/tools/build-adapters.sh"
  printf -- '---\ndescription: old\n---\n<!-- %s -->\n' "$marker" > "$P/.claude/commands/$name.md"
  printf '<!-- %s -->\n' "$marker" > "$P/.cursor/commands/$name.md"
  printf '# GENERATED from .agents/skills/%s/. Do not edit here.\n# Regenerate with .agents/tools/build-adapters.sh\n' "$name" > "$P/.gemini/commands/$name.toml"
done
printf '%s\n' 'My own deploy steps. Run /ship first.' > "$P/.claude/commands/deploy.md"
printf '%s\n' '#!/usr/bin/env sh' 'echo "Run /sync to check and reconcile them."' > "$P/.agents/hooks/session-end-sync.sh"
{
  printf '{"version": 1, "skills": {'
  sep=""
  for name in $eleven; do
    printf '%s"%s": {"source": "gwpicard/ai-build-kit", "sourceType": "github"}' "$sep" "$name"
    sep=", "
  done
  printf '}}\n'
} > "$P/skills-lock.json"
cp "$P/.claude/commands/deploy.md" "$rs_dir/deploy-before"
cp "$P/.agents/hooks/session-end-sync.sh" "$rs_dir/hook-before"

listed=$(python3 "$LEFTOVERS" "$P")
rs_report "every generated command file is listed, for all three tools" \
  "$([ "$(printf '%s\n' "$listed" | grep -cE '^adapter	\.(claude|cursor|gemini)/commands/')" = 27 ] && echo yes || echo no)"
rs_report "the four retired skill folders are listed" \
  "$([ "$(printf '%s\n' "$listed" | grep -cE '^folder	\.agents/skills/(fix|queue|sync|ship)$')" = 4 ] && echo yes || echo no)"
rs_report "the person's own build skill is named as left, not recognised" \
  "$(printf '%s\n' "$listed" | grep -qx "left	.agents/skills/build	not recognised as the kit's" \
     && ! printf '%s\n' "$listed" | grep -q '^folder	.agents/skills/build' && echo yes || echo no)"
rs_report "a generated skill folder for a dropped name is listed, one for a current name is not" \
  "$(printf '%s\n' "$listed" | grep -qx 'adapter	.claude/skills/grilling' \
     && ! printf '%s\n' "$listed" | grep -qE 'adapter	\.claude/skills/(clarify|change-triage)$' && echo yes || echo no)"
rs_report "a generated skill folder holding a file of the person's is left" \
  "$(printf '%s\n' "$listed" | grep -qx 'left	.claude/skills/plan	it holds files besides the generated one' && echo yes || echo no)"
rs_report "the person's own command file and skill are never listed" \
  "$(printf '%s\n' "$listed" | grep -qE 'deploy\.md|my-notes' && echo no || echo yes)"
rs_report "the old hook is named" \
  "$(printf '%s\n' "$listed" | grep -qx 'hook	.agents/hooks/session-end-sync.sh' && echo yes || echo no)"

python3 "$LEFTOVERS" --remove "$P"
r=yes
for n in queue fix ship sync; do [ ! -e "$P/.agents/skills/$n" ] || r=no; done
for n in $eleven; do [ -f "$P/.agents/skills/$n/SKILL.md" ] || r=no; done
rs_report "the retired folders are gone and the eleven remain" "$r"
rs_report "every generated command file is gone, and the emptied tool folders with them" \
  "$([ ! -e "$P/.cursor" ] && [ ! -e "$P/.gemini" ] && [ "$(ls "$P/.claude/commands")" = deploy.md ] && echo yes || echo no)"
rs_report "the person's command file, skills and hook are untouched" \
  "$(cmp -s "$P/.claude/commands/deploy.md" "$rs_dir/deploy-before" && cmp -s "$P/.agents/hooks/session-end-sync.sh" "$rs_dir/hook-before" \
     && [ -f "$P/.agents/skills/my-notes/SKILL.md" ] && grep -q 'my own build notes' "$P/.agents/skills/build/SKILL.md" \
     && [ -f "$P/.claude/skills/plan/notes.md" ] && echo yes || echo no)"
rs_report "the stale generated skill folder is gone, the current ones stay" \
  "$([ ! -e "$P/.claude/skills/grilling" ] && [ -f "$P/.claude/skills/clarify/SKILL.md" ] && echo yes || echo no)"
rs_report "a second run lists only what is never removed, which the visit then keeps quiet about" \
  "$([ "$(python3 "$LEFTOVERS" "$P" | grep -cv '^left	')" = 1 ] \
     && python3 "$LEFTOVERS" "$P" | grep -qx 'hook	.agents/hooks/session-end-sync.sh' && echo yes || echo no)"

# Links. A review linked the project's .claude/skills to a shared folder
# outside it, holding the person's own `sync` skill, and the removal followed
# the link and deleted it. Nothing outside the project is listed for removal,
# and a link is never followed: a link to the kit's folder inside the project
# goes on its own, and its target stays.
L="$rs_dir/links"
OUT="$rs_dir/links-outside"
mkdir -p "$L/.agents/skills" "$L/.agents/vendor" "$OUT"
kit_skill "$OUT/sync" sync
kit_skill "$OUT/plan" plan
mkdir -p "$L/.claude" "$L/.cursor"
ln -s "$OUT" "$L/.claude/skills"
ln -s "$OUT" "$L/.cursor/skills"
ln -s "$OUT/plan" "$L/.agents/skills/plan"
kit_skill "$L/.agents/vendor/start" start
ln -s "../vendor/start" "$L/.agents/skills/start"
cp -R "$OUT" "$rs_dir/outside-before"
links=$(python3 "$LEFTOVERS" "$L")
python3 "$LEFTOVERS" --remove "$L"
rs_report "a skill in a linked folder outside the project is named as left, and never removed" \
  "$(printf '%s\n' "$links" | grep -qx 'left	.claude/skills/sync	it sits in a folder whose real place is outside the project' \
     && diff -r "$OUT" "$rs_dir/outside-before" >/dev/null && echo yes || echo no)"
rs_report "a link to a skill outside the project is left, link and target both" \
  "$(printf '%s\n' "$links" | grep -qx 'left	.agents/skills/plan	it links to a folder outside the project' \
     && [ -L "$L/.agents/skills/plan" ] && echo yes || echo no)"
rs_report "a link to the kit's folder inside the project goes on its own, and its target stays" \
  "$(printf '%s\n' "$links" | grep -qx 'folder	.agents/skills/start' && [ ! -e "$L/.agents/skills/start" ] && [ ! -L "$L/.agents/skills/start" ] \
     && [ -f "$L/.agents/vendor/start/SKILL.md" ] && echo yes || echo no)"

# One folder reached two ways inside the project is listed once.
D="$rs_dir/twice"
mkdir -p "$D/.agents/skills"
kit_skill "$D/.agents/skills/queue" queue
ln -s ".agents" "$D/.claude"
rs_report "a folder reached through two paths is listed once" \
  "$([ "$(python3 "$LEFTOVERS" "$D" | grep -c '^folder')" = 1 ] && echo yes || echo no)"

# Off the shared route, a generated file for a current command may be how the
# person reaches it, so only a retired command's file is listed.
Q="$rs_dir/manual"
mkdir -p "$Q/.claude/commands"
for name in shape sync; do
  printf -- '---\n---\n<!-- GENERATED from .agents/skills/%s/. Do not edit here; regenerate with .agents/tools/build-adapters.sh -->\n' "$name" > "$Q/.claude/commands/$name.md"
done
rs_report "without a lockfile, only the retired command's file is listed" \
  "$([ "$(python3 "$LEFTOVERS" "$Q")" = "adapter	.claude/commands/sync.md" ] && echo yes || echo no)"

rs_done
