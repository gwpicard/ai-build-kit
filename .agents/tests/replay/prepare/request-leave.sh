#!/usr/bin/env sh
# request-leave.sh: prepare a founded starter with one screen piece ready to build.

set -eu
project=${1:?project directory}
me=request-leave.sh

if git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "$me: $project is inside a git work tree, so it is not a fresh replay project" >&2
  exit 1
fi
skill="$project/.agents/skills/setup-ai-build-kit"
for need in AGENTS.md scripts/use-starter.sh; do
  if [ "$need" = AGENTS.md ]; then source="$project/$need"; else source="$skill/$need"; fi
  [ -f "$source" ] || { echo "$me: the installed kit has no $need" >&2; exit 1; }
done
for already in masterplan.md CHANGELOG.md package.json .gh-fixture.json; do
  [ ! -e "$project/$already" ] || { echo "$me: $project already has $already" >&2; exit 1; }
done

# Use the installed kit, including when KIT_SRC names an older tree. Never add
# this branch's components hint or lint rules to a comparison project's copy.
sh "$skill/scripts/use-starter.sh" recipes/nextjs-supabase-on-vercel "$project"
python3 - "$project" <<'PY'
import json
from pathlib import Path
import re
import sys

project = Path(sys.argv[1])
agents = project / "AGENTS.md"
text = agents.read_text()
stack = """Recipe: nextjs-supabase-on-vercel
Run: `npm ci`, then `npm run dev`.
Project check: `npm run check`. Type check: `npm run typecheck`.
Lint: `npm run lint`. Tests: `npm test` and `npm run test:coverage`.
Design tool: none recorded"""
text, count = re.subn(r"\(Filled in by the setup-ai-build-kit skill: `Recipe:.*?\n.*?in the code\.\)",
                      lambda _: stack, text, flags=re.S)
if count != 1:
    sys.exit("request-leave.sh: the foundation has no stack placeholder to fill")
agents.write_text(text)

(project / "masterplan.md").write_text("""# Masterplan

## Risk record

Exposed: The maintainer trying a local demonstration with invented requests.
Data: Fictional dates, a leave type and an optional note. No real staff data.
Wrong answer: The demonstration shows the wrong request, which can be entered again.
Recovery: Delete the demonstration data and enter the invented request again.
Access: private
Risk areas: none
Accepted: none
Recheck when: real staff data or a shared service enters the scope.
Last checked: 2026-10-23

## What it does, and for whom

This local demonstration lets a person request leave. The ready piece adds the
Request leave page. The starter's sign-in and owner setup stay as they are.

## Key terms

A request has a start date, an end date, a type and an optional note.
The types are Annual leave and Unpaid leave. It makes no approval decision.

## What correct looks like

A valid request saves through a server action and shows a confirmation.
An end date before the start date is refused with a clear message.

## How it stays running

The project is not live. Only invented data is used on this computer.
Requests go in data/leave-requests.json, which Git ignores. No database or
outside service is needed for this piece. This store is for the demonstration.

## Out of scope

Approval, staff records, real leave balances, database work and hosting.
""")
(project / "CHANGELOG.md").write_text("""# Changelog

## 2026-10-23

The project starts from the recipe's pinned starter. One Request leave piece
is ready. The code is already on the private repository. Nothing is live.
""")
with (project / ".gitignore").open("a") as handle:
    handle.write("\n/data/leave-requests.json\n")
body = """## So that
a person can send one leave request without asking across the room

## Done when
- D1: /request-leave shows a Request leave heading and a labelled form with
  start date, end date, type (Annual leave or Unpaid leave), an optional note
  and a Save request button.
- D2: A valid submission saves through a server action to
  data/leave-requests.json and shows a confirmation. An end date before the
  start date shows a clear error and saves nothing.

## Evidence
An automated check of valid and invalid submissions, and a local screen check.

## Masterplan change
nothing

## Not in this piece
Database work, approval, leave balances, staff records, hosting and changes to
the existing sign-in, invitation or owner setup.

## Decided
Use invented data only. The local JSON store is enough for this demonstration.
The request page is at src/app/request-leave/page.tsx. Keep its supporting
form and action in that route or in src/components/.

Risk areas: none

<details><summary>Under the hood</summary>

Reaches: src/app/request-leave/, src/components/
</details>
"""
state = {"repo": "office-tools/leave-request", "visibility": "PRIVATE", "next": 2,
         "issues": [{"number": 1, "title": "Request leave", "body": body,
                     "state": "open", "labels": ["behaviour", "ready"],
                     "assignees": [], "blocked_by": [], "sub_issues": []}],
         "pull_requests": []}
(project / ".gh-fixture.json").write_text(json.dumps(state, indent=2) + "\n")
PY
