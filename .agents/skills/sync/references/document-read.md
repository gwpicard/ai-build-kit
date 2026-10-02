# Document read

A project's instructions can promise a check whose name still exists but whose
route no longer runs it. This read finds missing names and a small set of
explicit missing connections. It reports what it inspected and leaves anything
outside that set unverified.

This is a whole-project read, so the rules in
the `setup-ai-build-kit` skill's `references/whole-project-reads.md` apply.

## Where it applies

Every `/sync`, on every build path, which includes the quarterly visit, since
that runs sync first.

## Which documents

`README.md`, and every document AGENTS.md points at. Nothing else.
Where AGENTS.md points at `docs/README.md`, each concept file that list names
counts as pointed at too. The records sync already trues (the masterplan, the
changelog with its waiting files in `changes/`, AGENTS.md itself) are not read
again here for stale names. Root AGENTS.md is read for the explicit declarations
below only. The kit's files and code comments are excluded. A name in `changes/`
is never reported missing, since that folder empties at every fold.

A project whose documentation lives somewhere AGENTS.md never mentions gets no
read of it. Point at it from AGENTS.md. Documents and mechanism files that lead
outside the project are not opened.

## What counts as wrong

A document may say less than the project does. That is never a finding.
Missing files, folders, local links, commands and environment variables retain
the stale-name checks. An explicit declaration can also name a check that still
exists but is absent from its declared package-script route.

Whether arbitrary prose describes a flow that still happens is out of reach.
No finding means only that these checks found no mismatch. Unsupported rules
remain unverified, including prose that does not use the declaration syntax.

## Explicit declarations

The following are whole, case-sensitive lines outside fenced code blocks.
A Markdown `- ` or `* ` bullet and a final full stop are optional. Each command
has exactly the form `npm run <name>`, `pnpm run <name>` or `yarn run <name>`.
Names contain letters, digits, underscores, colons, dots or hyphens.

```text
Required command: `npm run test`.
Required check: `npm run guard` via `npm run check`.
Required check: `yarn run guard` via `pnpm run check` when file `care.flag` exists.
```

A required command must name an entry in the root `package.json` scripts
object. This establishes availability, not that anybody invokes the command.
A required check must be reachable from its route through literal package-script
calls. A route naming the check itself counts as reachable. Package-manager
names select the same script object; workspaces and other package files are
unsupported. No executable's behaviour or success is inferred.

The route recogniser accepts only whole `npm run <name>`, `pnpm run <name>` or
`yarn run <name>` calls, optionally joined by `&&`. It follows their script
entries until the required check is reached. The exact terminal commands
`node --test`, `tsc --noEmit` and `true` have no further package-script calls.
Other bodies, arguments, shell wrappers, variables, quoting, pipes, semicolons,
`||`, lifecycle hooks and cycles leave the relationship unverified. A route
exceeding 100 inspected entries also remains unverified. A literal
edge alongside unknown shell content also remains unverified. This is static
wiring evidence; it does not establish that a check passes or what its code does.

The only supported condition says `when file`, then a path in backticks, then
`exists`, as in the example. The path is relative to the project root.
A regular file activates the rule; an absent file makes it inactive. An absolute
path, a `..` component, a link outside the project, a broken link, a directory
or an unreadable condition is indeterminate. Other conditions remain unverified.
Inactive rules are reported as inactive and are never called broken, even when
their commands are absent. File contents and environment values are not read.

A line starting `Required command:` or `Required check:` that falls outside this
grammar produces an unverified rule with its location. Missing or invalid
package data leaves an active rule unverified. Each mismatch gives the document
and line, required check, route and inspected script entries or missing keys.
Inactive and unverified results state the reason. Existing stale-name output
keeps its document, line, kind and name format.

## Engines, best first

1. `python3 <skill folder>/scripts/document-claims.py`, where `<skill folder>` is
   this installed sync skill's folder, run from the project root. It reads the
   selected documents, root `package.json`, `Makefile` and Git's tracked names
   and environment-name references. The added wiring read uses only script
   entries and condition-file metadata. It executes no project scripts or
   hooks, changes no project files, and lists documents changed longest ago
   first. When there is no mismatch, inactive rule or verification limit, it prints
   nothing.
2. Where the script cannot run, read the documents directly and check the same
   four kinds of name by hand. Explicit declarations may be checked against the
   same bounded evidence; anything not inspected stays unverified. Say in the
   internal evidence that this was the fallback.

Where `lychee` is already in the project, it may check links to other sites as
well. Without it, links to other sites are not checked; say so if asked.

## Checking a finding

Open the document at the line the script names and confirm the name is there
and is meant as a name in this project. A name in an example of some other
project's setup is not a finding, and nor is a name mentioned only to say it
does not exist. For a wiring mismatch, confirm the declared route and inspect
the script entries the result names. Drop anything that does not survive.

Before reporting a finding, look at the open pieces. A name already on an open
piece has been raised and decided, so do not raise it again.

## Saying it

Give at most three findings, in the order the script gives them, each with its
place and what is missing:

"README.md line 7 names scripts/deploy.sh, which is no longer in the project."

"AGENTS.md line 12 requires the guard check through the check route, but that
route only calls the unit tests. I checked those package-script entries."

Say how many more there are in one line, and offer to list them. With a finding
or an unverified rule, say once: "This checks names and explicit check routes.
Other instructions remain unverified." An inactive rule is evidence, not a
repair proposal; say why it is inactive if the person asks. Report an unverified
rule as a limit, never as a broken rule or a passed check.

For a stale name, offer to correct it on the spot, changing that name and
nothing else in the sentence around it, or file it as a piece to come back to.
Never rewrite the person's prose. A correction is saved with sync's other
corrections, in step 8. For a wiring mismatch, offer `/fix` for the missing
connection, or `/shape` if the intended rule needs deciding. Do not edit project
mechanisms during this document read.

When the read finds nothing, say nothing about it. Silence is no assurance about
unsupported instructions. The throwaway fixtures establish bounded detector
behaviour only. A later real-project audit needs an authorised project and must
be recorded separately; fixture results never count as that audit.
