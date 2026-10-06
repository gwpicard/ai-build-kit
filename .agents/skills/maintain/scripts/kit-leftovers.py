#!/usr/bin/env python3
"""Find, and on request tidy, what an update leaves behind after the kit renames
or folds a command.

An update refreshes the kit's skills and nothing else. When the kit renames a
command or folds one into another, the old skill can stay installed, a whole
copy of the kit keeps its old command files, and the project's AGENTS.md keeps
listing the old commands. This script finds each of those and prints one line
for it. It prints nothing when there is nothing to find, so a second visit
after the tidy says nothing.

Usage:

    kit-leftovers.py [PROJECT]                     list what it finds
    kit-leftovers.py --remove [PROJECT]            remove the folders and files
                                                   listed as `folder` or `adapter`
    kit-leftovers.py --rewrite-commands [PROJECT]  rewrite the lines listed as
                                                   `commands`

PROJECT defaults to the current folder. Each finding is one line of fields
separated by tabs. The first field says what it is:

    installer  NAME    a skill under a former name that skills-lock.json lists
                       as the kit's; the installer removes it with
                       `npx skills remove NAME`, never this script
    folder     PATH    a skill folder under a former name that the lockfile
                       does not list as the kit's
    adapter    PATH    a command file the kit generated, known by its marker
    missing    NAME    one of the kit's skills is not installed
    commands   FILE:LINE  OLD  NEW
                       a line of the command list or its counts in AGENTS.md
    commands   FILE:LINE  OLD  left as written: WHY
                       a list the script cannot rewrite safely
    hook       PATH    the kit's session-end hook still names a retired command

The script never runs the installer and never touches a file the lockfile
lists. It removes nothing and rewrites nothing unless asked, and then only what
it listed. A rewrite of AGENTS.md changes the listed lines and nothing else,
line endings included.
"""

import json
import os
import re
import shutil
import sys

# The kit's eleven skills today.
KIT_SKILLS = (
    "setup-ai-build-kit", "shape", "implement", "setup-hosting",
    "maintain", "what-now", "clarify", "change-triage", "screen-check",
    "section-builder", "second-opinion",
)

# Every name a kit skill had before. `build` split into `shape` and
# `implement`, `start` became `setup-ai-build-kit`, `plan` became `shape`,
# `ship` became `setup-hosting`, and `fix`, `queue` and `sync` folded into
# `shape`, `implement` and `maintain`.
FORMER_NAMES = ("build", "start", "plan", "fix", "queue", "sync", "ship")

KIT_SOURCE = "gwpicard/ai-build-kit"
SKILL_FOLDERS = (".agents/skills", ".claude/skills")
ADAPTER_FOLDERS = (".claude/commands", ".cursor/commands", ".gemini/commands")

# The installed skills sit beside this one, so the founding template the
# command list is rewritten to is the one this release ships.
INSTALLED = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TEMPLATE = os.path.join(INSTALLED, "setup-ai-build-kit", "templates", "foundation", "AGENTS.md")

NUMBERS = ("one two three four five six seven eight nine ten eleven twelve "
           "thirteen fourteen fifteen sixteen").split()
NUMBER = "(" + "|".join(NUMBERS) + ")"
# The counts in the sentences above the list, in every wording the template
# has used. Whitespace may be a line break, since the sentences wrap.
COUNTS = (
    ("skills", re.compile(r"(?i)\blives\s+in\s+" + NUMBER + r"\s+installed\b")),
    ("commands", re.compile(r"(?i)\b" + NUMBER + r"\s+are\s+commands\b")),
    ("background", re.compile(r"(?i)\b" + NUMBER + r"\s+run\s+in\s+the\s+background\b")),
)
BULLETS = ("- Commands:", "- Background skills:")
TICKED = re.compile(r"`([^`]+)`")


