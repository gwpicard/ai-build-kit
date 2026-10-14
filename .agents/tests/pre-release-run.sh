#!/usr/bin/env sh
# pre-release-run.sh: check the pre-release run in docs/MAINTAINING.md still
# works as written.
#
# If this breaks, a maintainer following it on release day could meet a path
# that no longer exists, or a preview version the builder refuses.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
pass=0
ok() { echo "  ok: $1"; pass=$((pass + 1)); }
fail() { echo "FAIL: $1" >&2; exit 1; }

DOC="$ROOT/docs/MAINTAINING.md"
HEADING='## Trying unreleased work as a person would'

SECTION="$WORK/section.md"
awk -v h="$HEADING" '
  $0 == h { on = 1; print; next }
  on && /^## / { exit }
  on { print }
' "$DOC" > "$SECTION"
[ -s "$SECTION" ] || fail "MAINTAINING.md has no section headed '$HEADING'"
ok "the section exists"

# Every repository path the section names has to exist, or a maintainer
# following it on release day meets a missing file.
paths=$(grep -oE '\.agents/[A-Za-z0-9_./-]*[A-Za-z0-9_-]/?' "$SECTION" | sort -u)
[ -n "$paths" ] || fail "the section names no repository path"
for p in $paths; do
  [ -e "$ROOT/$p" ] || fail "the section names $p, which does not exist"
done
ok "every repository path the section names exists"

# The builder's own argument check decides the version form. It checks the
# version before the output folder, so an output under a missing parent tells
# an accepted version from a refused one without building anything.
build_line=$(grep -E '^ *\.agents/tools/build-release\.sh ' "$SECTION" || true)
[ "$(printf '%s\n' "$build_line" | grep -c .)" -eq 1 ] \
  || fail "the section should give exactly one build command"
version=$(printf '%s\n' "$build_line" | awk '{print $2}' | sed 's/N$/7/')
probe() {
  sh "$ROOT/.agents/tools/build-release.sh" "$1" "$WORK/no-such-parent/out" 2>&1 || true
}
case "$(probe "$version")" in
  *"output parent does not exist"*) ok "build-release.sh accepts the version form $version" ;;
  *) fail "build-release.sh refuses the version the section gives: $version" ;;
esac
case "$(probe "v0.0.0.preview")" in
  *"version must look like"*) ok "the probe tells a refused version apart" ;;
  *) fail "the version probe cannot tell a refused version from an accepted one" ;;
esac

# The teardown deletes real projects and repositories, so its commands are
# held here as commands, not as sentences.
if grep -qE '(^|[^[:alnum:]])rm +-[a-zA-Z]*[rR]' "$SECTION"; then
  fail "the section deletes something recursively with rm; the teardown trashes items one by one"
fi
ok "no recursive rm in the section"
add_line=$(grep -nE 'gh auth refresh .*-s +delete_repo' "$SECTION" | head -1 | cut -d: -f1)
del_line=$(grep -nE 'gh repo delete ' "$SECTION" | head -1 | cut -d: -f1)
off_line=$(grep -nE 'gh auth refresh .*-r +delete_repo' "$SECTION" | head -1 | cut -d: -f1)
[ -n "$add_line" ] && [ -n "$del_line" ] && [ -n "$off_line" ] \
  && [ "$add_line" -lt "$del_line" ] && [ "$del_line" -lt "$off_line" ] \
  || fail "the repository delete must sit between adding the delete scope and taking it off again"
ok "the delete scope is added just for the delete and taken off after it"
grep -qE 'find .*-newer ' "$SECTION" || fail "the teardown no longer finds what the run made by the start marker"
ok "the teardown finds the run's files by the start marker"
for place in '/private/tmp/abk-' '~/.config/abk-try-' '~/Backups/abk-try-' '~/.abk-try-'; do
  grep -qE "^ *ls $(printf '%s' "$place" | sed 's/[.]/[.]/g')" "$SECTION" \
    || fail "the teardown no longer checks that $place... is gone"
done
ok "the teardown checks each place it cleaned, the backups included"

echo
echo "$(basename -- "$0"): all $pass checks passed"
