#!/usr/bin/env sh
# whole-copy-leftovers.sh: run the shipped kit-leftovers.py and the release
# recorder in throwaway whole copies of the last nine-command release and the
# last eleven-skill release. If this
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
# just registered today's skills with the installer. The person added a skill and a
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
eight=$(awk '$1 == "command" || $1 == "background" { print $2 }' "$ROOT/.agents/tools/kit-inventory.txt" | tr '\n' ' ')
mkdir -p "$P/.agents/skills" "$P/.agents/hooks" "$P/.claude/commands" "$P/.cursor/commands" "$P/.gemini/commands"
for name in $eight my-notes; do
  mkdir -p "$P/.agents/skills/$name"
  printf -- '---\nname: %s\n---\n' "$name" > "$P/.agents/skills/$name/SKILL.md"
done
for name in queue fix ship sync; do kit_skill "$P/.agents/skills/$name" "$name"; done
# The person's own skill under a former name, in no lockfile.
mkdir -p "$P/.agents/skills/build"
printf -- '---\nname: build\ndescription: my own build notes\n---\n' > "$P/.agents/skills/build/SKILL.md"
# The kit's generated background skill folders: two under current names, one
# under the name `clarify` once had, and one the person added a file to.
for name in clarify second-opinion grilling plan; do
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
  for name in $eight; do
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
     && ! printf '%s\n' "$listed" | grep -qE 'adapter	\.claude/skills/(clarify|second-opinion)$' && echo yes || echo no)"
report "a generated skill folder holding a file of the person's is left" \
  "$(printf '%s\n' "$listed" | grep -qx 'left	.claude/skills/plan	it holds files besides the generated one' && echo yes || echo no)"
report "the person's own command file and skill are never listed" \
  "$(printf '%s\n' "$listed" | grep -qE 'deploy\.md|my-notes' && echo no || echo yes)"
report "the old hook is named" \
  "$(printf '%s\n' "$listed" | grep -q '^left	.agents/hooks/session-end-sync.sh	' && echo yes || echo no)"

python3 "$LEFTOVERS" --remove "$P"
r=yes
for n in queue fix ship sync; do [ ! -e "$P/.agents/skills/$n" ] || r=no; done
for n in $eight; do [ -f "$P/.agents/skills/$n/SKILL.md" ] || r=no; done
report "the retired folders are gone and today's skills remain" "$r"
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

# A whole copy of the last eleven-skill release. Two of its background skills
# were renamed since, and the update left their folders, with the bytes that
# release shipped, and their generated Claude Code folders. Its third,
# screen-check, came back under its own name, so its folders are today's and
# stay. The person added a note to one copy of section-builder in a second
# project.
E="$work/eleven"
F="$ROOT/.agents/tests/fixtures/upgrade-v0.20.3/retired-skills"
folded="change-triage section-builder"
mkdir -p "$E/.agents/skills"
for name in $eight; do
  mkdir -p "$E/.agents/skills/$name"
  printf -- '---\nname: %s\n---\n' "$name" > "$E/.agents/skills/$name/SKILL.md"
done
(cd "$F" && find . -type f -name '*.txt') | while IFS= read -r file; do
  target="$E/.agents/skills/${file#./}"
  target="${target%.txt}"
  mkdir -p "$(dirname "$target")"
  cp "$F/$file" "$target"
done
for name in $folded; do
  mkdir -p "$E/.claude/skills/$name"
  printf -- '---\nname: %s\nuser-invocable: false\n---\n<!-- GENERATED from .agents/skills/%s/. Do not edit here; regenerate with .agents/tools/build-adapters.sh -->\n' "$name" "$name" > "$E/.claude/skills/$name/SKILL.md"
done
cp -R "$E" "$work/eleven-changed"
printf '%s\n' 'My build notes.' > "$work/eleven-changed/.agents/skills/section-builder/notes.md"
listed=$(python3 "$LEFTOVERS" "$E")
report "the two renamed background skill folders are listed, with their generated copies" \
  "$([ "$(printf '%s\n' "$listed" | grep -cE '^folder	\.agents/skills/(change-triage|section-builder)$')" = 2 ] \
     && [ "$(printf '%s\n' "$listed" | grep -cE '^adapter	\.claude/skills/(change-triage|section-builder)$')" = 2 ] && echo yes || echo no)"
