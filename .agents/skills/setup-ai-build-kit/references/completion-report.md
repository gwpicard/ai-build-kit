# Completion report

The message /setup-ai-build-kit ends with. Lead with what is ready, where it is
saved, whether anything was uploaded, and the next command to type. Never lead
with a checkpoint reference, Git state, package-manager command, port, branch,
or remote status.

## Translate before reporting

Internal facts, and what the person hears instead:

- `npm test` passes -> "The automatic project check passed."
- `npm start` serves a local address -> "The private preview opened successfully."
- the working tree is clean -> "All setup work has been saved."
- the current branch is ahead of its remote -> "The saved work has not been uploaded."
- the commit identifier -> only in the checkpoint reference at the very end.
- no push occurred -> "No code was uploaded or published."
- the online repository holds none of the code yet -> "The code stays on this computer until your first build asks you before putting it online."
- the pieces were opened as issues -> "The build steps are listed as issues in the project's online repository, [owner/name], which is [private or public]."
- the label set and the branch setting -> "GitHub's default labels were replaced with the kit's own, and a piece's branch is removed once it merges."
- `Recipe: <folder name>` in AGENTS.md -> "The tool will run on [the recipe's name, from its recipe.md], and the kit can check its launch steps."
- the recipe's tool report -> "This computer has the tools those checks use." or "Before the first launch this computer needs [each missing tool, in plain words]; that is on the plan as a setup task."
- `Recipe: none` -> "The tool runs on a stack the kit has no recipe for, so it cannot check the launch steps a recipe would."

## Shape

Include only the parts that apply, with no placeholder left unfilled. The
checkpoint reference comes last and is never skipped.

Read the checkpoint back before writing, and take its reference from what you
read. Where there is no checkpoint beyond the project's starting state, the
report is not due: go and save one.

End with a clean cut, not an offer to build: setup is done and saved, the first
ready piece with a rough, honest time, and that an empty project is expected.
Point at `/implement` to build the first piece and `/shape` to shape more, in a
fresh chat since founding was a long conversation. On an adopted project that
is not empty, name the first outstanding piece instead of the "this is normal"
line. Never tell the person to push the checkpoint.

```md
# Your [project name] is ready to build

The initial setup is complete.

## What is ready

- The purpose of the tool, its intended users, and its access rules are written down.
- The work has been divided into [number] small build steps.
- A separate review checked the plan, and any important findings were resolved.
- [What the tool will run on, whether the kit can check its launch steps, and whether this computer has the tools those checks use.]
- The automatic project check passed.
- The instructions for opening the private preview were tested successfully.

## Where it is saved

A checkpoint has been saved inside the project on this computer.

No code was uploaded or published. The build steps are listed as issues in the
project's online repository, [owner/name], which is [private or public]. That
is where the kit keeps the work still to do. GitHub's default labels were
replaced with the kit's own, and a piece's branch is removed once it merges.
[Only where the online repository holds none of the project's code yet:] The
code stays on this computer until your first build asks you before putting it
online.
[State whether an online project copy exists and whether it was updated.]

Private preview address: `[address]`

This address works only on this computer while the preview is running.

## What to do next

Setup is done and your work is saved. Your project is empty right now, which is
how it should look at this point, not a sign anything went wrong. The plan holds
[number] small build steps, and the first is [first step name], about
[rough time].

Then start a fresh chat and type `/implement` to build the first piece, or `/shape`
to shape more first. `/what-now` tells you where things
stand any time.

Checkpoint reference: `[short reference]`
```
