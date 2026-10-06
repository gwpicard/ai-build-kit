#!/usr/bin/env sh
# shared-route-adds.sh: guard the shared installer route, which has to add a
# skill the kit renamed and not only refresh the ones already there.
#
# The kit renamed `plan` to `shape`. A project on the shared route updated
# across that rename with the installer's `update` command, which refreshes
# only what `skills-lock.json` already lists and drops any other name without a
# word. The update removed `plan`, because it had gone upstream, and never
# installed `shape`, because it was not in the lockfile. The project was left
# with no command for shaping a piece, and the version file said it was up to
# date, because the same update that dropped the skill rewrote the version.
#
# Three rules close that. The route is the installer's `add` command, which
# refreshes an installed skill and adds a missing one. The monthly pass counts
# the lockfile against eleven, since the count is the only sign a skill is
# missing. And each rename migration fires on what is on disk rather than on
# which update this is, with a branch for the state where the old skill is
# gone and the new one never came. The maintain skill carries the rules and
# this check reads them back, because the installer is somebody else's tool and
# nothing here can watch it run.
#
# The move to six commands left the opposite problem. The `add`
# command brings `setup-hosting`, but it keeps `fix`, `queue`, `sync` and `ship`
# installed and listed, so the old commands stay on offer beside the new ones,
# and the project's AGENTS.md still lists all nine. A rehearsal with the real
# installer showed both. So the migration offers the installer's own `remove`
# for the names the lockfile lists as the kit's, never a deletion by hand, and
# rewrites the command list with a shipped script. The second half of this
# check runs that script in a throwaway project laid out as a shared install of
# the last nine-command release, after the update.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

MAINTAIN="$ROOT/.agents/skills/maintain/SKILL.md"
COMPAT="$ROOT/docs/COMPATIBILITY.md"
WORKFLOW="$ROOT/WORKFLOW.md"
SCENARIOS="$ROOT/.agents/tests/scenarios.md"
LEFTOVERS="$ROOT/.agents/skills/maintain/scripts/kit-leftovers.py"
TEMPLATE="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"

rs_init "Shared-route-adds checks"
rs_exists "$MAINTAIN" "$COMPAT" "$WORKFLOW" "$SCENARIOS" "$LEFTOVERS" "$TEMPLATE"

# The count, and why the version file cannot stand in for it.
rs_rule "the lockfile is counted against the eleven names" \
  'count its entries against the eleven names'
rs_rule "because the update that drops a skill also rewrites the version" \
  'the same update that drops a skill rewrites the version'
rs_rule "a matching version alone is not proof" \
  'a matching version alone is not proof'

# The route, and why the other command is not it.
rs_rule "the person picks the agents the project already uses" \
  'choose the same coding agents the project already uses'
rs_rule "universal is what gives the real folder" \
  'choosing .universal. is what puts the real folder'
rs_rule "the installer's update command is refused for the kit" \
  'do not use .npx skills update. for the kit'
rs_rule "because it drops a name it does not know without a word" \
  'drops any other name without a word'
rs_rule "the add route brings in screen-check for an older installation" \
  'same .npx skills add. command added it'
rs_rule "the visit waits until screen-check is present" \
  'carry on only once it is there'

# The migrations fire on the disk, and recover the neither-present state.
rs_rule "the migrations are decided by what is on disk" \
  'decided by what is on disk rather than by which update this is'
rs_rule "the shape migration fires on plan present or shape absent" \
  'finds a .plan. skill installed, or no .shape. skill'
rs_rule "and adds shape when neither is there" \
  'carry on only once .shape. is there'
rs_rule "the setup migration fires on start present or setup absent" \
  'finds a .start. skill installed, or no .setup-ai-build-kit. skill'
rs_rule "and adds setup-ai-build-kit when neither is there" \
  'carry on only once .setup-ai-build-kit. is there'

# The project's own instructions are brought up to the new name, with approval,
# rather than left to the person.
rs_rule "the reason the kit edits a project-owned file" \
  'made to fix it by hand after every rename will stop updating'
rs_rule "plan becomes shape in the command list" \
  'where it names .plan., replace it with .shape.'
rs_rule "the change is shown and applied on approval" \
  'show the change and apply it on approval'
rs_rule "an unrecognised list is left alone and named" \
  'leave the file alone and say which name needs changing'
rs_rule "the shape migration calls it rather than asking the person" \
  'rather than asking the person to do it'
rs_rule "the setup migration calls it too" \
  'so the person is not left to do it'

# The move to six commands. It fires on the disk and on the list, every visit.
rs_rule "the count names an old entry the installer kept" \
  'an entry under one of the kit.s former names, such as .fix., .queue., .sync. or .ship., is an old skill the installer kept'
rs_rule "the monthly step calls the six-command migration" \
  'also run "migrating a project installed before the six commands"'
