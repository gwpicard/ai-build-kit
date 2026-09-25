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

A project on a recipe needs a few more tools, but only at launch. Each recipe
names the command-line tools its launch checks run, on its `Command-line tools:`
line. `check-tooling.sh --recipe <recipe file>` adds one line for each: ready,
or missing and needed before the first `/ship`. A missing one never stops
founding, because a project that uses no recipe needs none of them.

When `check-tooling.sh` reports a tool as missing, `manual-setup.md` guides the
install one step at a time. Keep this list and the script in step: a tool added
to one belongs in the other.
