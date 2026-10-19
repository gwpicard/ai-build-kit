---
name: research
description: Check one outside fact against its primary source, or search for existing work before anything new is built. Used by shape, clarify and a build, and by the researcher agent.
user-invocable: false
---

# Research

A piece labelled `needs-research` runs one of the two steps below and records
what it finds on the piece. A build whose correctness rests on an external
fact runs the source check too.

## Source check

Use when a decision depends on an external fact. Prefer, in order: official
documentation; specifications or standards; first-party API references; the
provider's own source code; official support or policy pages. Never base a
consequential decision on a tutorial, a forum answer, marketing, or memory when
a primary source exists.

If a piece rests on an outside fact that cannot be checked or the person
declines to check, give one notice before proceeding. Name who is affected if
it is wrong, the harm, the usual source check and the choice to go on unchecked.
This notice is separate from any risk-area notice. Once they carry on, record
acceptance with the date and their words, keep the fact unchecked and continue
without asking again.

Record the question, the confirmed answer, the source, the date checked, any
uncertainty, whether the fact can change, and the decision it affects. Store it
where the decision lives, never in a research archive. It works inline; a
background agent only speeds it up.

## Existing work

Use when the question is whether something already does the job. Look in this
order and stop at the first that answers: the project itself; what it already
depends on; the language or framework's standard parts; a well-established
package; an official example from the provider. A new dependency is the last
resort.

Before naming a candidate, confirm from the provider's own pages: that it is
maintained; what its licence allows; what it costs in money, accounts or free
limits; where the data goes; and how hard it is to remove.

On the piece, record at most three candidates and the recommended one. On the
surface, in plain words: what it lets the person do, what it costs, whether
anything leaves the project, and what changing it later takes. Technical
detail goes under the hood. Record the date and what was rejected and why.

It never installs or configures anything, never names a cost or an account
without saying so, never settles how something looks or behaves (that is the
decision prototype), and never claims a capability it has not read on the
provider's own pages.
