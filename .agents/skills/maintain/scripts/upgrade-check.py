#!/usr/bin/env python3
"""Read everything a kit update leaves for /maintain to finish, in one pass.

An update refreshes the kit's skills and nothing else. What it leaves behind,
such as an old skill the installer kept, a command list naming retired
commands, an older plan helper or older safety rules, is finished by
/maintain. This is the one read that says whether anything is left. It
changes nothing unless it is asked to apply one named step.

Usage:

    upgrade-check.py [--monthly] [PROJECT]       list what is left
    upgrade-check.py --apply STEP [PROJECT]      apply one step
    upgrade-check.py --decline STEPS [PROJECT]   record a no, STEPS separated
                                                 by commas

PROJECT defaults to the current folder, which must hold a masterplan.md.

Each line has fields separated by tabs. The first field says what it is, and
the step that settles it:

    installer  NAME  COMMAND   an old skill the installer kept       installer
    missing    NAME            one of the kit's skills not installed  missing
    folder     PATH            a retired skill folder                 remove
    adapter    PATH            a generated command file or folder     remove
    kitcopy    PATH            a kit file a whole copy brought        remove
    hook       PATH            an older session-end hook              remove
    commands   FILE:LINE  OLD  NEW
                               the command list or its counts         commands
    pointer    FILE:LINE  OLD  NEW
                               a pointer to a skill's file            pointers
    helper     PATH  WHY       the plan printout helper               helper
    settings   deny|ask  RULE  a missing Claude Code safety rule      settings
    template   FILE:LINE  NEW  the kit's own sentence naming /ship    template

These are named, never changed, and do not count as left:

    mention    FILE:LINE  TEXT another line naming a retired command
    left       PATH  WHY       something that stays as it is
    pointer lines ending in `left as written: WHY`
    command lists left as written that name no retired command or are links
    declined   STEP  ...       an offer the person said no to

Exit codes: 1 while any line above the second list is printed, 0 when none
is, 2 when it could not run. A step the person declined prints as `declined`
until a run with `--monthly`, which offers it again. A declined safety rule
stays declined until a release adds a rule the no did not cover.

`--apply` runs the step's own tool: `helper` places the plan helper, `remove`
runs `kit-leftovers.py --remove`, `commands` runs `kit-leftovers.py
--rewrite-commands`, `pointers` runs `old-skill-pointers.py --apply`,
`settings` runs `settings-rules.py --apply`, and `template` rewrites the one
sentence. The installer's own steps, `installer` and `missing`, are never run
from here. `--decline` writes `upgrade-declined|<date>|<steps>` into
`.ai-build-kit-maintenance`, keeping only steps that still have something
left, and passes a declined `settings` to `settings-rules.py --decline`.
"""

import datetime
import runpy
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
INSTALLED = os.path.dirname(os.path.dirname(HERE))
LEFTOVERS = os.path.join(HERE, "kit-leftovers.py")
POINTERS = os.path.join(HERE, "old-skill-pointers.py")
SETTINGS = os.path.join(HERE, "settings-rules.py")
SETUP = os.path.join(INSTALLED, "setup-ai-build-kit")
HELPER_TEMPLATE = os.path.join(SETUP, *"templates/foundation/plan-refresh.sh".split("/"))
PLACE_HELPER = os.path.join(SETUP, "scripts", "place-plan-helper.sh")
HELPER = ".agents/tools/plan-refresh.sh"
MAINTENANCE = ".ai-build-kit-maintenance"
DECLINED = "upgrade-declined|"

# The masterplan template's one sentence that named /ship, as every release
# from v0.17.0 to v0.19.3 wrote it. Only a line that matches it exactly is the
# kit's own text; any other line naming a retired command is the person's.
OLD_SENTENCE = "Where the tool runs on a server somebody else runs, /ship writes a hosting"
NEW_SENTENCE = "Where the tool runs on a server somebody else runs, /setup-hosting writes a hosting"

RETIRED = re.compile(r"(?<![\w/.-])/(fix|queue|sync|ship)(?![\w/-])")
MENTION_FILES = ("AGENTS.md", "masterplan.md")

STEP_OF = {
    "installer": "installer", "missing": "missing", "folder": "remove",
    "adapter": "remove", "kitcopy": "remove", "hook": "remove",
    "commands": "commands", "pointer": "pointers", "helper": "helper",
    "settings": "settings", "template": "template",
}
DECLINABLE = ("installer", "missing", "remove", "commands", "pointers", "settings", "template")
APPLIABLE = ("helper", "remove", "commands", "pointers", "settings", "template")



def linked_path(project, relative):
    current = os.path.abspath(project)
    for part in relative.split("/"):
        current = os.path.join(current, part)
        if os.path.islink(current):
            return True
    return False

def run(command, project):
    result = subprocess.run(command, cwd=project, capture_output=True, text=True)
    return result.returncode, [l for l in result.stdout.splitlines() if l.strip()]


def python(script, *args):
    return [sys.executable, script] + list(args)


# --- reading ------------------------------------------------------------------

