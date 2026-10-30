#!/usr/bin/env python3
"""Check the shape of the kit's skills: thin commands, background skills that
earn their place, and files short enough to be followed.

Usage:

    check-structure.py [--strict] [ROOT]

ROOT defaults to the repository this script sits in. It reads the inventory in
.agents/tools/kit-inventory.txt, every skill under .agents/skills/ and every
agent under .agents/agents/, and prints one line for each thing out of shape:

    loads     FILE:LINE  a skill loads a command's reference or section
    missing   FILE:LINE  a skill names a file that no skill has
    callers   NAME       a background skill with fewer than two callers and no
                         agent that loads it
    words     FILE       a file over its word budget
    command   FILE:LINE  a skill entry point names a retired or unknown kit command

Rules:

1. A skill never loads a command's own files. A command's `references/` and its
   named sections are its own; another skill that needs the same rule calls a
   background skill instead. Scripts and templates may still be run or copied
   by path from anywhere, since a script costs the agent no attention.
2. A background skill is called by at least two other skills, or an agent's
   `skills:` line names it. A call is written as the skill's name in backticks
   followed by "skill", as in "the `records` skill".
3. A command's SKILL.md holds at most 400 words, a background skill's at most
   800, and any file under a `references/` folder at most 600. Frontmatter
   is not counted.
4. SKILL.md entry points cannot name a retired kit command or an unknown
   /ai-build-kit:<name> command. Other slash tokens are outside this check.

Without --strict it prints what it finds and exits 0, so a slice can land the
check before the tree meets it. With --strict it exits 1 when anything prints.
It exits 2 when the inventory or the skills folder cannot be read.
"""

import json
import os
import re
import sys

BUDGET = {"command": 400, "background": 800, "reference": 600}
# A command's references or a named section of it, reached from another skill.
# The name may sit in backticks or not, and the line may break after "skill's".
LOAD = re.compile(
    r"`?([a-z][a-z-]*)`?\s+skill['’]s\s+"
    r"(`references/[^`]+`|\"[^\"]+\"|“[^”]+”)"
)
# A path into another skill's folder, bare or with a leading ../, skills/ or
# .agents/skills/: its references, or its SKILL.md itself.
SIBLING = re.compile(
    r"(?<![A-Za-z0-9_-])(?:\.\./|\.agents/skills/|skills/)?"
    r"([a-z][a-z-]*)/(?:references/[A-Za-z0-9_./-]+\.md|SKILL\.md)")
# A file named on its own, such as `fit-check.md`. It must be a file some
# skill has, or one the project keeps, or it points at nothing.
BARE = re.compile(r"(?<![A-Za-z0-9_./<-])([A-Za-z0-9_-]+\.md)\b")
PROJECT_FILES = {"plan.md", "DESIGN.md", "WORKFLOW.md", "CLAUDE.md", "GEMINI.md",
                 "MAINTAINING.md", "setup-notes.md", "team.md"}
CALL = re.compile(r"`([a-z][a-z-]*)`\s+skill\b")
# Only retired names and explicit kit commands belong to this check.
SLASH_COMMAND = re.compile(
    r"(?<![A-Za-z0-9_./<:-])/(?P<name>(?:ai-build-kit:)?[a-z][a-z0-9-]*)"
    r"(?=`|[\s\"')\]}*]|[.,;:!?](?:\s|$)|$)")


def slash_commands(line, retired, commands):
    for match in SLASH_COMMAND.finditer(line):
        name = match["name"]
        if name.startswith("ai-build-kit:"):
            if name.split(":", 1)[1] not in commands:
                yield match
        elif name in retired:
            yield match


def read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def body(text):
    """The text after a leading frontmatter block."""
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            return text[end + 4:]
    return text


def frontmatter(text):
    fields = {}
    if not text.startswith("---"):
        return fields
    end = text.find("\n---", 3)
    if end == -1:
        return fields
    key = None
    for line in text[3:end].splitlines():
        match = re.match(r"^([A-Za-z-]+):\s*(.*)$", line)
        if match:
            key = match.group(1)
            fields[key] = match.group(2).strip()
        elif key and line.strip().startswith("- "):
            fields[key] = (fields[key] + " " + line.strip()[2:]).strip()
    return fields


def listed(value):
    """A frontmatter list written as [a, b] or as '- a' lines."""
    return [item.strip().strip("'\"") for item in re.split(r"[\s,\[\]]+", value) if item.strip()]