def kit_lockfile(project):
    """The names skills-lock.json lists as the kit's, or None without one."""
    try:
        with open(os.path.join(project, "skills-lock.json"), encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return None
    skills = data.get("skills") if isinstance(data, dict) else None
    if not isinstance(skills, dict):
        return None
    names = set()
    for name, entry in skills.items():
        source = entry.get("source", "") if isinstance(entry, dict) else ""
        if KIT_SOURCE in str(source).lower():
            names.add(name)
    return names


def installed(project, name):
    return any(os.path.isfile(os.path.join(project, folder, name, "SKILL.md"))
               for folder in SKILL_FOLDERS)


def generated(path):
    """True when the first lines carry the marker build-adapters.sh writes."""
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            head = "".join(handle.readline() for _ in range(6))
    except OSError:
        return False
    return "GENERATED from .agents/skills/" in head and "build-adapters.sh" in head


def skill_findings(project):
    lock = kit_lockfile(project)
    listed = lock or set()
    shared = bool(lock)
    found = []
    for name in FORMER_NAMES:
        if name in listed:
            found.append(("installer", name))
            continue
        for folder in SKILL_FOLDERS:
            path = os.path.join(folder, name)
            if os.path.islink(os.path.join(project, path)) or os.path.isdir(os.path.join(project, path)):
                found.append(("folder", path))
    for folder in ADAPTER_FOLDERS:
        where = os.path.join(project, folder)
        if not os.path.isdir(where):
            continue
        for entry in sorted(os.listdir(where)):
            path = os.path.join(folder, entry)
            stem = os.path.splitext(entry)[0]
            # A generated file for a retired command opens nothing on any
            # route. One for a current command is only a second copy where the
            # installer already reaches it, which is the shared route.
            if os.path.isfile(os.path.join(project, path)) and generated(os.path.join(project, path)) \
                    and (shared or stem in FORMER_NAMES):
                found.append(("adapter", path))
    if shared:
        for name in KIT_SKILLS:
            if not installed(project, name):
                found.append(("missing", name))
    hook = os.path.join(".agents", "hooks", "session-end-sync.sh")
    try:
        with open(os.path.join(project, hook), encoding="utf-8", errors="replace") as handle:
            if re.search(r"/(sync|fix|queue|ship)\b", handle.read()):
                found.append(("hook", hook))
    except OSError:
        pass
    return found


def template_lines():
    """The two bullets and the three counts the shipped template uses."""
    try:
        with open(TEMPLATE, encoding="utf-8") as handle:
            lines = handle.read().splitlines()
    except OSError:
        return None
    bullets = {}
    for prefix in BULLETS:
        for index, line in enumerate(lines):
            if line.startswith(prefix):
                block = [line]
                for more in lines[index + 1:]:
                    if more.startswith("  ") and more.strip():
                        block.append(more)
                    else:
                        break
                bullets[prefix] = block
    text = "\n".join(lines)
    counts = {}
    for key, pattern in COUNTS:
        match = pattern.search(text)
        if match:
            counts[key] = match.group(1).lower()
    if len(bullets) != 2 or len(counts) != 3:
        return None
    return bullets, counts


def bullet_at(lines, index):
    """The lines of the bullet that starts at index, continuation included."""
    end = index + 1
    while end < len(lines) and lines[end].startswith("  ") and lines[end].strip():
        end += 1
    return end


def plain(line):
    return line.rstrip("\r\n")


def ending(line):
    return line[len(plain(line)):] or "\n"


def same_case(old, new):
    return new.capitalize() if old[:1].isupper() else new


def commands_findings(project, shipped):
    """Yield (line number, old text, new lines or None, reason) for AGENTS.md."""
    path = os.path.join(project, "AGENTS.md")
    try:
        with open(path, encoding="utf-8", newline="") as handle:
            lines = handle.readlines()
    except (OSError, UnicodeDecodeError):
        return [], None
    known = set(KIT_SKILLS) | set(FORMER_NAMES)
    found = []
    start = next((i for i, line in enumerate(lines) if line.startswith(BULLETS[0])), None)
    if start is None:
        # A list in the person's own words. Only say so where it still names a
        # retired command, so the person knows which word to change.
        for number, line in enumerate(lines, 1):
            for name in TICKED.findall(line) + re.findall(r"(?<![\w/.-])/([a-z-]+)\b", line):
                if name in FORMER_NAMES[3:]:
                    found.append((number, plain(line), None,
                                  "the command list was not recognised; `%s` needs changing by hand" % name))
                    break
        return found, lines
    if shipped is None:
        found.append((start + 1, plain(lines[start]), None,
                      "the installed founding template could not be read"))
        return found, lines
    bullets, counts = shipped
    index = start
    for prefix in BULLETS:
        if index >= len(lines) or not lines[index].startswith(prefix):
            break
        end = bullet_at(lines, index)
        old = [plain(line) for line in lines[index:end]]
        names = TICKED.findall(" ".join(old))
        if old != bullets[prefix]:
            unknown = [n for n in names if n not in known]
            if unknown:
                found.append((index + 1, " ".join(s.strip() for s in old), None,
                              "it names `%s`, which is not one of the kit's commands" % unknown[0]))
            else:
                found.append((index + 1, (index, end), bullets[prefix], ""))
        index = end
    # The counts sit in the paragraph between the heading above the list and
    # the list itself.
    top = start
    while top > 0 and not lines[top - 1].startswith("#"):
        top -= 1
    paragraph = "".join(lines[top:start])
    for key, pattern in COUNTS:
        for match in pattern.finditer(paragraph):
            word = match.group(1)
            if word.lower() != counts[key]:
                row = top + paragraph.count("\n", 0, match.start(1))
                column = match.start(1) - (paragraph.rfind("\n", 0, match.start(1)) + 1)
                found.append((row + 1, word, same_case(word, counts[key]), ("count", column)))
    return found, lines


def rewrite(project, found, lines):
    """Apply the rewritable findings, right to left so positions stay true."""
    out = list(lines)
    # Counts right to left within a line, so an earlier column stays true.
    counts = sorted((f for f in found if isinstance(f[3], tuple)),
                    key=lambda f: (f[0], f[3][1]), reverse=True)
    for number, old, new, (_, column) in counts:
        line = out[number - 1]
        out[number - 1] = line[:column] + new + line[column + len(old):]
    blocks = sorted((f for f in found if f[3] == "" and isinstance(f[1], tuple)),
                    key=lambda f: f[1][0], reverse=True)
    for _, (begin, end), new, _ in blocks:
        tail = ending(out[end - 1])
        out[begin:end] = [line + tail for line in new]
    if out != lines:
        with open(os.path.join(project, "AGENTS.md"), "w", encoding="utf-8", newline="") as handle:
            handle.writelines(out)


def remove(project, findings):
    for kind, path in findings:
        if kind not in ("folder", "adapter"):
            continue
        where = os.path.join(project, path)
        if os.path.islink(where) or os.path.isfile(where):
            os.remove(where)
        elif os.path.isdir(where):
            shutil.rmtree(where)
        parent = os.path.dirname(where)
        # An adapter folder left empty goes too, and so does its tool folder
        # when nothing else is in it.
        for _ in range(2):
            if kind == "adapter" and os.path.isdir(parent) and not os.listdir(parent):
                os.rmdir(parent)
                parent = os.path.dirname(parent)


def main(argv):
    flags = {a for a in argv if a.startswith("--")}
    rest = [a for a in argv if not a.startswith("--")]
    unknown = flags - {"--remove", "--rewrite-commands"}
    if unknown:
        print("usage: kit-leftovers.py [--remove | --rewrite-commands] [PROJECT]", file=sys.stderr)
        return 2
    project = rest[0] if rest else "."
    skills = skill_findings(project)
    commands, lines = commands_findings(project, template_lines())
    if "--remove" in flags:
        remove(project, skills)
        return 0
    if "--rewrite-commands" in flags:
        if lines is not None:
            rewrite(project, commands, lines)
        return 0
    for kind, value in skills:
        if kind == "installer":
            print("installer\t%s\tnpx skills remove %s" % (value, value))
        else:
            print("%s\t%s" % (kind, value))
    for number, old, new, why in commands:
        if isinstance(old, tuple):
            begin, end = old
            old = " ".join(plain(line).strip() for line in lines[begin:end])
        if new is None:
            print("commands\tAGENTS.md:%d\t%s\tleft as written: %s" % (number, old, why))
        elif isinstance(new, list):
            print("commands\tAGENTS.md:%d\t%s\t%s" % (number, old, " ".join(s.strip() for s in new)))
        else:
            print("commands\tAGENTS.md:%d\t%s\t%s" % (number, old, new))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
