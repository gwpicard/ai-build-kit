#!/usr/bin/env python3
"""List the branches whose work already reached the default branch, with the
command that removes each one. It never removes a branch.

Run it from inside the project:

    stale-branches.py [--keep NAME]...

--keep names a branch the project's own records say stays, such as one a
release is published from. The kit never sets a branch aside by its name
alone, so only a branch named here is kept for that reason.

It reads two groups, on this computer and on GitHub, and keeps them apart:

    Git confirms it      every commit on the branch is in the default branch
    GitHub records it    a pull request from the branch merged by squashing or
                         rebasing, and the branch ends at or before its last
                         commit, so Git cannot confirm it but GitHub can

It never lists the default branch, a branch checked out in any working copy,
a branch with an open pull request, a branch named with --keep, or a branch
GitHub protects from deletion. A branch with work added after its pull
request merged joins neither group and is named on its own line.

It prints the report the person reads, ready to pass on as it stands, and
exits:

    0  nothing to say: no branch qualifies and nothing was set aside
    1  the report is printed
    2  the default branch could not be found, or this is not a Git project

It runs `git fetch origin` without --prune, which changes no branch, and
asks GitHub through the gh tool. It writes nothing else.
"""

import argparse
import json
import shutil
import subprocess
import sys


def run(*cmd):
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return result.stdout if result.returncode == 0 else None


def git(*args):
    return run("git", *args)


def ancestor(older, newer):
    try:
        return subprocess.run(["git", "merge-base", "--is-ancestor", older, newer],
                              capture_output=True).returncode == 0
    except OSError:
        return False


def gh(*args):
    if not shutil.which("gh"):
        return None
    return run("gh", *args)


