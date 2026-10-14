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
kit's skills, under today's name or a name it had before, is found. A pointer
already in the named form, naming the skill and then the path inside it, is
found only where it names a skill the kit has retired, since that skill is no longer
installed and the pointer opens nothing. A project's
own skill under the same folder, a placeholder such as `<name>`, and a mention
of the folder itself are never found, since those are the person's words or
still true.

A pointer is rewritten only where it stands alone in prose: as a whole code
span in single backticks, or as a bare path between spaces, at the end of a
sentence, or on a line of its own. Inside a code block, a longer code span such
as a command, or a link, a rewrite would break the line, so the pointer is
listed with the reason and left for the person. So is a pointer to a file the
skill no longer has. A rewrite changes only those pointers: every other
character of the file, line endings included, stays as it was.

A pointer under a name the kit has retired is rewritten only when that name is
not the project's own skill. Where a folder of that name is still installed,
it must carry the kit's name and a description a release shipped, as
kit-leftovers.py recognises the kit's folders. A folder of the person's own, or
a name the lockfile lists under another source, keeps its pointer, listed with
the reason.

The fix skill's one file, and section-builder's repair reference, held both
halves of a repair. Shaping a repair now sits in the `shape` skill's
`references/repair.md`, and building one in the `implement` skill's. A pointer
whose sentence speaks of shaping or reproducing a fault, and not of building
one, follows the first. Every other one follows the second, which opens by
pointing at the first.
"""

import os
import re
import runpy
import sys

# The kit's eight skills. A name outside this list may be the project's own
# skill, and its pointer is the person's to keep.
KIT_SKILLS = (
    "setup-ai-build-kit", "shape", "implement", "setup-hosting",
    "maintain", "what-now", "clarify", "second-opinion",
)

# Names a kit skill had before, with the name it has now. The templates of the
# earliest releases pointed into the founding skill under its first name, and
# the rename migration removes that folder, so those pointers open nothing on
# any install route.
FORMER_NAMES = {
    "start": "setup-ai-build-kit", "ship": "setup-hosting", "fix": "implement",
    "queue": "implement", "sync": "maintain", "change-triage": "shape",
    "section-builder": "implement", "screen-check": "implement",
}

# A former skill's file that moved somewhere other than the same path in the
# skill that took its name. The fix skill had only its SKILL.md, and its rules
# now sit in the two repair references, which REPAIR_FILES chooses between. The routine of `sync` became the maintain skill's truing
# reference. The handover template left `ship` for the maintain skill, which
# now owns handovers. Change-triage's two research references became shape's
# one, and its rules joined shape's own SKILL.md. Section-builder's repair
# reference kept its path in implement, its rules joined implement's SKILL.md,
# and screen-check became implement's screen rules. Section-builder's other
# references and scripts, sync's document read and script, and the rules of
# `queue` kept their paths or joined the SKILL.md of the skill that took the
# name, so those need no entry here.
FORMER_FILES = {
    ("fix", "SKILL.md"): ("implement", "references/repair.md"),
    ("sync", "SKILL.md"): ("maintain", "references/truing.md"),
    ("ship", "templates/handover.md"): ("maintain", "templates/handover.md"),
    ("change-triage", "references/source-check.md"): ("shape", "references/research.md"),
    ("change-triage", "references/existing-work.md"): ("shape", "references/research.md"),
    ("screen-check", "SKILL.md"): ("implement", "references/screen-rules.md"),
}

# The two files that held both halves of a repair, and the words that say a
# sentence means the shaping half: the fault reproduced and written into a
# piece before anything is built.
REPAIR_FILES = (("fix", "SKILL.md"), ("section-builder", "references/repair.md"))
SHAPING = re.compile(r"(?i)\b(shap(e|es|ed|ing)|reproduc\w*|symptom|failing case)\b")
BUILDING = re.compile(r"(?i)\b(build\w*|built|fix(es|ed|ing)?|attempts?|escalat\w*)\b")

FILES = ("AGENTS.md", "masterplan.md")

NAMES = sorted(KIT_SKILLS + tuple(FORMER_NAMES), key=len, reverse=True)
POINTER = re.compile(
    r"\.agents/skills/(" + "|".join(re.escape(s) for s in NAMES) + r")/"
    r"([A-Za-z0-9_./-]*[A-Za-z0-9_-])"
)
# A pointer that already names its skill, under a name the kit has retired.
NAMED = re.compile(
    r"`(" + "|".join(re.escape(s) for s in sorted(FORMER_NAMES, key=len, reverse=True)) + r")`"
    r" skill['\u2019]s `([A-Za-z0-9_./-]*[A-Za-z0-9_-])`"
)
# A code span opens and closes with the same run of backticks.
CODE_SPAN = re.compile(r"(`+)(.+?)(?<!`)\1(?!`)")
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
CLOSING_FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})[ \t]*\r?\n?$")

# The installed skills sit beside this skill. Where they can be read, a new
# pointer is written only for a file the skill still has.
INSTALLED = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def target_problem(skill, path):
    """Say why the new pointer would open nothing, or return None."""
    if not os.path.isdir(os.path.join(INSTALLED, skill)):
        return None
    where = os.path.join(INSTALLED, skill, path)
    if os.path.isfile(where):
        return None
    if os.path.isdir(where):
        return "it names a folder, not a file"
    return "the `%s` skill no longer has that file" % skill


def placement(line, start, end):
    """Say how the pointer at line[start:end] sits: (rewrite start, end) or a reason."""
    for span in CODE_SPAN.finditer(line):
        if span.start() < start and end <= span.end():
            if len(span.group(1)) == 1 and span.start(2) == start and span.end(2) == end:
                return (span.start(), span.end()), None
            if len(span.group(1)) > 1:
                return None, "it sits inside a code span in double backticks"
            return None, "it sits inside a longer code span, such as a command"
    before = line[start - 1] if start > 0 else " "
    if before not in " \t":
        return None, "it sits inside a link, brackets or another path"
    after = line[end:end + 2] + "\n"
    if after[0] in " \t\r\n" or (after[0] in ".,;:!?" and after[1] in " \t\r\n"):
        return (start, end), None
    return None, "it runs on into more of a path or an address"


def new_home(name, path, sentence=""):
    """The skill and path a pointer into `name` at `path` should name now.

    `sentence` is the line with its pointers taken out. It decides which half
    of a repair a pointer to one of REPAIR_FILES means."""
    if (name, path) in REPAIR_FILES:
        if SHAPING.search(sentence) and not BUILDING.search(sentence):
            return "shape", "references/repair.md"
        return "implement", "references/repair.md"
    if (name, path) in FORMER_FILES:
        return FORMER_FILES[(name, path)]
    return FORMER_NAMES.get(name, name), path


def own_skills(project):
    """{former name: reason} for each retired name the project uses for a
    skill of its own. Read with kit-leftovers.py's own tests, so the two
    scripts recognise the kit's folders alike."""
    try:
        leftovers = runpy.run_path(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                "kit-leftovers.py"))
    except (OSError, SyntaxError):
        return {}
    lock = leftovers["lockfile"](project)
    kit_listed, any_listed = lock if lock else (set(), set())
    known = leftovers["known_descriptions"]()
    own = {}
    for name in FORMER_NAMES:
        if name in any_listed and name not in kit_listed:
            own[name] = "the project has a `%s` skill of its own" % name
            continue
        for folder in leftovers["SKILL_FOLDERS"]:
            full = os.path.join(project, folder, name)
            if not (os.path.islink(full) or os.path.isdir(full)):
                continue
            skill = os.path.join(full, "SKILL.md")
            if leftovers["generated"](skill):
                continue
            got_name, description = leftovers["frontmatter"](skill)
            if got_name != name or description not in known.get(name, []):
                own[name] = "the project has a `%s` skill of its own" % name
                break
    return own


