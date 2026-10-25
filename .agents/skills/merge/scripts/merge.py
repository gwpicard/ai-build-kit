#!/usr/bin/env python3
"""Hold a pull request until its checks, review boxes and approval are clear."""

import json
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

def shared_review_reader():
    """The project's reader when it knows the review record, else the kit's own."""
    candidates = [Path.cwd() / ".agents" / "hooks" / "review_boxes.py",
                  Path(__file__).resolve().parents[2] / "setup-ai-build-kit" / "templates" /
                  "foundation" / "review_boxes.py"]
    for candidate in candidates:
        if candidate.is_file():
            import importlib.util
            spec = importlib.util.spec_from_file_location("review_boxes", candidate)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            if hasattr(module, "review_hold"):
                return module
    raise ImportError("shared review-box reader is missing")


def result_names():
    import importlib.util
    path = Path(__file__).resolve().parents[2] / "quality-checks" / "scripts" / "results.py"
    spec = importlib.util.spec_from_file_location("results", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sys.dont_write_bytecode = True
reviews = shared_review_reader()
open_review_box = reviews.open_review_box
results = result_names()


def review_held(body, head):
    """Stop unless a whole review record names this head and has no open finding."""
    reason = reviews.review_hold(body, head)
    if reason:
        stop("merge: %s (%s); the pull request stays open" % (reason, results.NOT_RUN))
    if (reviews.read_record(body) or {}).get("open") != "0":
        stop("merge: the review record still has an open finding (%s); the pull request stays open"
             % results.FAIL)


def gh(*args):
    try:
        return subprocess.run(["gh", *args], text=True, capture_output=True)
    except FileNotFoundError:
        stop("merge: GitHub CLI (gh) is not installed", 2)


def stop(message, code=1):
    print(message, file=sys.stderr)
    raise SystemExit(code)


def read_json(result, label):
    try:
        return json.loads(result.stdout)
    except (ValueError, TypeError):
        stop("merge: GitHub returned unreadable " + label, 2)


def check_hold(rows):
    projects = [row for row in rows if row.get("name") == "project-check"]
    if not projects:
        stop("merge: project-check is missing (%s); the pull request stays open" % results.NOT_RUN)
    for row in rows:
        name = str(row.get("name") or "unnamed check")
        state = str(row.get("state") or "unknown")
        result = results.from_github(row)
        if results.blocks(result):
            stop("merge: %s is %s (%s); the pull request stays open" % (name, state, result))
        if name == "project-check" and result != results.PASS:
            stop("merge: project-check is %s (%s); the pull request stays open" % (state, result))


BILLING = re.compile(r"job was not started because .*(payments have failed|spending limit)", re.I)


def billing_blocked(row):
    """True when GitHub says it never started this check because of billing."""
    job = re.search(r"/job/(\d+)", str(row.get("link") or ""))
    if not job:
        return False
    notes = gh("api", "repos/{owner}/{repo}/check-runs/%s/annotations" % job.group(1))
    if notes.returncode != 0:
        return False
    try:
        rows = json.loads(notes.stdout)
    except ValueError:
        return False
    return isinstance(rows, list) and any(
        isinstance(note, dict) and BILLING.search(str(note.get("message") or ""))
        for note in rows)


def billing_fallback(rows, head, base, number):
    """Run project-check here when billing alone stopped GitHub from running it."""
    held = [row for row in rows if results.blocks(results.from_github(row))]
    if not held or any(row.get("name") != "project-check" for row in held):
        return rows, False
    if not all(billing_blocked(row) for row in held):
        return rows, False
    print("merge: GitHub did not start project-check because of a billing limit; "
          "running the same steps on this computer, on a clean copy of " + head[:12])
    script = Path(__file__).with_name("local-check.py")
    try:
        done = subprocess.run([sys.executable, str(script), head, base, number], text=True,
                              capture_output=True)
    except OSError:
        stop("merge: the local project-check could not start", 2)
    sys.stdout.write(done.stdout)
    sys.stderr.write(done.stderr)
    if done.returncode == 1:
        stop("merge: project-check failed on this computer (%s); the pull request stays open"
             % results.FAIL)
    if done.returncode:
        stop("merge: project-check could not run on this computer (%s); the pull request "
             "stays open" % results.NOT_RUN, 2)
    passed = [dict(row, bucket="pass", state="SUCCESS") if row in held else row for row in rows]
    return passed, True


def git(*args):
    try:
        return subprocess.run(["git", *args], text=True, capture_output=True)
    except OSError:
        stop("merge: Git could not run", 2)


def newest_main(head):
    remotes = git("remote")
    if remotes.returncode:
        stop("merge: could not read Git remotes", 2)
    if "origin" in remotes.stdout.splitlines():
        fetched = git("fetch", "--no-tags", "origin", "main")
        if fetched.returncode:
            stop("merge: could not fetch the newest main", 2)
        main = git("rev-parse", "origin/main^{commit}")
    else:
        main = git("rev-parse", "main^{commit}")
    if main.returncode:
        stop("merge: could not read main", 2)
    base = git("merge-base", main.stdout.strip(), head)
    if base.returncode:
        stop("merge: could not compare the branch with main", 2)
    if base.stdout.strip() != main.stdout.strip():
        stop("merge: this change is behind the newest version. Bring it up to date and settle any conflicts first, then the checks run again.")
    return main.stdout.strip()


def pause_file():
    result = git("rev-parse", "--git-common-dir")
    if result.returncode:
        stop("merge: could not locate the local automatic-merge pause", 2)
    common = Path(result.stdout.strip())
    if not common.is_absolute():
        common = Path.cwd() / common
    return common / "ai-build-kit-auto-paused"


def pause_auto(reason):
    path = pause_file()
    try:
        path.write_text(reason.strip() + "\n", encoding="utf-8")
    except OSError:
        stop("merge: could not save the automatic-merge pause", 2)
    print("merge: automatic merging is paused: " + reason.strip())


def resume_auto():
    path = pause_file()
    try:
        path.unlink(missing_ok=True)
    except OSError:
        stop("merge: could not clear the automatic-merge pause", 2)
    print("merge: automatic merging is re-enabled")


def check_main_health():
    path = pause_file()
    if path.exists():
        reason = path.read_text(encoding="utf-8").strip()
        stop("merge: automatic merging is paused: " + (reason or "a person must turn it on again"))
    result = gh("run", "list", "--branch", "main", "--limit", "1",
                "--json", "status,conclusion,name")
    if result.returncode != 0:
        stop("merge: could not read the latest check on main", 2)
    rows = read_json(result, "latest check on main")
    if not isinstance(rows, list) or not rows:
        stop("merge: no check is reported on main; automatic merging is blocked")
    row = rows[0]
    if row.get("status") != "completed":
        stop("merge: the latest check on main is still running; automatic merging is blocked")
    if row.get("conclusion") != "success":
        reason = "%s is %s" % (row.get("name") or "the latest check on main",
                               row.get("conclusion") or row.get("status") or "unknown")
        pause_auto(reason)
        stop("merge: " + reason + "; automatic merging is paused")


def wait_for_auto_checks(number, rows, timeout=15 * 60):
    deadline = time.monotonic() + timeout
    while any(row.get("bucket") == "pending" for row in rows) and time.monotonic() < deadline:
        time.sleep(min(15, max(0, deadline - time.monotonic())))
        checks = gh("pr", "checks", number, "--json", "name,state,bucket")
        if checks.returncode != 0:
            stop("merge: GitHub could not reread pending checks", 2)
        rows = read_json(checks, "pending pull request checks")
        if not isinstance(rows, list) or any(not isinstance(row, dict) for row in rows):
            stop("merge: GitHub returned unreadable pending pull request checks", 2)
    if any(row.get("bucket") == "pending" for row in rows):
        stop("merge: a check stayed pending for 15 minutes; the pull request stays open")
    return rows


def auto_setting(main):
    result = git("show", main + ":masterplan.md")
    if result.returncode:
        stop("merge: main has no readable masterplan; automatic merge is off")
    line = re.search(r'(?m)^Runs on its own:.*\bmerge\b.*\bdecided\s+\d{4}-\d{2}-\d{2}\b.*"[^\"]+".*$', result.stdout)
    if not line:
        stop("merge: main has no Runs on its own setting for merge")
    words = line.group(0)
    notes = git("notes", "--ref=refs/notes/ai-build-kit-approved-merges", "list")
    if notes.returncode != 0:
        stop("merge: could not count earlier explicitly approved merges", 2)
    earned = len([line for line in notes.stdout.splitlines() if line.strip()])
    if earned < 3:
        stop("merge: three explicitly approved merges are required before automatic merge")
    return words


def touched_paths(base, head):
    result = git("diff", "--name-only", base + "..." + head)
    if result.returncode:
        stop("merge: could not read the pull request's changed files", 2)
    return result.stdout.splitlines()


def auto_holds(data, main, head):
    auto_setting(main)
    paths = touched_paths(data["baseRefOid"], head)
    if any(re.search(r"(^|/)(migrations?|alembic|versions?)(/|$)|\.(sql)$", p, re.I) for p in paths):
        stop("merge: this piece changes a migration; it needs your approval, naming this pull request")
    def is_setting(path):
        name = Path(path).name.casefold()
        return (path.startswith((".github/", ".claude/", ".agents/")) or
                name in {".env.example", "checks.yml", "checks.yaml", "pyproject.toml",
                         "package.json", "package-lock.json", "npm-shrinkwrap.json",
                         "pnpm-lock.yaml", "yarn.lock", "uv.lock", "poetry.lock", "bun.lock", "bun.lockb",
                         "requirements.txt", "pipfile.lock", "gemfile.lock", "cargo.lock", "go.sum",
                         "pipfile", "pipfile.lock", "cargo.toml", "cargo.lock",
                         "composer.json", "composer.lock", "go.mod", "go.sum",
                         "gemfile", "gemfile.lock", "requirements.txt"} or
                name.startswith("requirements") and name.endswith(".txt") or
                "/requirements/" in ("/" + path.casefold() + "/"))
    if any(is_setting(path) for path in paths):
        stop("merge: this piece changes a setting; it needs your approval, naming this pull request")
    if open_review_box(data.get("body") or ""):
        stop("merge: a finding under Worth stopping for is open; the pull request stays open")
    review_held(data.get("body") or "", head)
    body = data.get("body") or ""
    refs = data.get("closingIssuesReferences") or []
    if not refs or not isinstance(refs, list):
        stop("merge: the pull request has no linked piece to check")
    issue_number = next((str(item.get("number")) for item in refs
                         if isinstance(item, dict) and item.get("number")), None)
    if not issue_number:
        stop("merge: the pull request has no readable linked piece")
    issue = gh("issue", "view", issue_number, "--json", "title,body,labels")
    if issue.returncode != 0:
        stop("merge: could not read the linked piece", 2)
    issue_data = read_json(issue, "linked piece")
    if not isinstance(issue_data, dict) or not isinstance(issue_data.get("body"), str):
        stop("merge: the linked piece is unreadable", 2)
    piece_body = issue_data["body"]
    labels = {str(label.get("name", "")).casefold()
              for label in issue_data.get("labels", []) if isinstance(label, dict)}
    if "repair" in labels or "broken" in labels or "repair" in str(issue_data.get("title", "")).casefold():
        stop("merge: a repair needs your approval, naming this pull request")
    if re.search(r"(?im)^Live side needs:\s*\S+", piece_body):
        stop("merge: this piece needs a live setting; it needs your approval, naming this pull request")
    done = re.search(r"(?ims)^##+\s+Done when\s*\n(.*?)(?=^##+\s|\Z)", piece_body)
    if done and any("(try it)" in line.casefold() for line in done.group(1).splitlines()):
        stop("merge: a Done when item needs a person to try it")
    env_script = Path(__file__).with_name("env-names-added.sh")
    try:
        env = subprocess.run(["sh", str(env_script), head, data["baseRefOid"]],
                             text=True, capture_output=True)
    except OSError:
        stop("merge: could not check for new settings", 2)
    if env.returncode == 1:
        stop("merge: this piece adds a setting; it needs your approval, naming this pull request")
    if env.returncode != 0:
        stop("merge: could not check for new settings", 2)
    auto_rule = git("show", head + ":masterplan.md")
    if auto_rule.returncode != 0:
        stop("merge: could not read the pull request's masterplan")
    pr_line = re.search(r"(?m)^Runs on its own:.*$", auto_rule.stdout)
    main_text = git("show", main + ":masterplan.md")
    if main_text.returncode:
        stop("merge: could not reread the setting on main", 2)
    main_line = re.search(r"(?m)^Runs on its own:.*$", main_text.stdout)
    if (pr_line.group(0) if pr_line else None) != (main_line.group(0) if main_line else None):
        stop("merge: this pull request changes its own-merge setting")
    if any("repair" in p.casefold() for p in paths):
        stop("merge: repair changes need your approval, naming this pull request")
    newest_main(head)


def approved_yes(change):
    """The one gate before an online change: the person's recorded approval for it."""
    gate = Path(__file__).resolve().parents[2] / "records" / "scripts" / "approval.py"
    try:
        done = subprocess.run([sys.executable, str(gate), "use", change], text=True,
                              capture_output=True)
    except OSError:
        stop("merge: the approval gate could not run", 2)
    if done.returncode == 1:
        stop("merge: " + (done.stderr.strip() or "no recorded approval for " + change), 1)
    if done.returncode:
        stop("merge: the approval gate could not run: " + (done.stderr or done.stdout).strip(), 2)
    sys.stdout.write(done.stdout)


def kit_area_check():
    here = Path(__file__).resolve()
    for parent in here.parents:
        for candidate in (
                parent / "setup-ai-build-kit" / "templates" / "foundation" / "check-sensitive-areas.sh",
                parent / "skills" / "setup-ai-build-kit" / "templates" / "foundation" / "check-sensitive-areas.sh"):
            if candidate.is_file():
                return str(candidate)
    stop("merge: could not find the kit's risk-area check", 2)


def check_sensitive_area(base, head, automatic=False):
    script = kit_area_check()
    try:
        fetch = subprocess.run(["git", "fetch", "origin", base, head], text=True,
                               capture_output=True)
    except OSError:
        stop("merge: could not fetch the pull request commits", 2)
    if fetch.returncode != 0:
        detail = (fetch.stderr or fetch.stdout).strip()
        stop("merge: could not fetch the pull request commits" +
             (": " + detail if detail else ""), 2)
    plan = subprocess.run(["git", "show", head + ":masterplan.md"], text=True,
                          capture_output=True)
    if plan.returncode != 0:
        if "masterplan.md" in (plan.stderr or ""):
            return
        stop("merge: could not read the pull request's masterplan", 2)
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=".md") as handle:
            handle.write(plan.stdout)
            handle.flush()
            result = subprocess.run(["sh", script, "--change", base, "--head", head,
                                     "--masterplan", handle.name],
                                    text=True, capture_output=True)
    except OSError:
        stop("merge: could not run the risk-area check", 2)
    if result.stdout:
        sys.stdout.write(result.stdout)
    if automatic and result.stdout.strip():
        stop("merge: this piece touches a risk area; it needs your approval, naming this pull request")
    if result.returncode == 1:
        stop("merge: the risk-area check is open; the pull request stays open")
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        stop("merge: could not run the risk-area check" +
             (": " + detail if detail else ""), 2)


