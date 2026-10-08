#!/usr/bin/env python3
"""Find, and on request tidy, what an update leaves behind after the kit renames
or folds a command.

An update refreshes the kit's skills and nothing else. When the kit renames a
command or folds one into another, the old skill can stay installed, a whole
copy of the kit keeps its old generated files, and the project's AGENTS.md
keeps listing the old commands. This script finds each of those and prints one
line for it. It prints nothing when there is nothing to find.

Usage:

    kit-leftovers.py [PROJECT]                     list what it finds
    kit-leftovers.py --remove [PROJECT]            remove what is listed as
                                                   `folder`, `adapter` or
                                                   `kitcopy`, and replace the
                                                   `hook`
    kit-leftovers.py --rewrite-commands [PROJECT]  rewrite the `commands` lines
                                                   that show a new form

PROJECT defaults to the current folder. Each finding is one line of fields
separated by tabs. The first field says what it is:

    installer  NAME    a skill under a former name that skills-lock.json lists
                       as the kit's; the installer removes it with
                       `npx skills remove NAME`, never this script
    folder     PATH    a skill folder under a former name, not in the
                       lockfile, whose SKILL.md is the kit's own
    adapter    PATH    a command file or skill folder the kit generated,
                       known by its marker
    left       PATH    WHY
                       something that looks like a leftover but is never
                       removed, with the reason
    missing    NAME    one of the kit's skills is not installed
    commands   FILE:LINE  OLD  NEW
                       a line of the command list or its counts in AGENTS.md
    commands   FILE:LINE  OLD  left as written: WHY
                       a line the script will not rewrite, with the reason
    hook       PATH    the kit's session-end hook is a released copy older than
                       the one this release ships; --remove replaces it
    kitcopy    PATH    a file or folder only the kit needs, which a whole copy
                       brought and no update refreshes, matching a released
                       copy byte for byte; --remove removes it

What it will not touch. A name the lockfile lists under any other source is
the person's. A folder not in the lockfile counts as the kit's only when its
SKILL.md carries the former name and a description one of the kit's releases
gave it, and every file matches a released copy for that skill, kept in
kit-retired-skills.json beside this script. Personal additions or edits keep
the whole folder. Nothing whose
real location is outside the project is ever listed for removal, and a link is
never followed: at most the link itself goes. A rewrite of AGENTS.md changes
only a list that holds the kit's names and nothing else, and only those lines,
line endings included. A kit file from a whole copy, or the old session-end
hook, is removed or replaced only when every byte matches a copy a release
shipped at the same path, kept in kit-released-copies.json beside this script.
A version marker holding only a stable version number also counts as the
kit's own file. One that differs gets a `left` line and stays as it is.
The kit's README from a whole copy is only ever named, never removed.

In list mode it exits 0, whatever it prints. upgrade-check.py, beside it, is
the read that exits 1 while something is left.
"""

import hashlib
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
# `grilling` became `clarify`,
# `ship` became `setup-hosting`, and `fix`, `queue` and `sync` folded into
# `shape`, `implement` and `maintain`.
FORMER_NAMES = ("build", "start", "plan", "grilling", "fix", "queue", "sync", "ship")

KIT_SOURCE = "gwpicard/ai-build-kit"
SKILL_FOLDERS = (".agents/skills", ".claude/skills")
ADAPTER_FOLDERS = (".claude/commands", ".cursor/commands", ".gemini/commands")
SKILL_ADAPTER_FOLDERS = (".claude/skills", ".cursor/skills", ".gemini/skills")

HERE = os.path.dirname(os.path.abspath(__file__))
# The installed skills sit beside this one, so the founding template the
# command list is rewritten to is the one this release ships.
INSTALLED = os.path.dirname(os.path.dirname(HERE))
TEMPLATE = os.path.join(INSTALLED, "setup-ai-build-kit", "templates", "foundation", "AGENTS.md")
KNOWN = os.path.join(HERE, "kit-retired-skills.json")
RELEASED = os.path.join(HERE, "kit-released-copies.json")
VERSION = os.path.join(os.path.dirname(HERE), "VERSION")
HOOK = ".agents/hooks/session-end-sync.sh"
NEW_HOOK = os.path.join(INSTALLED, "setup-ai-build-kit", "templates", "foundation", "session-end-sync.sh")
MARKER = ".ai-build-kit-version"
# What a whole copy carries that only the kit itself needs, in the order the
# lines print. The version marker comes last, since once it goes the copy is no
# longer recognised as a whole copy, and what was left stays named only once.
KIT_COPIES = ("agent-plugin", ".claude-plugin", "WORKFLOW.md",
              ".agents/guard/blocked-commands.md", ".agents/tools/build-adapters.sh",
              MARKER)

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


