# The check floor

Every founded project gets its language's own mechanical checks on the first
day: a type check and a linter, wherever the language has them. They sit in
`jobs.project-check` beside install and test, so they turn the same tick red.
The person meets no new idea. Green still means the checks that exist really
passed, and red still means don't merge and tell /fix.

This is a whole-project read, so the rules in `whole-project-reads.md` apply.

## Choosing the commands

Use the first of these that the project has:

1. What the project already runs. A type check or lint script in its package
   file, or a configuration its framework's starter created. Use it as it
   stands and do not rewrite its rules.
2. The language's own checker, or its most common one, at that tool's own
   default rules. The table below lists the usual ones.
3. Nothing. Where the language has no type checker or no linter, write
   `Type check: none for <language>` or `Lint: none for <language>` in
   AGENTS.md's stack section and carry on. Never stop founding over this, and
   never invent a tool the language does not have.

| Language | Type check | Lint |
|---|---|---|
| TypeScript | `npx tsc --noEmit` | `npx eslint .` with ESLint's own recommended rules and typescript-eslint's recommended rules |
| JavaScript | none, unless the project already checks types | `npx eslint .` with ESLint's own recommended rules |
| Python | `mypy .` | `ruff check .` |
| Go | the compiler, through `go build ./...` | `go vet ./...` |
| Rust | `cargo check` | `cargo clippy` |

For any other language, the compiler the build already runs counts as the type
check. Add a linter only where the language has one that most of its users run.

## Keep it quiet

A check that goes red for reasons the person cannot act on teaches them to
ignore red, and that is worse than having no check. So:

- Use each tool's own default rules. Do not import a style preset, and do not
  add a formatter check.
- The check passes on the day it is wired. Run it locally before saving, and
  fix what it finds in code founding wrote.
- In an adopted project, the new checks may fail on code that was already
  there. Do not turn the tick red for work nobody asked for. Wire only the
  checks that pass, write the other as `Lint: not yet, <count> existing
  problems` in the stack section, and file one piece to clear them.

## Wiring

Put each command in its own named step, `Type check` and `Lint`, after install
and before test, so a red tick says which one failed. Write the same commands
in AGENTS.md's stack section, so the agent can run them locally before it hands
work over.

## Where it applies

Always, on every build path, in any language that has these tools. On Explore
privately the remote check stays optional, as it is for tests; the commands
still go in the stack section and still run before hand-over.
