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
    upgrade-check.py --latest --route [PROJECT]  the version check and the
                                                 update command, either alone

`--latest` asks GitHub's `releases/latest` endpoint, the only one that cannot
answer with a draft or a prerelease, and prints `holds`, `latest` and
`compare` lines, then `say` lines with the words the person hears. The
versions are compared as numbers: `compare` is `same`, `newer` when a newer
release is published, or `ahead` when the project holds a version the latest
release has not reached, such as a preview, and `different` when the
installed version cannot be read. It exits 0 for `same` or `ahead`, 1 for
`newer` or `different`, and 3 when the latest could not be read: never say the project
is up to date then. `--route` prints a `route` line for each way the kit is
installed, with its update command, and a `then` line for a second command.
The shared route's command is `npx skills add`, never `npx skills update`. It
exits 4 when more than one route is active, so the person chooses one; with
`--latest` too, 4 wins and otherwise the version's code stands.

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
    template   FILE:LINE  NEW  the kit's own sentence naming a retired
                               command or skill                       template
    fitcheck   FILE:LINE  OLD  a build-path section with four-path
                               fields, rewritten as the maintain
                               skill's references/four-paths.md says  fitcheck
    recipe     FILE:LINE  NAME AGENTS.md naming its recipe by file,
                               as NAME.md, before recipes were
                               folders                                recipe
    ready      NUMBERS         open pieces shaped before the kit had
                               a `ready` label, so nothing builds
                               them                                   ready
    access     masterplan.md  WHY
                               no `Access:` line, which the recipe's
                               access check reads                     access

These are named, never changed, and do not count as left:

    mention    FILE:LINE  TEXT another line naming a retired command
    left       PATH  WHY       something that stays as it is
    secrets    AGENTS.md  WHY  no line refusing to show a secret, as
                               the founding template now has
    pointer lines ending in `left as written: WHY`
    command lists left as written that name no retired command or are links
    declined   STEP  ...       an offer the person said no to
    planfile   plan.md         the kit's old list of pieces, or the
                               person's own notes: only the agent can
                               tell. Printed with --monthly alone, and
                               never recorded, so it comes back on
                               every monthly visit while the file is
                               there.

After those lines come `say` lines, `say  STEP  SENTENCE`, one for each step
or kind printed. Each holds the plain sentence the person hears for it, so
the words come from here rather than from memory. They are never counted.
A `mention`, `left` or `secrets` sentence is said once: it is left out when
CHANGELOG.md already holds the line it names (for `secrets`, the
sentence itself), and on a visit without
--monthly once `.ai-build-kit-maintenance` records `upgrade-offered|` with
the installed version.

Exit codes: 1 while any line above the second list is printed, 0 when none
is, 2 when it could not run. A step the person declined prints as `declined`
until a run with `--monthly`, which offers it again. A declined safety rule
stays declined until a release adds a rule the no did not cover.

`--apply` runs the step's own tool: `helper` places the plan helper, `ready`
labels the shaped pieces `ready` on GitHub, `remove`
runs `kit-leftovers.py --remove`, `commands` runs `kit-leftovers.py
--rewrite-commands`, `pointers` runs `old-skill-pointers.py --apply`,
`settings` runs `settings-rules.py --apply`, `template` rewrites the one
sentence, `recipe` names the recipe by its folder in AGENTS.md and in the
check-up record's menu lines, and `access=private`, `access=open-address`
or `access=public` writes the masterplan's `Access:` line the person
chose. It changes nothing live. `--apply helper` and `--apply ready` also print a `say` line with
what changed. The installer's own steps, `installer` and `missing`, and the
`fitcheck` step, which the agent carries out, are never run from here. `--decline` writes `upgrade-declined|<date>|<steps>` into
`.ai-build-kit-maintenance`, keeping only steps that still have something
left, and passes a declined `settings` to `settings-rules.py --decline`.
"""

import datetime
import json
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

# The masterplan template's one sentence that named the old launch command, as
# every release from v0.17.0 to v0.19.3 wrote it. Only a line that matches it
# exactly is the kit's own text; any other line naming a retired command is the
# person's.
OLD_SENTENCE = "Where the tool runs on a server somebody else runs, /ship writes a hosting"
NEW_SENTENCE = "Where the tool runs on a server somebody else runs, /setup-hosting writes a hosting"
# The AGENTS.md template's lines that named a background skill folded into
# /shape or /implement, as the eleven-skill releases wrote them. Each entry is
# a block of lines that must all match, in order, as the kit wrote them, so a
# block whose neighbour line the person edited is theirs and is left alone.
# Each old line becomes one new line, so the file keeps its line count.
TEMPLATE_LINES = (
    ("masterplan.md", (OLD_SENTENCE,), (NEW_SENTENCE,)),
    ("AGENTS.md", ("The user describes intent in plain language; change-triage chooses the route.",),
     ("The user describes intent in plain language; `/shape` chooses the route.",)),
    ("AGENTS.md", ("piece has a subject label, set once by change-triage. `plan.local.md` prints the",),
     ("piece has a subject label, set once by `/shape`. `plan.local.md` prints the",)),
)


def template_blocks(name, lines):
    """(index, old, new) for each kit block found whole in a file's lines."""
    bodies = [line.rstrip("\r\n") for line in lines]
    found = []
    for file, old, new in TEMPLATE_LINES:
        if file != name:
            continue
        for index in range(len(bodies) - len(old) + 1):
            if tuple(bodies[index:index + len(old)]) == old:
                found.append((index, old, new))
    return sorted(found)