rs_rule "it fires on an old skill, no setup-hosting, or an old list" \
  'run this on any monthly visit that finds a .fix., .queue., .sync. or .ship. skill installed, no .setup-hosting. skill, or a command list in agents\.md that names one of the four'
rs_rule "a second visit does nothing and says nothing" \
  'a visit that finds the six commands and the list already current does nothing here and says nothing'
rs_rule "why the step exists: the installer keeps a listed skill" \
  'the shared installer keeps an old skill it still lists'
rs_rule "it reads what is left with the shipped script" \
  'run .python3 <installed maintain skill>/scripts/kit-leftovers\.py.\. it prints one line for each thing left behind'
rs_rule "the installer removes what the lockfile lists, in one command" \
  'offer to remove it with the installer, naming each one in a single command such as .npx skills remove fix queue sync ship.'
rs_rule "never by hand" \
  'never delete one of these folders by hand, since the lockfile would still list it'
rs_rule "the removal is read back to eleven" \
  'carry on only once no .installer. line is left and the lockfile count is eleven'
rs_rule "a missing new skill is added again and read back" \
  'carry on only once no .missing. line is left'
rs_rule "the plugin update replaces the commands itself" \
  'the plugin update itself replaces the commands'
rs_rule "but the plugin route still needs the list rewritten" \
  'the agents\.md list still needs step 5'
rs_rule "old mentions in the records are history" \
  'is history\. it says what happened at the time, so leave it\. the changelog is never rewritten'
rs_rule "the one line the person hears" \
  '"the kit now has six commands\. /fix and /queue are part of /shape and /implement, /sync is part of /maintain, and /ship is now /setup-hosting\. nothing you built has changed\."'
rs_rule "a no leaves the old command and the offer returns" \
  'the old command stays on offer beside the new one until it is removed, and that the offer comes back on the next visit'
rs_rule "an Agent Plugins folder is read back for old skills" \
  'the agent.s command did not replace the folder whole'
rs_rule "a manual update leaves retired folders for the tidy" \
  'that leaves the folder of a skill the kit has since retired'

# The command list itself.
rs_rule "ship becomes setup-hosting in the command list" \
  'where it names .ship., replace it with .setup-hosting.'
rs_rule "a folded command's name is taken out" \
  'where it names .fix., .queue. or .sync., take the name out'
rs_rule "the background skills line is brought to five" \
  'bring the .- background skills:. line to the five the template names'
rs_rule "the rewrite changes those lines only" \
  'it changes those lines and nothing else in the file, line endings included'
rs_rule "the rewrite is read back" \
  'carry on only once no .commands. line offers a change'
rs_guard "$MAINTAIN" "the maintain skill"

# The places a person reads about the route say the same thing.
rs_require "COMPATIBILITY.md gives the add command as the route" \
  "$COMPAT" 'npx skills add gwpicard/ai-build-kit'
rs_require "and says why update is not the route" \
  "$COMPAT" 'refreshes only what the lockfile already lists'
rs_require "WORKFLOW.md says an update adds a renamed skill" \
  "$WORKFLOW" 'adds any skill the kit has renamed or added since'
rs_require "the scenario record says update cannot add" \
  "$SCENARIOS" 'cannot add a skill the kit renamed'
rs_require "WORKFLOW.md says a rename rewrites the command list with approval" \
  "$WORKFLOW" 'rewrites the command list in your agents.md, with your approval'
rs_require_load_bearing "WORKFLOW.md gives the one line about the six commands" \
  "$WORKFLOW" '/fix and /queue are now part of /shape and /implement, /sync is part of /maintain, and /ship is now /setup-hosting\. nothing you built changes'
rs_require_load_bearing "WORKFLOW.md says nothing is removed without a yes" \
  "$WORKFLOW" 'offers to remove the old skills and to rewrite the command list in your agents\.md, and does neither without your yes'
rs_require_load_bearing "WORKFLOW.md says the records keep their old mentions" \
  "$WORKFLOW" 'your masterplan and changelog keep their old mentions'
rs_require_load_bearing "COMPATIBILITY.md says the installer removes a retired skill on a yes" \
  "$COMPAT" 'offers to remove each one with .npx skills remove.'
rs_require_load_bearing "COMPATIBILITY.md says the plugin update drops a retired command" \
  "$COMPAT" 'a command the kit has retired is gone after that reload'

# --- the script, run ----------------------------------------------------------

