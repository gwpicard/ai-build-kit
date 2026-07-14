# WORKFLOW.md: how this project runs

The reference card. When in doubt about what to type, start here, or just type $what-now and let it tell you. Skills are invoked by typing $ and the name in the agent panel, or by asking for them by name.

## Seven words, named after moments

| The moment | Type |
|---|---|
| I'm starting something | $start |
| Keep going, or: I want it to... | $build |
| It's broken | $fix |
| I think it's ready | $ship |
| I'm done for today | $sync |
| It's been a while | $maintain |
| I'm lost | $what-now |

Underneath the seven sit exactly two kinds of work. $build makes the tool do something new or different. $fix brings it back to doing what it already should. Everything else is housekeeping around those two.

## Four documents, one per tense

The documents are the project's memory. The agent forgets everything between sessions; these don't, and every piece of work starts by reading them.

| Document | Job | Written |
|---|---|---|
| masterplan.md | What the tool is, in the present tense, in about a page. Its first part, the stakes section, records how careful this project needs to be; the agent reads that part first, always. | Created by $start; the stakes section changes only by re-running the assessment; kept true by $sync |
| plan.md | What's left to build: the pieces, in order, each with a sentence saying when it's done and how you'll check. It churns constantly, and that is its job. | Created by $start; updated by $build; kept true by $sync |
| CHANGELOG.md | What happened, dated, in plain language. | A line added after every piece of work |
| AGENTS.md | How we work here: the rules, the stack, the conventions. | Set up by $start; touched only when a convention changes |

The dividing rule: the masterplan describes the present, the plan holds the future, and the moment a sentence is about when, why, or how something was built, it belongs in the changelog.

## Day one

Type $start. It talks you out of building if something simpler would do, interviews you one question at a time with its best guess attached, pauses while you take the assessment, writes the masterplan, has a fresh session read that page looking for holes, cuts the work into pieces on the plan, and stands the project up with one passing test. Interrupt it anywhere; typing $start again resumes where it stopped.

## Day to day

Typed alone, $build takes the next piece from the plan. It agrees with you in one sentence what the piece should do, writes a test and shows it failing first, builds until the test passes, then stops so you can try it. Nothing is saved until you confirm it behaves. If the change touched sign-in, stored data, or money, a second agent with no memory of writing the code reviews it first and reports in plain language.

Typed with words after it, $build is how you bring anything new: "$build add a filter to the board". You never sort your own request; the agent works out what kind of work it is. Small and clear gets built right away. Vague gets a short interview. Anything touching data, access, or money gets written into the masterplan first. And if the request would change what kind of project this is (outside users, real money moving, a promise to someone), it sends you back through the assessment before building.

$fix is for when something that should work doesn't: "$fix the board duplicates cards when I drag them". Paste the whole error if there is one. It works out the cause before touching code, wipes failed attempts rather than stacking them, and finishes with a test that keeps the bug from coming back. If the same piece fails three rounds in a row, it stops patching and rebuilds the piece from the masterplan, which is usually quicker and cleaner.

You can't misfile work by picking the wrong word. Both check your request against the masterplan first and re-route politely if you guessed wrong.

## Two copies of the tool

There are two copies, the way a document has a draft and a published version. $build and $fix work on the draft, where you check behaviour and can break things freely. The copy your team actually uses changes only when you type $ship, so half-finished work can never land in front of people by accident.

## When it's ready: $ship

$ship checks everything first: it runs the tests, walks the main journeys, tries to break the tool on purpose, and has a fresh session review the whole build. Then it takes the work live, with error alerts pointed at an inbox someone reads and a backup that has actually been restored once. After the first launch it gets lighter: it re-checks what changed and moves that over.

## Running ahead: $build auto

Once the plan exists, "$build auto" builds several pieces in a row without you between them. You approve the plan once, then it runs. Every piece still gets its own test and its own saved snapshot, and the run stops at any failure, anything risky, and anything unclear. The trade is that you check a batch at the end instead of each piece as it lands: the run finishes with a checklist of things to try, riskiest first.

## Housekeeping

$sync trues the documents up against what actually happened, at the end of a session. The pack wires it to run by itself when a session closes, where the tool supports that; typing it by hand is the fallback. $maintain is the service visit: monthly and light for updates and anything the error alerts caught, quarterly and fuller for a tidy-up. It also owns the ending, when a tool's time is over: export the data, tell the team, switch off the services.

## Git, day to day

Everyone on main for now, and one builder at a time: two people running $build at once will collide on the same files, and untangling that is the worst first experience this system can give you. If two of you want to build in the same week, claim pieces by name in plan.md first. Pull before you start, commit when a piece works, push so others can pull it. Conflicts go to the agent to walk through.

## If the plan outgrows the file

Three signs: more than one person building at once, pieces that block each other in ways an ordered list can't say, or an automation that needs somewhere to file what it finds. At that point the plan moves to GitHub Issues, which the project already lives next to. The words don't change: $build takes the next ready issue instead of the next line, and plan.md shrinks to a pointer.

## What stays yours

Two things no skill ever takes: saying clearly what you want going in (a real example, the output you expect, what done means), and trying the result before it's saved. The system automates the routine and never the judgement.
