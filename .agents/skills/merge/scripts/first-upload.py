#!/usr/bin/env python3
"""Say whether a push is the project's first upload, and make it with approval.

Founding tells the person nothing will be uploaded, so the first push of the
project's code requires their approval. Whether a push is that first upload is a
fact about the remote, so this script reads it rather than leaving it to
memory.

Usage:

    first-upload.py [PROJECT]                         read only
    first-upload.py --approved [--branch B] [PROJECT] make the first upload

PROJECT defaults to the current folder. The repository is the one `origin`
names. The GitHub tool's own default repository is never used, since it can
be another remote, such as the one a project was copied from. The read prints
lines with fields separated by tabs:

    repository  OWNER/NAME | unknown
    visibility  private | public | internal | unknown
    state       STATE  [WHY]

and exits with the state's code:

    0  online         main is on the remote and shares history with the local
                      main: push as usual
    3  first-upload   the repository has no branch: ask for approval naming the
                      upload, then run again with --approved
    4  holds-other    the repository has branches, none sharing history with
                      main: push nothing and ask the person
    5  unknown        the remote could not be read, origin is not on GitHub,
                      or the GitHub tool cannot write to the repository: keep
                      the work here and note the step that did not happen
    6  kit            origin is the kit's own repository: push nothing and ask
                      for the person's own
    9  no-main        a branch from this project is online but main is not,
                      because an earlier first upload stopped halfway: ask
                      for approval to create main, then run again with --approved
    2                 usage error

Before it says first-upload or no-main, it checks that the GitHub tool is
signed in and may write to the repository. Without that, the state is
unknown, so nothing is pushed that could leave a branch online with no main.

With --approved, in the first-upload state, it pushes the piece's branch (the
current branch unless --branch names one) as a command of its own, creates
main on GitHub at the commit that branch was cut from, and makes main the
default branch. In the no-main state it pushes nothing and only creates main
and makes it the default. It never pushes main. Exit 0 means the code is online.
A protection failure leaves the upload complete. GitHub Free's private plan
limit is recorded, with one explanation shared with founding. Other failures
say why protection could not be set. Exit 7 means
the push failed and nothing was created; exit 8 means main could not be created.
Exit 10 means Git would not run the kit's push guard.
In any other state --approved changes nothing and exits with that state's code.
"""

import json
import os
from pathlib import Path
import re
import subprocess
import sys

KIT = "gwpicard/ai-build-kit"
CODES = {"online": 0, "first-upload": 3, "holds-other": 4, "unknown": 5, "kit": 6,
         "no-main": 9}
WRITERS = ("ADMIN", "MAINTAIN", "WRITE")


def run(*args, cwd):
    result = subprocess.run(list(args), cwd=cwd, capture_output=True, text=True)
    return result.returncode, result.stdout.strip(), result.stderr.strip()


def name_from_url(url):
    match = re.search(r"github\.com[:/]+([^/\s]+)/([^/\s]+?)(?:\.git)?/?$", url, re.I)
    return "%s/%s" % (match.group(1), match.group(2)) if match else None


def access(project, name):
    """(visibility, may_write, why) for the named repository."""
    code, out, err = run("gh", "repo", "view", name, "--json", "visibility,viewerPermission",
                         cwd=project)
    if code != 0:
        why = (err.splitlines() or ["GitHub could not be read"])[-1]
        return "unknown", False, "the GitHub tool could not read %s: %s" % (name, why)
    try:
        data = json.loads(out)
    except ValueError:
        return "unknown", False, "GitHub's answer about %s could not be read" % name
    visibility = (data.get("visibility") or "unknown").lower()
    permission = (data.get("viewerPermission") or "").upper()
    if permission not in WRITERS:
        return visibility, False, "the GitHub tool may not write to %s" % name
    return visibility, True, ""


def state_of(project):
    """(state, why, name, visibility)."""
    # The URL as written, before any insteadOf rewrite, is the one that names
    # the repository on GitHub.
    code, url, _ = run("git", "config", "--get", "remote.origin.url", cwd=project)
    if code != 0 or not url:
        return "unknown", "there is no origin", None, "unknown"
    name = name_from_url(url)
    if name and name.lower() == KIT:
        return "kit", "origin is the kit's own repository", KIT, "unknown"
    if not name:
        return "unknown", "origin does not point at a GitHub repository", None, "unknown"
    visibility, may_write, why_not = access(project, name)
    code, out, err = run("git", "ls-remote", "--exit-code", "--heads", "origin", cwd=project)
    if code == 2:
        if not may_write:
            return "unknown", why_not, name, visibility
        return "first-upload", "", name, visibility
    if code != 0:
        why = (err.splitlines() or ["the remote could not be listed"])[-1]
        return "unknown", why, name, visibility
    remote_main = any(line.endswith("\trefs/heads/main") for line in out.splitlines())
    code, _, err = run("git", "fetch", "-q", "--prune", "origin", cwd=project)
    if code != 0:
        return "unknown", "the remote could not be fetched", name, visibility
    code, main, _ = run("git", "rev-parse", "-q", "--verify", "refs/heads/main", cwd=project)
    if code != 0:
        return "holds-other", "there is no local main to compare with", name, visibility
    if not shared_refs(project, main):
        return "holds-other", "no branch on it shares history with main", name, visibility
    if remote_main:
        return "online", "", name, visibility
    if not may_write:
        return "unknown", why_not, name, visibility
    return "no-main", "a branch is online but main is not", name, visibility


