#!/usr/bin/env python3
"""Record the kit files a released whole copy carries, so /maintain can tell
an untouched copy from one somebody changed.

A project founded from a whole copy of the kit keeps the kit's own files at its
root: the Agent Plugins folder, the Claude plugin folder, WORKFLOW.md, the
kit's README, the guard file, the adapter builder, the session-end hook and
the version marker. No update refreshes them, so after an update they describe
an older kit. The maintain skill's `kit-leftovers.py` offers to remove one
only when every byte matches a copy a release shipped at the same path. This
tool writes the record it compares against:
`.agents/skills/maintain/scripts/kit-released-copies.json`.

Usage:

    record-released-copies.py SOURCE...

Each SOURCE is a release archive (`ai-build-kit-vX.Y.Z.tar.gz`) or a folder
holding an unpacked release. Its version is read from `.ai-build-kit-version`
inside it, or from the archive's name. The record keeps what it already holds
and adds each source, so running it again with the same archive changes
nothing. Run it on the next branch after every release, with that release's
archive, so the release after it recognises its files.
"""

import hashlib
import io
import json
import os
import re
import sys
import tarfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RECORD = os.path.join(ROOT, ".agents", "skills", "maintain", "scripts", "kit-released-copies.json")

# The files and folders a whole copy carries that only the kit needs.
FILES = (
    "WORKFLOW.md", "README.md", ".ai-build-kit-version",
    ".agents/guard/blocked-commands.md", ".agents/tools/build-adapters.sh",
    ".agents/hooks/session-end-sync.sh",
)
FOLDERS = ("agent-plugin/", ".claude-plugin/")

COMMENT = ("The kit files a released whole copy carried, by path, each as the first "
           "16 hex digits of its SHA-256. kit-leftovers.py removes such a file only "
           "when it matches one of these at the same path. Written by "
           ".agents/tools/record-released-copies.py from the release archives.")


def digest(data):
    return hashlib.sha256(data).hexdigest()[:16]


def wanted(path):
    return path in FILES or path.startswith(FOLDERS)


def from_archive(path):
    files = {}
    with tarfile.open(path, "r:gz") as archive:
        for member in archive.getmembers():
            if not member.isfile():
                continue
            name = member.name
            while name.startswith("./"):
                name = name[2:]
            if wanted(name):
                files[name] = archive.extractfile(member).read()
    return files


def from_folder(path):
    files = {}
    for here, _dirs, names in os.walk(path):
        for name in names:
            full = os.path.join(here, name)
            if os.path.islink(full) or not os.path.isfile(full):
                continue
            rel = os.path.relpath(full, path).replace(os.sep, "/")
            if wanted(rel):
                with open(full, "rb") as handle:
                    files[rel] = handle.read()
    return files


def version_of(source, files):
    marker = files.get(".ai-build-kit-version", b"").decode("utf-8", "replace").strip()
    if re.match(r"^v\d+\.\d+\.\d+$", marker):
        return marker
    match = re.search(r"(v\d+\.\d+\.\d+)", os.path.basename(source.rstrip("/")))
    if match:
        return match.group(1)
    raise SystemExit("record-released-copies: cannot tell the version of %s" % source)


def main(argv):
    if not argv or any(a.startswith("-") for a in argv):
        print(__doc__.strip().splitlines()[0], file=sys.stderr)
        print("usage: record-released-copies.py SOURCE...", file=sys.stderr)
        return 2
    try:
        with open(RECORD, encoding="utf-8") as handle:
            record = json.load(handle)
    except OSError:
        record = {"versions": [], "files": {}}
    versions = set(record.get("versions", []))
    known = {path: set(hashes) for path, hashes in record.get("files", {}).items()}
    for source in argv:
        if os.path.isdir(source):
            files = from_folder(source)
        elif os.path.isfile(source):
            files = from_archive(source)
        else:
            raise SystemExit("record-released-copies: no such archive or folder: %s" % source)
        if not files:
            raise SystemExit("record-released-copies: %s holds none of the kit's own files" % source)
        versions.add(version_of(source, files))
        for path, data in files.items():
            known.setdefault(path, set()).add(digest(data))

    def order(version):
        return tuple(int(part) for part in version[1:].split("."))

    out = {
        "comment": COMMENT,
        "versions": sorted(versions, key=order),
        "files": {path: sorted(hashes) for path, hashes in sorted(known.items())},
    }
    text = json.dumps(out, indent=1, sort_keys=False) + "\n"
    buffer = io.open(RECORD, "w", encoding="utf-8", newline="\n")
    with buffer as handle:
        handle.write(text)
    print("record-released-copies: %d versions, %d paths" % (len(out["versions"]), len(out["files"])))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
