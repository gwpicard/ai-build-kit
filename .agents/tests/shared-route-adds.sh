#!/usr/bin/env sh
# shared-route-adds.sh: run the shipped kit-leftovers.py in a throwaway shared
# install of the last nine-command release, and of the last eleven-skill
# release, after the update. If this breaks,
# the old commands stay on offer beside the new ones, the AGENTS.md command
# list stays stale, or the script names, removes or rewrites the person's own
# skills and sentences.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
LEFTOVERS="$ROOT/.agents/skills/maintain/scripts/kit-leftovers.py"
TEMPLATE="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
passed=0
report() {
  if [ "$2" = yes ]; then
    echo "  ok: $1"; passed=$((passed + 1))
  else
    echo "FAIL: $1" >&2; exit 1
  fi
}

echo "Shared-route leftovers:"
for f in "$LEFTOVERS" "$TEMPLATE"; do
  [ -f "$f" ] || { echo "FAIL: missing $f" >&2; exit 1; }
done

# --- the script, run ----------------------------------------------------------

# A shared install of the last nine-command release, for Claude Code and
# Codex, after the update: the add command brought setup-hosting and kept the
# four old skills listed, as the real installer did in a rehearsal. The update
# from the last eleven-skill release keeps the two renamed background skills
# listed the same way, so they are here too; screen-check came back, so it is
# one of today's. The person
# has a skill and a command file of their own, and records that mention the
# old commands.
P="$work/shared"
mkdir -p "$P/.agents/skills" "$P/.claude/skills" "$P/.claude/commands"
kit=$(awk '$1 == "command" || $1 == "background" { print $2 }' "$ROOT/.agents/tools/kit-inventory.txt" | tr '\n' ' ')
old="fix queue sync ship change-triage section-builder"
# The counts and the background line the founding template carries today.
count_skills=$(sed -n 's/^The work lives in \([a-z-]*\) installed AI Build Kit skills.*/\1/p' "$TEMPLATE")
count_background=$(sed -n 's/^\([a-z-]*\) run in the background when a command needs them\./\1/p' "$TEMPLATE")
background_line=$(awk '/^- Background skills:/ { on = 1 } on { printf "%s%s", sep, $0; sep = " "; if ($0 ~ /\.$/) exit }' "$TEMPLATE" | tr -s ' ')
{
  printf '{\n  "version": 1,\n  "skills": {\n'
  for name in $kit $old; do
    printf '    "%s": { "source": "gwpicard/ai-build-kit", "sourceType": "github", "computedHash": "0" },\n' "$name"
  done
  printf '    "my-notes": { "source": "someone/notes", "sourceType": "github", "computedHash": "0" }\n  }\n}\n'
} > "$P/skills-lock.json"
for name in $kit $old my-notes build; do
  mkdir -p "$P/.agents/skills/$name"
  printf -- '---\nname: %s\n---\n' "$name" > "$P/.agents/skills/$name/SKILL.md"
  ln -s "../../.agents/skills/$name" "$P/.claude/skills/$name"
done
printf -- '---\nname: build\ndescription: my own build notes\n---\n' > "$P/.agents/skills/build/SKILL.md"
cp -R "$P/.agents/skills/build" "$work/own-build"
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
  cp "$P/$f" "$work/before-$(basename "$f")"
done
cp "$P/AGENTS.md" "$work/before-agents"

listed=$(python3 "$LEFTOVERS" "$P")
report "each old skill the lockfile lists is named for the installer to remove" \
  "$([ "$(printf '%s\n' "$listed" | grep -c '^installer	')" = 6 ] \
     && printf '%s\n' "$listed" | grep -qF 'installer	ship	npx skills remove ship' \
     && printf '%s\n' "$listed" | grep -qF 'installer	section-builder	npx skills remove section-builder' && echo yes || echo no)"
report "the person's own skill, listed from elsewhere, is never named" \
  "$(printf '%s\n' "$listed" | grep -q 'my-notes' && echo no || echo yes)"
report "the command list is offered as the six" \
  "$(printf '%s\n' "$listed" | grep -qF -- '- Commands: `setup-ai-build-kit`, `shape`, `implement`, `setup-hosting`, `maintain`, `what-now`.' && echo yes || echo no)"
report "and the counts as the template's" \
  "$(printf '%s\n' "$listed" | grep -qF "	fourteen	$count_skills" && printf '%s\n' "$listed" | grep -qF '	Nine	Six' \
     && printf '%s\n' "$listed" | grep -qF "	five	$count_background" && echo yes || echo no)"
report "the background line is offered as the template's" \
  "$(printf '%s\n' "$listed" | tr -s ' ' | grep -qF -- "$background_line" && echo yes || echo no)"

python3 "$LEFTOVERS" --remove "$P"
report "the script never removes a folder the lockfile lists" \
  "$(for n in $old; do [ -d "$P/.agents/skills/$n" ] || echo gone; done | grep -q gone && echo no || echo yes)"
