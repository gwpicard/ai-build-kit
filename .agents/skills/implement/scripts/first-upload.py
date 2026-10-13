#!/usr/bin/env python3
"""Say whether a push is the project's first upload, and make it on a yes.

Founding tells the person nothing will be uploaded, so the first push of the
project's code waits for their yes. Whether a push is that first upload is a
fact about the remote, so this script reads it rather than leaving it to
memory.

Usage:

    first-upload.py [PROJECT]                         read only
    first-upload.py --approved [--branch B] [PROJECT] make the first upload

PROJECT defaults to the current folder. The read prints lines with fields
separated by tabs:

    repository  OWNER/NAME | unknown
    visibility  private | public | internal | unknown
    state       STATE  [WHY]

and exits with the state's code:

    0  online         a remote branch shares history with main: push as usual
    3  first-upload   the repository has no branch: ask for a yes naming the
                      upload, then run again with --approved
    4  holds-other    the repository has branches, none sharing history with
                      main: push nothing and ask the person
    5  unknown        the remote could not be read: keep the work here and note
                      the step that did not happen
    6  kit            origin is the kit's own repository: push nothing and ask
                      for the person's own
    2                 usage error

With --approved, and only in the first-upload state, it pushes the piece's
branch (the current branch unless --branch names one) as a command of its
own, creates main on GitHub at the commit that branch was cut from, and makes
main the default branch. It never pushes main. Exit 0 then means the code is
online. Exit 7 means the push failed and nothing was created; exit 8 means the
branch is online but main could not be created. In any other state
--approved changes nothing and exits with that state's code.
"""

import json
import os
import re
import subprocess
import sys

KIT = "gwpicard/ai-build-kit"
CODES = {"online": 0, "first-upload": 3, "holds-other": 4, "unknown": 5, "kit": 6}


def run(*args, cwd):
    result = subprocess.run(list(args), cwd=cwd, capture_output=True, text=True)
    return result.returncode, result.stdout.strip(), result.stderr.strip()


def name_from_url(url):
    match = re.search(r"github\.com[:/]+([^/\s]+)/([^/\s]+?)(?:\.git)?/?$", url, re.I)
    return "%s/%s" % (match.group(1), match.group(2)) if match else None


def repository(project, url):
    """(owner/name or None, visibility)."""
    code, out, _ = run("gh", "repo", "view", "--json", "nameWithOwner,visibility", cwd=project)
    if code == 0:
        try:
            data = json.loads(out)
            return data.get("nameWithOwner") or name_from_url(url), \
                (data.get("visibility") or "unknown").lower()
        except ValueError:
            pass
    return name_from_url(url), "unknown"


def state_of(project):
    """(state, why, name, visibility)."""
    code, url, _ = run("git", "remote", "get-url", "origin", cwd=project)
    if code != 0 or not url:
        return "unknown", "there is no origin", None, "unknown"
    name, visibility = repository(project, url)
    from_url = name_from_url(url)
    if any(n and n.lower() == KIT for n in (name, from_url)):
        return "kit", "origin is the kit's own repository", name or KIT, visibility
    code, out, err = run("git", "ls-remote", "--exit-code", "--heads", "origin", cwd=project)
    if code == 2:
        return "first-upload", "", name, visibility
    if code != 0:
        why = (err.splitlines() or ["the remote could not be listed"])[-1]
        return "unknown", why, name, visibility
    code, _, err = run("git", "fetch", "-q", "origin", cwd=project)
    if code != 0:
        return "unknown", "the remote could not be fetched", name, visibility
    code, main, _ = run("git", "rev-parse", "-q", "--verify", "refs/heads/main", cwd=project)
    if code != 0:
        return "holds-other", "there is no local main to compare with", name, visibility
    _, refs, _ = run("git", "for-each-ref", "--format=%(objectname)", "refs/remotes/origin/", cwd=project)
    for sha in refs.split():
        if run("git", "merge-base", main, sha, cwd=project)[0] == 0:
            return "online", "", name, visibility
    return "holds-other", "no branch on it shares history with main", name, visibility


def report(state, why, name, visibility):
    print("repository\t%s" % (name or "unknown"))
    print("visibility\t%s" % visibility)
    print("state\t%s%s" % (state, "\t" + why if why else ""))


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
    if not name:
        print("refused\tthe repository's name could not be read")
        return 5
    push = subprocess.run(["git", "push", "-u", "origin", branch], cwd=project,
                          capture_output=True, text=True)
    if push.returncode != 0:
        print("pushed\tno")
        sys.stdout.write(push.stderr)
        return 7
    print("pushed\t%s" % branch)
    code, _, err = run("gh", "api", "repos/%s/git/refs" % name,
                       "-f", "ref=refs/heads/main", "-f", "sha=" + base, cwd=project)
    if code != 0:
        print("main\tnot created\t%s" % (err.splitlines() or [""])[-1])
        return 8
    print("main\tcreated at %s" % base)
    code, _, _ = run("gh", "repo", "edit", name, "--default-branch", "main", cwd=project)
    print("default-branch\t%s" % ("main" if code == 0 else "not changed"))
    return 0


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
    if not approved or state != "first-upload":
        return CODES[state]
    if branch is None:
        code, branch, _ = run("git", "symbolic-ref", "--short", "-q", "HEAD", cwd=project)
        if code != 0:
            print("refused\tno branch is checked out; name it with --branch")
            return 2
    return upload(project, branch, name)


def usage():
    print("usage: first-upload.py [--approved [--branch BRANCH]] [PROJECT]", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
