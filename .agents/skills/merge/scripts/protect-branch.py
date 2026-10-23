#!/usr/bin/env python3
"""Require project checks on an existing branch without replacing its rules.

Exit 0: set. 2: could not be set, with the reason. 3: the account's plan does
not offer protection on this private repository. With --defer-missing, a branch
that does not exist yet gives 4 when the plan allows protection, 5 when the
plan could not be read, and 3 when the plan rules it out. Exit 3 is a supported,
recorded condition. --check reads without changing GitHub: 0 means required,
3 means unavailable on this plan, and 4 means missing but available.
With --defer-missing, 6 means could not check; founding can still save locally.
"""

import json
from pathlib import Path
import re
import subprocess
import sys


def api(method, path, body=None):
    args = ["gh", "api", "-X", method, path]
    if body is not None:
        args.extend(["--input", "-"])
    try:
        result = subprocess.run(args, input=json.dumps(body) if body is not None else None,
                                text=True, capture_output=True)
    except FileNotFoundError:
        return 2, "GitHub CLI (gh) is not installed"
    except OSError as error:
        return 2, str(error)
    return result.returncode, (result.stderr or result.stdout).strip()


def report(message):
    print(message, file=sys.stderr)
    return 2


def plan_blocks(repo):
    """True when a private repository's owner is on GitHub Free, None if unreadable."""
    code, text = api("GET", "repos/%s" % repo)
    try:
        info = json.loads(text) if not code else {}
    except ValueError:
        info = {}
    if not isinstance(info, dict) or not info:
        return None
    if not info.get("private"):
        return False
    owner = info.get("owner") or {}
    path = "orgs/%s" % owner.get("login") if owner.get("type") == "Organization" else "user"
    code, text = api("GET", path)
    try:
        account = json.loads(text) if not code else {}
    except ValueError:
        return None
    if not isinstance(account, dict):
        return None
    if path == "user" and str(account.get("login", "")).lower() != str(owner.get("login", "")).lower():
        return None
    plan = (account.get("plan") or {}).get("name")
    return None if plan is None else plan.lower() == "free"


def record_condition(repo, branch, unavailable, condition="unavailable-private-free"):
    top = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                         text=True, capture_output=True)
    root = Path(top.stdout.strip()) if top.returncode == 0 else Path.cwd()
    path = root / ".ai-build-kit-maintenance"
    if path.is_symlink():
        raise OSError("the maintenance record is a link; leave it in place")
    text = path.read_text() if path.exists() else ""
    prefix = "branch-protection|%s|%s|" % (repo.lower(), branch)
    line = prefix + condition
    known = line in text.splitlines()
    if unavailable and known:
        return False
    if unavailable or any(row.startswith(prefix) for row in text.splitlines()):
        kept = "".join(row for row in text.splitlines(keepends=True)
                       if not row.startswith(prefix))
        if unavailable:
            kept += ("\n" if kept and not kept.endswith("\n") else "") + line + "\n"
        path.write_text(kept)
    return True


def plan_unavailable(repo, branch):
    first = record_condition(repo, branch, True)
    print("protection\tunavailable-private-free\t%s has no GitHub protection on this private repository's Free plan." % branch)
    if first:
        print("GitHub protection would require the project check even for changes made on GitHub. "
              "The push guard still refuses changes to main and replacement of remote work from this computer. "
              "Work can continue. A paid plan or a public repository would add that second layer if you ever want it.")
    return 3


