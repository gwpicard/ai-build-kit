# _common.sh: what the shell stand-ins in this folder share.
#
# stand_in_or_real <name> "$@" hands the call to the real command when
# FAKE_HOST_STATE names no file, since the run is then not one of the scenarios
# this folder serves. Otherwise it logs the call and returns, and the caller
# answers.
stand_in_or_real() {
  sr_name=$1
  shift
  if [ -z "${FAKE_HOST_STATE:-}" ] || [ ! -f "$FAKE_HOST_STATE" ]; then
    sr_here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
    sr_old_ifs=$IFS
    IFS=:
    for sr_dir in $PATH; do
      [ -n "$sr_dir" ] || continue
      sr_real=$(CDPATH= cd -- "$sr_dir" 2>/dev/null && pwd -P) || continue
      [ "$sr_real" = "$sr_here" ] && continue
      if [ -f "$sr_dir/$sr_name" ] && [ -x "$sr_dir/$sr_name" ]; then
        IFS=$sr_old_ifs
        exec "$sr_dir/$sr_name" "$@"
      fi
    done
    IFS=$sr_old_ifs
    echo "$sr_name: command not found" >&2
    exit 127
  fi
  printf 'CALL\t%s %s\n' "$sr_name" "$*" >> "${FAKE_HOST_LOG:-$FAKE_HOST_STATE.log}"
}
