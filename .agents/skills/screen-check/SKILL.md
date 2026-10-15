---
name: screen-check
description: Apply the kit's screen rules during a build or review that touches an interface. Read the project's own design system first, report what was applied and what remains for a person to try, and make no claim that the screen is accessible, compliant, or good.
user-invocable: false
---

# Screen rules

Apply while building and reviewing screens. Skip founding, shaping, and
`/setup-hosting`. A repair uses these rules only for screen faults.

## When it applies

Run when the piece carries `visual` or changed files render a screen. This
includes pages, views, components, templates, styles, and native interfaces,
even if the piece missed its `visual` subject. Otherwise, do nothing.

Read the agreed behaviour, changed screen files, and any available render or
screenshot. Do not require a browser or service the coding agent lacks.

## Read the project first

Read `DESIGN.md` when present and the `Stack, and how to run and check it`
section of `AGENTS.md`. Their design system or component library wins over a
conflicting house rule. Say which project rule you followed. If the records
disagree, name the contradiction instead of choosing silently.

Do not create `DESIGN.md`, choose a library, install anything, or call a
service. Use only project files, supplied evidence, and available tools.

## Build the screen

Use one spacing scale based on multiples of 4 or 8. Group with space before
adding boxes. Use one accent colour with neutral greys; reserve colour for
meaning, never as its only carrier.

Use one type scale, at most two weights, and no light weights. Keep
prose lines 65 to 75 characters where space allows.

Design empty, loading, and error states first. Explain empty lists. Use a
spinner for 2 to 9 second work, then a measured percentage after 10 seconds.
Use skeletons only on tables and tiles.

Put a visible label above every field; placeholders are examples or hints.
Size fields for their content. Validate filled fields on blur, not empty ones.
On submit, focus the error summary, even for one error. Repeat the field label
and explain the fix. Avoid "please", "sorry", "invalid", and "you forgot".
Keep the person's entry after errors.

Use a list or table for like records, not cards. Give tables enough width; keep
column titles short and right-align numbers with tabular figures.

Give each screen one primary action. On forms, put it on the left. Prefer undo
to confirmation. Confirm only irreversible actions with outcome labels such as
"Delete" and "Keep". Require typing a name only for expensive loss. Return to
the list after deletion.

Support keyboard use. Keep focus visible and unobscured. Escape closes a dialog
and returns focus to its opener. Interaction targets are at least 24 pixels
wide and high.

Body text contrast is at least 4.5:1; controls, focus, and state indicators at
least 3:1. At 400 pixels wide, the screen must not scroll in two directions.
Only a table may overflow its box.

Use sentence case and button labels with a verb and noun. Avoid "click here"
and directions such as "above" or "below". Errors use plain words, name the
fix, and fit within two lines beside a field. Keep each element consistent
throughout the tool.

Show errors beside what failed, not in a vanishing toast. Use a modal only for
a decision needing protected focus, such as final confirmation.

## Refuse the defaults

Unless a project rule deliberately requires one, refuse:

- gradients and gradient text;
- glass or blur used as decoration;
- emoji or text glyphs used as icons;
- cards inside cards;
- all-caps eyebrow labels and hero headings on a product screen;
- the same entrance animation on every section;
- `outline: none` without a visible replacement;
- blocked paste or disabled zoom;

## Hand over the screen

Before the guided manual check, say: "I applied the screen rules before your
check, and I will name what they could not prove."

Then report three short parts:

- `Applied:` project and house rules used;
- `Could not check:` rules the available files and tools could not settle;
- `Try:` the exact action and expected result for the person's guided check.

During a build review, put findings inside `Worth stopping for` or
`Worth knowing`, without a screen heading. Say which rule was applied, what
was tried and happened, and what remains untested.

## Claim boundary

Never call a screen accessible, compliant, or good. Applying rules proves only
they were followed; conformance needs a person and a method these rules do not
provide. The handover names what was applied, what could not be checked, and
what a person should try.

## Reference pointers

For a longer checklist, see the [Vercel Web Interface Guidelines](https://github.com/vercel-labs/web-interface-guidelines/blob/main/AGENTS.md).
The [WCAG 2.2 quick reference](https://www.w3.org/WAI/WCAG22/quickref/)
provides criteria behind several rules. These are reading pointers, not
run-time dependencies. Do not fetch them.
