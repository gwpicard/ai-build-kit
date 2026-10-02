---
name: project-context
description: Look up the current project knowledge relevant to a change. Called explicitly by commands before shaping or changing behaviour, data, permissions, integrations or architecture, including refactors crossing those areas. Uncertain reach takes a small lookup; purely mechanical formatting may skip it. Keeps facts in project records and names context gaps through the existing shaping or blocking route.
user-invocable: false
---

# Project context

This skill selects what to read, not what the project should do. It holds no
project facts. Use it on every build path for the changes in its description,
including repairs and refactors intended to preserve behaviour. When the reach
is uncertain, start with a small lookup rather than assuming no rule applies.
A purely mechanical formatting edit may skip product lookup once its reach is
clear. Standing instructions and the working rules required for the action
remain mandatory independently of this lookup.

## Select current owners

Load the `setup-ai-build-kit` skill's `references/project-records.md` first.
Its format route determines ownership; reading never migrates a legacy project.
On the new format, read the current `docs/README.md` index, which names what each
concept owns. On the legacy route, use the relevant masterplan sections and
linked design documents. The overview is an orientation and pointer, not a
replacement for an authoritative rule. Read only its relevant summaries and
links; invoking this skill never requires the whole masterplan, every concept
or every completed issue.

Start with the task, its agreed decisions and affected-document list. For work
with code, use the `section-builder` skill's `references/reach-check.md` against
the current tree. Use the reach result and the index's ownership descriptions to
find relevant rules, not just a matching filename or exact word. Search the
index and candidate headings with the available local search tool, such as
`rg`, then read the authoritative sections that govern the action. A shared
permission, data or architecture rule can own more than one concept.

## Read enough to establish the rule

Follow necessary cross-references from each selected rule, including a rule's
definitions, exceptions, origins and dependencies. A narrow read that omits an
exception is incomplete. Read a linked document in full when the reference
requires the whole document; otherwise select its relevant section. Use direct
reads when that is simpler. The `project-context` skill's `scripts/read-context.py` is an optional
local section reader:

```text
python3 <installed project-context skill>/scripts/read-context.py --root <project> docs/access.md#retirement
```

Give it one or more project-relative Markdown paths, optionally with heading
anchors. It returns selected sections, the files opened and unresolved external
or non-Markdown leads. It follows local inline and reference links in those
sections, including cycles only once. It reads current files on every call,
writes nothing and emits no successful partial result on a broken reference.
Its output is retrieval evidence, never a ruling on authority or consent.
Unsupported link syntax or an unresolved lead needs a direct read when relevant;
the reader is no guarantee that the selected context is complete.

Compare the rules with the requested result and current code. Search related
history only when it can settle a specific question, such as whether a repair
already failed or a choice was declined. Do not load all completed pieces to
compensate for uncertainty.

## Carry the selection, refresh the evidence

When shaping, put the authoritative documents and relevant sections on the
piece's `Under the hood` notes. In its existing `Masterplan change` field name
the intended updates to each affected owner, or why no update is needed. Name
masterplan changes only for its overview, useful summaries or links. Shaping
records future changes on the piece; it does not apply them to current records.

Before building and on resumption, re-read the current index, selected sections
and required working rules. Earlier session memory and a saved selection are
leads, not proof they remain current. When newly reached code or a changed
requirement expands scope, refresh the lookup and the affected-document list
before changing that area. Use the command's existing scope and readiness
rules if the change opens a new decision.

## A context gap is work still unsettled

Name a missing document, broken reference or contradictory rule precisely,
including the owners and the action it prevents. Say: "I cannot establish the
rule for <action>: <named gap>." Never treat it as no constraint, invent a rule,
or manufacture permission or sensitive-area acceptance.

Where it affects the result or authorisation, leave dependent work untouched
and take the calling command's existing shaping, waiting or blocking route.
A factual gap takes its existing research route; a product decision takes
`/shape`; stale records take `/sync`. Continue only independent work already
authorised. This adds no new consent gate or state. Explicit coverage,
reconciliation and launch reviews can read the broader records their purpose
requires; selective lookup must not narrow those reviews.
