# Required tools

The kit runs a few small scripts of its own, and those need three outside tools
before setup can go ahead. `scripts/check-tooling.sh` checks for them and reports
which are ready, so a missing one is caught early rather than at the step that
creates the issues.

- Git, because the kit saves each project version with it.
- The GitHub command line tool, because the pieces are kept as GitHub issues.
  Setup needs it installed and signed in before it founds them.
- python3, because the kit reads the issue list with it to print your pieces.

`jq` is not needed. The kit filters JSON with python3 instead, which is also what
lets the test harness stand in for the GitHub command line tool. A tool used only
to build a release lives in the maintainer source and never reaches a project.

When `check-tooling.sh` reports a tool as missing, `manual-setup.md` guides the
install one step at a time. Keep this list and the script in step: a tool added
to one belongs in the other.
