#!/usr/bin/env python3
"""Check Codex GitHub access without printing credentials or changing a file."""
import argparse
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys


def project_root(start=None):
    path = Path(start or Path.cwd()).resolve()
    for folder in (path, *path.parents):
        if (folder / "AGENTS.md").is_file() or (folder / ".git").exists():
            return folder
    return path


def launcher_path(project=None, skill=None):
    project = project_root(project)
    candidates = [Path(skill)] if skill else []
    candidates += [project / prefix / "setup-ai-build-kit" for prefix in
                   (".agents/skills", ".claude/skills", "agent-plugin/skills")]
    pointer = project / ".agents/tools/codex-setup-path"
    if pointer.is_file():
        candidates.append(Path(pointer.read_text().strip()))
    here = Path(__file__).resolve()
    if here.parent.name == "foundation":
        candidates.append(here.parents[2])
    for candidate in candidates:
        launcher = candidate / "scripts/codex-with-github.py"
        if launcher.is_file() and (candidate / "SKILL.md").is_file():
            return launcher.resolve()
    return None


def restart_message(project=None, skill=None, session_start=False):
    launcher = launcher_path(project, skill)
    if launcher is None:
        return "This session cannot reach GitHub. Install AI Build Kit again in this project, then start Codex with its launcher."
    command = "python3 " + shlex.quote(str(launcher))
    if session_start:
        return "This session cannot reach GitHub. Quit and start Codex with: " + command
    return "Codex cannot read the GitHub sign-in on this Mac; do not sign in again, quit and start Codex with: " + command


def authenticated():
    env = dict(os.environ)
    env.pop("GH_DEBUG", None)
    env.pop("DEBUG", None)
    try:
        result = subprocess.run(["gh", "auth", "status", "--hostname", "github.com"],
                                env=env, capture_output=True, timeout=15)
        return result.returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--launcher", action="store_true")
    parser.add_argument("--message", action="store_true")
    parser.add_argument("--hook", action="store_true")
    parser.add_argument("--skill")
    args = parser.parse_args()
    project = project_root()
    if args.hook:
        try:
            project = project_root(json.load(sys.stdin).get("cwd"))
        except (ValueError, TypeError):
            pass
    if args.launcher:
        launcher = launcher_path(project, args.skill)
        if launcher is None:
            return 1
        print(launcher)
        return 0
    if args.message:
        print(restart_message(project, args.skill))
        return 0
    if authenticated():
        return 0
    message = restart_message(project, args.skill, session_start=True)
    if args.hook:
        print(json.dumps({"continue": False, "systemMessage": message,
                          "stopReason": message}))
        return 0
    print(message)
    return 1


if __name__ == "__main__":
    sys.exit(main())
