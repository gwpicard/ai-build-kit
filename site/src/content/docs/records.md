---
title: Project records, risk and hosting
description: What the project records and how the kit handles risk and hosting.
draft: false
---

## Project records

The agent keeps project records in your repository. During setup, it creates a masterplan describing the tool’s purpose and risks; each piece records its result, decisions and risk areas. Approval records retain your words and the date in a local file in the repository’s shared Git directory. Git does not commit that file.

## Risk

The agent asks who could be affected if the tool fails, what data it uses and how you would recover. It records the applicable risk areas, and each piece identifies those it affects.

For a risk you can judge, the agent explains who could be affected and what caution, or safeguard, would normally prevent harm. You can take that caution, remove the affected work from scope or continue with the risk. If you continue, the agent records your acceptance and proceeds with the work; the risk remains listed.

The kit uses six risk areas. A piece names each area it touches, or records `none`.

| Risk area | Typical caution |
|---|---|
| Personal or sensitive data | Independent access review before real data. |
| Money | Keep card details out of the tool and check the first figures against a known case. |
| Sign-in and permissions | Use managed sign-in and get an independent access review before outside use. |
| Automatic action | Require approval until a live run proves the action, and provide an off switch. |
| Irreplaceable live data | Back up, restore and rehearse on a copy before changing the original. |
| Regulated decisions | A qualified person signs off before anyone acts. |

The exact caution depends on the tool and its exposure. A risk notice explains who could be affected and what the caution would normally prevent.

<a id="live-tool-and-recipe"></a>

## Hosting recipes and recovery

The tool goes live through a [hosting recipe](/ai-build-kit/recipes/), which lists the services that run it and the steps for deployment, backup, restoration and rollback. The launch script does not record a live address while its backup and rollback conditions are unmet; it cannot stop a host that deploys on merge. You create and control the service accounts. Outside a recipe, the kit states that it provides no guarantees.

[Read the rules that apply in every project](/ai-build-kit/what-it-checks/).

[Read about live data and recovery](/ai-build-kit/live-data/).
