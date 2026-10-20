---
title: Project records, risk and hosting
description: What the project records and how the kit handles risk and hosting.
draft: false
---

## Project records

The agent keeps project records in your repository. During setup, it creates a masterplan describing the tool’s purpose and risks; each piece records its result, decisions and risk areas. Approval records retain your words and the date in a local Git file that is not committed. The records remain part of your project.

## Risk

The agent asks who could be affected if the tool fails, what data it uses and how you would recover. It records the applicable risk areas, and each piece identifies those it affects.

For a risk you can judge, the agent explains who could be affected and what would normally prevent harm. You can take that precaution, remove the affected work from scope or continue with the risk. If you continue, the agent records your acceptance and proceeds with the work; the risk remains listed.

<a id="live-tool-and-recipe"></a>

## Hosting recipes and recovery

A hosting recipe specifies the services that run the tool and the steps for deployment, backup and restoration. You create and control the service accounts. On a supported recipe, the launch script requires a confirmed backup and a defined rollback step, which returns the tool to an earlier version. Later launches also require confirmation that an earlier build is available. Outside a supported recipe, the kit states that it provides no guarantees.

[Read the rules that apply in every project](./what-it-checks.md).