RETIRED = re.compile(r"(?<![\w/.-])/(fix|queue|sync|ship)(?![\w/-])")
MENTION_FILES = ("AGENTS.md", "masterplan.md")

STEP_OF = {
    "installer": "installer", "missing": "missing", "folder": "remove",
    "adapter": "remove", "kitcopy": "remove", "hook": "remove",
    "commands": "commands", "pointer": "pointers", "helper": "helper",
    "settings": "settings", "template": "template", "fitcheck": "fitcheck",
    "ready": "ready", "recipe": "recipe", "access": "access",
}
DECLINABLE = ("installer", "missing", "remove", "commands", "pointers", "settings", "template",
              "fitcheck", "recipe", "access")
# The build-path fields the kit used while it had four build paths.
FOUR_PATHS = re.compile(r"^\s*(Required controls:|Outside help:|Path:\s*(Build with expert help|Professional-led))")
APPLIABLE = ("helper", "ready", "remove", "commands", "pointers", "settings", "template",
             "recipe")

# A project founded before recipes became folders names its recipe by its file,
# as in `Recipe: <name>.md`. The kit reads that as the folder of the same
# name, so nothing waits on it, but the record says the folder now. The line
# may sit in a list item, in bold or in code quotes.
RECIPE_LINE = re.compile(r"^(\s*(?:[-*]\s+)?`?(?:\*\*)?Recipe:(?:\*\*)?\s*`?)([A-Za-z0-9_-]+)\.md(`?\s*)$")
RECIPES = os.path.join(INSTALLED, "setup-hosting", "recipes")

# The label /implement builds from, as founding creates it. A project founded
# before the kit split /build into /shape and /implement never had it, so none
# of its pieces carries it and /implement would build nothing.
READY = ("ready", "0e8a16", "Shaped and waiting to be built")
WAITING = ("needs-clarification", "needs-prototype", "needs-research")
DONE_WHEN = re.compile(r"^##\s+Done when\b", re.M)



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
    found = []
    for name in ("masterplan.md", "AGENTS.md"):
        if linked_path(project, name):
            found.append(("left", name, "it is a link, so it was left alone"))
            continue
        try:
            with open(os.path.join(project, name), encoding="utf-8", newline="") as handle:
                lines = handle.readlines()
        except (OSError, UnicodeDecodeError):
            continue
        for index, old, new in template_blocks(name, lines):
            found.append(("template", "%s:%d" % (name, index + 1), " ".join(new)))
    return found


def recipe_findings(project):
    """The AGENTS.md line naming the recipe by its old file name, where the
    installed kit holds that recipe as a folder."""
    if linked_path(project, "AGENTS.md"):
        return []
    try:
        with open(os.path.join(project, "AGENTS.md"), encoding="utf-8", newline="") as handle:
            lines = handle.read().splitlines()
    except (OSError, UnicodeDecodeError):
        return []
    for number, line in enumerate(lines, 1):
        found = RECIPE_LINE.match(line)
        if found and os.path.isfile(os.path.join(RECIPES, found.group(2), "recipe.md")):
            return [("recipe", "AGENTS.md:%d" % number, found.group(2))]
    return []


def apply_recipe(project):
    """Name the recipe by its folder in AGENTS.md, and in the check-up
    record's menu lines, which are the kit's own bookkeeping."""
    changed = False
    for finding in recipe_findings(project):
        path = os.path.join(project, "AGENTS.md")
        with open(path, encoding="utf-8", newline="") as handle:
            lines = handle.readlines()
        index = int(finding[1].split(":")[1]) - 1
        line = lines[index]
        ending = line[len(line.rstrip("\r\n")):]
        lines[index] = RECIPE_LINE.sub(lambda m: m.group(1) + m.group(2) + m.group(3),
                                       line.rstrip("\r\n")) + ending
        with open(path, "w", encoding="utf-8", newline="") as handle:
            handle.writelines(lines)
        print("recipe\t%s\t%s" % (finding[1], finding[2]))
        changed = True
    path = os.path.join(project, MAINTENANCE)
    if not linked_path(project, MAINTENANCE) and os.path.isfile(path):
        with open(path, encoding="utf-8", newline="") as handle:
            lines = handle.readlines()
        out = []
        for line in lines:
            if line.startswith(("founding-menu|", "recipe-move-declined|")):
                body = line.rstrip("\r\n")
                ending = line[len(body):]
                fields = body.split("|")
                fields[2:] = [",".join(n.strip()[:-3] if n.strip().endswith(".md") else n.strip()
                                       for n in re.split(r"[,\s]+", f) if n.strip())
                              for f in fields[2:]]
                line = "|".join(fields) + ending
            out.append(line)
        if out != lines:
            with open(path, "w", encoding="utf-8", newline="") as handle:
                handle.writelines(out)
    if changed:
        print("say\trecipe\tAGENTS.md now names the recipe by its folder, and nothing else in "
              "the file changed.")
    return 0


