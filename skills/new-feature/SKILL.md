---
name: new-feature
description: Use when the user asks to create, add, build, implement, or extend an app with a new feature. Guides feature work from context discovery through scoped implementation, validation, and handoff.
---

# New Feature

Use this skill to implement a feature in an existing app or a fresh codebase.

## Workflow

1. Understand the request
   - Identify the user-visible outcome, not just the code change.
   - Infer reasonable defaults from the app when details are missing.
   - Ask only when a missing decision would materially change the result or risk wasted work.

2. Inspect the app
   - Find the framework, package manager, entry points, routes, and existing feature patterns.
   - Read nearby components, services, tests, styles, and data models before editing.
   - Prefer existing conventions over introducing new abstractions.

3. Plan the implementation
   - Keep the feature small enough to finish and verify in one pass when possible.
   - Identify affected files, state/data flow, UI states, error states, and validation needs.
   - Choose the least surprising integration point.

4. Implement
   - Make focused edits that match local naming, structure, styling, and dependency patterns.
   - Include empty, loading, error, and success states when they are part of the user flow.
   - Avoid unrelated refactors and broad formatting churn.

5. Validate
   - Run the narrowest meaningful tests, type checks, linters, or build command available.
   - For frontend work, run the app and inspect the changed flow in a browser when practical.
   - Fix issues discovered during validation before handing off.

6. Handoff
   - Summarize what changed and where.
   - Mention commands run and any failures or skipped validation.
   - Call out follow-up work only when it is directly relevant.

## Feature Quality Checklist

- The feature is reachable from the existing app flow.
- The main path works with realistic data.
- Edge cases do not break layout or state.
- Errors are visible and recoverable where appropriate.
- The implementation follows existing app patterns.
- Validation results are reported clearly.
