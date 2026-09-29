#!/usr/bin/env python3
"""Find, and on request rewrite, pointers to a kit skill's files at a fixed folder.

A project founded before the kit named its pointers by skill carries lines in
its AGENTS.md and masterplan.md that name a skill's file by its place in the
project's `.agents/skills/` folder. A project installed for Claude Code alone,
or through a plugin, has no such folder, so those lines open nothing. The
current form names the skill and the path inside it, the `setup-ai-build-kit`
skill's `references/pieces.md`, which a coding agent finds on every install
route.

Usage:

    old-skill-pointers.py [PROJECT]            list what it finds
    old-skill-pointers.py --apply [PROJECT]    rewrite the ones it can

PROJECT defaults to the current folder. Only AGENTS.md and masterplan.md at its
root are read. Each finding prints as one line, in one of two forms:

    file:line<TAB>old pointer<TAB>new pointer
    file:line<TAB>old pointer<TAB>left as written: <why>

Nothing prints when there is nothing to find. Only a pointer into one of the
kit's skills, under today's name or a name it had before, is found. A project's
own skill under the same folder, a placeholder such as `<name>`, and a mention
of the folder itself are never found, since those are the person's words or
still true.

A pointer is rewritten only where it stands alone: as a whole code span, or as
a bare path between spaces, at the end of a sentence, or on a line of its own.
Inside a longer code span, such as a command, or inside a link, a rewrite would
break the line, so the pointer is listed with the reason and left for the
person. So is a pointer to a file the skill no longer has.
"""

import os
import re
import sys

# The kit's fourteen skills. A name outside this list may be the project's own
# skill, and its pointer is the person's to keep.
KIT_SKILLS = (
    "setup-ai-build-kit", "shape", "implement", "queue", "fix", "ship", "sync",
    "maintain", "what-now", "clarify", "change-triage", "screen-check",
    "section-builder", "second-opinion",
)

# Names a kit skill had before, with the name it has now. The templates of the
# earliest releases pointed into the founding skill under its first name, and
# the rename migration removes that folder, so those pointers open nothing on
# any install route.
FORMER_NAMES = {"start": "setup-ai-build-kit"}

FILES = ("AGENTS.md", "masterplan.md")

NAMES = sorted(KIT_SKILLS + tuple(FORMER_NAMES), key=len, reverse=True)
POINTER = re.compile(
    r"\.agents/skills/(" + "|".join(re.escape(s) for s in NAMES) + r")/"
    r"([A-Za-z0-9_./-]*[A-Za-z0-9_-])"
)

# The installed skills sit beside this skill. Where they can be read, a new
# pointer is written only for a file the skill still has.
INSTALLED = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def target_exists(skill, path):
    if not os.path.isdir(os.path.join(INSTALLED, skill)):
        return True
    return os.path.isfile(os.path.join(INSTALLED, skill, path))


def stands_alone(line, start, end):
    """Say whether the pointer at line[start:end] can be rewritten, and why not."""
    inside_span = line[:start].count("`") % 2 == 1
    if inside_span:
        if line[start - 1] == "`" and end < len(line) and line[end] == "`":
            return True, ""
        return False, "it sits inside a longer code span, such as a command"
    before = line[start - 1] if start > 0 else " "
    if before not in " \t":
        return False, "it sits inside a link, brackets or another path"
    after = line[end:end + 2] + "\n"
    if after[0] in " \t\n" or (after[0] in ".,;:!?" and after[1] in " \t\n"):
        return True, ""
    return False, "it runs on into more of a path or an address"


def findings(line):
    """Yield (start, end, old, new-or-None, reason) for each pointer on the line."""
    for match in POINTER.finditer(line):
        skill = FORMER_NAMES.get(match.group(1), match.group(1))
        path = match.group(2)
        start, end = match.start(), match.end()
        alone, why = stands_alone(line, start, end)
        whole_span = alone and start > 0 and line[start - 1] == "`"
        if whole_span:
            start, end = start - 1, end + 1
        old = line[start:end]
        if not alone:
            yield start, end, old, None, why
        elif not target_exists(skill, path):
            yield start, end, old, None, "the `%s` skill no longer has that file" % skill
        else:
            yield start, end, old, "the `%s` skill's `%s`" % (skill, path), ""


def main(argv):
    apply = "--apply" in argv
    rest = [a for a in argv if a != "--apply"]
    project = rest[0] if rest else "."
    for name in FILES:
        path = os.path.join(project, name)
        try:
            with open(path, encoding="utf-8") as handle:
                lines = handle.readlines()
        except OSError:
            continue
        changed = False
        for number, line in enumerate(lines, 1):
            found = list(findings(line))
            for start, end, old, new, why in found:
                if new is None:
                    print("%s:%d\t%s\tleft as written: %s" % (name, number, old, why))
                else:
                    print("%s:%d\t%s\t%s" % (name, number, old, new))
            new_line = line
            # Right to left, so each rewrite leaves the earlier positions true.
            for start, end, old, new, why in reversed(found):
                if new is not None:
                    new_line = new_line[:start] + new + new_line[end:]
            if new_line != line:
                lines[number - 1] = new_line
                changed = True
        if apply and changed:
            with open(path, "w", encoding="utf-8") as handle:
                handle.writelines(lines)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