ACCESS_LINE = re.compile(r"^Access:\s*\S", re.M)
ACCESS_CHOICES = {"private": "Access: private",
                  "public": "Access: public (decided %s)",
                  "open-address": "Access: open address, invitation only (decided %s)"}
ACCESS_WORDS = ("This release makes every tool private by default: only people you invite can "
                "get in, and a check on the live tool proves it. Public is a setting you choose, "
                "and it is recorded with the date. Your masterplan does not say which this tool "
                "is. Should it be private; an open address with invitation only, which anyone "
                "can reach but only invited people can sign in to; or public? I "
                "record your answer, then run the access check, which changes nothing. Changing "
                "the live tool to match waits for a separate yes.")


def access_findings(project):
    """The masterplan's build path with no Access: line, as every project
    founded before the kit made tools private by default has it."""
    if linked_path(project, "masterplan.md"):
        return []
    text = read_text(os.path.join(project, "masterplan.md"))
    if not text or ACCESS_LINE.search(text):
        return []
    return [("access", "masterplan.md", "no access setting recorded")]


def apply_access(project, choice):
    """Write the Access: line the person chose into the build-path section:
    before its Sensitive areas: line, or after its Path: line, or under its
    heading. Nothing live changes."""
    if choice not in ACCESS_CHOICES:
        print("upgrade-check.py: the access step takes %s" % ", ".join(
            "access=" + c for c in ACCESS_CHOICES), file=sys.stderr)
        return 2
    if not access_findings(project):
        return 0
    line = ACCESS_CHOICES[choice]
    if "%s" in line:
        line = line % datetime.date.today().isoformat()
    path = os.path.join(project, "masterplan.md")
    with open(path, encoding="utf-8", newline="") as handle:
        lines = handle.readlines()
    ending = "\r\n" if lines and lines[0].endswith("\r\n") else "\n"
    start = next((i for i, l in enumerate(lines) if re.match(r"^##\s+Build path\b", l)), None)
    if start is None:
        print("left\tmasterplan.md\tit has no build-path section, so the access line was not written")
        return 1
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("## ")), len(lines))
    at = next((i for i in range(start + 1, end) if lines[i].startswith("Sensitive areas:")), None)
    if at is None:
        path_line = next((i for i in range(start + 1, end) if lines[i].startswith("Path:")), None)
        at = path_line + 1 if path_line is not None else start + 1
    lines.insert(at, line + ending)
    with open(path, "w", encoding="utf-8", newline="") as handle:
        handle.writelines(lines)
    print("access\tmasterplan.md:%d\t%s" % (at + 1, line))
    print("say\taccess\tThe masterplan now records %s. Next I run the access check, which "
          "changes nothing live." % line)
    return 0


def fitcheck_findings(project):
    try:
        with open(os.path.join(project, "masterplan.md"), encoding="utf-8", errors="replace") as handle:
            lines = handle.read().splitlines()
    except OSError:
        return []
    for number, line in enumerate(lines, 1):
        if FOUR_PATHS.match(line):
            return [("fitcheck", "masterplan.md:%d" % number, line.strip())]
    return []


def origin_repo(project):
    """OWNER/NAME of the GitHub repository `origin` names, or None."""
    try:
        result = subprocess.run(["git", "remote", "get-url", "origin"], cwd=project,
                                capture_output=True, text=True)
    except OSError:
        return None
    match = re.search(r"github\.com[:/]+([^/\s]+)/([^/\s]+?)(?:\.git)?/?$", result.stdout.strip(), re.I)
    if result.returncode != 0 or not match:
        return None
    return "%s/%s" % (match.group(1), match.group(2))


def gh_json(project, args):
    """GitHub's answer as data, or None when it could not be read."""
    try:
        result = subprocess.run(["gh"] + args, cwd=project, capture_output=True, text=True, timeout=120)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    try:
        return json.loads(result.stdout)
    except ValueError:
        return None


def unready_pieces(project):
    """The open pieces a project founded before /shape and /implement shaped
    but never labelled `ready`. Read from the project's own GitHub records,
    never from which skill folders are installed, so every install route and
    an edited folder are read alike. Empty when GitHub could not be read."""
    repo = origin_repo(project)
    if not repo or repo.lower() == KIT_REPO:
        return []
    labels = gh_json(project, ["label", "list", "--json", "name", "--limit", "1000"])
    if not isinstance(labels, list):
        return []
    if any(isinstance(l, dict) and l.get("name") == READY[0] for l in labels):
        return []
    issues = gh_json(project, ["issue", "list", "--state", "open", "--json", "number,labels,body",
                               "--limit", "1000"])
    if not isinstance(issues, list):
        return []
    shaped = []
    for issue in issues:
        if not isinstance(issue, dict):
            continue
        names = {l.get("name") for l in issue.get("labels") or [] if isinstance(l, dict)}
        if names & set(WAITING) or names & {"parked", READY[0]}:
            continue
        if DONE_WHEN.search(issue.get("body") or ""):
            shaped.append(issue.get("number"))
    return sorted(n for n in shaped if isinstance(n, int))


