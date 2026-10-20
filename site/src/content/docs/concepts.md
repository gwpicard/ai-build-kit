---
title: Concepts
description: The ideas that guide a piece of work.
draft: false
---

## Piece

A piece is one task with a result that can be checked. `/shape` turns a request into a piece with a clear result. [`shape/SKILL.md`](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/shape/SKILL.md) owns this step.

## Risk area and risk record

The project risk record describes who could be affected, what data the tool holds, how a failure is recovered from, and which risk areas apply. Each piece names the risk areas it touches. The kit gives a caution for a named area and records the person's decision. [`fit-check/SKILL.md`](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/fit-check/SKILL.md) owns the risk check.

## Review gate

The review checks the saved change against the work it claims to have reviewed. A person decides whether to merge. [`second-opinion/SKILL.md`](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/second-opinion/SKILL.md) describes the independent review, and [`merge/SKILL.md`](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/SKILL.md) holds the merge gate.

## Checks and exit codes

Checks report a result. Exit code 0 means pass, 1 means fail, and 2 means the check could not decide. A check that did not run is not shown as a pass. [`quality-checks/SKILL.md`](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/SKILL.md) defines the check results.

## `/maintain` as the backstop

`/maintain` restores the kit's project records, settings and checks to their defaults. It also checks the live copy and due upkeep. It cannot repair badly written code. [`maintain/SKILL.md`](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/maintain/SKILL.md) owns this visit.

## Optional autonomy

An unattended run can build several ready pieces only when the project has enabled that option. It never accepts a risk or merges on a person's behalf. [`implement/SKILL.md`](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/implement/SKILL.md) sets those limits.
