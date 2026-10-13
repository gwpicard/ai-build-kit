#!/usr/bin/env python3
"""List the project's documents that repeat each other or are no longer needed.

Reads every Markdown document git tracks, apart from the kit's own files, the
project records and anything in a folder whose name starts with a dot. It
prints one line for each of two findings, and nothing when there are none:

    repeated<TAB>document:line<TAB>other-document:line
        The same paragraph, of forty words or more, in two documents.
    unreferenced<TAB>document
        No other file in the project names the document. A README is never
        listed, since it is where a reader starts.

A document that names things the project no longer has is the document read's
to find, in every /maintain visit, one name at a time.

It compares paragraphs word for word, after ignoring case, spacing and
punctuation, so it finds a copy and never two documents that say the same
thing in different words.

With --skip-offered it leaves out each finding an earlier visit offered the
person, as --record-offered wrote it into `.ai-build-kit-maintenance`. A
finding that never reached the person, because it did not fit under the cap
or the read failed, comes back at the next visit.

--record-offered reads finding lines, exactly as printed, on standard input,
and adds one `offered|document-bloat|<date>|...` line for each to
`.ai-build-kit-maintenance`, keeping every other line.

Exit codes: 0 nothing to report, 1 findings printed, 2 not a project under
Git.

Apart from --record-offered, it reads the project and writes nothing. Run it
from the project root:

    python3 <maintain skill folder>/scripts/document-bloat.py [--skip-offered]
    python3 <maintain skill folder>/scripts/document-bloat.py --record-offered < LINES
"""

import datetime
import os
import re
import subprocess
import sys
from collections import defaultdict

SKIPPED = {
    "AGENTS.md", "CLAUDE.md", "GEMINI.md", "WORKFLOW.md", "masterplan.md",
    "CHANGELOG.md", "plan.local.md",
}
SHORTEST_PARAGRAPH = 40


def tracked():
    result = subprocess.run(["git", "ls-files"], capture_output=True, text=True)
    return [f for f in result.stdout.split("\n") if f]


def documents(files):
    found = []
    for name in files:
        if not name.endswith(".md") or os.path.basename(name) in SKIPPED:
            continue
        if any(part.startswith(".") for part in name.split("/")[:-1]):
            continue
        if name.startswith("node_modules/") or not os.path.isfile(name):
            continue
        found.append(name)
    return found


def paragraphs(document):
    """Yield (first line, words) for each paragraph outside a fenced block."""
    with open(document, encoding="utf-8") as handle:
        lines = handle.read().split("\n")
    fenced, start, words = False, None, []
    for number, line in enumerate(lines + [""], start=1):
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        if fenced:
            continue
        if line.strip() and not line.lstrip().startswith("#"):
            if start is None:
                start = number
            words.extend(re.findall(r"[a-z0-9]+", line.lower()))
        elif start is not None:
            yield start, words
            start, words = None, []


def repeated(docs):
    seen = defaultdict(list)
    for document in docs:
        for line, words in paragraphs(document):
            if len(words) >= SHORTEST_PARAGRAPH:
                seen[" ".join(words)].append((document, line))
    found = []
    for places in seen.values():
        documents_here = {document for document, _ in places}
        if len(documents_here) < 2:
            continue
        (first, first_line), *others = sorted(places)
        for other, other_line in others:
            if other != first:
                found.append(("repeated", f"{first}:{first_line}", f"{other}:{other_line}"))
    return found


def unreferenced(docs, files):
    texts = {}
    for name in files:
        try:
            with open(name, encoding="utf-8") as handle:
                texts[name] = handle.read()
        except (OSError, UnicodeDecodeError):
            continue
    found = []
    for document in docs:
        if os.path.basename(document).lower() == "readme.md":
            continue
        base = os.path.basename(document)
        named = any(
            other != document and (document in text or base in text)
            for other, text in texts.items()
        )
        if not named:
            found.append(("unreferenced", document))
    return found


def findings():
    files = tracked()
    docs = documents(files)
    return repeated(docs) + unreferenced(docs, files)


RECORD = ".ai-build-kit-maintenance"
READ_NAME = "document-bloat"


def key(finding):
    """A finding without its line numbers, which move as the documents change."""
    return "|".join(part.rsplit(":", 1)[0] for part in finding)


def offered():
    try:
        with open(RECORD, encoding="utf-8") as handle:
            lines = handle.read().splitlines()
    except OSError:
        return set()
    return {parts[3] for parts in (line.split("|", 3) for line in lines)
            if len(parts) == 4 and parts[0] == "offered" and parts[1] == READ_NAME}


def record_offered(lines):
    known = offered()
    new = []
    for line in lines:
        fields = tuple(line.rstrip("\n").split("\t"))
        if not ((fields[0] == "repeated" and len(fields) == 3)
                or (fields[0] == "unreferenced" and len(fields) == 2)):
            continue
        found = key(fields)
        if found not in known and found not in new:
            new.append(found)
    try:
        with open(RECORD, encoding="utf-8") as handle:
            text = handle.read()
    except OSError:
        text = ""
    if new:
        if text and not text.endswith("\n"):
            text += "\n"
        today = datetime.date.today().isoformat()
        with open(RECORD, "w", encoding="utf-8") as handle:
            handle.write(text + "".join(f"offered|{READ_NAME}|{today}|{k}\n" for k in new))
    print(f"recorded\t{len(new)}")
    return 0


def main():
    if subprocess.run(["git", "rev-parse", "--git-dir"], capture_output=True).returncode != 0:
        print("This folder is not a project under Git.", file=sys.stderr)
        return 2
    if "--record-offered" in sys.argv[1:]:
        return record_offered(sys.stdin.readlines())
    found = findings()
    if "--skip-offered" in sys.argv[1:]:
        known = offered()
        found = [f for f in found if key(f) not in known]
    for finding in found:
        print("\t".join(finding))
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
