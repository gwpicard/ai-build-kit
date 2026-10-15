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
  owner/name and whether it is public or private. Say the default labels were
  replaced and merged branches are removed.
- A named recipe: name its product and whether launch checks can test its
  steps. Say which accounts the person owns and where the tool runs. `Recipe:
  none` means the kit cannot check recipe launch steps.
- Missing recipe tools: name each tool and say it is a setup task before the
  first `/setup-hosting`. A tool report with none missing means the computer
  has what the checks need.

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
published. [Where issues exist, name the repository and say its default labels
were replaced and merged branches are removed.] [If the online repository has
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