report "the person's own build skill, listed nowhere, is named as left and kept" \
  "$(printf '%s\n' "$listed" | grep -qF 'left	.agents/skills/build	not recognised as the kit' \
     && diff -r "$P/.agents/skills/build" "$work/own-build" >/dev/null && [ -L "$P/.claude/skills/build" ] && echo yes || echo no)"

python3 "$LEFTOVERS" --rewrite-commands "$P"
diff "$work/before-agents" "$P/AGENTS.md" > "$work/agents.diff" || true
report "the rewrite gives the template's command line" \
  "$(grep -qF -- '- Commands: `setup-ai-build-kit`, `shape`, `implement`, `setup-hosting`,' "$P/AGENTS.md" \
     && grep -qF '  `maintain`, `what-now`.' "$P/AGENTS.md" && echo yes || echo no)"
report "and the template's counts" \
  "$(grep -qF "The work lives in $count_skills installed AI Build Kit skills. Six are commands:" "$P/AGENTS.md" \
     && grep -qF "$count_background run in the background when a command needs them." "$P/AGENTS.md" \
     && tr '\n' ' ' < "$P/AGENTS.md" | tr -s ' ' | grep -qF -- "$background_line" && echo yes || echo no)"
report "and changes nothing else in the file, the person's own line included" \
  "$([ "$(grep -c '^<' "$work/agents.diff")" = 6 ] \
     && grep -qF 'Our team types /ship on Fridays, and nine is our lucky number.' "$P/AGENTS.md" && echo yes || echo no)"

# The installer's remove, as the rehearsal saw it: the folders, their links
# and their lockfile entries go. Then the person installs a `ship` skill of
# their own from another source, and takes their `build` skill out.
for n in $old build; do
  rm -R "$P/.agents/skills/$n"
  rm "$P/.claude/skills/$n"
done
mkdir -p "$P/.agents/skills/ship"
printf -- '---\nname: ship\ndescription: my own release notes\n---\n' > "$P/.agents/skills/ship/SKILL.md"
cp -R "$P/.agents/skills/ship" "$work/own-ship"
python3 - "$P/skills-lock.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path))
for name in ("fix", "queue", "sync", "change-triage", "section-builder"):
    data["skills"].pop(name)
data["skills"]["ship"] = {"source": "someone/my-skills", "sourceType": "github"}
json.dump(data, open(path, "w"), indent=2)
PY
report "once the installer has removed them, a second run finds nothing, the person's ship skill included" \
  "$([ -z "$(python3 "$LEFTOVERS" "$P")" ] && echo yes || echo no)"
cp "$P/AGENTS.md" "$work/after-agents"
python3 "$LEFTOVERS" --rewrite-commands "$P"
python3 "$LEFTOVERS" --remove "$P"
report "and a second rewrite and removal change nothing, the person's ship skill included" \
  "$(cmp -s "$P/AGENTS.md" "$work/after-agents" && diff -r "$P/.agents/skills/ship" "$work/own-ship" >/dev/null && echo yes || echo no)"
report "the six commands and every background skill are all still installed" \
  "$(for n in $kit; do [ -f "$P/.agents/skills/$n/SKILL.md" ] && [ -e "$P/.claude/skills/$n" ] || echo gone; done | grep -q gone && echo no || echo yes)"
report "the person's records, their skill and their command file are untouched" \
  "$(cmp -s "$P/masterplan.md" "$work/before-masterplan.md" && cmp -s "$P/CHANGELOG.md" "$work/before-CHANGELOG.md" \
     && cmp -s "$P/.claude/commands/deploy.md" "$work/before-deploy.md" && [ -f "$P/.agents/skills/my-notes/SKILL.md" ] && echo yes || echo no)"

# An update that removed an old skill without adding its new one.
mkdir -p "$work/short/.agents/skills"
printf '{"version": 1, "skills": {"maintain": {"source": "gwpicard/ai-build-kit"}}}\n' > "$work/short/skills-lock.json"
mkdir -p "$work/short/.agents/skills/maintain"
printf -- '---\nname: maintain\n---\n' > "$work/short/.agents/skills/maintain/SKILL.md"
report "a missing new skill is named" \
  "$(python3 "$LEFTOVERS" "$work/short" | grep -qx 'missing	setup-hosting' && echo yes || echo no)"

# The lockfile's source names the kit only when it is the kit's repository.
mkdir -p "$work/src/.agents/skills/fix"
printf -- '---\nname: fix\ndescription: mine\n---\n' > "$work/src/.agents/skills/fix/SKILL.md"
printf '{"version": 1, "skills": {"fix": {"source": "gwpicard/ai-build-kit-extras"}}}\n' > "$work/src/skills-lock.json"
report "a source that only starts like the kit's is not the kit" \
  "$(python3 "$LEFTOVERS" "$work/src" | grep -q '^installer' && echo no || echo yes)"
