#!/usr/bin/env sh
# use-starter.sh: copy a recipe's pinned starter without replacing project files.

set -eu

SKILL_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P) || exit 2
[ "$#" -ge 1 ] && [ "$#" -le 2 ] || {
  echo "could not run: usage: use-starter.sh <recipe-folder> [project-folder]" >&2
  exit 2
}
command -v python3 >/dev/null 2>&1 || {
  echo "could not run: python3 is required to copy the starter safely" >&2
  exit 2
}
python3 - "$SKILL_ROOT" "$@" <<'PY'
import os
import shutil
import sys

def stop(message, code=2):
    print(message, file=sys.stderr)
    raise SystemExit(code)

skill = os.path.realpath(sys.argv[1])
recipe_arg = sys.argv[2]
recipe = recipe_arg if os.path.isabs(recipe_arg) else os.path.join(skill, "..", "setup-hosting", recipe_arg)
if not os.path.isdir(recipe) or os.path.islink(recipe):
    stop("could not run: recipe folder is missing or redirected")
recipe = os.path.realpath(recipe)
recipe_file = os.path.join(recipe, "recipe.md")
if not os.path.isfile(recipe_file) or os.path.islink(recipe_file):
    stop("could not run: recipe.md is missing")
with open(recipe_file, encoding="utf-8") as handle:
    starters = [line.removeprefix("Starter: ").strip() for line in handle if line.startswith("Starter: ")]
if len(starters) != 1 or not starters[0] or os.path.isabs(starters[0]):
    stop("could not run: recipe has no safe Starter path")
starter = os.path.realpath(os.path.join(recipe, starters[0]))
allowed = os.path.realpath(os.path.join(skill, "..", "setup-hosting", "recipes", "parts", "starters"))
if os.path.commonpath((allowed, starter)) != allowed or not os.path.isdir(starter):
    stop("could not run: starter folder is missing or outside the shared recipe starter directory")
project = sys.argv[3] if len(sys.argv) == 4 else os.getcwd()
if not os.path.isdir(project):
    stop("could not run: project folder does not exist")
project = os.path.realpath(project)
if project == os.path.sep or project == starter:
    stop("could not run: choose a project folder outside the starter")

files = []
for root, dirs, names in os.walk(starter, followlinks=False):
    if any(os.path.islink(os.path.join(root, name)) for name in dirs):
        stop("could not run: starter contains a redirected folder")
    for name in names:
        source = os.path.join(root, name)
        if os.path.islink(source) or not os.path.isfile(source):
            stop("could not run: starter contains a non-regular file")
        files.append((source, os.path.relpath(source, starter)))
if not files:
    stop("could not run: starter folder is empty")

clashes = []
for _, relative in files:
    target = os.path.join(project, relative)
    parent = os.path.dirname(target)
    while parent != project and os.path.commonpath((project, parent)) == project:
        if os.path.islink(parent):
            stop("could not run: project path is redirected: " + relative)
        if os.path.exists(parent) and not os.path.isdir(parent):
            clashes.append(relative)
            break
        next_parent = os.path.dirname(parent)
        if next_parent == parent:
            break
        parent = next_parent
    if os.path.lexists(target):
        clashes.append(relative)
if clashes:
    print("refused: these starter files already exist:", file=sys.stderr)
    for relative in sorted(set(clashes)):
        print(relative, file=sys.stderr)
    raise SystemExit(1)

try:
    for source, relative in files:
        target = os.path.join(project, relative)
        os.makedirs(os.path.dirname(target), exist_ok=True)
        shutil.copy2(source, target)
except OSError as error:
    stop("could not run: a starter file could not be copied: " + str(error))
print("Copied the pinned starter into the project.")
PY