def inventory(root):
    entries = {}
    path = os.path.join(root, ".agents", "tools", "kit-inventory.txt")
    for line in read(path).splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        kind, name = line.split()
        entries[name] = kind
    return entries


def skill_files(skill_dir):
    """Every Markdown file a skill loads: all but its templates, which are
    copied into a project rather than read as instructions."""
    for here, dirs, names in os.walk(skill_dir):
        dirs[:] = sorted(d for d in dirs if d != "templates")
        for name in sorted(names):
            if name.endswith(".md"):
                yield os.path.join(here, name)


def words(text):
    return len(text.split())


def main(argv):
    strict = "--strict" in argv
    args = [a for a in argv if a != "--strict"]
    root = os.path.abspath(args[0]) if args else \
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    skills_root = os.path.join(root, ".agents", "skills")
    agents_root = os.path.join(root, ".agents", "agents")
    try:
        kinds = inventory(root)
        retired = set(json.loads(read(os.path.join(
            skills_root, "maintain", "scripts", "kit-retired-skills.json")))["skills"])
    except (OSError, ValueError, KeyError) as error:
        print("could not read the inventory or retired skills: %s" % error, file=sys.stderr)
        return 2
    if not os.path.isdir(skills_root):
        print("could not read %s" % skills_root, file=sys.stderr)
        return 2

    commands = {n for n, k in kinds.items() if k == "command"}
    backgrounds = {n for n, k in kinds.items() if k == "background"}
    agents = {n for n, k in kinds.items() if k == "agent"}
    findings = []
    callers = {name: set() for name in backgrounds}
    known_files = set(PROJECT_FILES)
    for here, dirs, names in os.walk(skills_root):
        known_files.update(n for n in names if n.endswith(".md"))

    for skill in sorted(commands | backgrounds):
        skill_dir = os.path.join(skills_root, skill)
        if not os.path.isdir(skill_dir):
            continue
        for path in skill_files(skill_dir):
            rel = os.path.relpath(path, root)
            text = read(path)
            flat = re.sub(r"\s+", " ", text)
            for match in CALL.finditer(flat):
                name = match.group(1)
                if name in callers and name != skill:
                    callers[name].add(skill)
            for lineno, line in enumerate(text.splitlines(), 1):
                if path == os.path.join(skill_dir, "SKILL.md"):
                    for match in slash_commands(line, retired, commands):
                        findings.append(("command", "%s:%d" % (rel, lineno),
                                         "/%s is retired or not a command in the inventory" % match["name"]))
                window = line + " " + (text.splitlines()[lineno] if lineno < len(text.splitlines()) else "")
                for match in LOAD.finditer(window):
                    if match.start() >= len(line):
                        continue
                    owner = match.group(1)
                    if owner in commands and owner != skill:
                        findings.append(("loads", "%s:%d" % (rel, lineno),
                                         "loads the %s command's %s" % (owner, re.sub(r"\s+", " ", match.group(2)))))
                for match in SIBLING.finditer(line):
                    owner = match.group(1)
                    if owner in commands and owner != skill:
                        findings.append(("loads", "%s:%d" % (rel, lineno),
                                         "loads the %s command's %s" % (owner, match.group(0))))
                for match in BARE.finditer(line):
                    if match.group(1) not in known_files:
                        findings.append(("missing", "%s:%d" % (rel, lineno),
                                         "names %s, which no skill has" % match.group(1)))
            if os.path.basename(path) == "SKILL.md" and os.path.dirname(path) == skill_dir:
                kind = kinds[skill]
                count = words(body(text))
                if count > BUDGET[kind]:
                    findings.append(("words", rel, "%d words, over the %s budget of %d"
                                     % (count, kind, BUDGET[kind])))
            elif "/references/" in path.replace(os.sep, "/"):
                count = words(body(text))
                if count > BUDGET["reference"]:
                    findings.append(("words", rel, "%d words, over the reference budget of %d"
                                     % (count, BUDGET["reference"])))

    loaded_by_agent = set()
    for agent in sorted(agents):
        path = os.path.join(agents_root, agent + ".md")
        if not os.path.isfile(path):
            continue
        loaded_by_agent.update(listed(frontmatter(read(path)).get("skills", "")))

    for name in sorted(backgrounds):
        if len(callers[name]) < 2 and name not in loaded_by_agent:
            who = ", ".join(sorted(callers[name])) or "nobody"
            findings.append(("callers", name, "called by %s, and loaded by no agent" % who))

    for kind, where, why in findings:
        print("%s\t%s\t%s" % (kind, where, why))
    if findings and strict:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
