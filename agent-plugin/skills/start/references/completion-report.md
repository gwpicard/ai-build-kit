# Completion report

The message /start ends with. Lead with what's ready, where it's saved,
whether anything was uploaded, and the next command to type. Never lead with a
checkpoint reference, Git state, package-manager command, port, branch, or
remote status.

## Translate before reporting

Internal facts recorded for later agents, and what the user hears instead:

- `npm test` passes -> "The automatic project check passed."
- `npm start` serves a local address -> "The private preview opened successfully."
- the working tree is clean -> "All setup work has been saved."
- the current branch is ahead of its remote -> "The saved work has not been uploaded."
- the commit identifier -> only in the checkpoint reference at the very end, never leading the report.
- no push occurred -> "Nothing was published."

These commands and states stay wherever agents already keep them (AGENTS.md,
the changelog); the report never leads with them.

## Shape

Include only the subsections that apply to this project; skip the rest
rather than leaving a placeholder line unfilled. The checkpoint reference
belongs at the very end, for troubleshooting only.

End with a clean cut, not an offer to build. Say plainly that setup is done and
the work is saved, name the first ready piece and a rough, honest time, and say
the empty project is expected rather than broken. Point at `/implement` to build
the first piece and `/plan` to shape more, ideally in a fresh session so the
founding conversation does not carry into the build. Do not offer to build the
first piece in this session; founding a project and building it are separate,
deliberate steps. On an adopted project that is not empty, drop the "this is
normal" line and name the first outstanding piece instead.

```md
# Your [project name] is ready to build

The initial setup is complete.

## What is ready

- The purpose of the tool, its intended users, and its access rules are written down.
- The work has been divided into [number] small build steps.
- A separate review checked the plan, and any important findings were resolved.
- The automatic project check passed.
- The instructions for opening the private preview were tested successfully.

## Where it is saved

A checkpoint has been saved inside the project on this computer.

Nothing was uploaded or published.
[State whether an online project copy exists and whether it was updated.]

Private preview address: `[address]`

This address works only on this computer while the preview is running.

## What to do next

Setup is done and your work is saved. Your project is empty right now, which is
how it should look at this point, not a sign anything went wrong. The plan holds
[number] small build steps, and the first is [first step name], about
[rough time].

Push your changes, then start a fresh chat and type `/implement` to build the
first piece, or `/plan` to shape more first. `/what-now` tells you where things
stand any time.

Checkpoint reference: `[short reference]`
```
