#!/usr/bin/env sh
# update-kit.sh: plan or apply a conflict-aware update of kit-owned files in an
# existing project. The caller supplies unpacked official current and next
# starter releases; this script never downloads or publishes anything.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)

fail() {
  echo "error: $1" >&2
  exit 1
}

if [ "$#" -ne 3 ]; then
  fail "usage: update-kit.sh <plan|apply> <current-release-folder> <new-release-folder>"
fi

MODE=$1
BASE=$2
NEW=$3
case "$MODE" in
  plan|apply) ;;
  *) fail "first argument must be plan or apply" ;;
esac

[ -d "$BASE" ] || fail "current release folder does not exist: $BASE"
[ -d "$NEW" ] || fail "new release folder does not exist: $NEW"
BASE=$(CDPATH= cd -- "$BASE" && pwd -P)
NEW=$(CDPATH= cd -- "$NEW" && pwd -P)
case "$BASE" in "$ROOT"|"$ROOT"/*) fail "current release folder must be outside the project" ;; esac
case "$NEW" in "$ROOT"|"$ROOT"/*) fail "new release folder must be outside the project" ;; esac

project_root=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || true)
[ "$project_root" = "$ROOT" ] || fail "AI Build Kit updater must run from the project root"

safe_path() {
  checked_path=$1
  case "$checked_path" in
    ""|/*|.|..|../*|*/../*|*/..|*//*|*/|*'|'*)
      fail "managed file has an unsafe path: $checked_path"
      ;;
  esac
}

assert_no_symlink_components() {
  checked_root=$1
  checked_relative=$2
  checked_label=$3
  safe_path "$checked_relative"
  checked_remaining=$checked_relative
  checked_prefix=
  while :; do
    case "$checked_remaining" in
      */*)
        checked_component=${checked_remaining%%/*}
        checked_remaining=${checked_remaining#*/}
        ;;
      *)
        checked_component=$checked_remaining
        checked_remaining=
        ;;
    esac
    if [ -n "$checked_prefix" ]; then
      checked_prefix="$checked_prefix/$checked_component"
    else
      checked_prefix=$checked_component
    fi
    [ ! -L "$checked_root/$checked_prefix" ] || \
      fail "$checked_label uses a symbolic link: $checked_prefix"
    [ -n "$checked_remaining" ] || break
  done
}

stable_version() {
  printf '%s\n' "$1" | grep -Eq '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
}

read_version() {
  release_root=$1
  [ -f "$release_root/.ai-build-kit-version" ] || \
    fail "release has no version marker: $release_root"
  cat "$release_root/.ai-build-kit-version"
}

validate_release() {
  release_root=$1
  label=$2
  assert_no_symlink_components "$release_root" ".ai-build-kit-version" "$label release"
  assert_no_symlink_components "$release_root" ".ai-build-kit-managed" "$label release"
  release_version=$(read_version "$release_root")
  stable_version "$release_version" || fail "$label release version is not stable: $release_version"
  managed="$release_root/.ai-build-kit-managed"
  [ -f "$managed" ] || fail "$label release has no managed-file record"
  [ "$(awk -F'|' '$1 == "version" { print $2; exit }' "$managed")" = "$release_version" ] || \
    fail "$label managed-file record has the wrong version"

  seen="
"
  while IFS='|' read -r kind value path extra; do
    case "$kind" in
      ""|'#'*) continue ;;
      version|source) continue ;;
      file)
        [ -z "${extra:-}" ] || fail "$label managed-file line has too many fields"
        case "$value" in 100644|100755) ;; *) fail "$label managed file has invalid mode: $path" ;; esac
        safe_path "$path"
        assert_no_symlink_components "$release_root" "$path" "$label release"
        case "$seen" in *"
$path
"*) fail "$label managed file appears twice: $path" ;; esac
        seen="$seen$path
"
        [ -f "$release_root/$path" ] && [ ! -L "$release_root/$path" ] || \
          fail "$label managed file is missing or is not a regular file: $path"
        ;;
      *) fail "$label managed-file record has unknown entry: $kind" ;;
    esac
  done < "$managed"
}

validate_release "$BASE" "current"
validate_release "$NEW" "new"

