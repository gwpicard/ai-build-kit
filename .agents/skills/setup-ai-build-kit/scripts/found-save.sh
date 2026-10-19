#!/usr/bin/env sh
# found-save.sh: save founding's first checkpoint on this computer, then mark
# the masterplan as checked against it.
#
# Usage, from the project root:  sh found-save.sh ["<checkpoint message>"]
#
# It does four things, in order, and pushes nothing:
#   1. Makes the folder a Git repository on a branch called main, if it is not
#      one yet, and points Git at the project's push guard.
#   2. Sets a save name and email only where none is set, to the neutral
#      "Local project user", inside this project only. It never copies the
#      last commit's author, who may be somebody else entirely.
#   3. Makes sure Git ignores .env files, keeping .env.example, then saves the
#      founding checkpoint. In a new repository that is every file. Where the
#      repository already held work, it is the new files and the changes to
#      the records and the kit's own folders; a change to a file already saved
#      stays unsaved and is named. A file that looks like a key or password,
#      such as .env or a .pem file, stops the save before anything is staged.
#   4. Writes that checkpoint's hash into the masterplan's "Trued against:" line
#      and saves it in a second, records-only checkpoint, then checks the mark
#      with trued-mark.sh.
#
# Output lines have fields separated by tabs:
#   identity    kept | neutral
#   ignored     .env files          when .gitignore gained the .env lines
#   checkpoint  HASH
#   left        PATH  WHY           a change left out of the checkpoint
#   trued       HASH
#
# Exit 0: both checkpoints exist and the mark is usable.
# Exit 1: no new checkpoint was made, a file looked like a secret, or the mark
#         could not be written or read back. The line printed says which.
# Exit 2: usage error.

set -u

SKILL_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
message=${1:-Found the project}
[ "$#" -le 1 ] || { echo "usage: found-save.sh [\"<checkpoint message>\"]" >&2; exit 2; }
[ -f masterplan.md ] || { echo "found-save: there is no masterplan.md here; run it from the project root" >&2; exit 2; }
count=$(grep -c '^Trued against:' masterplan.md || true)
[ "$count" -eq 1 ] || { echo "found-save: the masterplan has $count Trued against: lines, so nothing was saved"; exit 1; }

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -q || { echo "found-save: Git could not start a repository here"; exit 1; }
  git symbolic-ref HEAD refs/heads/main
fi
top=$(CDPATH= cd -- "$(git rev-parse --show-toplevel)" && pwd -P)
[ "$top" = "$(pwd -P)" ] || {
  echo "found-save: this folder sits inside the Git repository at $top, so nothing was saved"
  exit 1
}
sh "$SKILL_ROOT/scripts/use-push-guard.sh" . ||
  { echo "found-save: the push guard is not on; run use-push-guard.sh from the project folder before saving" >&2; exit 1; }

name=$(git config --get user.name || true)
email=$(git config --get user.email || true)
if [ -n "$name" ] && [ -n "$email" ]; then
  echo "identity	kept"
else
  [ -n "$name" ] || git config --local user.name "Local project user"
  [ -n "$email" ] || git config --local user.email "local-project-user@localhost"
  echo "identity	neutral"
fi

# Keys and passwords live in .env files, which never go into a checkpoint.
# Make sure Git ignores them before anything is staged.
need=
{ git check-ignore -q .env && git check-ignore -q .env.local; } 2>/dev/null || need=yes
git check-ignore -q .env.example 2>/dev/null && need=yes
if [ -n "$need" ]; then
  if [ -s .gitignore ] && [ -n "$(tail -c1 .gitignore)" ]; then printf '\n' >> .gitignore; fi
  printf '%s\n' '# Keys and passwords stay on this computer.' '.env*' '!.env.example' >> .gitignore ||
    { echo "found-save: .gitignore could not be written, so nothing was saved"; exit 1; }
  echo "ignored	.env files"
fi