def helper_finding(project):
    if not os.path.isfile(HELPER_TEMPLATE):
        return []
    path = os.path.join(project, HELPER)
    if os.path.islink(path):
        return [("left", HELPER, "it is a link, so it was left alone")]
    if not os.path.exists(path):
        return [("helper", HELPER, "missing")]
    if not os.path.isfile(path):
        return [("left", HELPER, "it is not a file, so it was left alone")]
    with open(path, "rb") as mine, open(HELPER_TEMPLATE, "rb") as shipped:
        if mine.read() != shipped.read():
            return [("helper", HELPER, "older than the installed copy")]
    if not os.access(path, os.X_OK):
        return [("helper", HELPER, "not runnable")]
    for companion in ("codex-github-check.py", "codex-setup-path"):
        relative = ".agents/tools/" + companion
        target = os.path.join(project, relative)
        if linked_path(project, relative) or (os.path.exists(target) and not os.path.isfile(target)):
            return [("left", relative, "it is a link or not a file, so it was left alone")]
        expected = ((os.path.realpath(SETUP) + "\n").encode() if companion == "codex-setup-path" else
                    open(os.path.join(SETUP, "templates", "foundation", companion), "rb").read())
        if not os.path.isfile(target) or open(target, "rb").read() != expected:
            return [("helper", HELPER, "GitHub recovery helper needs refreshing")]
    return []


def template_findings(project):
    if linked_path(project, "masterplan.md"):
        return [("left", "masterplan.md", "it is a link, so it was left alone")]
    path = os.path.join(project, "masterplan.md")
    found = []
    try:
        with open(path, encoding="utf-8", newline="") as handle:
            lines = handle.readlines()
    except (OSError, UnicodeDecodeError):
        return found
    for number, line in enumerate(lines, 1):
        if line.rstrip("\r\n") == OLD_SENTENCE:
            found.append(("template", "masterplan.md:%d" % number, NEW_SENTENCE))
    return found


def mention_findings(project, skip):
    found = []
    for name in MENTION_FILES:
        try:
            with open(os.path.join(project, name), encoding="utf-8", errors="replace") as handle:
                lines = handle.read().splitlines()
        except OSError:
            continue
        for number, line in enumerate(lines, 1):
            where = "%s:%d" % (name, number)
            if where in skip or not RETIRED.search(line):
                continue
            found.append(("mention", where, line.strip()))
    return found


def findings(project):
    found = []
    code, lines = run(python(LEFTOVERS, project), project)
    if code != 0:
        raise RuntimeError("kit-leftovers.py could not run")
    for line in lines:
        found.append(tuple(line.split("\t")))
    code, lines = run(python(POINTERS, project), project)
    if code != 0:
        raise RuntimeError("old-skill-pointers.py could not run")
    for line in lines:
        found.append(("pointer",) + tuple(line.split("\t")))
    found.extend(helper_finding(project))
    code, lines = run(python(SETTINGS, project), project)
    if code not in (0, 1):
        raise RuntimeError("settings-rules.py could not run")
    for line in lines:
        fields = tuple(line.split("\t"))
        if fields[0] == "declined":
            found.append(("declined", "settings") + fields[1:])
        elif fields[0] == "left":
            found.append(fields)
        else:
            found.append(("settings",) + fields)
    templates = template_findings(project)
    found.extend(templates)
    # A line another step already names is not a mention as well.
    skip = {f[1] for f in found if f[0] in ("commands", "pointer", "template")}
    # Every line of a command list, its continuation included, belongs to
    # the commands step, even when it needs an agent edit.
    found.extend(mention_findings(project, skip | command_list_lines(project)))
    return found


def command_list_lines(project):
    try:
        with open(os.path.join(project, "AGENTS.md"), encoding="utf-8", errors="replace") as handle:
            lines = handle.read().splitlines()
    except OSError:
        return set()
    leftovers = runpy.run_path(LEFTOVERS)
    return {"AGENTS.md:%d" % (index + 1)
            for begin, end in leftovers["command_blocks"](lines)
            for index in range(begin, end)}


def informational(finding):
    kind = finding[0]
    if kind in ("mention", "left", "declined"):
        return True
    if kind == "commands" and finding[-1].startswith("left as written:"):
        return finding[-1].startswith("left as written: it is a link") or not re.search(
            r"`/?(?:fix|queue|sync|ship)`|(?<![\w/.-])/(?:fix|queue|sync|ship)(?![\w/-])", finding[2])
    if kind == "pointer" and finding[-1].startswith("left as written:"):
        return True
    return False


def declined_steps(project):
    try:
        with open(os.path.join(project, MAINTENANCE), encoding="utf-8") as handle:
            for line in handle.read().splitlines():
                if line.startswith(DECLINED):
                    parts = line.split("|", 2)
                    if len(parts) == 3:
                        return {s.strip() for s in parts[2].split(",") if s.strip()}
    except (OSError, UnicodeDecodeError):
        pass
    return set()


def founded(project):
    return os.path.isfile(os.path.join(project, "masterplan.md"))


