#!/usr/bin/env python3
"""check-release-notes.py: refuse a version's notes until the writing rules a
machine can test hold and a fresh review has passed the final text.

Usage: check-release-notes.py vX.Y.Z

Why this exists. The release-notes skill, the house rules in MAINTAINING.md and
the humanizer step in AGENTS.md each hold part of what a release's notes need.
Spread across three files, a step was skipped and nothing noticed: notes went
towards a stamp without the house-rule pass, without a second review after the
first review's fixes, and without the rewritten pull request list for the
Release's page. `stamp-version.sh` runs this before it writes a version, so the
parts a machine can test are no longer left to memory.

It checks:
  - `docs/release-notes/<version>.md` exists, with `## Updating` and
    `## What changes`;
  - no em or en dash, no contraction, no issue or pull request number, no cost
    figure, and none of the house rules' banned words;
  - no paragraph or list item longer than the house limit;
  - `.agents/tmp/release-notes-review/<version>/page.md`, the full text for the
    Release's page, holds the notes file word for word and a
    `## Pull requests in this release` list;
  - `review.md` beside it is newer than `page.md` and ends with a count line
    showing zero Critical and zero Major findings.

The humanizer pass itself cannot be tested here. The skill's checklist names it.
"""

import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
WORD_LIMIT = 110
BANNED = ("leverag", "robust", "comprehensive", "seamless", "crucial", "foster",
          "enhanc", "transformative", "delve", "empower", "streamlin", "holistic")
CONTRACTION = re.compile(
    r"\b\w+n't\b|\b(?:it|that|there|here|you|we|they|i|he|she|what|who|let)"
    r"'(?:s|re|ll|ve|d|m)\b", re.IGNORECASE)
NUMBER = re.compile(r"(?<![\w/.])#\d+\b|/(?:pull|issues)/\d+")
COST = re.compile(r"[$£€]\s?\d")


def blocks(text):
    """Paragraphs and list items, each as one string."""
    out, current = [], []
    for line in text.splitlines():
        starts_item = re.match(r"\s*(?:[-*]|\d+\.)\s", line)
        if not line.strip() or line.startswith("#") or starts_item:
            if current:
                out.append(" ".join(current))
            current = []
            if starts_item:
                current = [line.strip()]
            continue
        current.append(line.strip())
    if current:
        out.append(" ".join(current))
    return out


def check_text(text, label):
    problems = []
    for n, line in enumerate(text.splitlines(), 1):
        where = "%s:%d" % (label, n)
        if "—" in line or "–" in line:
            problems.append(where + ": an em or en dash; use a comma, colon or full stop")
        for m in CONTRACTION.finditer(line):
            problems.append(where + ": a contraction, %r" % m.group(0))
        for m in NUMBER.finditer(line):
            problems.append(where + ": an issue or pull request number, %r" % m.group(0))
        if COST.search(line):
            problems.append(where + ": a cost figure")
        lowered = line.lower()
        for stem in BANNED:
            if re.search(r"\b" + stem, lowered):
                problems.append(where + ": a banned word starting %r" % stem)
    for block in blocks(text):
        words = len(block.split())
        if words > WORD_LIMIT:
            problems.append("%s: a paragraph of %d words, over %d: %s..."
                            % (label, words, WORD_LIMIT, block[:50]))
    return problems


def main(argv):
    if len(argv) != 2 or not re.fullmatch(r"v\d+\.\d+\.\d+", argv[1]):
        print("usage: check-release-notes.py vX.Y.Z", file=sys.stderr)
        return 2
    version = argv[1]
    notes_path = os.path.join(ROOT, "docs", "release-notes", version + ".md")
    review_dir = os.path.join(ROOT, ".agents", "tmp", "release-notes-review", version)
    page_path = os.path.join(review_dir, "page.md")
    review_path = os.path.join(review_dir, "review.md")
    problems = []

    if not os.path.isfile(notes_path):
        print("refused: the %s notes are not ready to stamp: docs/release-notes/%s.md "
              "does not exist. Write it with .agents/maintainer-skills/release-notes/SKILL.md."
              % (version, version), file=sys.stderr)
        return 1
    notes = open(notes_path, encoding="utf-8").read()
    for heading in ("## Updating", "## What changes"):
        if not re.search(r"^" + re.escape(heading) + r"\s*$", notes, re.MULTILINE):
            problems.append("the notes have no %r section" % heading)
    problems += check_text(notes, "docs/release-notes/%s.md" % version)

    if not os.path.isfile(page_path):
        problems.append("no page text at .agents/tmp/release-notes-review/%s/page.md "
                        "(the notes plus the rewritten pull request list)" % version)
    else:
        page = open(page_path, encoding="utf-8").read()
        if notes.strip() not in page:
            problems.append("page.md does not hold the current notes file word for word; "
                            "rebuild it and have it reviewed again")
        if not re.search(r"^## Pull requests in this release\s*$", page, re.MULTILINE):
            problems.append("page.md has no '## Pull requests in this release' list")
        else:
            listed = page.split("## Pull requests in this release", 1)[1]
            problems += check_text(listed, "page.md pull request list")

    if not os.path.isfile(review_path):
        problems.append("no fresh review recorded at .agents/tmp/release-notes-review/%s/review.md"
                        % version)
    else:
        if os.path.isfile(page_path) and os.path.getmtime(review_path) < os.path.getmtime(page_path):
            problems.append("review.md is older than page.md; the final text has not been reviewed")
        lines = [l for l in open(review_path, encoding="utf-8").read().splitlines() if l.strip()]
        last = lines[-1] if lines else ""
        counts = dict((k.lower(), int(v)) for k, v in
                      re.findall(r"\b(Critical|Major)\s*:\s*(\d+)", last, re.IGNORECASE))
        if "critical" not in counts or "major" not in counts:
            problems.append("review.md does not end with a count line such as "
                            "'Critical: 0 · Major: 0 · Minor: 2'")
        elif counts["critical"] or counts["major"]:
            problems.append("the latest review found %d Critical and %d Major; fix them "
                            "and review the final text again" % (counts["critical"], counts["major"]))

    if problems:
        print("refused: the %s notes are not ready to stamp:" % version, file=sys.stderr)
        for p in problems:
            print("  - " + p, file=sys.stderr)
        return 1
    print("the %s notes pass the checks a machine can make; the humanizer pass is "
          "the maintainer's to confirm" % version)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
