---
title: Concepts
description: Plain explanations of the terms used by AI Build Kit.
draft: false
---

## Piece

A piece is one agreed task with a result that someone can check. You see its goal, what counts as success and any questions it still needs you to answer. `/shape` prepares a piece. You decide whether it is ready for the agent to build.

<a href="https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/shape/SKILL.md">Source (for maintainers)</a>

## Risk area and risk record

A risk area is a kind of harm a tool could cause, such as exposing personal data or giving a wrong answer. The risk record describes who could be affected, what data the tool holds and how you could recover from a failure. Each piece names the areas it touches. The kit explains the caution, then you decide what to do. It records your choice.

<a href="https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/fit-check/SKILL.md">Source (for maintainers)</a>

## Review

A review checks whether a change meets its agreed goal, whether it breaks something that worked before, and whether the evidence supports the result. A person decides whether a finding should stop the work. By default, you decide whether to approve the change for merge; automatic merging is an opt-in recorded with limits.

<a href="https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/second-opinion/SKILL.md">Source (for maintainers)</a>

## Checks

A check can pass, fail, or be unable to decide. Pass means it found no problem in what it checked. Fail means it found a problem. Unable to decide means it could not give a result. A check that did not run is not a pass. These results can also appear as exit codes: 0 means pass, 1 means fail, and 2 means unable to decide.

<a href="https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/SKILL.md">Source (for maintainers)</a>

## Merge

A merge puts a change into the project's main version. By default, you try the change first, then give a clear yes to merge it. Automatic merging is an opt-in recorded with limits. On a hosted project, a merge can put the change live.

<a href="https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/SKILL.md">Source (for maintainers)</a>

## Live copy

The live copy is the version of the tool that people can use. The kit compares it with the saved project and reports differences. You decide before the kit changes anything that is live.

<a href="https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/live-copy/SKILL.md">Source (for maintainers)</a>

## `/maintain`

`/maintain` checks the project records and the live copy. It also offers kit updates and upkeep when they are due. You decide whether to apply changes beyond routine updates. It cannot repair poorly written code.

<a href="https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/maintain/SKILL.md">Source (for maintainers)</a>

## Autonomy

Autonomy lets the kit build several ready pieces without a person present, when the project has enabled it. All options are off by default and recorded in `Runs on its own:`. The automatic merge option needs three earlier merges with a named yes and holds for checks, review findings, repairs and named risk areas.

<a href="https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/implement/SKILL.md">Source (for maintainers)</a>

## Recipe

A recipe is a proven setup for building and running a tool. It names the software stack and where the tool runs. It also sets how the tool goes live, gets backed up and returns to an earlier version. You create and own the accounts these services use.

<a href="https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/SKILL.md">Source (for maintainers)</a>
