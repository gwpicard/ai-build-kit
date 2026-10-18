# Capability check

Find what this harness and repository can actually do. Do not ask the person to
set up optional features before the interview.

Check:

1. Repository files can be read and edited.
2. Shell commands can run.
3. Git is available and this is a repository.
4. The current project state is understood.
5. A suitable name and email label are configured for saving project versions.
6. An online repository exists, if the selected route will require sharing.
7. The current user has access to that online repository, when required.
8. Online authentication works, when uploads, pull requests, or online checks
   are required.
9. The project can be started or its runtime installed.
10. A test or smoke-check command can be found or created.
11. A browser or preview can be reached, when behaviour needs a visual check.
    Use only a browser on this computer: a browser tool may list browsers on
    other computers signed in to the same account. Where none is here, use a
    headless browser, or say you could not see the page. Use a tab of your
    own, never one the person is using.
12. An independent-review route exists: the reviewer agent or another
    subagent, a headless run, a separate session, or a clean chat the person
    opens.
13. Reach is measured by `quality.py reach`; its built-in import reader is the
    fallback when dependency-cruiser is not installed.
14. Hooks and command blocks are recorded as optional, never assumed. Record
    whether the harness runs anything when a session opens; where it does
    not, the check-up reminder reaches the person through `/what-now`.
15. The pieces are kept as issues: the GitHub command line tool is installed
    and signed in, and issues are on for the repository.
16. The signed-in account can create and delete labels on the repository.

`scripts/check-tooling.sh` checks items 3, 15 and 16, and says when `origin`
is the kit's own repository. Confirm the rest by hand. Its `--conditions`
run, at the end of founding, decides whether the working conditions hold.

If the harness cannot run `scripts/check-tooling.sh`, work through
`required-tools.md` beside this file by hand; its "When GitHub access fails"
route applies to any GitHub failure. Guide a missing tool's install by
`manual-setup.md` beside this file.

A missing or signed-out GitHub tool is a required setup step: guide it by
`manual-setup.md` before the pieces are founded. Where issues are switched
off, say so and offer to switch them on; never do it yourself. Where the
account cannot create or delete labels, the pieces still become issues: say
which labels could not be made or removed.

A remote address never proves the current person has an account or access. A
previous commit's author is never the current person's identity.

Write the result into AGENTS.md under Capability profile. For each missing
capability, choose one: a safe fallback, a setup task, less automation, or a
stop because the working conditions require it. Never claim "works in this harness"
because an adapter folder exists.