def main(argv):
    defer_missing = argv[:1] == ["--defer-missing"]
    check = argv[:1] == ["--check"]
    args = argv[1:] if defer_missing or check else argv
    if len(args) != 2:
        print("usage: protect-branch.py [--defer-missing | --check] OWNER/REPO BRANCH", file=sys.stderr)
        return 2
    repo, branch = args
    required_contexts = ["project-check"]
    workflow = Path(".github/workflows/check.yml")
    if workflow.is_file() and re.search(r"(?m)^\s+recipe-check:\s*$", workflow.read_text()):
        required_contexts.append("recipe-check")
    check_names = ", ".join(required_contexts)

    def unreadable(message, detail=""):
        if "admin rights" in detail.lower():
            return report("Branch protection could not be set because this account does not have admin rights.")
        if not defer_missing:
            return report(message)
        first = record_condition(repo, branch, True, "could-not-check")
        print("protection\tcould not check\t%s" % message)
        if first:
            print("The first upload checks branch protection again and sets it when GitHub allows it. Work can continue to the local checkpoint.")
        return 6

    prefix = "repos/%s/branches/%s" % (repo, branch)
    code, detail = api("GET", prefix)
    if code:
        if "404" in detail or "Not Found" in detail:
            if defer_missing or check:
                blocks = plan_blocks(repo)
                if blocks:
                    return plan_unavailable(repo, branch)
                print("GitHub says %s does not exist yet; branch protection is deferred." % branch)
                return 4 if blocks is False else 5
            return report("GitHub says %s does not exist, so the check could not be required." % branch)
        return unreadable("GitHub could not read the branch before setting protection.", detail)

    code, detail = api("GET", prefix + "/protection")
    if check:
        if not code:
            try:
                protection = json.loads(detail)
                required = set(required_contexts).issubset((protection.get("required_status_checks") or {}).get("contexts") or [])
                admins = protection.get("enforce_admins") or {}
                if required and admins.get("enabled"):
                    record_condition(repo, branch, False)
                    print("protection\t%s required on %s, including admins" % (check_names, branch))
                    return 0
            except (ValueError, AttributeError):
                return report("GitHub's branch protection answer could not be read.")
        elif "404" not in detail and "not found" not in detail.lower():
            if "upgrade to github pro" in detail.lower():
                return plan_unavailable(repo, branch)
            return report("GitHub's branch protection could not be read.")
        blocks = plan_blocks(repo)
        if blocks:
            return plan_unavailable(repo, branch)
        if blocks is None:
            return report("GitHub's plan could not be read, so protection's availability is unknown.")
        record_condition(repo, branch, False)
        print("protection\tmissing\tGitHub protection is available; offer to switch it on for %s." % branch)
        return 4
    if defer_missing and code and not any(word in detail.lower() for word in ("404", "not found", "upgrade to github pro", "admin rights")):
        return unreadable("GitHub's branch protection could not be read.", detail)
    if code and ("404" in detail or "Not Found" in detail):
        body = {
            # Two pieces may merge from the same base; merge.py still holds on red or pending checks.
            "required_status_checks": {"strict": False, "contexts": required_contexts},
            "enforce_admins": True,
            "required_pull_request_reviews": None,
            "restrictions": None,
        }
        code, detail = api("PUT", prefix + "/protection", body)
        if not code:
            record_condition(repo, branch, False)
            print("protection\t%s required on %s, including admins" % (check_names, branch))
            return 0
    elif not code:
        code, detail = api("POST", prefix + "/protection/required_status_checks/contexts",
                           {"contexts": required_contexts})
        if code and ("404" in detail or "not found" in detail.lower()):
            # GitHub REST: https://docs.github.com/rest/branches/branch-protection#update-status-check-protection
            # Contexts POST can return 404 when protection has no required checks.
            read_code, current_text = api("GET", prefix + "/protection")
            if read_code:
                return unreadable("GitHub's existing required checks could not be read.", current_text)
            try:
                existing = json.loads(current_text).get("required_status_checks") or {}
            except (ValueError, TypeError, AttributeError):
                return unreadable("GitHub's existing required checks could not be read.")
            contexts = list(existing.get("contexts") or [])
            for context in required_contexts:
                if context not in contexts:
                    contexts.append(context)
            code, detail = api("PATCH", prefix + "/protection/required_status_checks",
                               {"strict": existing.get("strict", True), "contexts": contexts})
        if code == 0:
            code, detail = api("POST", prefix + "/protection/enforce_admins")
        if not code:
            record_condition(repo, branch, False)
            print("protection\t%s added on %s, including admins" % (check_names, branch))
            return 0

    lowered = detail.lower()
    if "upgrade to github pro" in lowered and (
            "make the repository public" in lowered or "make this repository public" in lowered):
        return plan_unavailable(repo, branch)
    if "must have admin rights" in lowered:
        return report("Branch protection could not be set because this account does not have admin rights.")
    if "404" in detail or "not found" in lowered:
        return report("Branch protection could not be set because GitHub says %s does not exist." % branch)
    if "422" in detail or "unprocessable" in lowered:
        return report("Branch protection could not be set because GitHub rejected the settings (422).")
    if any(word in lowered for word in (
            "timeout", "network", "connection", "resolve", "curl 6", "curl 7", "curl 28",
            "502", "503", "504")):
        return unreadable("Branch protection could not be set because of a network error.")
    return report("Branch protection could not be set: %s" % (detail or "unknown error"))


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except OSError as error:
        sys.exit(report("Branch protection's condition could not be recorded: %s" % error))
