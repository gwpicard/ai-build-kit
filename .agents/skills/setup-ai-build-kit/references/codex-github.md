# GitHub access in Codex

Use when a kit operation needs GitHub and Codex cannot reach or authenticate.
Report the failed command and exit status with credentials masked. Keep the
last plan until refresh succeeds.

On HTTP 401 or `unable to get password from user`, run this skill's
`templates/foundation/codex-github-check.py --message` with python3. Give its
restart sentence using the absolute installed path, then stop this session.
Do not retry a working terminal login. Continue below only after restart or
for a network or permission failure.

## Check connectivity and settings

Run `curl -I --connect-timeout 10 https://api.github.com`. Success proves
connectivity, not sign-in. On DNS or connection failure, request the client's
authorised network access. If settings need changing, identify the active
Codex home, profile, project settings and managed policy. Back up the file and
get approval before editing. Keep the sandbox and approval reviewer; never
bypass managed restrictions or combine permission systems.

Network access can be set by `sandbox_mode = "workspace-write"` with
`[sandbox_workspace_write] network_access = true`, or a named
`default_permissions` workspace profile with network enabled. These are
examples, not lines to append. Edit the active settings without duplicate
keys, preserve profile restrictions, then start a new session and check its
actual profile. See [Codex configuration](https://developers.openai.com/codex/config-reference/).

## Check the login

Compare `gh auth status --hostname github.com` in Codex and the person's
terminal. Never show a token. Report only whether `GH_TOKEN` and
`GITHUB_TOKEN` are present; an invalid environment token overrides a stored
login. Compare the `gh` executable, user, `HOME`, `GH_CONFIG_DIR` and
`XDG_CONFIG_HOME`. Do not re-authenticate a working login.

If these match but only the terminal can use the stored login, offer
`scripts/codex-with-github.py`. The person runs it with python3 from an
ordinary terminal in the project, using its absolute installed path. They may
pass Codex arguments after the script path. Only use it for access they
authorised.

The launcher passes an existing token to the new Codex process, or captures
the current `gh` login in memory for that process. It writes no credential and
does not change GitHub storage. It disables shell snapshots, uses a dedicated
process, preserves permissions, and resets Git's GitHub helper to
`gh auth git-credential` in that process. It changes no global file and needs
no `gh auth setup-git`. If a custom environment policy filters variables,
preserve the policy and ask the person to allow the session credential. Never
put tokens in settings, files, prompts or logs, enable HTTP debug logging, or
dump the environment. Check token presence in Codex, never its value.

If the custom policy filters the token, inspect
`shell_environment_policy.inherit`, `ignore_default_excludes` and `filters`,
or legacy `exclude` and `include_only`. Include rules cannot undo an earlier
exclusion. See [Codex environment filtering](https://developers.openai.com/codex/config-reference/)
and [GitHub credential precedence](https://cli.github.com/manual/gh_help_environment).

## Verify access

Run `gh api user --jq .login` and `gh repo view --json nameWithOwner` from the
project to confirm the account and repository, then refresh the plan. These
reads do not prove write access; handle a refused operation against that
repository. Do not create a test issue. A connector's separate authorisation
failure is not repaired by the launcher.

Run `git ls-remote --heads origin` for an HTTPS GitHub remote. A successful
`gh` call does not prove Git access. The launcher covers HTTPS; SSH needs its
own access.
