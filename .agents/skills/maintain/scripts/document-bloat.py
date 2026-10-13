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

With --since-visit it prints only what is new since the last full visit: a
finding already there on the `last-full-pass` date in
`.ai-build-kit-maintenance` was offered then, so it is left out. That earlier
state is read again from Git history, in a temporary copy, and never saved.

Exit codes: 0 nothing to report, 1 findings printed, 2 not a project under
Git.

It reads the project and writes nothing. Run it from the project root:

    python3 <maintain skill folder>/scripts/document-bloat.py [--since-visit]
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile
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


def key(finding):
    return tuple(part.rsplit(":", 1)[0] for part in finding)


def at_last_visit():
    """The findings as they stood at the last full visit, or None when there is none."""
    try:
        with open(".ai-build-kit-maintenance", encoding="utf-8") as handle:
            record = handle.read()
    except OSError:
        return None
    date = re.search(r"^last-full-pass:?\s*(\d{4}-\d{2}-\d{2})", record, re.M)
    if not date:
        return None
    commit = subprocess.run(["git", "rev-list", "-1", f"--before={date.group(1)} 23:59:59", "HEAD"],
                            capture_output=True, text=True).stdout.strip()
    if not commit:
        return None
    here, folder = os.getcwd(), tempfile.mkdtemp()
    copy = os.path.join(folder, "earlier")
    try:
        cloned = subprocess.run(["git", "clone", "-q", "--shared", "--no-checkout", here, copy],
                                capture_output=True).returncode == 0
        if not cloned or subprocess.run(["git", "checkout", "-q", "--detach", commit], cwd=copy,
                                        capture_output=True).returncode != 0:
            return None
        os.chdir(copy)
        return findings()
    finally:
        os.chdir(here)
        shutil.rmtree(folder, ignore_errors=True)


def main():
    if subprocess.run(["git", "rev-parse", "--git-dir"], capture_output=True).returncode != 0:
        print("This folder is not a project under Git.", file=sys.stderr)
        return 2
    found = findings()
    if "--since-visit" in sys.argv[1:]:
        earlier = at_last_visit()
        if earlier is not None:
            known = {key(f) for f in earlier}
            found = [f for f in found if key(f) not in known]
    for finding in found:
        print("\t".join(finding))
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
