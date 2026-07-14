---
name: start
description: Begin a new project, or resume a beginning that was interrupted. Use when the user types $start or asks to start, plan, or set up a new tool. Runs once per project; if the founding documents already exist and are complete, say so and point at $build. Do not use for new features on an existing project (that is build) or for repairs (that is fix).
disable-model-invocation: true
---

# Start

You take a team from an idea to a project ready to build: interviewed, assessed, documented, stood up. You write no feature code in this skill. It is resumable: read what already exists, say plainly which step you are resuming from, and carry on.

## 1. Should this be software at all?

Test the idea against the ladder, cheapest first: a process change, a feature in something the team already pays for, an off-the-shelf product, a configured AI chat, an agent skill, custom software. Ask the four questions: will it keep records that build up over time? Will other people use it without the person who made it? Should it act on its own? Must it enforce rules? If nothing needs custom software, say so, say what would do instead, and stop. Saving the team a project is a good outcome.

## 2. The interview

Run the grilling skill for the founding interview. It ends when your guesses keep being right.

## 3. The fit check

Go through references/fit-check.md, all six questions, one at a time, guesses attached like the interview. All six no: the pre-filled stakes section from templates/masterplan.md applies. Any yes: the fit check says what the stakes section records instead, flags and launch rule included, and what that means in practice: a paid review before the flagged part goes live, a planned handover, or a pause to redesign. Either way, the answers and the date go in the stakes section.

## 4. Write the masterplan

Create masterplan.md from templates/masterplan.md, filled from the interview, present tense throughout. The stakes section goes first: the fit check's outcome, or the preset.

## 5. Fresh eyes on the page

The drafted masterplan gets read by fresh eyes: a new chat, running the second-opinion skill on masterplan.md. A problem found on paper costs a sentence to fix; the same problem found in built code costs an evening. Stop here until that review has happened; when resuming, look for its note in the changelog.

## 6. Three questions

Three questions get answered from the masterplan alone, no memory allowed: who can see and do what? What happens when the main flow fails? What is out of scope? If any answer isn't on the page, fix the page and ask again. When all three hold, note it in the changelog.

## 7. Cut the plan

Create plan.md from templates/plan.md. Pieces sized for one sitting, in the order they unblock each other, each cutting through the whole tool so the unknowns surface early. Every done line says how it will be checked: a test proves it, you see it in the browser, or you check it by hand. Ideas that did not make the cut go under parked ideas.

## 8. Stand the project up

Ask two questions: will the team use this in a browser, and does it need to work when your machine is off? Set up accordingly. One established, conventional stack, because the agent is strongest where the conventions run deepest. Managed services for anything storing sign-ins, payments, or files; those never get hand-built, however capable you feel. If hosting is needed, arrange it so day-to-day pushes land at a preview address and only $ship changes the address the team uses. If the interview surfaced confidential working files, create their folder now, add it to .gitignore and .worktreeinclude, and record the handling rules in AGENTS.md. Fill in AGENTS.md's project line and stack section. Finish with one passing test and a first commit, pushed.

## Done when

masterplan.md and plan.md exist and held their review, AGENTS.md is filled in, one test passes, the first commit is pushed, and the user has been told the next word is $build.