report "the restored screen-check folder is never listed" \
  "$(printf '%s\n' "$listed" | grep -q 'screen-check' && echo no || echo yes)"
report "nothing is removed before the yes" \
  "$(for n in $folded; do [ -d "$E/.agents/skills/$n" ] && [ -d "$E/.claude/skills/$n" ] || echo gone; done | grep -q gone && echo no || echo yes)"
python3 "$LEFTOVERS" --remove "$E"
r=yes
for n in $folded; do [ ! -e "$E/.agents/skills/$n" ] && [ ! -e "$E/.claude/skills/$n" ] || r=no; done
[ -f "$E/.agents/skills/screen-check/SKILL.md" ] || r=no
for n in $eight; do [ -f "$E/.agents/skills/$n/SKILL.md" ] || r=no; done
report "on the yes the two folders go, and screen-check and today's skills remain" "$r"
report "a second run finds nothing" \
  "$([ -z "$(python3 "$LEFTOVERS" "$E")" ] && echo yes || echo no)"
changed=$(python3 "$LEFTOVERS" "$work/eleven-changed")
python3 "$LEFTOVERS" --remove "$work/eleven-changed"
report "a folded folder holding a note of the person's is left whole" \
  "$(printf '%s\n' "$changed" | grep -q '^left	.agents/skills/section-builder	' \
     && [ -f "$work/eleven-changed/.agents/skills/section-builder/notes.md" ] \
     && [ -f "$work/eleven-changed/.agents/skills/section-builder/SKILL.md" ] \
     && [ ! -e "$work/eleven-changed/.agents/skills/change-triage" ] && echo yes || echo no)"

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

# Released documents use the same removal decision and once-only notice as
# other leftovers. Isolate these findings from unrelated upgrade steps.
python3 - "$ROOT" "$work" <<'PYDOC'
import contextlib, hashlib, importlib.util, io, json, pathlib, shutil, subprocess, sys
root, work = map(pathlib.Path, sys.argv[1:])
scripts = root/'.agents/skills/maintain/scripts'
def load(name):
    spec = importlib.util.spec_from_file_location(name, scripts/(name+'.py'))
    mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
    return mod
left = load('kit-leftovers'); upgrade = load('upgrade-check')
p = work/'documents'; (p/'docs').mkdir(parents=True)
original = (root/'.agents/tests/fixtures/upgrade-v1.1.2/SOURCES.md.txt').read_bytes()
(p/'docs/SOURCES.md').write_bytes(original)
notes = 'Our notes: `.agents/skills/implement/references/merge.md`.\n'
(p/'docs/notes.md').write_text(notes)
(p/'masterplan.md').write_text('Our project.\n')
# Exercise the real pointer scan and leftover classification, while leaving
# unrelated foundation migrations to upgrade-rehearsal.sh.
def document_findings(project):
    result = subprocess.run([sys.executable, str(scripts/'old-skill-pointers.py'), str(project)],
                            capture_output=True, text=True, check=True)
    pointers = [('pointer', *line.split('\t')) for line in result.stdout.splitlines()]
    return left.skill_findings(project) + pointers
upgrade.findings = document_findings
upgrade.planfile_findings = lambda project, monthly: []
def listing():
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        code = upgrade.listing(str(p), False)
    return code, out.getvalue()
