#!/usr/bin/env python3
"""legacy-masterplan.py: give a project the build-path section an older kit reads.

An older release starts every session by reading the build-path section at the top
of the masterplan. The replay fixtures carry a risk record instead, so every run of
that release stopped at its own startup check and measured nothing. This rewrites
the risk record as the build-path section that release expects, from the same
facts, and leaves every other section as it was.

Usage: legacy-masterplan.py <masterplan.md>
Exit 0 when the file now holds a build-path section (or already did), 1 when the
file has neither section to work from.
"""
import re
import sys


def main(path):
    text = open(path).read()
    if re.search(r"(?m)^## Build path\s*$", text):
        return 0
    match = re.search(r"(?ms)^## Risk record\s*$(.*?)(?=^## |\Z)", text)
    if not match:
        return 1
    fields, name = {}, None
    for line in match.group(1).splitlines():
        found = re.match(r"^([A-Z][A-Za-z ]*):\s*(.*)$", line)
        if found:
            name = found.group(1)
            fields[name] = found.group(2).strip()
        elif name and line.strip():
            fields[name] += " " + line.strip()
    areas = fields.get("Risk areas", "none")
    careful = not areas.lower().startswith("none")
    why = " ".join(fields.get(k, "") for k in ("Exposed", "Data", "Wrong answer", "Recovery")).strip()
    section = "\n".join([
        "## Build path",
        "",
        "Path: " + ("Build with care" if careful else "Build and run it"),
        "Why: " + why,
        "Sensitive areas: " + areas,
        "Accepted: " + fields.get("Accepted", "none"),
        "Recheck when: " + fields.get("Recheck when", ""),
        "Last checked: " + fields.get("Last checked", ""),
        "",
        "",
    ])
    open(path, "w").write(text[:match.start()] + section + text[match.end():])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