printf '{"version": 1, "skills": {"fix": {"source": "https://github.com/GWPicard/ai-build-kit.git"}}}\n' > "$work/src/skills-lock.json"
report "the kit's address in another form is still the kit" \
  "$(python3 "$LEFTOVERS" "$work/src" | grep -qx 'installer	fix	npx skills remove fix' && echo yes || echo no)"

# A list in the person's own words, or one naming a command of their own, is
# named and left alone.
mkdir -p "$work/own"
printf '%s\n' '## The skills' '' '- Commands: `shape`, `ship`, `deploy-now`.' > "$work/own/AGENTS.md"
cp "$work/own/AGENTS.md" "$work/own-before"
own=$(python3 "$LEFTOVERS" "$work/own")
python3 "$LEFTOVERS" --rewrite-commands "$work/own"
report "a list naming a command of the person's own is listed with its reason and left" \
  "$(printf '%s\n' "$own" | grep -q 'left as written: it names `deploy-now`' && cmp -s "$work/own/AGENTS.md" "$work/own-before" && echo yes || echo no)"
printf '%s\n' 'We use /shape, /implement and /sync every week.' > "$work/own/AGENTS.md"
report "ordinary prose about using commands is not a command list" \
  "$([ -z "$(python3 "$LEFTOVERS" "$work/own")" ] && echo yes || echo no)"

# Words of the person's own inside the bullet: the line is left, with the
# suggested one, and so are the counts above it.
nine_list() {
  printf '%s\n' '## The skills' '' \
    'The work lives in fourteen installed AI Build Kit skills. Nine are commands:' \
    'the other five run in the background.' '' \
    '- Commands: `setup-ai-build-kit`, `shape`, `implement`, `queue`, `fix`, `ship`,' \
    '  `sync`, `maintain`, `what-now`.'
}
mkdir -p "$work/extra"
{ nine_list; printf '%s\n' '  We run `implement` only after the Monday stand-up.'; } > "$work/extra/AGENTS.md"
cp "$work/extra/AGENTS.md" "$work/extra-before"
extra=$(python3 "$LEFTOVERS" "$work/extra")
python3 "$LEFTOVERS" --rewrite-commands "$work/extra"
report "a bullet holding the person's own sentence is left as written, with the suggested line" \
  "$(printf '%s\n' "$extra" | grep -q 'left as written: it holds words of its own besides the kit.s names; suggested: - Commands: `setup-ai-build-kit`, `shape`, `implement`, `setup-hosting`, `maintain`, `what-now`.' \
     && cmp -s "$work/extra/AGENTS.md" "$work/extra-before" && echo yes || echo no)"
report "and the counts above a list left as written are not offered" \
  "$(printf '%s\n' "$extra" | grep -qE '	(fourteen|Nine)	' && echo no || echo yes)"

# Windows line endings, and a file with one such line and no final newline,
# come back with only the listed lines changed.
mkdir -p "$work/crlf" "$work/mixed"
nine_list | sed 's/$/\r/' > "$work/crlf/AGENTS.md"
python3 "$LEFTOVERS" --rewrite-commands "$work/crlf"
report "a file with Windows line endings keeps them on every line" \
  "$([ "$(grep -c "$(printf '\r')\$" "$work/crlf/AGENTS.md")" = "$(wc -l < "$work/crlf/AGENTS.md" | tr -d ' ')" ] \
     && grep -q 'setup-hosting' "$work/crlf/AGENTS.md" && echo yes || echo no)"
nine_list | sed '1s/$/\r/' | python3 -c 'import sys; sys.stdout.write(sys.stdin.read().rstrip("\n"))' > "$work/mixed/AGENTS.md"
python3 "$LEFTOVERS" --rewrite-commands "$work/mixed"
report "a file with one Windows ending and no final newline keeps both" \
  "$(head -1 "$work/mixed/AGENTS.md" | grep -q "$(printf '\r')\$" && [ -n "$(tail -c 1 "$work/mixed/AGENTS.md")" ] \
     && tail -1 "$work/mixed/AGENTS.md" | grep -qF '  `maintain`, `what-now`.' && echo yes || echo no)"
report "and a second run on either finds nothing" \
  "$([ -z "$(python3 "$LEFTOVERS" "$work/crlf")$(python3 "$LEFTOVERS" "$work/mixed")" ] && echo yes || echo no)"

# A project founded from today's templates gets nothing.
mkdir -p "$work/today"
cp "$TEMPLATE" "$work/today/AGENTS.md"
report "a project founded today gets nothing" \
  "$([ -z "$(python3 "$LEFTOVERS" "$work/today")" ] && echo yes || echo no)"

# The script's list of the kit's skills has to be the kit's skills.
names=$(PYTHONDONTWRITEBYTECODE=1 python3 - "$LEFTOVERS" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("k", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
print("\n".join(sorted(module.KIT_SKILLS)))
PY
)
report "the script names exactly the kit's skills" \
  "$([ "$names" = "$(ls "$ROOT/.agents/skills" | sort)" ] && echo yes || echo no)"

echo
echo "shared-route-adds.sh: all $passed checks passed"