def ready_findings(project):
    numbers = unready_pieces(project)
    if not numbers:
        return []
    return [("ready", ",".join(str(n) for n in numbers))]


def planfile_findings(project, monthly):
    if monthly and os.path.isfile(os.path.join(project, "plan.md")):
        return [("planfile", "plan.md")]
    return []


# The founding template's line refusing to show a secret. An AGENTS.md written
# before it has no such line, so the agent is told once, and adds it on a yes.
REFUSAL = "show or read out a secret"
SECRETS_WORDS = ("Your AGENTS.md has no line telling me to refuse to show a secret, because "
                 "anything shown here stays in this conversation's record. I can add the kit "
                 "template's lines on that to your secrets section and change nothing else. "
                 "Shall I?")


def secrets_findings(project):
    if linked_path(project, "AGENTS.md"):
        return []
    try:
        with open(os.path.join(project, "AGENTS.md"), encoding="utf-8") as handle:
            text = " ".join(handle.read().split())
    except (OSError, UnicodeDecodeError):
        return []
    if REFUSAL in text:
        return []
    return [("secrets", "AGENTS.md", "no line refusing to show a secret")]


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
    found.extend(fitcheck_findings(project))
    found.extend(recipe_findings(project))
    found.extend(access_findings(project))
    found = ready_findings(project) + found
    # A line another step already names is not a mention as well.
    skip = {f[1] for f in found if f[0] in ("commands", "pointer", "template")}
    # Every line of a command list, its continuation included, belongs to
    # the commands step, even when it needs an agent edit.
    found.extend(mention_findings(project, skip | command_list_lines(project)))
    found.extend(secrets_findings(project))
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
    if kind in ("mention", "left", "declined", "planfile", "secrets"):
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
    found = findings(project) + planfile_findings(project, monthly)
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
    for step, sentence in sentences(said_once(out, project, monthly), project):
        print("say\t%s\t%s" % (step, sentence))
    return 1 if left else 0