def listing(project, monthly):
    found = findings(project)
    declined = set() if monthly else declined_steps(project)
    left = False
    out = []
    for finding in found:
        if not informational(finding) and STEP_OF.get(finding[0]) in declined \
                and finding[0] != "settings":
            out.append(("declined", STEP_OF[finding[0]]) + finding)
            continue
        if not informational(finding):
            left = True
        out.append(finding)
    for finding in out:
        print("\t".join(finding))
    return 1 if left else 0


# --- changing -----------------------------------------------------------------

def apply_template(project):
    if linked_path(project, "masterplan.md"):
        print("left\tmasterplan.md\tit is a link, so it was left alone")
        return 0
    path = os.path.join(project, "masterplan.md")
    with open(path, encoding="utf-8", newline="") as handle:
        lines = handle.readlines()
    changed = False
    for index, line in enumerate(lines):
        body = line.rstrip("\r\n")
        if body == OLD_SENTENCE:
            lines[index] = NEW_SENTENCE + line[len(body):]
            changed = True
    if changed:
        with open(path, "w", encoding="utf-8", newline="") as handle:
            handle.writelines(lines)
    return 0


def apply(project, step):
    if step == "helper":
        if not os.path.isfile(PLACE_HELPER):
            print("upgrade-check.py: the installed setup-ai-build-kit skill has no place-plan-helper.sh",
                  file=sys.stderr)
            return 2
        result = subprocess.run(["sh", PLACE_HELPER, project])
        return result.returncode
    if step == "remove":
        return subprocess.run(python(LEFTOVERS, "--remove", project)).returncode
    if step == "commands":
        return subprocess.run(python(LEFTOVERS, "--rewrite-commands", project)).returncode
    if step == "pointers":
        return subprocess.run(python(POINTERS, "--apply", project)).returncode
    if step == "settings":
        return subprocess.run(python(SETTINGS, "--apply", project)).returncode
    if step == "template":
        return apply_template(project)
    return 2


def decline(project, steps):
    if linked_path(project, MAINTENANCE):
        print("left\t%s\tit is a link, so it was left alone" % MAINTENANCE)
        return 0
    found = findings(project)
    still = {STEP_OF.get(f[0]) for f in found if not informational(f)}
    if "settings" in steps and "settings" in still:
        subprocess.run(python(SETTINGS, "--decline", project), check=False)
    keep = sorted(((declined_steps(project) | set(steps)) & still) - {"settings"})
    path = os.path.join(project, MAINTENANCE)
    try:
        with open(path, encoding="utf-8", newline="") as handle:
            lines = handle.readlines()
    except OSError:
        lines = []
    ending = "\r\n" if lines and lines[0].endswith("\r\n") else "\n"
    kept = [l for l in lines if not l.startswith(DECLINED)]
    if kept and not kept[-1].endswith(("\n", "\r")):
        kept[-1] += ending
    if keep:
        kept.append(DECLINED + datetime.date.today().isoformat() + "|" + ",".join(keep) + ending)
    if kept != lines:
        with open(path, "w", encoding="utf-8", newline="") as handle:
            handle.writelines(kept)
    return 0


def usage(message=None):
    if message:
        print("upgrade-check.py: %s" % message, file=sys.stderr)
    print("usage: upgrade-check.py [--monthly | --apply STEP | --decline STEPS] [PROJECT]",
          file=sys.stderr)
    return 2


def main(argv):
    monthly = False
    apply_step = decline_steps = None
    rest = []
    args = list(argv)
    while args:
        arg = args.pop(0)
        if arg == "--monthly":
            monthly = True
        elif arg in ("--apply", "--decline"):
            if not args:
                return usage("%s needs a step" % arg)
            value = args.pop(0)
            if arg == "--apply":
                apply_step = value
            else:
                decline_steps = [s.strip() for s in value.split(",") if s.strip()]
        elif arg.startswith("--"):
            return usage("unknown option %s" % arg)
        else:
            rest.append(arg)
    if len(rest) > 1 or (apply_step and decline_steps is not None):
        return usage()
    project = os.path.abspath(rest[0] if rest else ".")
    if not founded(project):
        print("upgrade-check.py: %s holds no masterplan.md, so it is not a founded project" % project,
              file=sys.stderr)
        return 2
    for script in (LEFTOVERS, POINTERS, SETTINGS):
        if not os.path.isfile(script):
            print("upgrade-check.py: %s is missing beside it" % os.path.basename(script), file=sys.stderr)
            return 2
    try:
        if apply_step:
            if apply_step not in APPLIABLE:
                if apply_step in ("installer", "missing"):
                    return usage("the installer does that step: see the line's own command")
                return usage("unknown step %s" % apply_step)
            return apply(project, apply_step)
        if decline_steps is not None:
            unknown = [s for s in decline_steps if s not in DECLINABLE]
            if unknown or not decline_steps:
                return usage("a step that can be declined is one of %s" % ", ".join(DECLINABLE))
            return decline(project, decline_steps)
        return listing(project, monthly)
    except RuntimeError as error:
        print("upgrade-check.py: %s" % error, file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