code, out = listing()
assert code == 1 and 'kitcopy\tdocs/SOURCES.md' in out, out
assert 'say\tremove\t' in out and 'pointer\tdocs/SOURCES.md' not in out, out
assert 'pointer\tdocs/notes.md:' in out and 'document of your own' in out, out
assert (p/'docs/SOURCES.md').read_bytes() == original
upgrade.decline(str(p), ['remove'])
code, out = listing()
assert code == 0 and 'say\tremove\t' not in out, out
assert 'declined\tremove\tkitcopy\tdocs/SOURCES.md' in out, out
assert 'remove' in (p/'.ai-build-kit-maintenance').read_text()
print('  ok: the unchanged released document is offered, and a recorded no stops the offer')
# A yes uses the existing removal step and leaves no offer on the next visit.
upgrade.apply(str(p), 'remove')
code, out = listing()
assert code == 0 and 'docs/SOURCES.md' not in out, out
assert not (p/'docs/SOURCES.md').exists()
assert (p/'docs/notes.md').read_text() == notes
print('  ok: an approved removal leaves personal notes intact and is not offered again')
(p/'docs/SOURCES.md').write_bytes(original + b'\nOur added credit.\n')
changed = (p/'docs/SOURCES.md').read_bytes()
code, out = listing()
assert code == 0 and "it started as the kit's document and was changed, so it stays" in out, out
assert 'pointer\tdocs/SOURCES.md' not in out and 'say\tremove\t' not in out, out
left.remove(str(p), left.skill_findings(str(p)))
assert (p/'docs/SOURCES.md').read_bytes() == changed
(p/'.ai-build-kit-maintenance').write_text('upgrade-offered|'+upgrade.installed_version()+'\n')
code, out = listing()
assert code == 0 and 'say\tleft\t' not in out, out
assert 'pointer\tdocs/notes.md:' in out
print('  ok: an edited kit document stays with one explanation and no pointer lines')
# A file changed between the offer and removal must stay too.
(p/'docs/SOURCES.md').write_bytes(original)
found = left.skill_findings(str(p))
(p/'docs/SOURCES.md').write_bytes(changed)
left.remove(str(p), found)
assert (p/'docs/SOURCES.md').read_bytes() == changed
print('  ok: a document edited after listing is rechecked before removal')
# Generated command copies already use the adapter offer on the shared route.
(p/'.claude/commands').mkdir(parents=True)
(p/'.claude/commands/shape.md').write_text('<!-- GENERATED from .agents/skills/shape/. Do not edit here; regenerate with .agents/tools/build-adapters.sh -->\n'+notes)
(p/'skills-lock.json').write_text(json.dumps({'skills': {'shape': {'source': 'gwpicard/ai-build-kit'}}}))
found = document_findings(str(p))
assert ('adapter', '.claude/commands/shape.md') in found, found
assert not any(f[0]=='pointer' and f[1].startswith('.claude/commands/') for f in found), found
print('  ok: generated command copies keep their adapter offer without personal pointer reports')
# Both archive and folder sources must record all shipped regular files.
tool_root = work/'document-recorder'; tool = tool_root/'.agents/tools/record-released-copies.py'
tool.parent.mkdir(parents=True); shutil.copy2(root/'.agents/tools/record-released-copies.py', tool)
record = tool_root/'.agents/skills/maintain/scripts/kit-released-copies.json'; record.parent.mkdir(parents=True)
release = work/'v1.1.2'; (release/'docs').mkdir(parents=True)
(release/'docs/SOURCES.md').write_bytes(original)
(release/'.ai-build-kit-version').write_text('v1.1.2\n')
(release/'LICENSE').write_text('Release licence.\n')
import tarfile
archive = work/'ai-build-kit-v1.1.2.tar.gz'
with tarfile.open(archive, 'w:gz') as handle:
    for path in release.rglob('*'):
        if path.is_file(): handle.add(path, arcname='./'+path.relative_to(release).as_posix())
for source in (release, archive):
    if record.exists(): record.unlink()
    subprocess.run([sys.executable, str(tool), str(source)], check=True, capture_output=True)
    files = json.loads(record.read_text())['files']
    assert files['docs/SOURCES.md'] == [hashlib.sha256(original).hexdigest()[:16]]
    assert files['LICENSE'] == [hashlib.sha256(b'Release licence.\n').hexdigest()[:16]]
print('  ok: folder and archive recording include released documents and other shipped files')
PYDOC

echo
echo "whole-copy-leftovers.sh: all checks passed"