def sentence_of(line):
    return NAMED.sub(" ", POINTER.sub(" ", line))


def findings(line, in_block, own=None):
    """Yield (start, end, old, new-or-None, reason) for each pointer on the line."""
    own = own or {}
    sentence = sentence_of(line)
    for match in NAMED.finditer(line):
        skill, path = new_home(match.group(1), match.group(2), sentence)
        if in_block:
            yield match.start(), match.end(), match.group(0), None, "it sits inside a code block"
            continue
        if match.group(1) in own:
            yield match.start(), match.end(), match.group(0), None, own[match.group(1)]
            continue
        problem = target_problem(skill, path)
        if problem:
            yield match.start(), match.end(), match.group(0), None, problem
            continue
        yield match.start(), match.end(), match.group(0), "`%s` skill's `%s`" % (skill, path), ""
    for match in POINTER.finditer(line):
        skill, path = new_home(match.group(1), match.group(2), sentence)
        if in_block:
            yield match.start(), match.end(), match.group(0), None, "it sits inside a code block"
            continue
        if match.group(1) in own:
            yield match.start(), match.end(), match.group(0), None, own[match.group(1)]
            continue
        where, why = placement(line, match.start(), match.end())
        if where is None:
            yield match.start(), match.end(), match.group(0), None, why
            continue
        start, end = where
        old = line[start:end]
        problem = target_problem(skill, path)
        if problem:
            yield start, end, old, None, problem
            continue
        # "Read the `...`" already has its article.
        article = "" if line[:start].lower().endswith("the ") else "the "
        yield start, end, old, "%s`%s` skill's `%s`" % (article, skill, path), ""


def main(argv):
    apply = "--apply" in argv
    rest = [a for a in argv if a != "--apply"]
    project = rest[0] if rest else "."
    own = own_skills(project)
    for name in FILES:
        path = os.path.join(project, name)
        if os.path.islink(path):
            print("%s\t\tleft as written: it is a link, so it was left alone" % name)
            continue
        try:
            # newline="" keeps each line's own ending, so a rewrite changes the
            # pointers and nothing else.
            with open(path, encoding="utf-8", newline="") as handle:
                lines = handle.readlines()
        except OSError:
            continue
        except UnicodeDecodeError:
            print("%s\t\tleft as written: it is not readable text, so it was not searched" % name)
            continue
        changed = False
        fence = None
        for number, line in enumerate(lines, 1):
            opener = FENCE.match(line)
            if fence is None and opener:
                fence = opener.group(1)
                in_block = True
            elif fence is not None:
                in_block = True
                # A fence closes only on a run of the same mark at least as
                # long as the one that opened it, with nothing after it, so a
                # block shown inside a longer fence stays inside.
                closer = CLOSING_FENCE.match(line)
                if closer and closer.group(1)[0] == fence[0] and len(closer.group(1)) >= len(fence):
                    fence = None
            else:
                in_block = line.startswith("    ") or line.startswith("\t")
            found = list(findings(line, in_block, own))
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
            with open(path, "w", encoding="utf-8", newline="") as handle:
                handle.writelines(lines)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
