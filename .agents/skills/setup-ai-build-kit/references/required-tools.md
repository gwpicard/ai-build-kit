# Required tools

`scripts/check-tooling.sh` checks the three outside tools the kit's scripts
need, so a missing one is caught early:

- Git, which saves each project version.
- The GitHub command line tool, installed and signed in, since the pieces are
  GitHub issues.
- python3, which reads the issue list to print the pieces.

A recipe's launch checks need more tools, named on its `Command-line tools:`
line. `check-tooling.sh --recipe <recipe folder>` reports each as ready or
missing. A missing one stops founding. The line saying `origin` is still the
kit's own repository stops only the closing `--conditions` run.

A missing tool is installed step by step by `manual-setup.md`. Keep this list
and the script in step.

## When GitHub access fails

This applies whenever a kit command needs GitHub. Run `gh` through the current
agent's command tool; a working terminal elsewhere proves nothing about it.

A network failure or a command the client refused does not mean the person is
signed out. Ask for the access through the client's approval mechanism, then
retry. Say: "GitHub access is blocked in this session; I need it to read or
save your pieces." Never weaken permission settings, repeat a denied request
through another tool, or move to an outside terminal unless the person says
to. If access stays unavailable, name the limit and keep the last printout;
never treat a failed read as an empty backlog.

An authentication refusal, HTTP 401 included, does not prove sign-out either.
Compare `gh auth status --hostname github.com` in the command tool and the
person's terminal. Report only whether `GH_TOKEN` and `GITHUB_TOKEN` exist.
Compare the `gh` path, user, `HOME`, `GH_CONFIG_DIR` and `XDG_CONFIG_HOME`.
Never print a credential or use `--show-token`. For Codex, follow [the
recovery guide](codex-github.md).

In Codex, an HTTP 401 or `unable to get password from user` first gets this
skill's `templates/foundation/codex-github-check.py`, run with python3 and
`--message`. Give its restart sentence and stop, without signing in again or
retrying.

Where the account is plainly signed out, guide `gh auth login` in the
person's terminal. Where it refuses repository access, check the account's
permissions for that repository.
