# Safety net for adopted code

This protects later changes to a tool the kit did not build. At adoption the
person sees which existing behaviours have tests and which still need evidence.
Explain: "I will record how access and the main tasks work today before changing
them, and name anything the tests cannot check."

## Before editing existing code

Read the actual entry points and permission boundaries. Use synthetic records
and local stand-ins, with no live data or outside writes. Keep the existing
language and test runner. If a boundary cannot run locally, name it as uncovered
and offer a piece to make it testable; leave that code untouched for now.

Create a test folder and run the quality-checks skill's script from the project root:

```sh
python3 <skill>/scripts/adoption-safety-net.py snapshot tests/adoption.json <source files>
```

List the existing files involved in permissions and the main journeys, including
their policy, storage and configuration dependencies. The script records their
fingerprints and refuses to replace an existing inventory. Do this before
writing tests or editing those files. Keep that inventory with the tests.

## Write tests against today's behaviour

First test who can see and change each kind of record: each observed role,
signed-out people, and another person's or team's records. Exercise the real
permission boundary through its entry point; a mock that grants or refuses
access cannot prove it. Then test the main journeys, including a refusal or
failure people rely on. Assert observed results even where they appear wrong;
record the fault separately for a later piece.

Fill the inventory's `permissions` and `journeys` arrays, each with suites like:

```json
{
  "behaviour": "Members read their team's notes and cannot read another team's",
  "tests": ["tests/permissions.test.mjs"],
  "command": ["node", "--test", "tests/permissions.test.mjs"]
}
```

Use the project's commands and paths. Fill `uncovered` with concrete gaps, such
as session expiry or an outside connection. An empty array means no further
gaps are known, not that coverage is complete.

Run `python3 <skill>/scripts/adoption-safety-net.py baseline tests/adoption.json`.
It checks the fingerprints before and after running permissions, then journeys.
Exit 1 means a test failed or existing code changed; exit 2 means it could not
check. Resolve the test setup or record the limitation without changing the
baseline to get a pass. Save the passing tests and inventory before feature
code. Follow the records skill for each masterplan entry.

## Later changes and the report

Wire `python3 <skill>/scripts/adoption-safety-net.py check tests/adoption.json`
into the project check. This runs the tests without requiring unchanged source.
Before touching an uncovered area, snapshot its files in a separate inventory
and repeat the baseline step. Keep earlier tests running.

Include the script's result and coverage limits in the completion report. It
states that recorded behaviour is not approved behaviour and may record a
fault. If a test fails later, the person can ask `/implement` to investigate;
they do not need to read code or approve the old behaviour to proceed.