assert_no_symlink_components "$ROOT" ".ai-build-kit-version" "project"
CURRENT_VERSION=$(cat "$ROOT/.ai-build-kit-version" 2>/dev/null || true)
BASE_VERSION=$(read_version "$BASE")
NEW_VERSION=$(read_version "$NEW")
[ -n "$CURRENT_VERSION" ] || fail "project has no AI Build Kit version marker"
[ "$CURRENT_VERSION" = "$BASE_VERSION" ] || \
  fail "project uses $CURRENT_VERSION but the supplied current release is $BASE_VERSION"

is_forward=$(awk -v current="$CURRENT_VERSION" -v candidate="$NEW_VERSION" 'BEGIN {
  sub(/^v/, "", current)
  sub(/^v/, "", candidate)
  split(current, a, ".")
  split(candidate, b, ".")
  for (i = 1; i <= 3; i++) {
    if ((b[i] + 0) > (a[i] + 0)) { print "yes"; exit }
    if ((b[i] + 0) < (a[i] + 0)) { print "no"; exit }
  }
  print "no"
}')
[ "$is_forward" = "yes" ] || fail "$NEW_VERSION is not newer than $CURRENT_VERSION"

SCRATCH=$(mktemp -d)
STAGED="$SCRATCH/staged"
PATHS="$SCRATCH/paths"
DESIRED="$SCRATCH/desired"
ACTIONS="$SCRATCH/actions"
CONFLICTS="$SCRATCH/conflicts"
GENERATED_CHANGES="$SCRATCH/generated-changes"
BACKUP="$SCRATCH/backup"
BACKUP_RECORD="$SCRATCH/backup-record"
CREATED_DIRS="$SCRATCH/created-dirs"
APPLY_STARTED=no
ACTIVE_TEMP=
mkdir -p "$STAGED"
: > "$DESIRED"
: > "$ACTIONS"
: > "$CONFLICTS"
: > "$GENERATED_CHANGES"
: > "$BACKUP_RECORD"
: > "$CREATED_DIRS"

remove_active_temp() {
  [ -n "$ACTIVE_TEMP" ] || return 0
  if [ -d "$ACTIVE_TEMP" ] && [ ! -L "$ACTIVE_TEMP" ]; then
    rm -R "$ACTIVE_TEMP"
  else
    rm -f "$ACTIVE_TEMP"
  fi
  ACTIVE_TEMP=
}

remove_project_entry() {
  remove_relative=$1
  assert_no_symlink_components "$ROOT" "$remove_relative" "project update target"
  if [ -d "$ROOT/$remove_relative" ] && [ ! -L "$ROOT/$remove_relative" ]; then
    rm -R "$ROOT/$remove_relative"
  else
    rm -f "$ROOT/$remove_relative"
  fi
}

backup_matches_project() {
  backup_kind=$1
  backup_relative=$2
  case "$backup_kind" in
    absent)
      [ ! -e "$ROOT/$backup_relative" ] && [ ! -L "$ROOT/$backup_relative" ]
      ;;
    file)
      [ -f "$ROOT/$backup_relative" ] && [ ! -L "$ROOT/$backup_relative" ] && \
        cmp -s "$BACKUP/$backup_relative" "$ROOT/$backup_relative" && \
        [ "$(file_mode "$BACKUP/$backup_relative")" = "$(file_mode "$ROOT/$backup_relative")" ]
      ;;
    directory)
      [ -d "$ROOT/$backup_relative" ] && [ ! -L "$ROOT/$backup_relative" ] && \
        diff -qr "$BACKUP/$backup_relative" "$ROOT/$backup_relative" >/dev/null 2>&1
      ;;
    *) return 1 ;;
  esac
}

restore_backups() {
  restore_failed=no
  while IFS='|' read -r restore_kind restore_relative; do
    [ -n "$restore_relative" ] || continue
    if backup_matches_project "$restore_kind" "$restore_relative"; then
      continue
    fi
    if ! remove_project_entry "$restore_relative"; then
      restore_failed=yes
      continue
    fi
    case "$restore_kind" in
      absent) ;;
      file|directory)
        restore_parent=$(dirname -- "$ROOT/$restore_relative")
        if ! mkdir -p "$restore_parent" || \
          ! cp -Rp "$BACKUP/$restore_relative" "$ROOT/$restore_relative"; then
          restore_failed=yes
        fi
        ;;
    esac
  done < "$BACKUP_RECORD"

  awk '{ lines[NR]=$0 } END { for (i=NR; i>0; i--) print lines[i] }' \
    "$CREATED_DIRS" | while IFS= read -r created_relative; do
      [ -n "$created_relative" ] || continue
      rmdir "$ROOT/$created_relative" 2>/dev/null || true
    done
  [ "$restore_failed" = "no" ]
}

