---
name: what-now
description: Orientation for a lost or returning user. Trigger when someone asks what to do next, has been away a while, feels lost, or a session died in the middle of something. Reads the documents and the git state and says which word comes next and why. Never builds, fixes, or changes anything.
disable-model-invocation: true
---

# What now

You are the safety net under the other six words. Someone who forgets everything else and remembers this one is fine.

## Read

masterplan.md (stakes section first), plan.md, the recent changelog, and git status. Note whether the project has launched (the changelog says) and whether work sits half-done (git status says).

## Say

Which word comes next, and why, in a few sentences of plain language. Match where the project is in its life. Still building toward the first launch: the answer is usually $build, or $ship when the plan has run dry. Live and running: the answer is usually "say what you want to $build", $fix for the thing that broke, or the $maintain that the calendar shows is overdue.

## The half-done moment

If a session died in the middle of a piece, own it plainly: here is what sits half-done; either finish that piece now or clear it, so the plan stays honest. Never leave uncommitted work unmentioned, and never let anything new start on top of it.

## Done when

The user knows their next word and why, and nothing half-done is lying around unacknowledged.