def default_branch(has_origin):
    answer = gh("repo", "view", "--json", "defaultBranchRef", "--jq", ".defaultBranchRef.name")
    if answer and answer.strip():
        return answer.strip()
    if has_origin:
        ref = git("symbolic-ref", "--quiet", "refs/remotes/origin/HEAD")
        if ref and ref.strip():
            return ref.strip().rsplit("/", 1)[-1]
    for name in ("main", "master"):
        if git("rev-parse", "--verify", "-q", "refs/heads/" + name) is not None:
            return name
    return None


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--keep", action="append", default=[])
    try:
        args = parser.parse_args()
    except SystemExit:
        return 2
    if git("rev-parse", "--show-toplevel") is None:
        print("The branch check did not run, because this folder is not a project under Git.")
        return 2

    has_origin = "origin" in (git("remote") or "").split()
    fetched = has_origin and git("fetch", "--quiet", "origin") is not None
    default = default_branch(has_origin)
    if not default:
        print("The branch check did not run, because the default branch could not be found.")
        return 2
    target = f"origin/{default}" if fetched and git("rev-parse", "--verify", "-q", f"origin/{default}") else default

    never = {default, *args.keep}
    for line in (git("worktree", "list", "--porcelain") or "").splitlines():
        if line.startswith("branch refs/heads/"):
            never.add(line[len("branch refs/heads/"):])

    signed_in = gh("auth", "status") is not None
    open_heads = gh("pr", "list", "--state", "open", "--limit", "500", "--json", "headRefName") if signed_in else None
    if open_heads:
        never |= {pr["headRefName"] for pr in json.loads(open_heads)}

    local = {}
    for line in (git("for-each-ref", "--format=%(refname:short) %(objectname)", "refs/heads") or "").splitlines():
        name, sha = line.rsplit(" ", 1)
        local[name] = sha
    remote = {}
    if fetched:
        for line in (git("ls-remote", "--heads", "origin") or "").splitlines():
            sha, ref = line.split("\t")
            remote[ref[len("refs/heads/"):]] = sha

    def merged_pr(name):
        if not signed_in:
            return None
        answer = gh("pr", "list", "--state", "merged", "--head", name, "--base", default,
                    "--limit", "50", "--json", "number,headRefOid")
        return json.loads(answer) if answer else []

    groups = {"local-git": [], "remote-git": [], "local-gh": [], "remote-gh": []}
    after_merge = set()
    for where, branches in (("local", local), ("remote", remote)):
        for name, sha in sorted(branches.items()):
            if name in never:
                continue
            if ancestor(sha, target):
                groups[f"{where}-git"].append(name)
                continue
            for pr in merged_pr(name) or []:
                head = pr.get("headRefOid", "")
                if head and ancestor(sha, head):
                    groups[f"{where}-gh"].append(name)
                    break
                if head and ancestor(head, sha):
                    after_merge.add(name)
                    break

    protected, unchecked = set(), False
    candidates = {n for g in groups.values() for n in g}
    if fetched and candidates:
        for name in sorted(candidates & set(remote)):
            flag = gh("api", f"repos/{{owner}}/{{repo}}/branches/{name}", "--jq", ".protected") if signed_in else None
            rules = gh("api", f"repos/{{owner}}/{{repo}}/rules/branches/{name}") if signed_in else None
            if flag is None:
                unchecked = True
                continue
            types = {rule.get("type") for rule in json.loads(rules or "[]")}
            if (flag or "").strip() == "true" or "deletion" in types:
                protected.add(name)
        for key in groups:
            groups[key] = [n for n in groups[key] if n not in protected]

    lines = []
    width = max([len(n) for g in groups.values() for n in g] + [len(n) for n in after_merge | protected] + [12]) + 2
    if any(groups.values()):
        lines.append(f"Some branches have finished their work, and their changes are already in {default}.")
        lines.append("You can remove them. I have not removed anything.")
    if groups["local-git"]:
        lines += ["", f"On this computer, every change confirmed in {default}:"]
        lines += [f"  {n.ljust(width)} git branch -d {n}" for n in groups["local-git"]]
    if groups["remote-git"]:
        lines += ["", f"On GitHub, every change confirmed in {default}:"]
        lines += [f"  {n.ljust(width)} git push origin --delete {n}" for n in groups["remote-git"]]
    if groups["local-gh"] or groups["remote-gh"]:
        lines += ["", "GitHub records these as merged, but Git cannot check every change, because",
                  "the merge combined the branch's changes into one. The capital D removes the",
                  "branch without Git's own check. It is safe here only because GitHub records",
                  "the same work as merged:"]
        lines += [f"  {n.ljust(width)} on this computer: git branch -D {n}" for n in groups["local-gh"]]
        lines += [f"  {n.ljust(width)} on GitHub: git push origin --delete {n}" for n in groups["remote-gh"]]
    if after_merge:
        lines += ["", "GitHub shows these branches as merged, but they have work added after the",
                  "merge. I have left them alone:"]
        lines += [f"  {n}" for n in sorted(after_merge)]
    if protected:
        lines += ["", "GitHub protects these branches from deletion, so I have left them alone:"]
        lines += [f"  {n}" for n in sorted(protected)]
    notes = []
    if has_origin and not fetched:
        notes.append("GitHub could not be reached, so only this computer was checked.")
    elif not has_origin:
        notes.append("The project has no copy on GitHub, so only this computer was checked.")
    if fetched and not signed_in:
        notes.append("The GitHub tool is missing or signed out, so branches merged by combining their "
                     "changes into one were not checked.")
    if unchecked:
        notes.append("Whether GitHub protects these branches could not be checked.")
    unread = (has_origin and not fetched) or (fetched and not signed_in) or unchecked
    if not lines and not unread:
        return 0
    if not lines:
        notes = [n for n in notes if not n.startswith("The project has no copy")]
    if any(groups.values()):
        lines += ["", f"I can tell that a branch's work reached {default}. I cannot tell whether somebody",
                  "still plans to use it."]
    for note in notes:
        lines += ["", note] if lines else [note]
    print("\n".join(lines))
    return 1


if __name__ == "__main__":
    sys.exit(main())
