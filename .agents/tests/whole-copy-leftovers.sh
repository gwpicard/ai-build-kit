#!/usr/bin/env sh
# whole-copy-leftovers.sh: run the shipped kit-leftovers.py and the release
# recorder in throwaway whole copies of the last nine-command release. If this
# breaks, a monthly visit can delete a command file, skill or notes the person
# wrote, follow a link out of the project, or leave every command offered twice.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
LEFTOVERS="$ROOT/.agents/skills/maintain/scripts/kit-leftovers.py"

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

echo "Whole-copy leftovers:"
[ -f "$LEFTOVERS" ] || { echo "FAIL: missing $LEFTOVERS" >&2; exit 1; }

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
  cp "$ROOT/.agents/tests/fixtures/upgrade-v0.19.3/retired-skills/$2.md.txt" "$1/SKILL.md"
}
P="$work/copy"
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
cp "$P/.claude/commands/deploy.md" "$work/deploy-before"
cp "$P/.agents/hooks/session-end-sync.sh" "$work/hook-before"

listed=$(python3 "$LEFTOVERS" "$P")
report "every generated command file is listed, for all three tools" \
  "$([ "$(printf '%s\n' "$listed" | grep -cE '^adapter	\.(claude|cursor|gemini)/commands/')" = 27 ] && echo yes || echo no)"
report "the four retired skill folders are listed" \
  "$([ "$(printf '%s\n' "$listed" | grep -cE '^folder	\.agents/skills/(fix|queue|sync|ship)$')" = 4 ] && echo yes || echo no)"
report "the person's own build skill is named as left, not recognised" \
  "$(printf '%s\n' "$listed" | grep -qx "left	.agents/skills/build	not recognised as the kit's" \
     && ! printf '%s\n' "$listed" | grep -q '^folder	.agents/skills/build' && echo yes || echo no)"
report "a generated skill folder for a dropped name is listed, one for a current name is not" \
  "$(printf '%s\n' "$listed" | grep -qx 'adapter	.claude/skills/grilling' \
     && ! printf '%s\n' "$listed" | grep -qE 'adapter	\.claude/skills/(clarify|change-triage)$' && echo yes || echo no)"
report "a generated skill folder holding a file of the person's is left" \
  "$(printf '%s\n' "$listed" | grep -qx 'left	.claude/skills/plan	it holds files besides the generated one' && echo yes || echo no)"
report "the person's own command file and skill are never listed" \
  "$(printf '%s\n' "$listed" | grep -qE 'deploy\.md|my-notes' && echo no || echo yes)"
report "the old hook is named" \
  "$(printf '%s\n' "$listed" | grep -q '^left	.agents/hooks/session-end-sync.sh	' && echo yes || echo no)"

python3 "$LEFTOVERS" --remove "$P"
r=yes
for n in queue fix ship sync; do [ ! -e "$P/.agents/skills/$n" ] || r=no; done
for n in $eleven; do [ -f "$P/.agents/skills/$n/SKILL.md" ] || r=no; done
report "the retired folders are gone and the eleven remain" "$r"
report "every generated command file is gone, and the emptied tool folders with them" \
  "$([ ! -e "$P/.cursor" ] && [ ! -e "$P/.gemini" ] && [ "$(ls "$P/.claude/commands")" = deploy.md ] && echo yes || echo no)"
report "the person's command file, skills and hook are untouched" \
  "$(cmp -s "$P/.claude/commands/deploy.md" "$work/deploy-before" && cmp -s "$P/.agents/hooks/session-end-sync.sh" "$work/hook-before" \
     && [ -f "$P/.agents/skills/my-notes/SKILL.md" ] && grep -q 'my own build notes' "$P/.agents/skills/build/SKILL.md" \
     && [ -f "$P/.claude/skills/plan/notes.md" ] && echo yes || echo no)"
report "the stale generated skill folder is gone, the current ones stay" \
  "$([ ! -e "$P/.claude/skills/grilling" ] && [ -f "$P/.claude/skills/clarify/SKILL.md" ] && echo yes || echo no)"
report "a second run lists only what is never removed, which the visit then keeps quiet about" \
  "$([ "$(python3 "$LEFTOVERS" "$P" | grep -cv '^left	')" = 0 ] \
     && python3 "$LEFTOVERS" "$P" | grep -q '^left	.agents/hooks/session-end-sync.sh	' && echo yes || echo no)"

# Links. A review linked the project's .claude/skills to a shared folder
# outside it, holding the person's own `sync` skill, and the removal followed
# the link and deleted it. Nothing outside the project is listed for removal,
# and a link is never followed: a link to the kit's folder inside the project
# goes on its own, and its target stays.
L="$work/links"
OUT="$work/links-outside"
mkdir -p "$L/.agents/skills" "$L/.agents/vendor" "$OUT"
kit_skill "$OUT/sync" sync
kit_skill "$OUT/plan" plan
mkdir -p "$L/.claude" "$L/.cursor"
ln -s "$OUT" "$L/.claude/skills"
ln -s "$OUT" "$L/.cursor/skills"
ln -s "$OUT/plan" "$L/.agents/skills/plan"
kit_skill "$L/.agents/vendor/start" start
ln -s "../vendor/start" "$L/.agents/skills/start"
cp -R "$OUT" "$work/outside-before"
links=$(python3 "$LEFTOVERS" "$L")
python3 "$LEFTOVERS" --remove "$L"
report "a skill in a linked folder outside the project is named as left, and never removed" \
  "$(printf '%s\n' "$links" | grep -qx 'left	.claude/skills/sync	it sits in a folder whose real place is outside the project' \
     && diff -r "$OUT" "$work/outside-before" >/dev/null && echo yes || echo no)"
