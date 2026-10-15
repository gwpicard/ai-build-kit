#!/usr/bin/env python3
"""Bring the test check into a founded project's check on pull requests.

Founding copies `check-tests.sh` into `.agents/hooks/` and a step that runs it
into `.github/workflows/checks.yml`, with a checkout that fetches the whole
history so the step can read every commit in the pull request. A project
founded before that has neither, and an update refreshes skills only, so its
check never rejects a silent edit to one of its tests. /maintain runs this in
the truing, offers what it prints once, and runs it with --apply on a yes.

Usage, from the project root:

    place-trim-check.py              say what is missing; change nothing
    place-trim-check.py --apply      add what is missing
    place-trim-check.py --decline    record the person's no

Without an option it prints one line for each thing missing:

    hook     .agents/hooks/check-tests.sh is missing or older than the kit's
    step     the project check has no step that runs it
    history  the checkout fetches only the last commit

Exit codes:

    0  nothing is missing, the project has no check on pull requests, or
       the person said no before (it prints `declined` then); --apply and
       --decline exit 0 once done
    1  something is missing; the lines say what
    2  it could not run, or --apply could not find the checkout step to
       place the new step after, and changed nothing

--apply copies the hook from this skill, sets `fetch-depth: 0` on the
project-check job's checkout step, and adds the test check straight after it.
It changes nothing else in the file. --decline writes
`tests-check-declined|<date>|<fingerprint of the kit's hook>` into
`.ai-build-kit-maintenance`, keeping every other line. A later run then
prints `declined` and exits 0, until a release changes the kit's hook.
"""

import datetime
import hashlib
import os
import re
import shutil
import sys

SKILL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE = os.path.join(SKILL, "templates", "foundation", "check-tests.sh")
HOOK = os.path.join(".agents", "hooks", "check-tests.sh")
WORKFLOW = os.path.join(".github", "workflows", "checks.yml")
RECORD = ".ai-build-kit-maintenance"
STEP = ["- name: Check tests were not changed silently",
        "  run: sh .agents/hooks/check-tests.sh"]


def read(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except OSError:
        return None


def checkout_step(lines):
    """(first, last, dash column) of the project-check job's checkout step, or None."""
    job = next((i for i, l in enumerate(lines) if re.match(r"^\s*project-check:\s*$", l)), None)
    if job is None:
        return None
    job_indent = len(lines[job]) - len(lines[job].lstrip())
    for i in range(job + 1, len(lines)):
        text = lines[i]
        if text.strip() and len(text) - len(text.lstrip()) <= job_indent:
            return None
        m = re.match(r"^(\s*)- uses:\s*actions/checkout@", text)
        if not m:
            continue
        dash = len(m.group(1))
        last = i
        for j in range(i + 1, len(lines)):
            other = lines[j]
            if not other.strip():
                continue
            indent = len(other) - len(other.lstrip())
            if indent < dash or (indent == dash and other.lstrip().startswith("- ")):
                break
            last = j
        return i, last, dash
    return None


def missing(text, hook, template):
    found = []
    if hook != template:
        found.append(("hook", HOOK + " is missing or older than the kit's"))
    if "check-tests.sh" not in text:
        found.append(("step", "the project check has no step that runs " + HOOK))
    lines = text.split("\n")
    place = checkout_step(lines)
    deep = place and any(re.match(r"^\s*fetch-depth:\s*0\s*$", l)
                         for l in lines[place[0]:place[1] + 1])
    if not deep:
        found.append(("history", "the checkout fetches only the last commit"))
    return found


def apply(text):
    """The workflow with the history and the step added, or None when it cannot be placed."""
    lines = text.split("\n")
    place = checkout_step(lines)
    if place is None:
        return None
    first, last, dash = place
    block = lines[first:last + 1]
    pad = " " * (dash + 2)
    depth = next((k for k, l in enumerate(block) if re.match(r"^\s*fetch-depth:", l)), None)
    if depth is not None:
        indent = block[depth][:len(block[depth]) - len(block[depth].lstrip())]
        block[depth] = indent + "fetch-depth: 0"
    else:
        with_line = next((k for k, l in enumerate(block) if re.match(r"^\s*with:\s*$", l)), None)
        if with_line is not None:
            block.insert(with_line + 1, pad + "  fetch-depth: 0")
        else:
            block += [pad + "with:", pad + "  fetch-depth: 0"]
    result = lines[:first] + block + lines[last + 1:]
    result = [line.replace("Check the trim left the tests alone", STEP[0].removeprefix("- name: "))
                  .replace("sh .agents/hooks/check-trim.sh", "sh .agents/hooks/check-tests.sh")
              for line in result]
    text = "\n".join(result)
    if "check-tests.sh" not in text:
        # Place the step after checkout, where the full history is available.
        updated = text.split("\n")
        place = checkout_step(updated)
        if place is None:
            return None
        first, last, dash = place
        updated[last + 1:last + 1] = [" " * dash + STEP[0], " " * dash + STEP[1]]
        text = "\n".join(updated)
    return text


def fingerprint(template):
    return hashlib.sha256(template.encode("utf-8")).hexdigest()[:12]


def declined(template):
    """True while a recorded no covers the kit's present copy of the hook."""
    record = read(RECORD) or ""
    if re.search(r"^trim-check-declined\|", record, re.M):
        return True
    match = re.search(r"^tests-check-declined\|\d{4}-\d{2}-\d{2}\|(\w+)$", record, re.M)
    return bool(match) and match.group(1) == fingerprint(template)


def main():
    option = sys.argv[1] if len(sys.argv) > 1 else ""
    if option not in ("", "--apply", "--decline") or len(sys.argv) > 2:
        print("usage: place-trim-check.py [--apply | --decline]", file=sys.stderr)
        return 2
    template = read(TEMPLATE)
    if template is None:
        print("the installed setup-ai-build-kit skill carries no check-tests.sh to copy", file=sys.stderr)
        return 2
    text = read(WORKFLOW)
    if text is None:
        return 0
    if os.path.islink(HOOK) or os.path.islink(WORKFLOW):
        print("the hook or the workflow is a link, so it was left alone", file=sys.stderr)
        return 2
    found = missing(text, read(HOOK), template)

    if option == "--decline":
        record = [l for l in (read(RECORD) or "").splitlines() if not l.startswith("tests-check-declined|")]
        record.append("tests-check-declined|%s|%s" % (datetime.date.today().isoformat(),
                                                     fingerprint(template)))
        with open(RECORD, "w", encoding="utf-8") as handle:
            handle.write("\n".join(record) + "\n")
        print("declined")
        return 0

    if option == "--apply":
        if any(kind in ("step", "history") for kind, _ in found):
            changed = apply(text)
            if changed is None:
                print("the project-check job has no checkout step to place the test check after, "
                      "so nothing was changed", file=sys.stderr)
                return 2
            with open(WORKFLOW, "w", encoding="utf-8") as handle:
                handle.write(changed)
        # Remove the retired trim hook so founded projects have one test-path guard.
        old_hook = ".agents/hooks/check-trim.sh"
        if os.path.isfile(old_hook) and not os.path.islink(old_hook):
            os.unlink(old_hook)
        if any(kind == "hook" for kind, _ in found):
            os.makedirs(os.path.dirname(HOOK), exist_ok=True)
            shutil.copyfile(TEMPLATE, HOOK)
            os.chmod(HOOK, 0o755)
        for kind, _ in found:
            print("added\t" + kind)
        return 0

    if not found:
        return 0
    if declined(template):
        print("declined")
        return 0
    for kind, why in found:
        print(f"{kind}\t{why}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