# A shared install of the last nine-command release, for Claude Code and
# Codex, after the update: the add command brought setup-hosting and kept the
# four old skills listed, as the real installer did in a rehearsal. The person
# has a skill and a command file of their own, and records that mention the
# old commands.
P="$rs_dir/shared"
mkdir -p "$P/.agents/skills" "$P/.claude/skills" "$P/.claude/commands"
eleven="setup-ai-build-kit shape implement setup-hosting maintain what-now clarify change-triage screen-check section-builder second-opinion"
old="fix queue sync ship"
{
  printf '{\n  "version": 1,\n  "skills": {\n'
  for name in $eleven $old; do
    printf '    "%s": { "source": "gwpicard/ai-build-kit", "sourceType": "github", "computedHash": "0" },\n' "$name"
  done
  printf '    "my-notes": { "source": "someone/notes", "sourceType": "github", "computedHash": "0" }\n  }\n}\n'
} > "$P/skills-lock.json"
for name in $eleven $old my-notes; do
  mkdir -p "$P/.agents/skills/$name"
  printf -- '---\nname: %s\n---\n' "$name" > "$P/.agents/skills/$name/SKILL.md"
  ln -s "../../.agents/skills/$name" "$P/.claude/skills/$name"
done
printf '%s\n' 'My own deploy notes.' > "$P/.claude/commands/deploy.md"
cat > "$P/AGENTS.md" <<'AGENTS'
# Standing instructions

## The skills

The work lives in fourteen installed AI Build Kit skills. Nine are commands:
start the one the user types, names, or asks for in plain words, and say which
one you are running. Never start a command the user did not ask for. The other
five run in the background when a command needs them.

- Commands: `setup-ai-build-kit`, `shape`, `implement`, `queue`, `fix`, `ship`,
  `sync`, `maintain`, `what-now`.
- Background skills: `clarify`, `change-triage`, `screen-check`,
  `section-builder`, `second-opinion`.

Our team types /ship on Fridays, and nine is our lucky number.
AGENTS
printf '%s\n' '# Masterplan' 'We launched with /ship and caught up with /sync.' > "$P/masterplan.md"
printf '%s\n' '# Changelog' '- 2026-09-01: /fix repaired the sign-in page.' > "$P/CHANGELOG.md"
for f in masterplan.md CHANGELOG.md skills-lock.json .claude/commands/deploy.md; do
  cp "$P/$f" "$rs_dir/before-$(basename "$f")"
done
cp "$P/AGENTS.md" "$rs_dir/before-agents"

listed=$(python3 "$LEFTOVERS" "$P")
rs_report "each old skill the lockfile lists is named for the installer to remove" \
  "$([ "$(printf '%s\n' "$listed" | grep -c '^installer	')" = 4 ] \
     && printf '%s\n' "$listed" | grep -qF 'installer	ship	npx skills remove ship' && echo yes || echo no)"
rs_report "the person's own skill, listed from elsewhere, is never named" \
  "$(printf '%s\n' "$listed" | grep -q 'my-notes' && echo no || echo yes)"
rs_report "the command list is offered as the six" \
  "$(printf '%s\n' "$listed" | grep -qF -- '- Commands: `setup-ai-build-kit`, `shape`, `implement`, `setup-hosting`, `maintain`, `what-now`.' && echo yes || echo no)"
rs_report "and the counts as eleven and six" \
  "$(printf '%s\n' "$listed" | grep -qF '	fourteen	eleven' && printf '%s\n' "$listed" | grep -qF '	Nine	Six' && echo yes || echo no)"
rs_report "a list already current offers no change to its background line" \
  "$(printf '%s\n' "$listed" | grep -q 'Background skills' && echo no || echo yes)"

python3 "$LEFTOVERS" --remove "$P"
rs_report "the script never removes a folder the lockfile lists" \
  "$(for n in $old; do [ -d "$P/.agents/skills/$n" ] || echo gone; done | grep -q gone && echo no || echo yes)"

python3 "$LEFTOVERS" --rewrite-commands "$P"
diff "$rs_dir/before-agents" "$P/AGENTS.md" > "$rs_dir/agents.diff" || true
rs_report "the rewrite gives the template's command line" \
  "$(grep -qF -- '- Commands: `setup-ai-build-kit`, `shape`, `implement`, `setup-hosting`,' "$P/AGENTS.md" \
     && grep -qF '  `maintain`, `what-now`.' "$P/AGENTS.md" && echo yes || echo no)"
rs_report "and the template's counts" \
  "$(grep -qF 'The work lives in eleven installed AI Build Kit skills. Six are commands:' "$P/AGENTS.md" && echo yes || echo no)"
rs_report "and changes nothing else in the file, the person's own line included" \
  "$([ "$(grep -c '^<' "$rs_dir/agents.diff")" = 3 ] \
     && grep -qF 'Our team types /ship on Fridays, and nine is our lucky number.' "$P/AGENTS.md" && echo yes || echo no)"

# The installer's remove, as the rehearsal saw it: the folders, their links
# and their lockfile entries go.
for n in $old; do
  rm -R "$P/.agents/skills/$n"
  rm "$P/.claude/skills/$n"
