#!/usr/bin/env python3
"""Run the project-check steps on this computer, on a clean copy of one commit.

merge.py uses this only when GitHub did not start the check because of a
billing limit. It reads jobs.project-check from the commit's own checks.yml and
runs each `run:` step as GitHub would for a pull request. A `uses:` step is
skipped: this computer's own tools stand in for it. Anything it does not
understand stops it before a step runs.

Usage: local-check.py <head commit> <base commit> <pull request number>
Exit 0 every step passed, 1 a step failed, 2 the check could not run.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

WORKFLOW = ".github/workflows/checks.yml"
STEP_KEYS = {"name", "id", "if", "uses", "with", "env", "run", "shell",
             "working-directory", "timeout-minutes"}
JOB_KEYS = {"runs-on", "steps", "name", "timeout-minutes", "permissions"}
STEP_TIMEOUT = 30 * 60
EXPRESSION = re.compile(r"\$\{\{\s*(.*?)\s*\}\}")


class CannotRun(Exception):
    pass


def git(*args, cwd=None):
    return subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)


def scalar(text):
    text = text.strip()
    if len(text) >= 2 and text[0] == text[-1] and text[0] in "'\"":
        return text[1:-1]
    return text


def indent(line):
    return len(line) - len(line.lstrip(" "))


def read_steps(text):
    """The steps of jobs.project-check, in the plain shape the kit writes."""
    lines = [line.rstrip("\n") for line in text.splitlines()]

    def child(start, name, depth):
        for at in range(start, len(lines)):
            line = lines[at]
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            if indent(line) < depth:
                break
            if indent(line) == depth and line.strip() == name + ":":
                return at
        return None

    jobs = child(0, "jobs", 0)
    if jobs is None:
        raise CannotRun("the checks file has no jobs")
    job = next((at for at in range(jobs + 1, len(lines))
                if lines[at].strip() == "project-check:"), None)
    if job is None:
        raise CannotRun("the checks file has no project-check job")
    depth = indent(lines[job])
    keys, body = set(), []
    for at in range(job + 1, len(lines)):
        line = lines[at]
        if line.strip() and not line.lstrip().startswith("#") and indent(line) <= depth:
            break
        body.append((at, line))
    key_depth = min((indent(line) for _, line in body if line.strip()), default=None)
    for _, line in body:
        if line.strip() and indent(line) == key_depth and ":" in line:
            keys.add(line.strip().split(":", 1)[0])
    if keys - JOB_KEYS:
        raise CannotRun("project-check uses job settings this check cannot copy: " +
                        ", ".join(sorted(keys - JOB_KEYS)))
    start = next((at for at, line in body
                  if indent(line) == key_depth and line.strip() == "steps:"), None)
    if start is None:
        raise CannotRun("project-check has no steps")

    steps, step, at = [], None, start + 1
    item_depth = None
    while at < len(lines):
        line = lines[at]
        if not line.strip() or line.lstrip().startswith("#"):
            at += 1
            continue
        if indent(line) <= key_depth:
            break
        stripped = line.strip()
        if stripped.startswith("- "):
            item_depth = indent(line)
            step = {}
            steps.append(step)
            line = " " * (item_depth + 2) + stripped[2:]
        if step is None or item_depth is None:
            raise CannotRun("the steps are not a plain list")
        if indent(line) != item_depth + 2 or ":" not in line:
            raise CannotRun("a step is written in a shape this check cannot read")
        key, value = line.strip().split(":", 1)
        value = value.strip()
        if key not in STEP_KEYS:
            raise CannotRun("a step uses a setting this check cannot copy: " + key)
        at += 1
        if value in ("|", "|-"):
            block = []
            while at < len(lines) and (not lines[at].strip() or indent(lines[at]) > item_depth + 2):
                block.append(lines[at])
                at += 1
            depth_here = min((indent(b) for b in block if b.strip()), default=0)
            step[key] = "\n".join(b[depth_here:] for b in block).strip("\n") + "\n"
        elif value == "":
            mapping = {}
            while at < len(lines) and (not lines[at].strip() or indent(lines[at]) > item_depth + 2):
                entry = lines[at].strip()
                at += 1
                if not entry or entry.startswith("#"):
                    continue
                if ":" not in entry:
                    raise CannotRun("a step setting is written in a shape this check cannot read")
                name, setting = entry.split(":", 1)
                mapping[name.strip()] = scalar(setting)
            step[key] = mapping
        elif value[0] in "|>[{&*!":
            raise CannotRun("a step uses a written form this check cannot read: " + key)
        else:
            step[key] = scalar(value)
    if not steps:
        raise CannotRun("project-check has no steps")
    return steps


def value_of(name, context):
    name = name.strip()
    if len(name) >= 2 and name[0] == name[-1] == "'":
        return name[1:-1]
    if name in context:
        return context[name]
    found = re.fullmatch(r"steps\.([\w-]+)\.outputs\.([\w-]+)", name)
    if found:
        return context["outputs"].get(found.group(1), {}).get(found.group(2), "")
    raise CannotRun("the checks file uses a value this check cannot supply: " + name)


def evaluate(expression, context):
    """The small set of expressions the kit's checks file uses."""
    expression = expression.strip()
    found = re.fullmatch(r"(.+?)\s*(==|!=)\s*(.+)", expression)
    if found:
        same = value_of(found.group(1), context) == value_of(found.group(3), context)
        return same if found.group(2) == "==" else not same
    for part in expression.split("||"):
        result = value_of(part, context)
        if result:
            return result
    return ""