before=$(git rev-parse -q --verify HEAD || true)
untracked=$(git -c core.quotepath=off ls-files --others --exclude-standard)
if [ -n "$before" ]; then
  # The repository already held work. Only what founding writes goes into the
  # checkpoint: new files, and changes to the records and the kit's own
  # folders. A change to a file already saved is somebody's work in progress.
  changed=$(git -c core.quotepath=off diff --name-only HEAD --)
else
  changed=$(git -c core.quotepath=off diff --cached --name-only 2>/dev/null || true)
fi
founding_path() {
  [ -z "$before" ] && return 0
  case "$1" in
    masterplan.md|CHANGELOG.md|AGENTS.md|CLAUDE.md|GEMINI.md|README.md|.gitignore|.ai-build-kit-maintenance) return 0 ;;
    .agents/*|.claude/*|.cursor/*|.gemini/*|.codex/*|.github/*) return 0 ;;
  esac
  return 1
}
looks_secret() {
  case "${1##*/}" in
    .env.example) return 1 ;;
    .env|.env.*|*.pem|*.key|*.p12|*.pfx|*.jks|*.keystore|id_rsa|id_dsa|id_ecdsa|id_ed25519|.netrc|credentials.json|service-account*.json) return 0 ;;
  esac
  return 1
}

list=$(git rev-parse --git-path ai-build-kit-founding-files)
: > "$list"
left=
secrets=
while IFS= read -r file; do
  [ -n "$file" ] || continue
  if ! founding_path "$file" && ! printf '%s\n' "$untracked" | grep -qxF -- "$file"; then
    left="$left$file
"
    continue
  fi
  looks_secret "$file" && secrets="$secrets  $file
"
  printf '%s\n' "$file" >> "$list"
done <<EOF
$(printf '%s\n%s\n' "$untracked" "$changed" | sed '/^$/d' | sort -u)
EOF
if [ -n "$secrets" ]; then
  rm -f "$list"
  echo "found-save: these files look like keys or passwords, so nothing was saved:"
  printf '%s' "$secrets"
  exit 1
fi
[ -s "$list" ] || { rm -f "$list"; echo "found-save: no new checkpoint was made, because nothing was waiting to be saved"; exit 1; }
GIT_LITERAL_PATHSPECS=1 git add -A --pathspec-from-file="$list" &&
  GIT_LITERAL_PATHSPECS=1 git commit -q -m "$message" --pathspec-from-file="$list" ||
  { rm -f "$list"; echo "found-save: no new checkpoint was made, because Git refused the commit"; exit 1; }
rm -f "$list"
printf '%s' "$left" | while IFS= read -r file; do
  [ -n "$file" ] && printf 'left\t%s\tnot founding'\''s, so it stays unsaved\n' "$file"
done
checkpoint=$(git rev-parse HEAD)
[ "$checkpoint" != "$before" ] || { echo "found-save: no new checkpoint was made"; exit 1; }
echo "checkpoint	$checkpoint"

python3 - "$checkpoint" <<'PY' || { echo "found-save: the mark could not be written"; exit 1; }
import sys
path = "masterplan.md"
with open(path, encoding="utf-8", newline="") as handle:
    lines = handle.readlines()
for index, line in enumerate(lines):
    if line.startswith("Trued against:"):
        ending = line[len(line.rstrip("\r\n")):]
        lines[index] = "Trued against: " + sys.argv[1] + ending
with open(path, "w", encoding="utf-8", newline="") as handle:
    handle.writelines(lines)
PY
git add masterplan.md
git commit -q -m "Mark the masterplan as checked against the founding checkpoint" -- masterplan.md ||
  { echo "found-save: the mark was written but not saved"; exit 1; }
[ "$(git rev-parse HEAD)" != "$checkpoint" ] || { echo "found-save: no records-only checkpoint was made"; exit 1; }

mark=$(sh "$SKILL_ROOT/../records/scripts/trued-mark.sh" masterplan.md) || { echo "found-save: $mark"; exit 1; }
echo "trued	${mark#usable: }"
exit 0
