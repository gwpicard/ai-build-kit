#!/usr/bin/env sh
# retired-names.sh: the four retired commands and the two renamed background
# skills stay retired.
#
# /fix, /queue, /sync and /ship were folded into other commands or renamed. A
# person sent to one of them types a command that does nothing. Every shipped
# files are read, and the maintain skill is included. The only text
# that may name them is the retirement notice supplied by upgrade-check.py,
# plus the old masterplan sentence that script recognises and rewrites. The released descriptions
# in kit-retired-skills.json and kit-released-copies.json are data the
# maintain skill matches old folders against, so they are not read.
#
# change-triage became triage and section-builder became build-piece. A skill
# told to load one of the old names finds nothing on a project updated past
# the rename, so no shipped file names them, in any case, except the maintain
# skill's scripts, which recognise the old folders to remove them.
# screen-check left for a time and came back under its own name.
#
# A scanned path that is missing fails rather than being skipped, and the
# check proves itself on copies: a planted "run /sync" in the maintain skill
# fails, as does a planted "Section-builder".

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cat > "$work/scan.py" <<'PY'
import os, re, runpy, sys

root = sys.argv[1]
skills = os.path.join(root, ".agents/skills")
fail = []

COMMANDS = ("README.md", "llms.txt", "docs/COMPATIBILITY.md",
            ".agents/hooks", ".agents/skills")
FOLDED_PATHS = ("README.md", "llms.txt", "docs/COMPATIBILITY.md",
                "docs/PHILOSOPHY.md", ".agents/hooks", ".agents/guard", ".claude-plugin",
                "agent-plugin", "release-manifest.txt", ".agents/skills")
DATA = {".agents/skills/maintain/scripts/kit-retired-skills.json",
        ".agents/skills/maintain/scripts/kit-released-copies.json"}
RETIRED = re.compile(r"/(fix|queue|sync|ship)([^a-z/-]|$)", re.M)
FOLDED = re.compile(r"(?i)change-triage|section-builder")

for name in ("fix", "queue", "sync", "ship", "change-triage", "section-builder"):
    for path in (".agents/skills/" + name, ".claude/skills/" + name, ".claude/commands/" + name + ".md"):
        if os.path.lexists(os.path.join(root, path)):
            fail.append("the retired %s skill is back: %s" % (name, path))

# The sentences allowed to name a retired command, read from the script that
# says them, so a reworded announcement is held to the script's words.
check = runpy.run_path(os.path.join(skills, "maintain/scripts/upgrade-check.py"))
announce = re.search(r"/fix and /queue[^.]*\.", check["SIX"]).group(0)
ALLOWED = [check["SIX"], announce, check["OLD_SENTENCE"]]


def files(paths):
    for rel in paths:
        full = os.path.join(root, rel)
        if not os.path.lexists(full):
            fail.append("a path this check reads is missing: %s" % rel)
            continue
        if os.path.isfile(full):
            yield rel
            continue
        for here, dirs, names in os.walk(full):
            dirs[:] = [d for d in dirs if d != "__pycache__"]
            for n in sorted(names):
                yield os.path.relpath(os.path.join(here, n), root)


def text(rel):
    with open(os.path.join(root, rel), encoding="utf-8", errors="replace") as handle:
        return handle.read()


def flat(body, rel):
    """The text with line breaks as spaces, and a Python string split over
    several literals joined, so a wrapped sentence reads as one."""
    if rel.endswith(".py"):
        body = re.sub(r'"\s*\n\s*"', "", body)
    return re.sub(r"\s+", " ", body)


for rel in files(COMMANDS):
    if rel in DATA:
        continue
    body = flat(text(rel), rel)
    for sentence in ALLOWED:
        body = body.replace(sentence, " ")
    for match in RETIRED.finditer(body):
        fail.append("%s still sends the person to a retired command: ...%s..." % (
            rel, body[max(0, match.start() - 40):match.end() + 20]))
        break

for rel in files(FOLDED_PATHS):
    if rel.startswith(".agents/skills/maintain/scripts/"):
        continue
    match = FOLDED.search(text(rel))
    if match:
        fail.append("%s still names a folded background skill: %s" % (rel, match.group(0)))

for line in fail:
    print("FAIL: " + line)
sys.exit(1 if fail else 0)
PY

python3 "$work/scan.py" "$ROOT" || exit 1

# The check must catch what it exists to catch. Each case runs on a copy.
copy() {
  rm -rf "$work/copy"; mkdir -p "$work/copy/docs" "$work/copy/.agents"
  for p in README.md llms.txt release-manifest.txt .claude-plugin agent-plugin; do
    cp -R "$ROOT/$p" "$work/copy/$p"
  done
  cp "$ROOT/docs/COMPATIBILITY.md" "$ROOT/docs/PHILOSOPHY.md" "$work/copy/docs/"
  for p in skills hooks guard; do cp -R "$ROOT/.agents/$p" "$work/copy/.agents/$p"; done
}
refused() {
  if python3 "$work/scan.py" "$work/copy" >/dev/null; then
    echo "FAIL: the check passed $1"; exit 1
  fi
  echo "  ok: $1 is caught"
}
copy; python3 "$work/scan.py" "$work/copy" >/dev/null || { echo "FAIL: a clean copy is refused"; exit 1; }
copy; printf '\nWhen the records drift, run /sync.\n' >> "$work/copy/.agents/skills/maintain/SKILL.md"
refused "a planted \"run /sync\" in the maintain skill"
copy; printf '\nSection-builder saves the change.\n' >> "$work/copy/.agents/skills/implement/SKILL.md"
refused "a capitalised folded skill name"

echo "retired-names.sh: all checks passed"
