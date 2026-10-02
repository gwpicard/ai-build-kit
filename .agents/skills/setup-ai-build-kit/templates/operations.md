# Operations

The current operational facts, ownership and locations this tool depends on.

## How it stays running

<!-- Optional for live tools. Services, alerts, backup, billing owner, access
owner, and manual fallback. Do not copy credentials here. Where a secret lives
outside the project goes here as its location only: a file path, a password
manager entry's name, or an environment variable's name. Never a value.

Where AGENTS.md names a recipe, that recipe file says how the tool previews,
goes live, rolls back, and is backed up and restored. Link it rather than
copying it, and write here only what it cannot know, such as who owns billing.

A `Goes live:` line says how the tool goes live: `through /ship`, the kit's
default, where a merge reaches a preview and /ship promotes it, `on every
merge`, where the host puts each merge to `main` live, or `not hosted`, where no
server runs the tool for people to reach, because people install it, copy it,
or run it on their own computer. On `not hosted`, a merge is never a launch, and
/ship makes a release instead. The merge step in the `section-builder` skill's
`references/merge.md` reads it before every merge.

A `Sample data:` line says what made-up records or test accounts each build
walks through the tool with, and where they live, or that there are none.

Where the tool runs on a server somebody else runs, /ship writes a hosting
request here on the first launch: repo and branch, lane, port, env var names,
persisted paths and health check path. Names only, never a value. What comes
back from the server goes under it. Later launches read it back. -->


<!-- Include account and access owners, manual fallback, alerts, billing, backup and recovery. Names and secret locations only. Goes live and Sample data each have one authoritative line here. -->