def main(argv):
    if len(argv) == 2 and argv[0] == "--pause":
        pause_auto(argv[1])
        return
    if argv == ["--resume"]:
        resume_auto()
        return
    if len(argv) == 1 and argv[0].isdigit():
        stop("merge: your approval naming this pull request is required", 1)
    mode = argv[0] if len(argv) == 2 else ""
    if len(argv) != 2 or mode not in ("--approved", "--auto") or not argv[1].isdigit():
        stop("usage: merge.py [--approved|--auto] <pull request number>", 2)
    number = argv[1]

    fields = "body,headRefOid,baseRefOid"
    if mode == "--auto":
        fields += ",closingIssuesReferences"
    pr = gh("pr", "view", number, "--json", fields)
    if pr.returncode != 0:
        stop("merge: GitHub could not read the pull request: " +
             (pr.stderr or pr.stdout).strip(), 2)
    data = read_json(pr, "pull request")
    if not isinstance(data, dict) or not data.get("headRefOid"):
        stop("merge: GitHub returned an unreadable pull request head", 2)
    head = data["headRefOid"]
    if not data.get("baseRefOid"):
        stop("merge: GitHub returned an unreadable pull request base", 2)
    main = newest_main(head)
    review_held(data.get("body") or "", head)
    if mode == "--auto":
        auto_holds(data, main, head)
        check_main_health()
    check_sensitive_area(data["baseRefOid"], head, automatic=(mode == "--auto"))

    checks = gh("pr", "checks", number, "--json", "name,state,bucket,link")
    if checks.returncode == 1 and not checks.stdout.strip() and "no checks reported" in checks.stderr:
        stop("merge: project-check is missing; the pull request stays open")
    if checks.returncode != 0:
        stop("merge: GitHub could not read the pull request checks: " +
             (checks.stderr or checks.stdout).strip(), 2)
    rows = read_json(checks, "pull request checks")
    if not isinstance(rows, list) or any(not isinstance(row, dict) for row in rows):
        stop("merge: GitHub returned unreadable pull request checks", 2)
    if mode == "--auto":
        rows = wait_for_auto_checks(number, rows)
    local = False
    if mode == "--approved":
        rows, local = billing_fallback(rows, head, data["baseRefOid"], number)
    check_hold(rows)

    if open_review_box(data.get("body") or ""):
        stop("merge: a finding under Worth stopping for is open; the pull request stays open")

    if mode == "--approved":
        approved_yes("merge pull request " + number)
    merged = gh("pr", "merge", number, "--merge", "--match-head-commit", head)
    if merged.returncode != 0:
        detail = (merged.stderr or merged.stdout).strip()
        stop("merge: GitHub did not merge the pull request" + (": " + detail if detail else ""), 2)
    if merged.stdout:
        sys.stdout.write(merged.stdout)
    if reviews.review_verified(data.get("body") or ""):
        print("merge: the review of this version is verified: a second login approved it")
    else:
        print("merge: the review of this version is unverified: the kit could not confirm "
              "that a second person read it")
    if local:
        print("merge: project-check ran on this computer, not on GitHub, because of a billing "
              "limit; it passed for commit " + head)
    if mode == "--approved":
        record = "approved merge " + number
        if local:
            record += "; project-check passed on this computer: GitHub did not start it (billing)"
        noted = git("notes", "--ref=refs/notes/ai-build-kit-approved-merges",
                    "add", "-f", "-m", record, head)
        if noted.returncode:
            stop("merge: merged, but could not record this explicitly approved merge", 2)
        remotes = git("remote")
        if remotes.returncode == 0 and "origin" in remotes.stdout.splitlines():
            pushed = git("push", "origin", "refs/notes/ai-build-kit-approved-merges")
            if pushed.returncode:
                stop("merge: merged, but could not publish the explicitly approved merge record", 2)


if __name__ == "__main__":
    main(sys.argv[1:])