finish() {
  finish_status=$?
  trap - EXIT HUP INT TERM
  remove_active_temp || true
  if [ "$finish_status" -ne 0 ] && [ "$APPLY_STARTED" = "yes" ]; then
    if restore_backups; then
      echo "error: kit update failed; the original project was restored" >&2
    else
      echo "error: kit update failed and automatic restoration was incomplete; use the clean starting checkpoint to recover" >&2
    fi
  fi
  rm -R "$SCRATCH"
  exit "$finish_status"
}
trap finish EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

awk -F'|' '$1 == "file" { print $3 }' \
  "$BASE/.ai-build-kit-managed" "$NEW/.ai-build-kit-managed" | sort -u > "$PATHS"

assert_no_symlink_components "$ROOT" ".ai-build-kit-version" "project"
[ -f "$ROOT/.ai-build-kit-version" ] || fail "project version marker is not a regular file"
assert_no_symlink_components "$ROOT" ".ai-build-kit-managed" "project"
[ -f "$ROOT/.ai-build-kit-managed" ] || fail "project managed-file record is not a regular file"
assert_no_symlink_components "$ROOT" ".agents/tools/build-adapters.sh" "project"
while IFS= read -r managed_path; do
  [ -n "$managed_path" ] || continue
  assert_no_symlink_components "$ROOT" "$managed_path" "project managed path"
done < "$PATHS"
for generated_path in .claude/commands .claude/skills .cursor/commands .gemini/commands; do
  assert_no_symlink_components "$ROOT" "$generated_path" "project generated adapter"
done

if ! "$ROOT/.agents/tools/build-adapters.sh" --check >/dev/null; then
  fail "current harness adapters contain unsaved or hand-edited drift"
fi

if [ "$MODE" = "apply" ] && [ -n "$(git -C "$ROOT" status --porcelain)" ]; then
  fail "save or clear current project changes before applying a kit update"
fi

entry_mode() {
  record=$1
  wanted=$2
  awk -F'|' -v wanted="$wanted" '$1 == "file" && $3 == wanted { print $2; exit }' "$record"
}

file_mode() {
  [ -x "$1" ] && printf '%s\n' 100755 || printf '%s\n' 100644
}

matches_release_file() {
  match_current=$1
  match_expected=$2
  match_mode=$3
  [ -f "$match_current" ] && [ ! -L "$match_current" ] && \
    cmp -s "$match_current" "$match_expected" && \
    [ "$(file_mode "$match_current")" = "$match_mode" ]
}

stage_file() {
  source_file=$1
  destination_path=$2
  destination_mode=$3
  mkdir -p "$(dirname -- "$STAGED/$destination_path")"
  cp -p "$source_file" "$STAGED/$destination_path"
  chmod "${destination_mode#100}" "$STAGED/$destination_path"
  printf '%s\n' "$destination_path" >> "$DESIRED"
}

record_action() {
  printf '%s|%s\n' "$1" "$2" >> "$ACTIONS"
}

record_conflict() {
  printf '%s\n' "$1" >> "$CONFLICTS"
}