report "a link to a skill outside the project is left, link and target both" \
  "$(printf '%s\n' "$links" | grep -qx 'left	.agents/skills/plan	it links to a folder outside the project' \
     && [ -L "$L/.agents/skills/plan" ] && echo yes || echo no)"
report "a link to the kit's folder inside the project goes on its own, and its target stays" \
  "$(printf '%s\n' "$links" | grep -qx 'folder	.agents/skills/start' && [ ! -e "$L/.agents/skills/start" ] && [ ! -L "$L/.agents/skills/start" ] \
     && [ -f "$L/.agents/vendor/start/SKILL.md" ] && echo yes || echo no)"

# One folder reached two ways inside the project is listed once.
D="$work/twice"
mkdir -p "$D/.agents/skills"
kit_skill "$D/.agents/skills/queue" queue
ln -s ".agents" "$D/.claude"
report "a folder reached through two paths is listed once" \
  "$([ "$(python3 "$LEFTOVERS" "$D" | grep -c '^folder')" = 1 ] && echo yes || echo no)"

# Off the shared route, a generated file for a current command may be how the
# person reaches it, so only a retired command's file is listed.
Q="$work/manual"
mkdir -p "$Q/.claude/commands"
for name in shape sync; do
  printf -- '---\n---\n<!-- GENERATED from .agents/skills/%s/. Do not edit here; regenerate with .agents/tools/build-adapters.sh -->\n' "$name" > "$Q/.claude/commands/$name.md"
done
report "without a lockfile, only the retired command's file is listed" \
  "$([ "$(python3 "$LEFTOVERS" "$Q")" = "adapter	.claude/commands/sync.md" ] && echo yes || echo no)"

# A recognised description must never authorise deleting personal additions.
C="$work/changed-retired"
kit_skill "$C/.agents/skills/fix" fix
printf '%s\n' 'My club notes.' > "$C/.agents/skills/fix/club-notes.md"
before=$(cksum < "$C/.agents/skills/fix/club-notes.md")
listed=$(python3 "$LEFTOVERS" "$C")
python3 "$LEFTOVERS" --remove "$C"
report "a personal addition keeps the whole retired folder" \
  "$(printf '%s\n' "$listed" | grep -q '^left	.agents/skills/fix	' \
     && [ -f "$C/.agents/skills/fix/SKILL.md" ] \
     && [ "$(cksum < "$C/.agents/skills/fix/club-notes.md")" = "$before" ] && echo yes || echo no)"
B="$work/changed-body"
kit_skill "$B/.agents/skills/fix" fix
printf '%s\n' 'My personal instructions.' >> "$B/.agents/skills/fix/SKILL.md"
before=$(cksum < "$B/.agents/skills/fix/SKILL.md")
python3 "$LEFTOVERS" --remove "$B"
report "a changed body with the old description stays intact" \
  "$([ -f "$B/.agents/skills/fix/SKILL.md" ] \
     && [ "$(cksum < "$B/.agents/skills/fix/SKILL.md")" = "$before" ] && echo yes || echo no)"

# Recheck the bytes after listing, and rehearse the post-release recorder.
python3 - "$ROOT" "$work" <<'PY'
import hashlib, importlib.util, json, pathlib, shutil, subprocess, sys
root, work = map(pathlib.Path,sys.argv[1:])
script=root/'.agents/skills/maintain/scripts/kit-leftovers.py'
spec=importlib.util.spec_from_file_location('leftovers',script); module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
p=work/'changed-after-list'; target=p/'.agents/skills/fix'; target.mkdir(parents=True)
shutil.copy2(root/'.agents/tests/fixtures/upgrade-v0.19.3/retired-skills/fix.md.txt',target/'SKILL.md')
found=module.skill_findings(str(p)); assert ('folder','.agents/skills/fix') in found
(target/'notes.md').write_text('Personal work added after the list.\n')
module.remove(str(p),found)
assert (target/'notes.md').read_text()=='Personal work added after the list.\n'
print('  ok: a file added after listing keeps the retired folder')
# The recorder must also keep canonical skill bytes for a later retirement.
tool_root=work/'recorder'; tool=tool_root/'.agents/tools/record-released-copies.py';tool.parent.mkdir(parents=True)
shutil.copy2(root/'.agents/tools/record-released-copies.py',tool)
record=tool_root/'.agents/skills/maintain/scripts/kit-released-copies.json';record.parent.mkdir(parents=True)
release=work/'released-copy'; (release/'.agents/skills/fix').mkdir(parents=True)
data=(target/'SKILL.md').read_bytes();(release/'.agents/skills/fix/SKILL.md').write_bytes(data)
(release/'.ai-build-kit-version').write_text('v0.19.3\n')
subprocess.run([sys.executable,str(tool),str(release)],check=True,capture_output=True)
known=json.loads(record.read_text()); assert known['files']['.agents/skills/fix/SKILL.md']==[hashlib.sha256(data).hexdigest()[:16]]
first=record.read_bytes();subprocess.run([sys.executable,str(tool),str(release)],check=True,capture_output=True);assert record.read_bytes()==first
print('  ok: the recorder keeps skill hashes and a second run changes nothing')
PY

echo
echo "whole-copy-leftovers.sh: all checks passed"
