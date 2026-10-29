---
title: Working with the kit
description: Build, repair and review pieces of work with AI Build Kit.
draft: false
---

## Choose a command

Use `/shape` to turn an idea or a fault into a ready piece of work. Use `/implement` to build a ready piece. If you choose the wrong one, it checks the request and sends it to the right command. `/what-now` reports the project's current state and next step.

## Repairs

The kit reproduces a fault before changing code. `/shape` records a repeatable failing case, and `/implement` fixes one likely cause at a time. After three failed attempts, another attempt needs a risk notice and your decision.

## Evidence

The evidence depends on the change. A behaviour change needs a test that fails before the change and passes afterwards. A screen change can be checked by trying it. A fact about an outside service needs a source. Work involving a backup, restore, migration or deployment needs an operational rehearsal. The report names what passed, failed or could not be checked, and what remains a human judgement.

For work in a named risk area, the kit may offer to break the changed code in a throwaway copy and check whether the tests notice. This optional check reports how many breaks the tests caught and missed. A miss in a named risk area is raised for your decision. The kit adds a test only to protect promised behaviour, not to improve the count.

## Automatic runs

Automatic work is off unless you ask for it. You can opt into building pieces in parallel, a short repeated loop, or automatic merging. The masterplan records your choice and its limits. Automatic merging requires three earlier approved merges and a current branch. It waits for checks, reviews, risk areas, migrations, new settings, live requirements, repairs and changes marked for you to try. A failed check on `main`, or a failed live check after an automatic merge, pauses it, and only you can resume it. A pull request whose checks fail stays open.

By default, `/implement` asks for your approval before merging each pull request. If the selected host deploys on merge, the merge also puts the change live.

## Working as a team

The pieces live as issues in the project's GitHub repository. Team members with repository access can see the shared work list and its decisions. `/implement` assigns the piece it starts, so the issue shows who is working on it. Agree through the piece and its records before changing shared data, access or live settings. See [project records and risk](/ai-build-kit/records/) for how the kit records those decisions.