while IFS= read -r path; do
  [ -n "$path" ] || continue
  old_mode=$(entry_mode "$BASE/.ai-build-kit-managed" "$path")
  new_mode=$(entry_mode "$NEW/.ai-build-kit-managed" "$path")
  current="$ROOT/$path"

  if [ -n "$old_mode" ] && [ -n "$new_mode" ]; then
    base_file="$BASE/$path"
    new_file="$NEW/$path"
    if [ ! -e "$current" ]; then
      if cmp -s "$base_file" "$new_file" && [ "$old_mode" = "$new_mode" ]; then
        record_action keep-deleted "$path"
      else
        record_conflict "$path"
      fi
      continue
    fi
    if [ ! -f "$current" ] || [ -L "$current" ]; then
      record_conflict "$path"
      continue
    fi

    if matches_release_file "$current" "$new_file" "$new_mode"; then
      stage_file "$current" "$path" "$new_mode"
      record_action already-current "$path"
      continue
    fi
    if matches_release_file "$current" "$base_file" "$old_mode"; then
      stage_file "$new_file" "$path" "$new_mode"
      record_action update "$path"
      continue
    fi
    if cmp -s "$base_file" "$new_file" && [ "$old_mode" = "$new_mode" ]; then
      stage_file "$current" "$path" "$(file_mode "$current")"
      record_action keep-local "$path"
      continue
    fi

    current_mode=$(file_mode "$current")
    mode_result=""
    if [ "$current_mode" = "$old_mode" ]; then
      mode_result=$new_mode
    elif [ "$new_mode" = "$old_mode" ] || [ "$current_mode" = "$new_mode" ]; then
      mode_result=$current_mode
    else
      record_conflict "$path"
      continue
    fi

    case "$path" in
      *.md)
        merged="$SCRATCH/merged"
        if git merge-file -p "$current" "$base_file" "$new_file" > "$merged" 2>/dev/null; then
          stage_file "$merged" "$path" "$mode_result"
          record_action merge "$path"
        else
          record_conflict "$path"
        fi
        ;;
      *) record_conflict "$path" ;;
    esac
  elif [ -n "$old_mode" ]; then
    if [ ! -e "$current" ]; then
      record_action already-deleted "$path"
    elif [ -f "$current" ] && [ ! -L "$current" ] && \
      cmp -s "$current" "$BASE/$path" && [ "$(file_mode "$current")" = "$old_mode" ]; then
      record_action delete "$path"
    else
      record_conflict "$path"
    fi
  else
    if [ ! -e "$current" ]; then
      stage_file "$NEW/$path" "$path" "$new_mode"
      record_action add "$path"
    elif [ -f "$current" ] && [ ! -L "$current" ] && \
      cmp -s "$current" "$NEW/$path" && [ "$(file_mode "$current")" = "$new_mode" ]; then
      stage_file "$current" "$path" "$new_mode"
      record_action already-current "$path"
    else
      record_conflict "$path"
    fi
  fi
done < "$PATHS"

conflict_count=$(grep -c . "$CONFLICTS" || true)
printf '%s\n' "AI Build Kit update: $CURRENT_VERSION -> $NEW_VERSION"
for action in update add delete merge keep-local keep-deleted; do
  count=$(awk -F'|' -v action="$action" '$1 == action { count++ } END { print count + 0 }' "$ACTIONS")
  [ "$count" -eq 0 ] || printf '%s: %s\n' "$action" "$count"
done

if [ "$conflict_count" -ne 0 ]; then
  printf '%s\n' "conflicts: $conflict_count"
  while IFS= read -r conflict; do
    [ -n "$conflict" ] || continue
    printf '  %s\n' "$conflict"
  done < "$CONFLICTS"
  fail "kit update has conflicts; no project files were changed"
fi

ensure_project_parent() {
  ensure_relative=$(dirname -- "$1")
  [ "$ensure_relative" != "." ] || return 0
  ensure_remaining=$ensure_relative
  ensure_prefix=
  while :; do
    case "$ensure_remaining" in
      */*)
        ensure_component=${ensure_remaining%%/*}
        ensure_remaining=${ensure_remaining#*/}
        ;;
      *)
        ensure_component=$ensure_remaining
        ensure_remaining=
        ;;
    esac
    if [ -n "$ensure_prefix" ]; then
      ensure_prefix="$ensure_prefix/$ensure_component"
    else
      ensure_prefix=$ensure_component
    fi
    if [ -e "$ROOT/$ensure_prefix" ] || [ -L "$ROOT/$ensure_prefix" ]; then
      [ -d "$ROOT/$ensure_prefix" ] && [ ! -L "$ROOT/$ensure_prefix" ] || \
        fail "project update parent is not a real folder: $ensure_prefix"
    else
      mkdir "$ROOT/$ensure_prefix"
      if ! grep -qxF "$ensure_prefix" "$CREATED_DIRS"; then
        printf '%s\n' "$ensure_prefix" >> "$CREATED_DIRS"
      fi
    fi
    [ -n "$ensure_remaining" ] || break
  done
}

