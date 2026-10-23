# Completion report

Lead with what is ready, where it is saved, whether it was uploaded, and the
next command. Do not lead with Git details, commands, ports or checkpoint data.

Translate internal facts:

- Passing `npm test`: "The automatic project check passed."
- A working local address: "The private preview opened successfully."
- Clean working tree: "All setup work has been saved."
- No push: "No code was uploaded or published."
- No online code yet: "The code stays on this computer until your first build
  asks before putting it online."
- Issues created: say they are listed in the online repository, naming its
  owner/name and whether it is public or private. Use the script's `removed`,
  `kept` and `settings` results to report which labels changed and whether
  automatic removal of merged branches was enabled.
- A named recipe: name its product and whether launch checks can test its
  steps. Say which accounts the person owns and where the tool runs. `Recipe:
  none` means the kit cannot check recipe launch steps.
- A `review identity: shared` line: say later reviews are recorded as
  unverified, because the agent and the reviewer use one GitHub login.

Include only relevant sections, with no placeholders. Read the checkpoint back
and use its reference at the very end. If there is no checkpoint beyond the
starting state, save one before reporting. Never tell the person to push it.

End with a clean handoff: name the first ready piece and a rough time, explain
that an empty project is expected, then point to `/implement` and `/shape` in a
fresh chat. On an adopted project, name its first outstanding piece. Mention
`/what-now` as the command to check progress.

```md
# Your [project name] is ready to build

The initial setup is complete.

## What is ready

- The tool's purpose, users and access rules are recorded.
- The work has [number] small build steps.
- [Review result and any finding that still waits for the person.]
- [What the tool runs on, whether launch steps can be checked, and whether
  this computer has the required tools.]
- The automatic project check passed.
- The private preview opened successfully.

## Where it is saved

A checkpoint is saved inside the project on this computer. [State whether an
online copy exists and whether it was updated.] No code was uploaded or
published. [Where issues exist, name the repository and report the actual label
and merged-branch settings results.] [If the online repository has
no project code, explain that the first build will ask before uploading.]

Private preview: `[address]`

This address works only on this computer while the preview is running.

## What to do next

Setup is saved. The project is empty, which is how it should look at this
point. The plan has [number] steps;
the first is [name], about [rough time]. Then start a fresh chat and type `/implement` to
build it or `/shape` to shape more work. `/what-now` shows where things stand.

Checkpoint reference: `[short reference]`
```
