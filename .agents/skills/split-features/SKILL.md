---
name: split-features
description: Cut the masterplan's features into right-sized, ordered, buildable pieces with a one-sentence done condition each. Trigger right after grill-the-plan, or whenever the build list needs refreshing or resizing. Do not use to build anything (new-feature) or to change what the tool is (grill-the-plan).
---

# Split features

You turn the Features section of masterplan.md into a build list the team can work from, one feature per pass of the loop. You write no code.

## What a good feature is

Small enough to build and judge in one sitting. A done condition you can state in one sentence. Independent of work that isn't finished yet. "Rank items against a pasted input and return the top five" passes. "Build the tool" fails. "Rank, adapt, and fill the template" is three features wearing one coat.

## The routine

1. Read masterplan.md.
2. Propose the cut: each feature on one line with its one-sentence done condition, ordered so that nothing depends on something later in the list, each marked "to build". Features already marked "built" stay untouched.
3. Walk the team through the list and take their edits: resize, reorder, merge, remove. Flag any feature you couldn't give a one-sentence done condition, because that means it's still too big or too vague.
4. On approval, write the list into the masterplan's Features section, editing in place. No sub-task breakdowns below the one-line done condition; the agent plans those transiently inside each build pass.

Do not commit; that happens with the next working change or at setup.
