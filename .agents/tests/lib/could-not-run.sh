# Shared result for a rehearsal with cases it could not run.
not_run=0
could_not_run() {
  printf 'could-not-run: %s\n' "$1"
  not_run=2
}
finish_rehearsal() { exit "$not_run"; }
