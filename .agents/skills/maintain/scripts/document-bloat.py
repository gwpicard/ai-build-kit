#!/usr/bin/env python3
"""List the project's documents that repeat each other or are no longer needed.

Reads every Markdown document git tracks, apart from the kit's own files, the
project records and anything in a folder whose name starts with a dot. It
prints one line for each of three findings, and nothing when there are none:

    repeated<TAB>document:line<TAB>other-document:line
        The same paragraph, of forty words or more, in two documents.
    unreferenced<TAB>document<TAB>
        No other file in the project names the document. A README is never
        listed, since it is where a reader starts.
    dead<TAB>document<TAB>the names that no longer exist
        The document names at least three files, links, commands or settings,
        and more than half of them no longer exist.

It compares paragraphs word for word, after ignoring case, spacing and
punctuation, so it finds a copy and never two documents that say the same
thing in different words.

It reads the project and writes nothing. Run it from the project root:

    python3 .agents/skills/maintain/scripts/document-bloat.py
"""

import importlib.util
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
FEWEST_NAMES = 3


def load_claims():
    # Loading a script this way normally leaves a cache folder beside it, which
    # in a project is inside the project. This read writes nothing.
    sys.dont_write_bytecode = True
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, "..", "..", "sync", "scripts", "document-claims.py")
    spec = importlib.util.spec_from_file_location("document_claims", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


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
            found.append(("unreferenced", document, ""))
    return found


def dead(docs, claims):
    scripts, targets = claims.package_scripts(), claims.make_targets()
    found = []
    for document in docs:
        missing = claims.claims(document, docs, scripts, targets)
        named = count_names(document, claims, scripts, targets)
        if named >= FEWEST_NAMES and len(missing) * 2 > named:
            gone = ", ".join(sorted({name for _, _, name in missing}))
            found.append(("dead", document, gone))
    return found


def count_names(document, claims, scripts, targets):
    """How many checkable names the document mentions, gone or not."""
    total = 0
    fenced = False
    with open(document, encoding="utf-8") as handle:
        lines = handle.read().split("\n")
    for line in lines:
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        total += sum(
            1 for target in claims.LINK.findall(line)
            if not target.startswith(("http:", "https:", "mailto:", "#"))
        )
        total += len(list(claims.COMMAND.finditer(line)))
        if not fenced:
            for span in claims.CODE_SPAN.findall(line):
                span = span.strip()
                if claims.ENV_NAME.match(span) or claims.looks_like_path(span):
                    total += 1
    return total


def main():
    files = tracked()
    docs = documents(files)
    claims = load_claims()
    for kind, place, detail in repeated(docs) + unreferenced(docs, files) + dead(docs, claims):
        print(f"{kind}\t{place}\t{detail}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
