# Write the masterplan

Create masterplan.md from the `setup-ai-build-kit` skill's
`templates/masterplan.md`, in the present tense, the
build-path section first. Create CHANGELOG.md from its template, empty. Create
`.ai-build-kit-maintenance` from this skill's `templates/maintenance-record` with today's
date on its `founded` line, keeping any `codex-shell` line already there and
leaving the pass lines empty. Do not mention that file. Fill AGENTS.md's
project line and capability profile.

Replace README.md's project-name and purpose placeholders with a short
description. Where it has no placeholders, it is somebody's real file: leave it
exactly as it is and say in one line that the description went into
masterplan.md and AGENTS.md.

Fill the masterplan from the notes and the conversation, then delete
`.agents/tmp/setup-notes.md`.

Read the connections section back in plain words, and let the team confirm
each outside connection: their email, their calendar, whatever it reaches.

On Build with care, write the sensitive-area paths and any boundaries by
fit-check.md, read each area and its home back in plain words, and run the
sensitive-area check the bootstrap installed. On the other paths, leave the map
out.

Delete docs/MAINTAINING.md if it exists, in the same commit. If the project
needs a `.env`, copy `.env.example` to `.env`, confirm `.gitignore` lists it,
and never print its contents.