def substitute(text, context):
    return EXPRESSION.sub(lambda m: str(evaluate(m.group(1), context)), text)


def condition(text, context):
    inner = EXPRESSION.fullmatch(text.strip())
    result = evaluate(inner.group(1) if inner else text, context)
    if not isinstance(result, bool):
        raise CannotRun("a step condition is not a plain comparison: " + text)
    return result


def run_steps(steps, copy, context, log):
    shell = shutil.which("bash")
    if not shell:
        raise CannotRun("bash is not installed on this computer")
    for number, step in enumerate(steps, 1):
        name = step.get("name") or step.get("uses") or "step %d" % number
        if "uses" in step:
            if "run" in step:
                raise CannotRun("a step both uses an action and runs a command")
            if not str(step["uses"]).startswith("actions/checkout@"):
                print("local-check: skipped %s; this computer's own tools stand in" % name)
            continue
        if "if" in step and not condition(step["if"], context):
            print("local-check: skipped %s; its condition is false for a pull request" % name)
            continue
        if step.get("shell", "bash") not in ("bash", "sh"):
            raise CannotRun("a step uses a shell this check cannot copy: " + step["shell"])
        if not isinstance(step.get("run"), str):
            raise CannotRun("a step has nothing to run: " + name)
        env = dict(os.environ)
        env.update(CI="true", GITHUB_EVENT_NAME="pull_request",
                   GITHUB_WORKSPACE=str(copy))
        outputs = Path(tempfile.mkstemp(prefix="output-", dir=copy.parent)[1])
        env["GITHUB_OUTPUT"] = str(outputs)
        for key, setting in (step.get("env") or {}).items():
            if setting.replace(" ", "") == "${{github.token}}":
                continue
            env[key] = substitute(setting, context)
        script = substitute(step["run"], context)
        here = copy / step.get("working-directory", ".")
        args = [shell, "--noprofile", "--norc", "-eo", "pipefail", "-c", script]
        if step.get("shell") == "sh":
            args = ["sh", "-e", "-c", script]
        log.write("\n== %s\n" % name)
        log.flush()
        try:
            done = subprocess.run(args, cwd=here, env=env, stdout=log, stderr=log,
                                  stdin=subprocess.DEVNULL, timeout=STEP_TIMEOUT)
        except subprocess.TimeoutExpired:
            print("local-check: %s did not finish in 30 minutes" % name)
            return 1
        except OSError as error:
            raise CannotRun("%s could not start: %s" % (name, error))
        if done.returncode:
            print("local-check: %s failed with exit %d" % (name, done.returncode))
            return 1
        if "id" in step:
            context["outputs"][step["id"]] = dict(
                line.split("=", 1) for line in outputs.read_text().splitlines() if "=" in line)
        print("local-check: passed %s" % name)
    return 0


def main(argv):
    if len(argv) != 3 or not argv[2].isdigit():
        print("usage: local-check.py <head commit> <base commit> <pull request number>",
              file=sys.stderr)
        return 2
    head, base, number = argv
    shown = git("show", head + ":" + WORKFLOW)
    if shown.returncode:
        print("local-check: could not read %s at %s" % (WORKFLOW, head[:12]), file=sys.stderr)
        return 2
    common = git("rev-parse", "--git-common-dir")
    if common.returncode:
        print("local-check: could not find the project's Git folder", file=sys.stderr)
        return 2
    log_path = (Path.cwd() / common.stdout.strip()).resolve() / "ai-build-kit-local-check.log"
    context = {
        "github.event_name": "pull_request",
        "github.event.pull_request.number": number,
        "github.event.pull_request.base.sha": base,
        "github.event.pull_request.head.sha": head,
        "github.event.before": "",
        "github.event.after": "",
        "outputs": {},
    }
    work = Path(tempfile.mkdtemp(prefix="ai-build-kit-local-check-"))
    copy = work / "copy"
    try:
        steps = read_steps(shown.stdout)
        added = git("worktree", "add", "--quiet", "--detach", str(copy), head)
        if added.returncode:
            raise CannotRun("could not make a clean copy of " + head[:12])
        with open(log_path, "w", encoding="utf-8") as log:
            code = run_steps(steps, copy, context, log)
        print("local-check: full output is in " + str(log_path))
        return code
    except CannotRun as error:
        print("local-check: " + str(error), file=sys.stderr)
        return 2
    finally:
        git("worktree", "remove", "--force", str(copy))
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
