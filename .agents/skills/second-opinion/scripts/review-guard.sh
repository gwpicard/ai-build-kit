#!/usr/bin/env sh
# review-guard.sh: keep a review from changing the work it reviews.
#
# Usage, from the project root:
#   review-guard.sh snapshot FILE...   keep the files under review and all
#                                      pre-existing uncommitted work and index entries
#   review-guard.sh check              compare and restore files and index entries
#
# check exits 0 when unchanged, 1 for reviewer changes, and 2 if it cannot run.
# A restored line means both the working file and index match the snapshot.
# Other working-tree changes are named and left for the person. Directories
# and submodules are skipped with a note. Copies in .agents/tmp/review-guard/
# are removed after a completed check and kept if restoration fails.

exec python3 - "$@" <<'PY'
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys

GUARD = Path(".agents/tmp/review-guard")


def git(*args, **kwargs):
    return subprocess.check_output(["git", *args], **kwargs)


def status():
    if not in_git:
        return []
    return [line for line in git("status", "--porcelain", "--untracked-files=all").decode(
        "utf-8", "surrogateescape").splitlines() if ".agents/tmp/" not in line]


def index(path):
    return git("ls-files", "-s", "-z", "--", path).decode("utf-8", "surrogateescape") if in_git else ""


def kind(path, staged):
    if any(entry.startswith("160000 ") for entry in staged.split("\0")):
        return "submodule"
    if path.is_symlink():
        return "symlink"
    if path.is_dir():
        return "directory"
    if path.is_file():
        return "regular"
    if not path.exists():
        return "absent"
    raise ValueError("unsupported file type: %s" % path)


def matches(path, entry):
    if kind(path, index(str(path))) != entry["kind"]:
        return False
    if entry["kind"] == "regular":
        return (path.read_bytes() == (GUARD / entry["copy"]).read_bytes()
                and stat.S_IMODE(path.stat().st_mode) == entry["mode"])
    if entry["kind"] == "symlink":
        return os.readlink(path) == entry["target"]
    return True


def restore_index(path, staged):
    if in_git:
        git("update-index", "--force-remove", "--", str(path))
        if staged:
            git("update-index", "-z", "--index-info", input=staged.encode("utf-8", "surrogateescape"))


def snapshot(paths):
    if not paths:
        raise ValueError("name the files under review")
    paths = set(paths)
    if in_git:
        for args in (("ls-files", "--modified", "--deleted", "--others", "--exclude-standard", "-z"),
                     ("diff", "--cached", "--name-only", "--no-renames", "-z")):
            paths.update(p.decode("utf-8", "surrogateescape") for p in git(*args).split(b"\0") if p)
    entries = []
    if GUARD.exists():
        shutil.rmtree(GUARD)
    (GUARD / "files").mkdir(parents=True)
    for name in sorted(paths):
        path = Path(name)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError("%s is not inside the project" % name)
        if "\n" in name or "\t" in name:
            raise ValueError("a filename contains a tab or newline; snapshot could not be kept")
        if path.is_relative_to(".agents/tmp"):
            continue
        staged = index(name)
        entry = {"path": name, "index": staged, "kind": kind(path, staged)}
        if entry["kind"] == "regular":
            entry["copy"] = "files/%d" % len(entries)
            entry["mode"] = stat.S_IMODE(path.stat().st_mode)
            shutil.copy2(path, GUARD / entry["copy"])
        elif entry["kind"] == "symlink":
            entry["target"] = os.readlink(path)
        entries.append(entry)
    (GUARD / "snapshot.json").write_text(json.dumps({"entries": entries, "status": status()}))
    print("review-guard: kept %d path(s) before review" % len(entries))
    return 0


def check():
    if not (GUARD / "snapshot.json").is_file():
        raise ValueError("no snapshot to compare with")
    saved = json.loads((GUARD / "snapshot.json").read_text())
    changed = False
    for entry in saved["entries"]:
        name = entry["path"]
        path = Path(name)
        if entry["kind"] in ("directory", "submodule"):
            print("skipped\t%s\t%s" % (name, entry["kind"]))
            continue
        working_matches = matches(path, entry)
        if working_matches and index(name) == entry["index"]:
            continue
        changed = True
        if not working_matches:
            if path.is_dir() and not path.is_symlink():
                raise ValueError("cannot restore %s over a directory; snapshot kept" % name)
            path.parent.mkdir(parents=True, exist_ok=True)
            if path.is_symlink():
                path.unlink()
            if entry["kind"] == "absent":
                if path.exists():
                    path.unlink()
            elif entry["kind"] == "regular":
                shutil.copy2(GUARD / entry["copy"], path)
            else:
                if path.exists():
                    path.unlink()
                path.symlink_to(entry["target"])
        restore_index(path, entry["index"])
        if not matches(path, entry) or index(name) != entry["index"]:
            raise ValueError("could not restore %s; snapshot kept" % name)
        print("restored\t%s" % name)
    for line in status():
        if line not in saved["status"]:
            print("changed\t%s" % line)
            changed = True
    shutil.rmtree(GUARD)
    return int(changed)


in_git = subprocess.run(["git", "rev-parse", "--is-inside-work-tree"],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
try:
    action = sys.argv[1] if len(sys.argv) > 1 else ""
    if action == "snapshot":
        result = snapshot(sys.argv[2:])
    elif action == "check":
        result = check()
    else:
        raise ValueError("usage: review-guard.sh snapshot FILE... | check")
except (OSError, ValueError, subprocess.CalledProcessError) as error:
    print("review-guard: %s" % error, file=sys.stderr)
    result = 2
sys.exit(result)
PY
