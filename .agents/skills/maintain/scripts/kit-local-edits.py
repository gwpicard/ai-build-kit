#!/usr/bin/env python3
"""Compare installed skills with released copies before allowing replacement.

With no --run, print local-edit and say lines, exiting 1 for differences,
0 for no differences and 2 when the comparison cannot run. --run requires
--approved and an --overwrite PATH for every difference, then runs the update.
Use the proposed release's record: an installed record can predate its own files.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys


HERE = Path(__file__).resolve().parent


def unreadable(error):
    raise error


def changed_files(skills, record):
    known = json.loads(record.read_text(encoding="utf-8"))["files"]
    if not isinstance(known, dict) or not known:
        raise ValueError("the released-copies record has no files")
    prefixes = (".agents/skills/", ".claude/skills/")
    names = {path[len(prefix):].split("/")[0] for path in known for prefix in prefixes
             if path.startswith(prefix)}
    if not names:
        raise ValueError("the released-copies record has no skills")
    changed = set()
    for name in sorted(names):
        folder = skills / name
        if not folder.exists():
            continue
        for directory, dirs, files in os.walk(folder, onerror=unreadable):
            # Skill-folder links are normal installations. A link inside a
            # skill is unrecognised and is never traversed.
            links = [item for item in dirs if (Path(directory) / item).is_symlink()]
            dirs[:] = sorted(item for item in dirs if item not in links)
            for item in sorted(files + links):
                path = Path(directory) / item
                relative = path.relative_to(skills).as_posix()
                hashes = set()
                for prefix in prefixes:
                    hashes.update(known.get(prefix + relative, ()))
                if path.is_symlink() or hashlib.sha256(path.read_bytes()).hexdigest()[:16] not in hashes:
                    changed.add(str(path.absolute()))
    return sorted(changed)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skills", type=Path, default=HERE.parent.parent)
    parser.add_argument("--record", type=Path, default=HERE / "kit-released-copies.json")
    parser.add_argument("--approved", action="store_true")
    parser.add_argument("--overwrite", action="append", default=[])
    parser.add_argument("--run", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    try:
        if not args.skills.is_dir():
            raise ValueError("the installed skills folder could not be read")
        changed = changed_files(args.skills.absolute(), args.record)
        for path in changed:
            print("local-edit\t" + path)
        if changed:
            print("say\tlocal-edits\tThese installed files differ from every recorded released copy. "
                  "Updating would replace them. Shall I overwrite the named files?")
        if args.run is None:
            return 1 if changed else 0
        approved = {str(Path(path).absolute()) for path in args.overwrite}
        if not args.approved or not set(changed) <= approved:
            print("kit-local-edits: update not run; approval must name every differing file", file=sys.stderr)
            return 1
        if not args.run:
            raise ValueError("--run needs an update command")
        return subprocess.run(args.run).returncode
    except (OSError, ValueError, KeyError, TypeError) as error:
        print("kit-local-edits: comparison or update could not run: " + str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