# --- where things are ---------------------------------------------------------

def real_inside(project, path):
    """True when the real location of path is inside the project."""
    root = os.path.realpath(project)
    real = os.path.realpath(path)
    return real == root or real.startswith(root + os.sep)


def normal_source(source):
    """A lockfile source with any address prefix and suffix taken off."""
    text = str(source).strip().lower()
    for prefix in ("https://github.com/", "http://github.com/", "git@github.com:",
                   "github.com/", "github:"):
        if text.startswith(prefix):
            text = text[len(prefix):]
    text = text.rstrip("/")
    if text.endswith(".git"):
        text = text[:-4]
    return text


def lockfile(project):
    """(names listed as the kit's, every name listed), or None without one."""
    try:
        with open(os.path.join(project, "skills-lock.json"), encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return None
    skills = data.get("skills") if isinstance(data, dict) else None
    if not isinstance(skills, dict):
        return None
    kit = set()
    for name, entry in skills.items():
        source = entry.get("source", "") if isinstance(entry, dict) else ""
        if normal_source(source) == KIT_SOURCE:
            kit.add(name)
    return kit, set(skills)


def frontmatter(path):
    """(name, description) from a SKILL.md, or (None, None)."""
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            lines = handle.read().splitlines()
    except OSError:
        return None, None
    if not lines or lines[0].strip() != "---":
        return None, None
    block = []
    for line in lines[1:]:
        if line.strip() == "---":
            break
        block.append(line)
    name = description = None
    for index, line in enumerate(block):
        if line.startswith("name:"):
            name = line[5:].strip().strip('"')
        elif line.startswith("description:"):
            value = line[12:].strip()
            if value in ("|", ">"):
                parts = []
                for more in block[index + 1:]:
                    if more.startswith((" ", "\t")) and more.strip():
                        parts.append(more.strip())
                    else:
                        break
                value = " ".join(parts)
            description = value.strip('"')
    return name, description


def known_descriptions():
    try:
        with open(KNOWN, encoding="utf-8") as handle:
            return json.load(handle).get("skills", {})
    except (OSError, ValueError):
        return {}


def generated(path):
    """True when the first lines carry the marker build-adapters.sh writes."""
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            head = "".join(handle.readline() for _ in range(6))
    except OSError:
        return False
    return "GENERATED from .agents/skills/" in head and "build-adapters.sh" in head


def installed(project, name):
    return any(os.path.isfile(os.path.join(project, folder, name, "SKILL.md"))
               for folder in SKILL_FOLDERS)


# --- finding ----------------------------------------------------------------

def skill_findings(project):
    lock = lockfile(project)
    kit_listed, any_listed = lock if lock else (set(), set())
    shared = bool(kit_listed)
    known = known_descriptions()
    found = []
    seen = set()

    def once(full):
        real = os.path.realpath(full)
        if real in seen:
            return False
        seen.add(real)
        return True

    for name in FORMER_NAMES:
        if name in kit_listed:
            found.append(("installer", name))
            continue
        if name in any_listed:
            # Listed under another source: the person's own skill.
            continue
        for folder in SKILL_FOLDERS:
            path = os.path.join(folder, name)
            full = os.path.join(project, path)
            if not (os.path.islink(full) or os.path.isdir(full)):
                continue
            if not real_inside(project, os.path.dirname(full)):
                found.append(("left", path, "it sits in a folder whose real place is outside the project"))
                continue
            if os.path.islink(full) and not real_inside(project, full):
                found.append(("left", path, "it links to a folder outside the project"))
                continue
            skill = os.path.join(full, "SKILL.md")
            if generated(skill):
                # A generated copy, not a skill. The adapter scan lists it.
                continue
            if not os.path.islink(full) and not once(full):
                continue
            got_name, description = frontmatter(skill)
            if got_name == name and description in known.get(name, []):
                problem = retired_folder_problem(project, path)
                found.append(("left", path, problem) if problem else ("folder", path))
            else:
                found.append(("left", path, "not recognised as the kit's"))

    def adapter_wanted(stem):
        # A generated copy for a retired command opens nothing on any route.
        # One for a current name is only a second copy where the installer
        # already reaches it, which is the shared route.
        return shared or stem in FORMER_NAMES

    for folder in ADAPTER_FOLDERS:
        where = os.path.join(project, folder)
        if not os.path.isdir(where) or not real_inside(project, where):
            continue
        for entry in sorted(os.listdir(where)):
            path = os.path.join(folder, entry)
            full = os.path.join(project, path)
            if os.path.islink(full) or not os.path.isfile(full):
                continue
            if generated(full) and adapter_wanted(os.path.splitext(entry)[0]):
                found.append(("adapter", path))
    for folder in SKILL_ADAPTER_FOLDERS:
        where = os.path.join(project, folder)
        if not os.path.isdir(where) or not real_inside(project, where):
            continue
        for entry in sorted(os.listdir(where)):
            path = os.path.join(folder, entry)
            full = os.path.join(project, path)
            if os.path.islink(full) or not os.path.isdir(full):
                continue
            # A generated skill folder under a current name is how Claude Code
            # reaches that background skill until the installer puts its own
            # link there, so only one under a name the kit dropped is stale.
            if not generated(os.path.join(full, "SKILL.md")) or entry in KIT_SKILLS:
                continue
            if not once(full):
                continue
            if os.listdir(full) != ["SKILL.md"]:
                found.append(("left", path, "it holds files besides the generated one"))
            else:
                found.append(("adapter", path))
    if shared:
        for name in KIT_SKILLS:
            if not installed(project, name):
                found.append(("missing", name))
    found.extend(hook_findings(project))
    found.extend(copy_findings(project))
    return found


# --- kit files a whole copy brought ------------------------------------------

def released():
    try:
        with open(RELEASED, encoding="utf-8") as handle:
            return {path: set(hashes) for path, hashes in json.load(handle).get("files", {}).items()}
    except (OSError, ValueError, AttributeError):
        return {}


def digest(path):
    with open(path, "rb") as handle:
        return hashlib.sha256(handle.read()).hexdigest()[:16]


def file_problem(project, path, known):
    """None when the file matches a released copy at its path, or the reason."""
    full = os.path.join(project, path)
    if not real_inside(project, os.path.dirname(full)):
        return "it sits in a folder whose real place is outside the project"
    if os.path.islink(full):
        return "it is a link"
    if not os.path.isfile(full):
        return "it is not a file"
    if path == MARKER:
        with open(full, "rb") as handle:
            if re.fullmatch(rb"v[0-9]+\.[0-9]+\.[0-9]+\s*", handle.read()):
                return None
    if digest(full) not in known.get(path, ()):
        return "it differs from every copy a release shipped, so it may hold changes of yours"
    return None


def folder_problem(project, path, known):
    """None when every file in the folder matches a released copy, or the reason."""
    full = os.path.join(project, path)
    if not real_inside(project, os.path.dirname(full)):
        return "it sits in a folder whose real place is outside the project"
    if os.path.islink(full):
        return "it is a link"
    changed = 0
    for here, dirs, names in os.walk(full):
        for name in dirs + names:
            if os.path.islink(os.path.join(here, name)):
                return "it holds a link"
        for name in names:
            item = os.path.join(here, name)
            rel = os.path.relpath(item, project).replace(os.sep, "/")
            if not os.path.isfile(item) or digest(item) not in known.get(rel, ()):
                changed += 1
    if changed:
        return "%d file%s in it differ%s from what a release shipped, so it may hold changes of yours" % (
            changed, "" if changed == 1 else "s", "s" if changed == 1 else "")
    return None



def retired_folder_problem(project, path):
    # A link is removed on its own, never with its target. A real folder must
    # contain only unchanged released files, including SKILL.md's body.
    if os.path.islink(os.path.join(project, path)):
        return None
    name = path.rsplit("/", 1)[-1]
    try:
        with open(KNOWN, encoding="utf-8") as handle:
            hashes = json.load(handle).get("files", {})
    except (OSError, ValueError):
        hashes = {}
    known = {path + "/" + rel[len(name) + 1:]: set(values)
             for rel, values in hashes.items() if rel.startswith(name + "/")}
    # Future releases record the skill folders too, so today's current skill
    # can later be recognised when it is retired.
    prefix = ".agents/skills/" + name + "/"
    for rel, values in released().items():
        if rel.startswith(prefix):
            known.setdefault(path + "/" + rel[len(prefix):], set()).update(values)
    return folder_problem(project, path, known)

def stale_copy(project):
    """True when the project is a whole copy and its kit files are from an
    older release than the installed skills."""
    try:
        with open(os.path.join(project, MARKER), encoding="utf-8") as handle:
            marker = handle.read().strip()
        with open(VERSION, encoding="utf-8") as handle:
            version = handle.read().strip()
    except (OSError, UnicodeDecodeError):
        return False
    return bool(marker) and marker != version


def copy_findings(project):
    if not stale_copy(project):
        return []
    known = released()
    found = []
    for path in KIT_COPIES:
        full = os.path.join(project, path)
        if not (os.path.lexists(full)):
            continue
        if os.path.isdir(full) and not os.path.islink(full):
            problem = folder_problem(project, path, known)
        else:
            problem = file_problem(project, path, known)
        found.append(("left", path, problem) if problem else ("kitcopy", path))
    if os.path.isfile(os.path.join(project, "README.md")) and \
            file_problem(project, "README.md", known) is None:
        found.append(("left", "README.md",
                      "it is the kit's own read-me from a whole copy, and yours to replace with one about your tool"))
    return found


def hook_findings(project):
    """The session-end hook a whole copy brought, when it is older than the
    copy this release ships."""
    full = os.path.join(project, HOOK)
    if not os.path.lexists(full):
        return []
    try:
        with open(NEW_HOOK, "rb") as handle:
            current = handle.read()
    except OSError:
        return []
    if os.path.isfile(full) and not os.path.islink(full):
        with open(full, "rb") as handle:
            if handle.read() == current:
                return []
    problem = file_problem(project, HOOK, released())
    if problem is None:
        return [("hook", HOOK)]
    try:
        with open(full, encoding="utf-8", errors="replace") as handle:
            stale = re.search(r"/(sync|fix|queue|ship)\b", handle.read())
    except OSError:
        stale = None
    if stale:
        return [("left", HOOK, problem + "; it still names a retired command")]
    return []


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
                bullets[prefix] = lines[index:bullet_end(lines, index)]
    text = "\n".join(lines)
    counts = {}
    for key, pattern in COUNTS:
        match = pattern.search(text)
        if match:
            counts[key] = match.group(1).lower()
    if len(bullets) != 2 or len(counts) != 3:
        return None
    return bullets, counts


def bullet_end(lines, index):
    """The index after the bullet that starts at index, continuation included."""
    end = index + 1
    while end < len(lines) and lines[end].startswith("  ") and lines[end].strip():
        end += 1
    return end


def plain(line):
    return line.rstrip("\r\n")


def ending(line):
    return line[len(plain(line)):]


def same_case(old, new):
    return new.capitalize() if old[:1].isupper() else new


def kit_shaped(prefix, block, known):
    """None when the bullet holds the kit's names and nothing else, or the reason."""
    text = " ".join(plain(line).strip() for line in block)
    names = TICKED.findall(text)
    unknown = [n for n in names if n not in known]
    if unknown:
        return "it names `%s`, which is not one of the kit's" % unknown[0]
    shape = re.escape(prefix) + r" `[a-z-]+`(, `[a-z-]+`)*\.$"
    if not re.match(shape, text):
        return "it holds words of its own besides the kit's names"
    return None


def command_blocks(lines):
    """Command-list blocks, including wrapped lists written as sentences."""
    commands = set(KIT_SKILLS[:6]) | set(FORMER_NAMES)
    blocks = []
    index = 0
    while index < len(lines):
        if lines[index].startswith(BULLETS):
            end = bullet_end(lines, index)
            blocks.append((index, end))
        elif lines[index].strip() and not lines[index].startswith("#"):
            end = index + 1
            while end < len(lines) and lines[end].strip() and not lines[end].startswith(("#", "- ")):
                end += 1
            text = " ".join(plain(line).strip() for line in lines[index:end])
            names = TICKED.findall(text) + re.findall(r"(?<![\w/.-])/([a-z-]+)\b", text)
            named = {n.lstrip("/") for n in names} & commands
            # Require a list introduction, so prose about using several
            # commands is not mistaken for the installed command list.
            if named and re.search(r"(?i)\bcommands\b[^`/]*?(?::|\bare\b)", text):
                blocks.append((index, end))
        else:
            end = index + 1
        index = end
    return blocks


def commands_findings(project, shipped):
    """Return (findings, lines) for AGENTS.md. Each finding is
    (line number, old, new or None, kind) where kind is a reason, "block"
    with a (begin, end) old, or ("count", column)."""
    path = os.path.join(project, "AGENTS.md")
    if os.path.islink(path):
        return [(1, "AGENTS.md", None, "it is a link, so it was left alone")], None
    try:
        with open(path, encoding="utf-8", newline="") as handle:
            lines = handle.readlines()
    except (OSError, UnicodeDecodeError):
        return [], None
    known = set(KIT_SKILLS) | set(FORMER_NAMES)
    found = []
    blocks = command_blocks(lines)
    start = next((i for i, line in enumerate(lines) if line.startswith(BULLETS[0])), None)
    for begin, end in blocks:
        if lines[begin].startswith(BULLETS):
            continue
        text = " ".join(plain(line).strip() for line in lines[begin:end])
        names = TICKED.findall(text) + re.findall(r"(?<![\w/.-])/([a-z-]+)\b", text)
        if any(n.lstrip("/") in ("fix", "queue", "sync", "ship") for n in names):
            found.append((begin + 1, text, None,
                          "the command list was not recognised; an agent edit needs approval"))
    if start is None:
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
        end = bullet_end(lines, index)
        old = [plain(line) for line in lines[index:end]]
        if old != bullets[prefix]:
            why = kit_shaped(prefix, old, known)
            if why:
                suggested = " ".join(s.strip() for s in bullets[prefix])
                found.append((index + 1, " ".join(s.strip() for s in old), None,
                              "%s; suggested: %s" % (why, suggested)))
                if prefix == BULLETS[0]:
                    # The person wrote into the list, so the counts above it
                    # are theirs to settle too.
                    return found, lines
            else:
                found.append((index + 1, (index, end), bullets[prefix], "block"))
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
    """Apply the rewritable findings, from the bottom up so positions stay true."""
    out = list(lines)
    counts = sorted((f for f in found if isinstance(f[3], tuple)),
                    key=lambda f: (f[0], f[3][1]), reverse=True)
    for number, old, new, (_, column) in counts:
        line = out[number - 1]
        out[number - 1] = line[:column] + new + line[column + len(old):]
    blocks = sorted((f for f in found if f[3] == "block"), key=lambda f: f[1][0], reverse=True)
    for _, (begin, end), new, _ in blocks:
        inner = ending(out[begin]) or "\n"
        last = ending(out[end - 1])
        out[begin:end] = [line + inner for line in new[:-1]] + [new[-1] + last]
    if out != lines:
        with open(os.path.join(project, "AGENTS.md"), "w", encoding="utf-8", newline="") as handle:
            handle.writelines(out)


# --- removing ---------------------------------------------------------------

def remove(project, findings):
    root = os.path.realpath(project)
    known = None
    for finding in findings:
        kind, path = finding[0], finding[1]
        if kind not in ("folder", "adapter", "kitcopy", "hook"):
            continue
        where = os.path.join(project, path)
        if kind == "folder" and retired_folder_problem(project, path) is not None:
            continue
        if kind in ("kitcopy", "hook"):
            # Checked again here, byte for byte, whatever the listing said.
            known = released() if known is None else known
            if os.path.isdir(where) and not os.path.islink(where):
                if folder_problem(project, path, known) is not None:
                    continue
            elif file_problem(project, path, known) is not None:
                continue
            if kind == "hook":
                with open(NEW_HOOK, "rb") as source, open(where, "wb") as handle:
                    handle.write(source.read())
                continue
        # Checked again here, so nothing reaches outside the project and no
        # link is followed, whatever the listing said.
        if not real_inside(project, os.path.dirname(where)):
            continue
        if os.path.islink(where):
            os.unlink(where)
        elif os.path.isfile(where):
            os.remove(where)
        elif os.path.isdir(where) and real_inside(project, where):
            shutil.rmtree(where)
        else:
            continue
        if kind not in ("adapter", "kitcopy"):
            continue
        # A generated folder left empty goes too, and so does its tool folder
        # when nothing else is in it.
        parent = os.path.dirname(where)
        for _ in range(2):
            real = os.path.realpath(parent)
            if (real != root and real.startswith(root + os.sep) and not os.path.islink(parent)
                    and os.path.isdir(parent) and not os.listdir(parent)):
                os.rmdir(parent)
                parent = os.path.dirname(parent)


def main(argv):
    flags = {a for a in argv if a.startswith("--")}
    rest = [a for a in argv if not a.startswith("--")]
    if flags - {"--remove", "--rewrite-commands"}:
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
    for finding in skills:
        kind, value = finding[0], finding[1]
        if kind == "installer":
            print("installer\t%s\tnpx skills remove %s" % (value, value))
        elif kind == "left":
            print("left\t%s\t%s" % (value, finding[2]))
        else:
            print("%s\t%s" % (kind, value))
    for number, old, new, kind in commands:
        if isinstance(old, tuple):
            begin, end = old
            old = " ".join(plain(line).strip() for line in lines[begin:end])
        if new is None:
            print("commands\tAGENTS.md:%d\t%s\tleft as written: %s" % (number, old, kind))
        elif isinstance(new, list):
            print("commands\tAGENTS.md:%d\t%s\t%s" % (number, old, " ".join(s.strip() for s in new)))
        else:
            print("commands\tAGENTS.md:%d\t%s\t%s" % (number, old, new))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
