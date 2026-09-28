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

    old-skill-pointers.py [PROJECT]            list what would change
    old-skill-pointers.py --apply [PROJECT]    rewrite those lines

PROJECT defaults to the current folder. Only AGENTS.md and masterplan.md at its
root are read. Each finding prints as one line:

    file:line<TAB>old pointer<TAB>new pointer

Nothing prints when there is nothing to change. Only a pointer into one of the
kit's fourteen skills, with a path inside it, is touched. A project's own skill
under the same folder, a placeholder such as `<name>`, and a mention of the
folder itself are left alone, since those are the person's words or still true.
"""

import re
import sys

# The kit's fourteen skills. A name outside this list may be the project's own
# skill, and its pointer is the person's to keep.
KIT_SKILLS = (
    "setup-ai-build-kit", "shape", "implement", "queue", "fix", "ship", "sync",
    "maintain", "what-now", "clarify", "change-triage", "screen-check",
    "section-builder", "second-opinion",
)

FILES = ("AGENTS.md", "masterplan.md")

POINTER = re.compile(
    r"(`?)\.agents/skills/(" + "|".join(re.escape(s) for s in KIT_SKILLS) + r")/"
    r"([A-Za-z0-9_./-]*[A-Za-z0-9_-])\1"
)


def replacement(match):
    return "the `%s` skill's `%s`" % (match.group(2), match.group(3))


def main(argv):
    apply = "--apply" in argv
    rest = [a for a in argv if a != "--apply"]
    project = rest[0] if rest else "."
    for name in FILES:
        path = "%s/%s" % (project.rstrip("/"), name)
        try:
            with open(path, encoding="utf-8") as handle:
                lines = handle.readlines()
        except OSError:
            continue
        changed = False
        for number, line in enumerate(lines, 1):
            for match in POINTER.finditer(line):
                print("%s:%d\t%s\t%s" % (name, number, match.group(0), replacement(match)))
            new = POINTER.sub(replacement, line)
            if new != line:
                lines[number - 1] = new
                changed = True
        if apply and changed:
            with open(path, "w", encoding="utf-8") as handle:
                handle.writelines(lines)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
