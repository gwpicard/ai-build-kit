#!/usr/bin/env python3
"""Require project-check on an existing branch without replacing its rules."""

import json
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


def main(argv):
    defer_missing = argv[:1] == ["--defer-missing"]
    args = argv[1:] if defer_missing else argv
    if len(args) != 2:
        print("usage: protect-branch.py [--defer-missing] OWNER/REPO BRANCH", file=sys.stderr)
        return 2
    repo, branch = args
    prefix = "repos/%s/branches/%s" % (repo, branch)
    code, detail = api("GET", prefix)
    if code:
        if "404" in detail or "Not Found" in detail:
            if defer_missing:
                print("GitHub says %s does not exist yet; branch protection is deferred." % branch)
                return 4
            return report("GitHub says %s does not exist, so the check could not be required." % branch)
        return report("GitHub could not read the branch before setting protection.")

    code, detail = api("GET", prefix + "/protection")
    if code and ("404" in detail or "Not Found" in detail):
        body = {
            "required_status_checks": {"strict": True, "contexts": ["project-check"]},
            "enforce_admins": True,
            "required_pull_request_reviews": None,
            "restrictions": None,
        }
        code, detail = api("PUT", prefix + "/protection", body)
        if not code:
            print("protection\tproject-check required on %s, including admins" % branch)
            return 0
    elif not code:
        code, detail = api("POST", prefix + "/protection/required_status_checks/contexts",
                           {"contexts": ["project-check"]})
        if code and ("404" in detail or "not found" in detail.lower()):
            # GitHub REST: https://docs.github.com/rest/branches/branch-protection#update-status-check-protection
            # Contexts POST can return 404 when protection has no required checks.
            read_code, current_text = api("GET", prefix + "/protection")
            if read_code:
                return report("GitHub's existing required checks could not be read.")
            try:
                existing = json.loads(current_text).get("required_status_checks") or {}
            except (ValueError, TypeError):
                return report("GitHub's existing required checks could not be read.")
            contexts = list(existing.get("contexts") or [])
            if "project-check" not in contexts:
                contexts.append("project-check")
            code, detail = api("PATCH", prefix + "/protection/required_status_checks",
                               {"strict": existing.get("strict", True), "contexts": contexts})
        if code == 0:
            code, detail = api("POST", prefix + "/protection/enforce_admins")
        if not code:
            print("protection\tproject-check added on %s, including admins" % branch)
            return 0

    lowered = detail.lower()
    if "upgrade to github pro" in lowered and (
            "make the repository public" in lowered or "make this repository public" in lowered):
        print("GitHub cannot require the check on this private repository with this plan, so the kit will hold the merge itself.")
        return 0
    if "must have admin rights" in lowered:
        return report("Branch protection could not be set because this account does not have admin rights.")
    if "404" in detail or "not found" in lowered:
        return report("Branch protection could not be set because GitHub says %s does not exist." % branch)
    if "422" in detail or "unprocessable" in lowered:
        return report("Branch protection could not be set because GitHub rejected the settings (422).")
    if any(word in lowered for word in (
            "timeout", "network", "connection", "resolve", "curl 6", "curl 7", "curl 28",
            "502", "503", "504")):
        return report("Branch protection could not be set because of a network error.")
    return report("Branch protection could not be set: %s" % (detail or "unknown error"))


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