done
python3 - "$P/skills-lock.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path))
for name in ("fix", "queue", "sync", "ship"):
    data["skills"].pop(name)
json.dump(data, open(path, "w"), indent=2)
PY
rs_report "once the installer has removed them, a second run finds nothing" \
  "$([ -z "$(python3 "$LEFTOVERS" "$P")" ] && echo yes || echo no)"
cp "$P/AGENTS.md" "$rs_dir/after-agents"
python3 "$LEFTOVERS" --rewrite-commands "$P"
python3 "$LEFTOVERS" --remove "$P"
rs_report "and a second rewrite and removal change nothing" \
  "$(cmp -s "$P/AGENTS.md" "$rs_dir/after-agents" && echo yes || echo no)"
rs_report "the six commands and five background skills are all still installed" \
  "$(for n in $eleven; do [ -f "$P/.agents/skills/$n/SKILL.md" ] && [ -e "$P/.claude/skills/$n" ] || echo gone; done | grep -q gone && echo no || echo yes)"
rs_report "the person's records, their skill and their command file are untouched" \
  "$(cmp -s "$P/masterplan.md" "$rs_dir/before-masterplan.md" && cmp -s "$P/CHANGELOG.md" "$rs_dir/before-CHANGELOG.md" \
     && cmp -s "$P/.claude/commands/deploy.md" "$rs_dir/before-deploy.md" && [ -f "$P/.agents/skills/my-notes/SKILL.md" ] && echo yes || echo no)"

# An update that removed an old skill without adding its new one.
mkdir -p "$rs_dir/short/.agents/skills"
printf '{"version": 1, "skills": {"maintain": {"source": "gwpicard/ai-build-kit"}}}\n' > "$rs_dir/short/skills-lock.json"
mkdir -p "$rs_dir/short/.agents/skills/maintain"
printf -- '---\nname: maintain\n---\n' > "$rs_dir/short/.agents/skills/maintain/SKILL.md"
rs_report "a missing new skill is named" \
  "$(python3 "$LEFTOVERS" "$rs_dir/short" | grep -qx 'missing	setup-hosting' && echo yes || echo no)"

# A list in the person's own words, or one naming a command of their own, is
# named and left alone.
mkdir -p "$rs_dir/own"
printf '%s\n' '## The skills' '' '- Commands: `shape`, `ship`, `deploy-now`.' > "$rs_dir/own/AGENTS.md"
cp "$rs_dir/own/AGENTS.md" "$rs_dir/own-before"
own=$(python3 "$LEFTOVERS" "$rs_dir/own")
python3 "$LEFTOVERS" --rewrite-commands "$rs_dir/own"
rs_report "a list naming a command of the person's own is listed with its reason and left" \
  "$(printf '%s\n' "$own" | grep -q 'left as written: it names `deploy-now`' && cmp -s "$rs_dir/own/AGENTS.md" "$rs_dir/own-before" && echo yes || echo no)"
printf '%s\n' 'We use /shape, /implement and /sync every week.' > "$rs_dir/own/AGENTS.md"
rs_report "a list in the person's own words names the word to change" \
  "$(python3 "$LEFTOVERS" "$rs_dir/own" | grep -q 'not recognised; `sync` needs changing by hand' && echo yes || echo no)"

# A project founded from today's templates gets nothing.
mkdir -p "$rs_dir/today"
cp "$TEMPLATE" "$rs_dir/today/AGENTS.md"
rs_report "a project founded today gets nothing" \
  "$([ -z "$(python3 "$LEFTOVERS" "$rs_dir/today")" ] && echo yes || echo no)"

# The script's list of the kit's skills has to be the kit's skills.
names=$(PYTHONDONTWRITEBYTECODE=1 python3 - "$LEFTOVERS" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("k", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
print("\n".join(sorted(module.KIT_SKILLS)))
PY
)
rs_report "the script names exactly the kit's eleven skills" \
  "$([ "$names" = "$(ls "$ROOT/.agents/skills" | sort)" ] && echo yes || echo no)"

# The stale-name refusals in other checks read past the migration's own
# passages, and only those. A stray mention outside them is still caught.
printf '%s\n' '## Migrating a project installed before the six commands' 'Type /sync no more.' '' \
  '## Next' 'Fine here.' > "$rs_dir/inside.md"
cp "$rs_dir/inside.md" "$rs_dir/outside.md"
printf '%s\n' 'Then type /sync.' >> "$rs_dir/outside.md"
rs_report "a retired name inside the migration section is read past" \
  "$([ -z "$(rs_retired_mentions '/sync([^a-z-]|$)' "$rs_dir/inside.md")" ] && echo yes || echo no)"
rs_report "and one outside it is still caught" \
  "$([ -n "$(rs_retired_mentions '/sync([^a-z-]|$)' "$rs_dir/outside.md")" ] && echo yes || echo no)"

rs_done
