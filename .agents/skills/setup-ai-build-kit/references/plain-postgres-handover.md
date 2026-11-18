# Founding with the plain Postgres template

Use this path only when the project already contains the new template's
`hosting/handover.json` and `scripts/found-handover.mjs`. The current founding
menu does not offer that template.

Run `node scripts/found-handover.mjs --questions` and ask each returned question
through clarify. Record the person's answers in the ignored setup notes. The
script owns the choices and field names. Recovery asks about recent work they
could lose and how long they could manage without the tool.

Once the masterplan exists, save those answers as a JSON object in an ignored
local file. Add the owner and tool name from the masterplan. For company
sign-in, include `outside_refused_test` with the existing test's path; stop if
the sign-in module has not supplied that test. Run
`node scripts/found-handover.mjs --answers <answer-file>`, then
`npm run handover:check`. The script writes the handover and generates the
masterplan's hosting section. Keep the answers until both checks pass.

The [handover schema](../../../../hosting/handover.schema.json) owns the
contract and requests. A standalone project receives that release file at
`hosting/handover.schema.json`; never maintain another schema in the template.

Copy the merge skill's `scripts/host-record.cjs`, `scripts/host-record-validator.cjs` and
`contracts/ai-host-kit/host-record.schema.json` into `hosting/` too. The reader
includes its validator and needs no project dependency. AI Host Kit owns
`hosting/host-record.json`; the renderer reads it without changing it. An
absent record leaves the requirements visible, while an invalid record names
the fields to correct and holds rendering and the project check.
