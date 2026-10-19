#!/usr/bin/env python3
"""Upload the current piece branch and open its pull request against main.

Usage: upload-piece.py --title TITLE (--body TEXT | --body-file FILE) [PROJECT]
       upload-piece.py --title-file FILE (--body TEXT | --body-file FILE) [PROJECT]

PROJECT defaults to the current folder. Origin names the GitHub repository.
An open pull request to main for this branch is reported without changing anything.
The body always reaches GitHub through --body-file, without a shell.

Exit codes:
    0  uploaded, or an open pull request already exists
    2  invalid arguments, folder or branch (main is refused)
    3  remote main is missing: use first-upload.py
    4  push guard: the push would change main or replace remote work
    5  GitHub sign-in or repository access was refused
    6  GitHub is unavailable or its answer could not be read
    7  the secret scan found a secret
    8  Git could not complete the push for another reason
    9  the secret scan could not run
   10  Git would not run the kit's push guard

Tool errors are classified without printing their raw text or credentials.
A Codex password failure gives the installed sign-in helper's message and
stops without signing in or retrying.
"""

import argparse
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

spec = importlib.util.spec_from_file_location("first_upload", Path(__file__).with_name("first-upload.py"))
first_upload = importlib.util.module_from_spec(spec)
spec.loader.exec_module(first_upload)


def run(project, *args, input=None):
    env = dict(os.environ)
    env.pop("GH_DEBUG", None)
    env.pop("GIT_TRACE", None)
    env.pop("GIT_CURL_VERBOSE", None)
    return subprocess.run(args, cwd=project, capture_output=True, text=True, env=env, input=input)


def stopped(code, why):
    print("stopped\t" + why)
    return code


def report(project, text):
    scanner = project / ".agents/hooks/scan-secrets.sh"
    scanned = run(project, "sh", str(scanner), "--text", "upload report", input=text)
    print(text if scanned.returncode == 0 else "[output hidden: the secret check did not pass]")


def failure(project, result, push=False):
    error = (result.stderr + result.stdout).lower()
    if "unable to get password from user" in error:
        helper = Path(__file__).resolve().parents[2] / "setup-ai-build-kit/templates/foundation/codex-github-check.py"
        message = run(project, sys.executable, str(helper), "--message")
        if message.stdout:
            report(project, message.stdout.strip())
        return stopped(5, "GitHub sign-in could not be read; stop without signing in or retrying")
    if "secret scan found a secret" in error:
        return stopped(7, "the secret scan found a secret")
    if "secret scan could not run" in error:
        return stopped(9, "the secret scan could not run")
    if "would change main directly" in error:
        return stopped(4, "the push guard refused a change to main directly")
    if any(word in error for word in ("would replace work", "non-fast-forward", "fetch first")):
        return stopped(4, "the push guard refused replacing remote work")
    if result.returncode == 4 or any(word in error for word in (
            "gh auth login", "authentication failed", "permission denied", "http 401", "http 403",
            "bad credentials", "not logged", "write access", "could not read username",
            "resource not accessible", "denied to", "not authorized", "access denied",
            "could not read password")):
        return stopped(5, "GitHub sign-in or repository access was refused")
    if any(word in error for word in ("could not resolve host", "could not resolve hostname",
                                     "connection refused", "connection timed out", "http 5")):
        return stopped(6, "GitHub is unavailable")
    return stopped(8 if push else 6, "Git could not complete the push" if push else "GitHub is unavailable")


def upload(args):
    project = Path(args.project).resolve()
    branch = run(project, "git", "symbolic-ref", "-q", "HEAD")
    if branch.returncode or not branch.stdout.strip().startswith("refs/heads/"):
        return stopped(2, "check out the piece's own branch; main cannot be uploaded here")
    branch = branch.stdout.strip()[len("refs/heads/"):]
    if branch == "main":
        return stopped(2, "check out the piece's own branch; main cannot be uploaded here")
    origin = run(project, "git", "config", "--get", "remote.origin.url")
    name = first_upload.name_from_url(origin.stdout.strip())
    if not name or name.lower() == first_upload.KIT:
        return stopped(2, "origin must name the project's own GitHub repository")
    title = Path(args.title_file).read_text(encoding="utf-8").strip() if args.title_file else args.title
    body = Path(args.body_file).read_text(encoding="utf-8") if args.body_file else args.body
    if not title.strip():
        return stopped(2, "the pull request title is empty")
    setup = Path(__file__).resolve().parents[2] / "setup-ai-build-kit"
    scanner = project / ".agents/hooks/scan-secrets.sh"
    for label, value in (("pull request title", title), ("pull request body", body)):
        scanned = run(project, "sh", str(scanner), "--text", label, input=value)
        if scanned.returncode:
            return stopped(7 if scanned.returncode == 1 else 9,
                           "the secret scan found a secret in the " + label if scanned.returncode == 1
                           else "the secret scan could not run")
    remote = run(project, "git", "ls-remote", "--exit-code", "--heads", "origin", "refs/heads/main")
    if remote.returncode == 2:
        return stopped(3, "remote main is missing; use first-upload.py")
    if remote.returncode:
        return failure(project, remote)
    existing = run(project, "gh", "pr", "list", "--repo", name, "--head", branch,
                   "--base", "main", "--state", "open", "--json", "url")
    if existing.returncode:
        return failure(project, existing)
    try:
        pulls = json.loads(existing.stdout)
        if not isinstance(pulls, list):
            raise ValueError()
        if pulls:
            report(project, "existing\t" + pulls[0]["url"])
            return 0
    except (ValueError, KeyError, TypeError):
        return stopped(6, "GitHub's pull request answer could not be read")
    guard = run(project, "sh", str(setup / "scripts/use-push-guard.sh"), "--check", str(project))
    if guard.returncode:
        return stopped(10, "the push guard is not on; run use-push-guard.sh from the project folder")
    # Use a complete refspec so push.default and remote.origin.push cannot
    # select main, another branch, or a set of branches.
    ref = "refs/heads/" + branch
    pushed = run(project, "git", "push", "-u", "origin", ref + ":" + ref)
    if pushed.returncode:
        return failure(project, pushed, push=True)
    report(project, "pushed\t" + branch)
    with tempfile.TemporaryDirectory(prefix="kit-upload-") as folder:
        body_file = Path(folder) / "body.md"
        body_file.write_text(body, encoding="utf-8")
        created = run(project, "gh", "pr", "create", "--repo", name, "--base", "main",
                      "--head", branch, "--title", title, "--body-file", str(body_file))
    if created.returncode:
        return failure(project, created)
    report(project, "opened\t" + created.stdout.strip())
    return 0


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    titles = parser.add_mutually_exclusive_group(required=True)
    titles.add_argument("--title")
    titles.add_argument("--title-file")
    bodies = parser.add_mutually_exclusive_group(required=True)
    bodies.add_argument("--body")
    bodies.add_argument("--body-file")
    parser.add_argument("project", nargs="?", default=".")
    args = parser.parse_args(argv)
    try:
        return upload(args)
    except (OSError, UnicodeError) as error:
        return stopped(6 if isinstance(error, FileNotFoundError) and error.filename in ("gh", "git") else 2,
                       "a required tool, folder or input file could not be read")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