def shared_refs(project, main):
    """The remote-tracking refs that share history with main."""
    _, refs, _ = run("git", "for-each-ref", "--format=%(refname)", "refs/remotes/origin/",
                     cwd=project)
    return [ref for ref in refs.split()
            if not ref.endswith("/HEAD") and run("git", "merge-base", main, ref, cwd=project)[0] == 0]


def report(state, why, name, visibility):
    print("repository\t%s" % (name or "unknown"))
    print("visibility\t%s" % visibility)
    print("state\t%s%s" % (state, "\t" + why if why else ""))


def create_main(project, name, base):
    code, _, err = run("gh", "api", "repos/%s/git/refs" % name,
                       "-f", "ref=refs/heads/main", "-f", "sha=" + base, cwd=project)
    if code != 0:
        print("main\tnot created\t%s" % (err.splitlines() or [""])[-1])
        return 8
    print("main\tcreated at %s" % base)
    code, _, _ = run("gh", "repo", "edit", name, "--default-branch", "main", cwd=project)
    print("default-branch\t%s" % ("main" if code == 0 else "not changed"))
    protection = subprocess.run([sys.executable, os.path.join(os.path.dirname(__file__),
                                 "protect-branch.py"), name, "main"], cwd=project,
                                capture_output=True, text=True)
    if protection.stdout:
        sys.stdout.write(protection.stdout)
    if protection.returncode != 0:
        if protection.stderr:
            sys.stderr.write(protection.stderr)
        return 0
    return 0


def ensure_push_guard(project):
    installer = Path(__file__).resolve().parents[2] / "setup-ai-build-kit/scripts/use-push-guard.sh"
    def check():
        return subprocess.run(["sh", str(installer), "--check", str(project)], cwd=project,
                              capture_output=True, text=True).returncode == 0
    if check():
        return True
    subprocess.run(["sh", str(installer), str(project)], cwd=project,
                   capture_output=True, text=True)
    if check():
        return True
    print("stopped\tthe push guard is not on. Run use-push-guard.sh from the project folder to switch it on. "
          "If that also stops, /maintain can set it up")
    return False


def upload(project, branch, name):
    if branch == "main":
        print("refused\tthe piece's branch is main; push a branch of its own")
        return 2
    if run("git", "rev-parse", "-q", "--verify", "refs/heads/" + branch, cwd=project)[0] != 0:
        print("refused\tthere is no local branch called %s" % branch)
        return 2
    code, base, _ = run("git", "merge-base", "main", branch, cwd=project)
    if code != 0 or not base:
        print("refused\t%s shares no commit with main" % branch)
        return 2
    if not ensure_push_guard(project):
        return 10
    push = subprocess.run(["git", "push", "-u", "origin", branch], cwd=project,
                          capture_output=True, text=True)
    if push.returncode != 0:
        print("pushed\tno")
        sys.stdout.write(push.stderr)
        return 7
    print("pushed\t%s" % branch)
    return create_main(project, name, base)


def finish_main(project, branch, name):
    """Create the main an earlier first upload left out, pushing nothing."""
    _, main, _ = run("git", "rev-parse", "refs/heads/main", cwd=project)
    shared = shared_refs(project, main)
    preferred = "refs/remotes/origin/" + branch if branch else None
    ref = preferred if preferred in shared else shared[0]
    code, base, _ = run("git", "merge-base", main, ref, cwd=project)
    if code != 0 or not base:
        print("refused\tno commit on the remote is shared with main")
        return 2
    return create_main(project, name, base)


def main(argv):
    approved = False
    branch = None
    rest = []
    args = list(argv)
    while args:
        arg = args.pop(0)
        if arg == "--approved":
            approved = True
        elif arg == "--branch":
            if not args:
                return usage()
            branch = args.pop(0)
        elif arg.startswith("--branch="):
            branch = arg.split("=", 1)[1]
        elif arg.startswith("-"):
            return usage()
        else:
            rest.append(arg)
    if len(rest) > 1 or (branch is not None and not approved):
        return usage()
    project = os.path.abspath(rest[0] if rest else ".")
    if run("git", "rev-parse", "--is-inside-work-tree", cwd=project)[0] != 0:
        print("first-upload.py: %s is not a Git repository" % project, file=sys.stderr)
        return 2
    state, why, name, visibility = state_of(project)
    report(state, why, name, visibility)
    if not approved or state not in ("first-upload", "no-main"):
        return CODES[state]
    if branch is None:
        code, branch, _ = run("git", "symbolic-ref", "--short", "-q", "HEAD", cwd=project)
        if code != 0:
            if state == "first-upload":
                print("refused\tno branch is checked out; name it with --branch")
                return 2
            branch = None
    if state == "no-main":
        return finish_main(project, branch, name)
    return upload(project, branch, name)


def usage():
    print("usage: first-upload.py [--approved [--branch BRANCH]] [PROJECT]", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