backup_project_path() {
  backup_relative=$1
  assert_no_symlink_components "$ROOT" "$backup_relative" "project update target"
  backup_parent=$(dirname -- "$BACKUP/$backup_relative")
  mkdir -p "$backup_parent"
  if [ -f "$ROOT/$backup_relative" ] && [ ! -L "$ROOT/$backup_relative" ]; then
    cp -p "$ROOT/$backup_relative" "$BACKUP/$backup_relative"
    printf 'file|%s\n' "$backup_relative" >> "$BACKUP_RECORD"
  elif [ -d "$ROOT/$backup_relative" ] && [ ! -L "$ROOT/$backup_relative" ]; then
    cp -Rp "$ROOT/$backup_relative" "$BACKUP/$backup_relative"
    printf 'directory|%s\n' "$backup_relative" >> "$BACKUP_RECORD"
  elif [ ! -e "$ROOT/$backup_relative" ] && [ ! -L "$ROOT/$backup_relative" ]; then
    printf 'absent|%s\n' "$backup_relative" >> "$BACKUP_RECORD"
  else
    fail "project update target is not a regular file or folder: $backup_relative"
  fi
}

install_project_file() {
  install_source=$1
  install_relative=$2
  ensure_project_parent "$install_relative"
  assert_no_symlink_components "$ROOT" "$install_relative" "project update target"
  install_parent=$(dirname -- "$ROOT/$install_relative")
  ACTIVE_TEMP=$(mktemp "$install_parent/.ai-build-kit-update.XXXXXX")
  cp -p "$install_source" "$ACTIVE_TEMP"
  mv -f "$ACTIVE_TEMP" "$ROOT/$install_relative"
  ACTIVE_TEMP=
}

install_project_directory() {
  install_directory_source=$1
  install_directory_relative=$2
  ensure_project_parent "$install_directory_relative"
  assert_no_symlink_components "$ROOT" "$install_directory_relative" "project generated adapter"
  install_directory_parent=$(dirname -- "$ROOT/$install_directory_relative")
  ACTIVE_TEMP=$(mktemp -d "$install_directory_parent/.ai-build-kit-update.XXXXXX")
  cp -Rp "$install_directory_source" "$ACTIVE_TEMP/replacement"
  if [ -e "$ROOT/$install_directory_relative" ] || [ -L "$ROOT/$install_directory_relative" ]; then
    remove_project_entry "$install_directory_relative"
  fi
  mv "$ACTIVE_TEMP/replacement" "$ROOT/$install_directory_relative"
  rmdir "$ACTIVE_TEMP"
  ACTIVE_TEMP=
}

# Prove the complete proposed canonical set can regenerate every harness
# adapter before touching the project.
"$STAGED/.agents/tools/build-adapters.sh" >/dev/null

for generated in .claude/commands .claude/skills .cursor/commands .gemini/commands; do
  assert_no_symlink_components "$ROOT" "$generated" "project generated adapter"
  if [ ! -d "$ROOT/$generated" ] || \
    ! diff -qr "$STAGED/$generated" "$ROOT/$generated" >/dev/null 2>&1; then
    printf '%s\n' "$generated" >> "$GENERATED_CHANGES"
  fi
done

if [ "$MODE" = "plan" ]; then
  echo "plan only: no project files were changed"
  exit 0
fi

# Capture every path that can change before the first write so a later failure
# can restore the exact starting state while the computer still permits it.
while IFS='|' read -r action action_path; do
  case "$action" in
    update|add|delete|merge) backup_project_path "$action_path" ;;
  esac
done < "$ACTIONS"
while IFS= read -r generated; do
  [ -n "$generated" ] || continue
  backup_project_path "$generated"
done < "$GENERATED_CHANGES"
backup_project_path ".ai-build-kit-version"
backup_project_path ".ai-build-kit-managed"

APPLY_STARTED=yes
while IFS='|' read -r action action_path; do
  case "$action" in
    update|add|merge)
      install_project_file "$STAGED/$action_path" "$action_path"
      ;;
    delete)
      remove_project_entry "$action_path"
      ;;
  esac
done < "$ACTIONS"

while IFS= read -r generated; do
  [ -n "$generated" ] || continue
  install_project_directory "$STAGED/$generated" "$generated"
done < "$GENERATED_CHANGES"

install_project_file "$NEW/.ai-build-kit-version" ".ai-build-kit-version"
install_project_file "$NEW/.ai-build-kit-managed" ".ai-build-kit-managed"

"$ROOT/.agents/tools/build-adapters.sh" --check >/dev/null || \
  fail "updated harness adapters did not verify"

APPLY_STARTED=no
echo "Applied AI Build Kit $NEW_VERSION"
