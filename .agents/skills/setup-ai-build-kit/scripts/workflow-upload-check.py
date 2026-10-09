#!/usr/bin/env python3
"""Warn about a known missing workflow permission without changing the login."""
import argparse
import importlib.util
import os
from pathlib import Path
import re
import subprocess
import sys

check_file = Path(__file__).resolve().parents[1] / "templates/foundation/codex-github-check.py"
spec = importlib.util.spec_from_file_location("codex_github_check", check_file)
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)
launcher_path = check.launcher_path


def read_command(command):
    env = dict(os.environ)
    env.pop("GH_DEBUG", None)
    env.pop("DEBUG", None)
    try:
        result = subprocess.run(command, env=env, capture_output=True,
                                text=True, timeout=15)
        return result.stdout + result.stderr if result.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""


def missing_workflow(status, origin):
    # An SSH push does not use the token whose scopes gh reports.
    if origin and not origin.startswith("https://github.com/"):
        return False
    if re.search(r"Git operations protocol:\s*ssh\b", status, re.I):
        return False
    match = re.search(r"Token scopes:[ \t]*([^\r\n]*)", status)
    if match is None:
        return False
    scopes = set(re.findall(r"[a-zA-Z0-9_:.-]+", match.group(1)))
    # Fine-grained tokens and unreadable scope lists are unknown.
    return bool(scopes) and "workflow" not in scopes


def recovery_message(codex=False):
    message = ("Before uploading the automated checks, run gh auth refresh -h github.com -s workflow "
               "in your own terminal; it opens the browser once to allow the upload.")
    if codex:
        import shlex
        launcher = launcher_path(skill=Path(__file__).resolve().parents[1])
        if launcher:
            message += (" Then quit and restart Codex with: python3 " + shlex.quote(str(launcher)) +
                        "; the launcher reads your login when the session starts.")
    return message


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--status-stdin", action="store_true")
    parser.add_argument("--refused", action="store_true")
    parser.add_argument("--codex", action="store_true")
    args = parser.parse_args()
    status = sys.stdin.read() if args.status_stdin else ""
    if not args.refused:
        origin = read_command(["git", "remote", "get-url", "--push", "origin"]).strip()
        if not args.status_stdin:
            status = read_command(["gh", "auth", "status", "--active", "--hostname", "github.com"])
        if not missing_workflow(status, origin):
            return 0
    codex = args.codex or bool(os.environ.get("CODEX_THREAD_ID") or os.environ.get("CODEX_SANDBOX"))
    print(recovery_message(codex))
    return 1


if __name__ == "__main__":
    sys.exit(main())