def read_text(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            return handle.read()
    except OSError:
        return ""


def left_words(finding):
    return "%s, because %s" % (finding[1], finding[2])


def said_once(out, project, monthly):
    """The listing without the `mention` and `left` lines already said.

    Each is named once. The visit's changelog line keeps its sentence, so a
    line the changelog already holds was named on an earlier visit. Between
    monthly visits, an offer already made for this version is not repeated."""
    changelog = read_text(os.path.join(project, "CHANGELOG.md"))
    offered = False
    if not monthly:
        mark = "upgrade-offered|%s" % installed_version()
        offered = any(line.strip() == mark for line in
                      read_text(os.path.join(project, MAINTENANCE)).splitlines())
    kept = []
    for finding in out:
        if finding[0] == "mention" and (offered or finding[2] in changelog):
            continue
        if finding[0] == "left" and (offered or left_words(finding) in changelog):
            continue
        if finding[0] == "secrets" and (offered or SECRETS_WORDS in changelog):
            continue
        kept.append(finding)
    return kept

# --- the words the person hears ----------------------------------------------

RETIRED_NAMES = ("fix", "queue", "sync", "ship")
# The background skills renamed after the six commands: `change-triage` is now
# `triage` and `section-builder` is now `build-piece`. A project founded on
# v0.20.3 has only these to hear about.
FOLDED = ("change-triage", "section-builder")


def names_skill(text, name):
    return re.search(r"`/?%s`|(?<![\w/.-])/%s(?![\w/-])" % (re.escape(name), re.escape(name)),
                     text) is not None


def names_retired(text):
    """True when a line of the command list names one of the four retired commands."""
    return any(names_skill(text, name) for name in RETIRED_NAMES)
# The commands renamed before the six, each with the skills that replaced it
# and the sentence the person hears once.
RENAMED = (
    ("build", ("implement",),
     "The old /build command has become two: /shape turns a new idea into a ready piece, and "
     "/implement builds one. Nothing you saved is lost; only the command names changed."),
    ("start", ("setup-ai-build-kit",),
     "The command that founds a project is now /setup-ai-build-kit, not /start. Founding runs "
     "once, so nothing you saved changes. A saved command that updates the kit by name uses "
     "the new name."),
    ("plan", ("shape",),
     "/shape is the command that turns an idea into a ready piece. It does everything /plan "
     "did. A saved note or shortcut that types /plan still needs changing by hand."),
)
SIX = ("The kit now has six commands. /fix and /queue are part of /shape and /implement, "
       "/sync is part of /maintain, and /ship is now /setup-hosting. Nothing you built has "
       "changed. A saved note or shortcut that types an old command still needs changing by hand.")


def joined(items):
    items = list(items)
    if len(items) < 2:
        return "".join(items)
    return ", ".join(items[:-1]) + " and " + items[-1]


def rule_words(key, rule):
    """What one safety rule stops, in plain words."""
    if key == "ask":
        if "merge" in rule.lower():
            return "a merge with no click from you"
        return "a change to a live service or a deletion on GitHub with no question first"
    if "--no-verify" in rule:
        return "a push that skips the push guard"
    if "git push" in rule and "main" in rule:
        return "a push straight to main in any spelling"
    if "git push" in rule:
        return "a force push"
    if rule.startswith("Bash(rm "):
        return "a forced delete"
    if rule.startswith(("Bash(security ", "Bash(gh auth token", "Read(")):
        return "reading the stored login of another tool"
    return "throwing away unsaved changes"


def files_of(findings):
    return joined(sorted({f[1].split(":")[0] for f in findings}))


def plural(count, one, many):
    return one if count == 1 else many


def sentences(out, project):
    """(step, sentence) for each step or kind in the listing, in offer order."""
    by = {}
    for finding in out:
        by.setdefault(finding[0], []).append(finding)
    said = []
    retired = any(
        (f[0] in ("installer", "folder") and f[1].rsplit("/", 1)[-1] in RETIRED_NAMES)
        or (f[0] == "missing" and f[1] == "setup-hosting")
        or (f[0] == "adapter" and os.path.splitext(f[1].rsplit("/", 1)[-1])[0] in RETIRED_NAMES)
        or (f[0] == "template" and f[2] == NEW_SENTENCE)
        or (f[0] == "commands" and not informational(f) and names_retired(f[2]))
        for f in out)
    for old, new, words in RENAMED:
        if any((f[0] in ("installer", "folder") and f[1].rsplit("/", 1)[-1] == old)
               or (f[0] == "adapter" and os.path.splitext(f[1].rsplit("/", 1)[-1])[0] == old)
               or (f[0] == "missing" and f[1] in new)
               or (f[0] == "ready" and old == "build")
               for f in out):
            said.append(("renamed", words))
    if retired:
        said.append(("kit", SIX))
    if "ready" in by:
        n = len(by["ready"][0][1].split(","))
        said.append(("ready", "%d %s shaped before the kit had a ready label, so /implement "
                     "would never build %s. I am marking %s ready now, and changing nothing "
                     "else on them." % (n, plural(n, "piece was", "pieces were"),
                                        plural(n, "it", "them"), plural(n, "it", "them"))))
    if "installer" in by:
        names = [f[1] for f in by["installer"]]
        said.append(("installer", "The old skills %s are still installed beside the new ones. The "
                     "installer removes them, with their links and their lockfile entries: "
                     "`npx skills remove %s`. Shall I run it?" % (joined(names), " ".join(names))))
    if "missing" in by:
        names = [f[1] for f in by["missing"]]
        said.append(("missing", "The update did not bring %s. Running `%s` again adds %s. "
                     "Shall I run it?" % (joined(names), SHARED, plural(len(names), "it", "them"))))
    removable = [f for f in out if f[0] in ("folder", "adapter", "kitcopy", "hook")]
    if removable:
        n = len(removable)
        said.append(("remove", "%d %s from an older copy of the kit %s still here: %s. Removing "
                     "%s shows each command once and stops the kit's own files describing an "
                     "older kit. Your own files stay. Shall I remove %s?" % (
                         n, plural(n, "file or folder", "files or folders"), plural(n, "is", "are"),
                         joined(f[1] for f in removable), plural(n, "it", "them"),
                         plural(n, "it", "them"))))
    rewrite = [f for f in by.get("commands", []) if not f[-1].startswith("left as written:")]
    by_hand = [f for f in by.get("commands", [])
               if f[-1].startswith("left as written:") and not informational(f)]
    if rewrite:
        folded = [n for n in FOLDED if any(names_skill(f[2], n) for f in rewrite)]
        if any(names_retired(f[2]) for f in rewrite):
            what = "still names old commands"
        elif folded:
            what = ("still names the background %s %s, which the kit has since renamed"
                    % (plural(len(folded), "skill", "skills"), joined(folded)))
        else:
            what = "still counts the skills of an older release"
        said.append(("commands", "The command list in AGENTS.md %s. I can bring it up to this "
                     "release's six commands and its background skills, and change "
                     "nothing else in the file. Shall I?" % what))
    if by_hand:
        said.append(("commands", "The command list in AGENTS.md still names old commands, and it "
                     "holds words of your own, so the script leaves it. I can replace those "
                     "lines with the current list and keep your sentences. Shall I?"))
    pointers = [f for f in by.get("pointer", []) if not f[-1].startswith("left as written:")]
    kept = [f for f in by.get("pointer", []) if f[-1].startswith("left as written:")]
    # A pointer through the skills folder is one kind; a pointer that already
    # names its skill, to a file that moved to another skill or a skill that
    # was renamed, is the other. Each hears the sentence that is true of it.
    by_folder = [f for f in pointers if ".agents/skills/" in f[2]]
    moved = [f for f in pointers if ".agents/skills/" not in f[2]]
    if by_folder:
        n = len(by_folder)
        said.append(("pointers", "%d %s in %s %s at a kit file through a folder some "
                     "installations do not have. I can name the skill instead, and each line "
                     "keeps its sentence: %s becomes %s. Shall I?" % (
                         n, plural(n, "line", "lines"), files_of(by_folder),
                         plural(n, "points", "point"), by_folder[0][2], by_folder[0][3])))
    if moved:
        n = len(moved)
        said.append(("pointers", "%d %s in %s %s at a kit file that has moved to another "
                     "skill, or to a skill the kit has renamed. I can point %s at the new "
                     "home, and each line keeps its sentence: %s becomes %s. Shall I?" % (
                         n, plural(n, "line", "lines"), files_of(moved),
                         plural(n, "points", "point"), plural(n, "it", "them"),
                         moved[0][2], moved[0][3])))
    if kept:
        n = len(kept)
        said.append(("pointers", "%s left as written: %s. %s yours to change if you want." % (
            plural(n, "One pointer to a kit file is", "%d pointers to kit files are" % n),
            "; ".join("%s, because %s" % (f[1], f[-1][len("left as written: "):]) for f in kept),
            plural(n, "It is", "They are"))))
    if "settings" in by:
        stops = []
        for f in by["settings"]:
            words = rule_words(f[1], f[2])
            if words not in stops:
                stops.append(words)
        n = len(by["settings"])
        said.append(("settings", "Your Claude Code settings are missing %d newer safety %s. "
                     "They stop %s. I add only those lines and change nothing else in the file. "
                     "The setup-ai-build-kit skill's references/blocked-commands.md lists what "
                     "the rules still cannot catch. Shall I add them?" % (
                         n, plural(n, "rule", "rules"), joined(stops))))
    if "template" in by:
        n = len(by["template"])
        files = sorted({f[1].split(":")[0] for f in by["template"]})
        said.append(("template", "%s still %s %d %s the kit wrote that %s an old command or "
                     "skill. I can change %s to today's wording, and nothing else." % (
                         " and ".join(files), plural(len(files), "holds", "hold"), n,
                         plural(n, "passage", "passages"), plural(n, "names", "name"),
                         plural(n, "that passage", "those passages"))))
    if "fitcheck" in by:
        said.append(("fitcheck", "Your masterplan's build-path section was written when the kit "
                     "had four build paths. It now has three, and the path follows what the "
                     "work touches rather than who owns the build. I can rewrite the section "
                     "to the new shape and show it to you above the old one first. Each "
                     "accepted risk is copied word for word, and nothing else in the "
                     "masterplan changes. Shall I?"))
    if "recipe" in by:
        name = by["recipe"][0][2]
        said.append(("recipe", "AGENTS.md names its recipe the old way, as the file %s.md. "
                     "Recipes are folders now, so that line would read Recipe: %s. The kit "
                     "reads either, so nothing waits on it. I can change that one line and "
                     "nothing else. Shall I?" % (name, name)))
    if "access" in by:
        said.append(("access", ACCESS_WORDS))
    if "mention" in by:
        n = len(by["mention"])
        said.append(("mention", "%s still %s an old command in your own words: %s. %s yours to "
                     "change, and I leave %s as written." % (
                         plural(n, "This line", "These lines"), plural(n, "names", "name"),
                         "; ".join('%s, "%s"' % (f[1], f[2]) for f in by["mention"]),
                         plural(n, "It is", "They are"), plural(n, "it", "them"))))
    if "secrets" in by:
        said.append(("secrets", SECRETS_WORDS))
    if "left" in by:
        said.append(("left", "These stay as they are: %s." % "; ".join(
            left_words(f) for f in by["left"])))
    if "planfile" in by:
        said.append(("planfile", "This project still keeps pieces in plan.md, which nothing reads "
                     "any more, so they are not picked up until they move into issues. I can "
                     "open one issue for each row and remove plan.md once they are all there. "
                     "Shall I? If you say no, I ask again on the next monthly visit."))
    for f in by.get("declined", []):
        if f[1] == "settings":
            words = ("You said no to the newer safety rules. I offer them again only when a "
                     "release adds another.")
        else:
            words = ("You chose to leave %s for now. The next monthly visit offers it again."
                     % STEP_WORDS.get(f[1], f[1]))
        if ("declined", words) not in said:
            said.append(("declined", words))
    return said


STEP_WORDS = {
    "installer": "the old skills installed", "missing": "the missing skills out",
    "remove": "the older kit files in place", "commands": "the command list as it is",
    "pointers": "the old pointers as they are", "template": "the kit's old lines as they are",
    "fitcheck": "the build-path section as it is",
    "recipe": "the recipe line as it is",
    "access": "the access setting unrecorded",
}

HELPER_WORDS = (
    ("added", "I have added the helper that prints your list of pieces, so /what-now and "
              "/implement read what is ready from it."),
    ("replaced", "I have brought the helper that prints your list of pieces up to date. Any change "
                 "made to the old copy by hand was replaced too, and the checkpoint saved first "
                 "keeps it."),
    ("made runnable", "I have made the helper that prints your list of pieces runnable again."),
)


# --- changing -----------------------------------------------------------------

def apply_template(project):
    for name in ("masterplan.md", "AGENTS.md"):
        if linked_path(project, name):
            print("left\t%s\tit is a link, so it was left alone" % name)
            continue
        path = os.path.join(project, name)
        try:
            with open(path, encoding="utf-8", newline="") as handle:
                lines = handle.readlines()
        except (OSError, UnicodeDecodeError):
            continue
        blocks = template_blocks(name, lines)
        for index, old, new in blocks:
            for offset, text in enumerate(new):
                line = lines[index + offset]
                lines[index + offset] = text + line[len(line.rstrip("\r\n")):]
        if blocks:
            with open(path, "w", encoding="utf-8", newline="") as handle:
                handle.writelines(lines)
    return 0


def apply_ready(project):
    """Label `ready` every open piece shaped before the kit had that label.

    It reads the pieces again rather than trusting an earlier listing, creates
    the label as founding does, and adds it to each piece. A piece that waits
    on a question, or is parked, is left for /shape. Once the label exists the
    listing finds nothing, so a second run changes nothing."""
    numbers = unready_pieces(project)
    if not numbers:
        return 0
    try:
        made = subprocess.run(["gh", "label", "create", READY[0], "--color", READY[1],
                               "--description", READY[2], "--force"],
                              cwd=project, capture_output=True, text=True)
    except OSError:
        print("upgrade-check.py: the GitHub command line tool is not installed", file=sys.stderr)
        return 2
    if made.returncode != 0:
        print("upgrade-check.py: GitHub refused the ready label: %s" % made.stderr.strip(),
              file=sys.stderr)
        return 1
    marked, failed = [], []
    for number in numbers:
        result = subprocess.run(["gh", "issue", "edit", str(number), "--add-label", READY[0]],
                                cwd=project, capture_output=True, text=True)
        (marked if result.returncode == 0 else failed).append(str(number))
    for number in marked:
        print("ready\t%s\tmarked" % number)
    for number in failed:
        print("ready\t%s\tnot marked" % number)
    n = len(marked)
    if n:
        print("say\tready\tI have marked %d %s ready, so /implement builds %s. Your backlog is "
              "all still there." % (n, plural(n, "piece", "pieces"), plural(n, "it", "them")))
    if failed:
        print("say\tready\tGitHub did not take the ready label on %s, so %s still %s. The next "
              "visit tries again." % (joined("#" + f for f in failed),
                                      plural(len(failed), "that piece", "those pieces"),
                                      plural(len(failed), "waits", "wait")))
        return 1
    return 0


def apply(project, step):
    if step == "helper":
        if not os.path.isfile(PLACE_HELPER):
            print("upgrade-check.py: the installed setup-ai-build-kit skill has no place-plan-helper.sh",
                  file=sys.stderr)
            return 2
        result = subprocess.run(["sh", PLACE_HELPER, project], capture_output=True, text=True)
        sys.stdout.write(result.stdout)
        sys.stderr.write(result.stderr)
        if result.returncode == 0:
            for word, sentence in HELPER_WORDS:
                if word in result.stdout:
                    print("say\thelper\t%s" % sentence)
                    break
        return result.returncode
    if step == "ready":
        return apply_ready(project)
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
    if step == "recipe":
        return apply_recipe(project)
    if step.startswith("access="):
        return apply_access(project, step[len("access="):])
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


# --- the version and the route ------------------------------------------------

KIT_REPO = "gwpicard/ai-build-kit"
SHARED = "npx skills add %s" % KIT_REPO
VERSION_FILE = os.path.join(os.path.dirname(HERE), "VERSION")


def installed_version():
    """The version of the kit installed beside this script. The monthly part
    asks for it before it updates anything, so it is the version the project
    holds at that moment."""
    try:
        with open(VERSION_FILE, encoding="utf-8") as handle:
            return handle.read().strip() or "unknown"
    except OSError:
        return "unknown"


def version_key(version):
    """A version as numbers, so v0.10.0 sorts after v0.9.0. A preview sorts
    before the release of the same number. None when it is not a version."""
    match = re.fullmatch(r"v?(\d+)\.(\d+)\.(\d+)(-[0-9A-Za-z.-]+)?", version.strip())
    if not match:
        return None
    return (int(match.group(1)), int(match.group(2)), int(match.group(3)),
            0 if match.group(4) else 1)


def latest():
    """Print what this project holds and the latest published release.

    Only `releases/latest` is asked: it is the one endpoint that cannot answer
    with a draft or a prerelease. Exit 0 when they match or the project is
    ahead, 1 when a newer one is published, 3 when the latest could not be
    read.
    """
    held = installed_version()
    print("holds\t%s" % held)
    unknown = ("say\tversion\tThe version check did not happen, because %s. I cannot say whether "
               "this project is up to date.")
    try:
        result = subprocess.run(["gh", "api", "repos/%s/releases/latest" % KIT_REPO,
                                 "--jq", ".tag_name"], capture_output=True, text=True)
    except OSError:
        print("latest\tunknown\tthe GitHub command line tool is not installed")
        print(unknown % "the GitHub command line tool is not installed")
        return 3
    tag = result.stdout.strip()
    if result.returncode != 0 or not re.fullmatch(r"v?\d+\.\d+\.\d+", tag):
        why = (result.stderr.strip().splitlines() or ["GitHub gave no release"])[-1]
        print("latest\tunknown\t%s" % why)
        print(unknown % "GitHub did not name the latest release")
        return 3
    print("latest\t%s" % tag)
    both = "This project holds %s, and the latest published AI Build Kit is %s." % (held, tag)
    mine, theirs = version_key(held), version_key(tag)
    if mine is not None and mine == theirs:
        print("compare\tsame")
        print("say\tversion\t%s It is on the latest release." % both)
        return 0
    if mine is not None and mine > theirs:
        print("compare\tahead")
        print("say\tversion\t%s This project is ahead of the latest release, so there is "
              "nothing newer to install." % both)
        return 0
    print("compare\t%s" % ("newer" if mine is not None else "different"))
    print("say\tversion\t%s A newer AI Build Kit is available. It refreshes the installed "
          "workflow skills. Your tool, project records and project instructions remain yours."
          % both)
    return 1


def claude_plugin_scope(project):
    """The scope of the ai-build-kit Claude plugin enabled for this project, or
    None. A local or project install records the folder it belongs to, and one
    for another folder does not count."""
    try:
        result = subprocess.run(["claude", "plugin", "list", "--json"],
                                capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    try:
        data = json.loads(result.stdout)
    except ValueError:
        return None
    entries = data if isinstance(data, list) else data.get("plugins", []) if isinstance(data, dict) else []
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        ident = entry.get("id") or entry.get("name") or ""
        if ident != "ai-build-kit@ai-build-kit" or not entry.get("enabled", True):
            continue
        where = entry.get("projectPath")
        if where and os.path.realpath(where) != os.path.realpath(project):
            continue
        return entry.get("scope") or "user"
    return None


def agent_plugin_here():
    """True when this skill runs from an Agent Plugins folder named ai-build-kit."""
    manifest = os.path.join(os.path.dirname(INSTALLED), "plugin.json")
    try:
        with open(manifest, encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return False
    return isinstance(data, dict) and data.get("name") == "ai-build-kit"


def shared_lock(project):
    try:
        with open(os.path.join(project, "skills-lock.json"), encoding="utf-8") as handle:
            return KIT_REPO in handle.read()
    except OSError:
        return False


def route(project):
    """Print the route this project receives the kit by, and its update
    command. Exit 0 for one route, 4 when more than one is active, so the
    person chooses which to keep. The shared route's command is always `add`,
    never `update`, which drops any skill the lockfile does not list yet."""
    routes = []
    if shared_lock(project):
        routes.append(("shared", [SHARED]))
    scope = claude_plugin_scope(project)
    if scope:
        routes.append(("claude-plugin", ["claude plugin marketplace update ai-build-kit",
                                         "claude plugin update ai-build-kit@ai-build-kit --scope %s" % scope]))
    if agent_plugin_here():
        routes.append(("agent-plugin", ["the coding agent's own plugin update command, or the "
                                        "agent-plugin folder from the latest published Release"]))
    if not routes:
        routes.append(("older", [SHARED]))
    for name, commands in routes:
        print("route\t%s\t%s" % (name, commands[0]))
        for command in commands[1:]:
            print("then\t%s" % command)
    return 4 if len(routes) > 1 else 0


def usage(message=None):
    if message:
        print("upgrade-check.py: %s" % message, file=sys.stderr)
    print("usage: upgrade-check.py [--monthly | --apply STEP | --decline STEPS | --latest | --route] [PROJECT]",
          file=sys.stderr)
    return 2


def main(argv):
    monthly = want_latest = want_route = False
    apply_step = decline_steps = None
    rest = []
    args = list(argv)
    while args:
        arg = args.pop(0)
        if arg == "--monthly":
            monthly = True
        elif arg == "--latest":
            want_latest = True
        elif arg == "--route":
            want_route = True
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
    if (want_latest or want_route) and (monthly or apply_step or decline_steps is not None):
        return usage("--latest and --route go together or alone")
    project = os.path.abspath(rest[0] if rest else ".")
    if not founded(project):
        print("upgrade-check.py: %s holds no masterplan.md, so it is not a founded project" % project,
              file=sys.stderr)
        return 2
    if want_latest or want_route:
        code = latest() if want_latest else 0
        if want_route and route(project) == 4:
            return 4
        return code
    for script in (LEFTOVERS, POINTERS, SETTINGS):
        if not os.path.isfile(script):
            print("upgrade-check.py: %s is missing beside it" % os.path.basename(script), file=sys.stderr)
            return 2
    try:
        if apply_step:
            if apply_step not in APPLIABLE and not apply_step.startswith("access="):
                if apply_step == "access":
                    return usage("say which: access=private, access=open-address or access=public")
                if apply_step in ("installer", "missing", "fitcheck"):
                    return usage("that step is not run from here: its say line says who carries it out")
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
