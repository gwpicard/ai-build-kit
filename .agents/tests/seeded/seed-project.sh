#!/usr/bin/env sh
# seed-project.sh: write one product's starting state into a project folder that
# already holds the kit.
#
# The runner copies the assembled kit into a fresh folder, then calls this to
# add what a founded project would have: the stack lines in AGENTS.md, a
# masterplan, a changelog, the product's code, and one ready piece for the
# GitHub stand-in to hold. It writes nothing before the first commit that the
# kit could not have seen in a real project.
#
# Fault keys are never read or copied here. A key lives in keys/ and only the
# scorer reads it, after the run.
#
# Usage: seed-project.sh <project-dir> <product-dir> <fault|twin>

set -eu

project=${1:?project directory}
product=${2:?product directory}
variant=${3:?fault or twin}
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
today=${SEEDED_TODAY:-$(date -u +%Y-%m-%d)}

case "$variant" in
  fault | twin) ;;
  *)
    echo "seed-project.sh: the variant is fault or twin, not '$variant'" >&2
    exit 2
    ;;
esac
[ -d "$product/start" ] && [ -f "$product/piece.md" ] && [ -f "$product/masterplan.md" ] || {
  echo "seed-project.sh: $product is not a product folder" >&2
  exit 2
}
[ -f "$project/AGENTS.md" ] || {
  echo "seed-project.sh: $project does not hold the kit" >&2
  exit 2
}
for already in masterplan.md CHANGELOG.md package.json .gh-fixture.json; do
  [ ! -e "$project/$already" ] || {
    echo "seed-project.sh: $project already has $already" >&2
    exit 2
  }
done

# The product's code: the shared Next.js base, then the product, then for the
# twin only the files that differ.
cp -R "$here/products/_base/." "$project/"
cp -R "$product/start/." "$project/"
if [ "$variant" = twin ] && [ -d "$product/twin/files" ]; then
  cp -R "$product/twin/files/." "$project/"
fi

# The records. The twin may carry its own masterplan or piece.
pick() {
  if [ "$variant" = twin ] && [ -f "$product/twin/$1" ]; then
    printf '%s' "$product/twin/$1"
  else
    printf '%s' "$product/$1"
  fi
}
sed "s/{{TODAY}}/$today/g" "$(pick masterplan.md)" > "$project/masterplan.md"
sed "s/{{TODAY}}/$today/g" "$(pick CHANGELOG.md)" > "$project/CHANGELOG.md"

# Keep build output and installed packages out of the saved work.
for line in node_modules .next next-env.d.ts; do
  grep -qx "$line" "$project/.gitignore" 2>/dev/null || printf '%s\n' "$line" >> "$project/.gitignore"
done

python3 - "$project" "$(pick piece.md)" "$product/about.md" "$today" <<'PY'
import json
import os
import sys

project, piece_file, about_file, today = sys.argv[1:5]

# AGENTS.md: the stack section founding fills in, and what the project is.
path = os.path.join(project, "AGENTS.md")
text = open(path).read()
start = text.find("(Filled in by the setup-ai-build-kit skill: `Recipe:")
if start < 0:
    sys.exit("seed-project.sh: AGENTS.md has no stack section to fill in")
end = text.find("\n\n", start)
if end < 0:
    end = len(text.rstrip("\n"))
stack = """Recipe: nextjs-supabase-on-vercel
Run: `npm run dev`, once `npm install` has run.
Test: `npm test`. It runs Node's own test runner and needs nothing installed.
Type check: `npx tsc --noEmit`, run by the project check on GitHub.
Lint: `npx eslint .`, run by the project check on GitHub.

Dependencies are not installed on this computer, and nothing here needs them:
the tests run without them, and the project check on GitHub runs the type check
and the linter on every pull request. `gh pr checks` shows its result.
Design tool: none recorded"""
text = text[:start] + stack + text[end:]
text += "\n## This project\n\n" + open(about_file).read()
open(path, "w").write(text)

with open(os.path.join(project, ".ai-build-kit-maintenance"), "w") as handle:
    handle.write("# AI Build Kit check-up dates. UTC, written as YYYY-MM-DD. start writes founded,\n"
                 "# and a founding-menu line naming the recipes on the menu it showed; maintain\n"
                 "# writes the two pass lines, and a recipe-move-declined line when the person\n"
                 "# turns down a move onto a recipe. Nothing else edits this file.\n"
                 "founded|%s\n"
                 "founding-menu|%s|nextjs-supabase-on-coolify,nextjs-supabase-on-vercel\n"
                 "last-light-pass|%s\n"
                 "last-full-pass|%s\n" % (today, today, today, today))

# The ready piece, as the kit would find it on GitHub.
lines = open(piece_file).read().split("\n")
title = lines[0].replace("Title:", "", 1).strip()
labels = [label.strip() for label in lines[1].replace("Labels:", "", 1).split(",") if label.strip()]
body = "\n".join(lines[3:]).strip() + "\n"
state = {
    "repo": "seeded/product",
    "next": 2,
    "issues": [{"number": 1, "title": title, "state": "open", "labels": labels,
                "assignees": [], "blocked_by": [], "body": body}],
}
with open(os.path.join(project, ".gh-fixture.json"), "w") as handle:
    json.dump(state, handle, indent=1)
    handle.write("\n")
PY

echo "seeded $(basename "$product") ($variant)"
