---
name: setup-ai-build-kit
description: Begin a new project, or resume a beginning that was interrupted. Use when the user types /setup-ai-build-kit or asks to start or set up a new tool. Runs once per project; if the founding documents already exist and are complete, say so and point at /implement. Do not use for new features or repairs on an existing project; both are shape.
---

# Setup AI Build Kit

You take a team from an idea to a project ready to build: interviewed,
assessed, documented, stood up. You write no feature code here. It is
resumable: read what exists, say which step you are resuming from, and carry
on.

## Conversation contract

Speak when the person needs to answer, decide, approve, understand a blocker,
or see a result that changes what they can do next. Finishing an internal step
is not a user-facing result by itself. Routine reading, research, setup, and
checking happen quietly. Do not narrate commands, searches, versions, retries,
waiting, or terminal output, and do not repeat a harness's own status text.

Ask every question in the shape clarify's "How to ask" section describes,
whichever step you are on.

Name a tool or service only when the person must choose it, pay for it, own
its account, grant it access, or understand a limit it puts on the product.
When you name one, say what it is in one plain sentence at the same moment.
Record technical choices in AGENTS.md.

Give the plain permission explanation once, immediately before a real
confirmation box. Do not announce that a confirmation might appear later.

## Founding ends with something stood up

No step below is a gate. Founding is finished when the project exists and a
checkpoint is saved, and that outranks any answer still outstanding. An answer
you want but do not need becomes an open question in the masterplan, with your
best guess beside it. A step that says to check something is a check, not an
interview question: record a gap as a setup task or open question and tell the
person what was recorded. A person who says to get on with it has answered
everything: take your guesses, say in one line what you assumed, and stand the
project up.

## 0. Resume safely

Load `references/resume.md` and follow it before anything else, and say where
you are resuming from.

## 1. Orientation

Before any technical action, say close to: "First I'll help turn your idea
into a small plan. Then I'll prepare a private working version, check that it
opens, and save a checkpoint. Nothing will be published or shared unless I
explain that separately and you approve it." For an existing project to adopt,
say you will understand what exists before anything changes. Say nothing about
GitHub yet. Skip this when a resumed session already said it.

## 2. Capability check

Run `scripts/check-tooling.sh` from this installed skill folder. It reports
whether Git, the GitHub command line tool and python3 are ready and signed in.
Then work through references/capability-check.md, which says what to do when
the script cannot run, and record the result in AGENTS.md under Capability
profile. A missing optional capability becomes a
setup task or a reduced-automation fallback, decided at the step that needs
it, never before the interview.

## 3. Fresh project, or adopting something that exists?

Ask whether code already exists: an app from an all-in-one builder, a tool
inside a chat assistant, an earlier attempt. If yes, follow
references/adopting.md, which reshapes the steps below.

## 4. Test the need for software

Test the idea against the ladder in `references/need-for-software.md`, and
carry straight on.

## 5. Founding interview

Run the `clarify` skill. Settle overloaded terms, use concrete examples, run the
source check for an outside fact, settle a visual or behavioural question with
something they have or a throwaway prototype, and keep open questions visible.
It ends when your guesses keep being right. Load `references/stand-up.md`
before the reply that closes it, which shows the recipe menu.

Write each agreed answer into `.agents/tmp/setup-notes.md` before the next
question, as plain sentences under the question. Before the first write, make
sure `.gitignore` carries `.agents/tmp/`. Say nothing about the file.

## 6. Fit check and build path

Go through the `fit-check` skill: who will use it, then the consequence and
ownership questions, one at a time, guesses attached. Record in the notes: the
access setting, the build path and why, each sensitive area and its caution,
the recheck triggers, and today's date. Before naming an area, work through the
redesign options; if a redesign changes the answers, run the check again. Where
an area survives, give the risk notice the `fit-check` skill describes, once
and in full, before any flagged work. If the person carries on after it, write
their acceptance into the notes with their words and the date, so the
masterplan's `Accepted:` line carries it, and go on in that same reply with no
further yes. If they do not, founding goes on and the caution stays `not yet
done`. A no to an ownership question becomes a founding task, never a path
move.

## 7. Write the masterplan

Load `references/write-the-masterplan.md` and follow it.

## 8. Review the masterplan

On Build with care only, review the masterplan with the `second-opinion` skill
before flagged work continues, by the best independent method in the capability
profile. Where none exists, say so, record it in the changelog as a gap to
close before flagged work, and carry on. Apply a finding worth stopping for
only on the person's yes, or where their go-ahead to use your guesses covers
it, saying which. The completion report lists those findings. On the other
paths, say in one line that the review was skipped and why, and record that in
the changelog.

## 9. Ownership check

Answer from the masterplan alone: can the team explain the main flow, who can
see and change what, where data, secrets and service accounts live, how to
carry on manually if the tool stops, and who owns alerts, backups, bills and
access? A no becomes a setup task, by the `fit-check` skill's ownership rule. The
changelog records only that this check ran and when.

## 10. Cut the plan

Cut pieces sized for one sitting, in the order they unblock each other, each a
vertical slice through the whole tool: what the person can do or see when it is
done, its evidence, and its real dependencies. Never split one capability into
"database", "API" and "UI" pieces. Then load `references/cut-the-plan.md` and
follow it.

## 11. Stand the project up

Follow `references/stand-up.md` to the end.

The founding save is always a local checkpoint. Do not push it or open a
pull request, whatever the tool will grow into: founding said nothing would be
uploaded. The first upload waits until the first piece that pushes asks, as
"The first upload" in the `merge` skill's `references/first-upload.md` describes.

Once it is stood up and saved, load references/completion-report.md and
report in its shape.

## Done when

The build path is recorded, the records exist (masterplan.md, CHANGELOG.md, and
the pieces as issues), AGENTS.md contains the capability profile and project
commands, the masterplan has had whatever review its build path called for or a
changelog line saying why none ran, the initial state is saved as a local
checkpoint, the plan is made of visible pieces each labelled `ready` or with its
open question, one check passes, and the user has received the plain-language
completion report, which ends on a clean cut naming `/implement` and `/shape`
rather than an offer to build in this session.
