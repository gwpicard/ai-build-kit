#!/usr/bin/env python3
"""Report a project's recorded recipe when it is stale or uses an old name."""
import datetime
import re
import sys
from pathlib import Path


def main():
    root = Path(sys.argv[1] if len(sys.argv) == 2 else ".").resolve()
    agents = root / "AGENTS.md"
    if not agents.is_file():
        print("could not run: AGENTS.md is missing")
        return 2
    match = re.search(r"^Recipe: ([^\s]+)\s*$", agents.read_text(), re.M)
    if not match or match.group(1) == "none":
        return 0
    name = match.group(1).removesuffix(".md")
    recipes = (
        root / ".agents/skills/setup-hosting/recipes" / name / "recipe.md",
        root / ".claude/skills/setup-hosting/recipes" / name / "recipe.md",
    )
    recipe = next((path for path in recipes if path.is_file()), None)
    if recipe is None:
        print("Recipe superseded: %s has left the menu; /maintain can offer a move to a current recipe." % name)
        return 1
    text = recipe.read_text()
    checked = re.search(r"^Last checked: (\d{4}-\d{2}-\d{2})$", text, re.M)
    if not checked:
        print("could not run: recipe has no Last checked date")
        return 2
    try:
        checked_date = datetime.date.fromisoformat(checked.group(1))
    except ValueError:
        print("could not run: recipe Last checked date is invalid")
        return 2
    stale = (datetime.date.today() - checked_date).days > 90
    old = []
    names = re.search(r"^Superseded settings: (.+)$", text, re.M)
    if names and names.group(1).strip() != "none":
        for setting in [part.strip() for part in names.group(1).split(",")]:
            for path in root.rglob("*"):
                if not path.is_file() or any(part in {".git", "node_modules", ".next"} for part in path.parts):
                    continue
                if path.name not in {".env", ".env.example", ".env.local.example", "Dockerfile"}:
                    continue
                try:
                    if setting in path.read_text(errors="ignore"):
                        old.append(setting)
                        break
                except OSError:
                    continue
    if not stale and not old:
        return 0
    reason = "; ".join((["last checked %s" % checked.group(1)] if stale else []) +
                       (["superseded setting %s" % ", ".join(old)] if old else []))
    print("Recipe stale: %s, %s. I can open a piece to move it onto a current recommendation." % (name, reason))
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
