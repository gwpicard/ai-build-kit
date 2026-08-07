# The evidence run

Used by ship before anything goes live, and by build auto at the end of a
run. Findings come with fresh output; no claims from memory. Skip a section
below only when it genuinely doesn't apply to this tool, and say so rather
than leaving it silently blank.

## 1. Promised behaviour

For each main journey named in the masterplan: the evidence type used, the
command or user action taken, the expected result, the actual result, and a
pass or fail.

## 2. Failure behaviour

Test whichever of these are relevant: invalid input, a duplicate action,
unauthorised access, an external service failing, an action interrupted
partway, two people acting at once, a large or malformed input, a retry, and
an offline or unavailable dependency. Narrate each probe in plain words; a
line saying "I tried two people pressing save at once" teaches the habit of
expecting failure better than any instruction to have it.

## 3. Data and access

Where applicable: secrets absent from the repository and from anything sent
to the browser, permissions checked across more than one user, test and live
data kept separate, a migration rehearsed on a copy, a backup actually
restored, and deletion or export behaviour checked.

## 4. Operations

Where applicable: alerts arrive, the named owner reads them, service and
billing ownership are known, the manual fallback works, and the rollback or
disable process works.

## 5. Review and expert gates

Independent review completed, its blocking findings resolved, any expert
condition completed, and the review's scope and limitations recorded rather
than implied.

## 6. Report honesty

End with what passed, what failed, what was not checked at all, what
remains a human judgement rather than a proven fact, and whether the current
build path permits shipping this.
