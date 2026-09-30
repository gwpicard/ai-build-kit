#!/usr/bin/env sh
# plan-refresh.sh: print the project's open pieces into plan.local.md.
#
# Information flows one way. The issues are the record; this file is a printout
# of them and never a source. Nothing here reads a piece from plan.local.md, and
# nothing anywhere writes back to an issue from it. If the printout looks stale,
# print it again. The one line read back is the time it was written, so a
# refresh that cannot reach GitHub can say how old the list in hand is.
#
# The file is gitignored, so it is one person's view of a shared record and can
# never collide with anyone else's.
#
# Founding copies this file to .agents/tools/plan-refresh.sh in the project, and
# /maintain adds it to a project founded before it shipped with every
# installation. It lives in the setup-ai-build-kit skill because every route that
# installs the kit carries the skills and nothing else.
#
# Run from the project's root folder.

set -eu

OUT=${1:-plan.local.md}

command -v gh >/dev/null 2>&1 || {
  echo "plan-refresh: the GitHub CLI is not installed, so the plan cannot be refreshed" >&2
  exit 1
}
command -v python3 >/dev/null 2>&1 || {
  echo "plan-refresh: python3 is needed to read the issue list" >&2
  exit 1
}

# When GitHub is out of reach the last printout stays as it was, and this says
# when it was written, so the person still has a list and knows its age.
last_written() {
  written=$(sed -n 's/^Last refreshed: //p' "$OUT" 2>/dev/null | head -1)
  if [ -n "$written" ]; then
    echo "plan-refresh: $OUT is left as it was, written $written" >&2
  else
    echo "plan-refresh: there is no earlier printout to fall back on" >&2
  fi
}

repo=$(gh repo view --json nameWithOwner 2>/dev/null \
  | python3 -c 'import json,sys; print(json.load(sys.stdin).get("nameWithOwner",""))' \
  2>/dev/null || true)
[ -n "$repo" ] || {
  echo "plan-refresh: could not reach GitHub, or cannot tell which GitHub repository this project belongs to" >&2
  last_written
  exit 1
}

# Nothing here uses gh's built-in --jq. The filtering happens in python instead,
# so the only thing gh has to do is return JSON. That keeps one query language
# out of the script, and it is what lets the test harness stand in for gh.
#
# One call for the whole backlog. The list payload carries
# issue_dependencies_summary, so blocked_by tells us whether anything open is
# holding a piece up without asking per issue. Only the pieces that are blocked
# need a second call, to name what is holding them.
#
# The REST issues endpoint returns pull requests too, so they are filtered out.
listing=$(gh api "repos/$repo/issues?state=open&per_page=100" --paginate 2>/dev/null) || {
  echo "plan-refresh: could not reach GitHub" >&2
  last_written
  exit 1
}

# A blocker is named by its title rather than its number. A number is a thing
# the reader has to go and look up, and the commands that read this file have to
# say "deposits cannot start until card payments is set up" rather than
# "blocked by #9". Carrying the title here means neither of them has to match a
# number back to a line somewhere else in the file and hope it is still there.
blockers_for() {
  gh api "repos/$repo/issues/$1/dependencies/blocked_by" 2>/dev/null \
    | python3 -c '
import json, sys
try:
    items = json.load(sys.stdin)
except Exception:
    raise SystemExit(0)
print(", ".join(i["title"] for i in items if i.get("state") == "open"))
' 2>/dev/null || true
}

# Names of the blockers, gathered before the printout is written so a failure
# part-way through leaves the previous printout intact rather than a half one.
blocked_numbers=$(printf '%s' "$listing" | python3 -c '
import json, sys
for i in json.load(sys.stdin):
    if i.get("pull_request") or i.get("state", "open") != "open":
        continue
    if (i.get("issue_dependencies_summary") or {}).get("blocked_by", 0) > 0:
        print(i["number"])
')

blocker_map=""
for n in $blocked_numbers; do
  blocker_map="$blocker_map$n	$(blockers_for "$n")
"
done

# The listing goes via a file rather than a pipe. This script reaches python on
# stdin, so anything piped in as well would be read as part of the script and
# leave sys.stdin empty by the time the program runs.
listing_file=$(mktemp)
trap 'rm -f "$listing_file"' EXIT INT TERM
printf '%s' "$listing" > "$listing_file"

python3 - "$OUT" "$listing_file" "$blocker_map" <<'PY'
import json, sys, subprocess

out, listing_file, blocker_raw = sys.argv[1], sys.argv[2], sys.argv[3]
# A closed issue is done. The listing asks for open issues only, but the check
# is made here too, so a closed idea that stays labelled `parked` can never
# print as work waiting to be done.
issues = [i for i in json.load(open(listing_file))
          if not i.get("pull_request") and i.get("state", "open") == "open"]

blockers = {}
for line in blocker_raw.splitlines():
    if "\t" in line:
        number, names = line.split("\t", 1)
        blockers[int(number)] = names.strip()

stamp = subprocess.run(["date", "+%d %b, %H:%M"], capture_output=True,
                       text=True).stdout.strip()

def labels(issue):
    return {l["name"] for l in issue.get("labels", [])}

# A piece made of parts. GitHub's sub-issue summary rides along in the list
# payload, the way the blocked-by summary does, so a parent is known without a
# second call. total is how many parts; completed is how many have closed.
def sub_summary(issue):
    s = issue.get("sub_issues_summary") or {}
    return s.get("total", 0), s.get("completed", 0)

# An issue with no "## Done when" was typed by hand and has never been sized.
# Shape decides rather than the label, so one that nobody has labelled yet still
# shows up here as what it is. A parent carries no Done when of its own, because
# its parts carry the checkable conditions, so it is never a bare note.
def still_a_note(issue):
    if sub_summary(issue)[0] > 0:
        return False
    return "## Done when" not in (issue.get("body") or "")

# The six states, in the order a piece moves through them. Exactly one sits on
# an open piece.
STATES = ["idea", "shaping", "ready", "building", "to check", "parked"]

# `blocked` is the label an older project used before the states. It reads as
# parked, the state that replaced it, until something moves it. The old labels
# let it sit beside `ready` or `building`, so that pair is how an older project
# looks rather than a mistake, and parked wins.
def state_labels(issue):
    names = labels(issue)
    found = [s for s in STATES if s in names]
    if "blocked" in names:
        found = ["parked"] + [s for s in found
                              if s not in ("ready", "building", "parked")]
    return found

# What a piece is waiting on, when it is waiting on a question rather than on a
# person. Written out in words, because the label names are for GitHub and this
# file is for reading.
QUESTIONS = [("needs-clarification", "needs a few questions"),
             ("needs-prototype", "needs a throwaway build to decide"),
             ("needs-research", "needs a fact from outside the project")]

def waiting_on(issue):
    names = labels(issue)
    for label, text in QUESTIONS:
        if label in names:
            return text
    return ""

# Why a piece needs a person to look at it, or "" when it does not. Each of these
# is a mistake in the labels, and the printout names it rather than guessing
# which label is true.
def attention(issue):
    names = labels(issue)
    if len(state_labels(issue)) > 1:
        found = [s for s in STATES if s in names]
        found += ["blocked"] if "blocked" in names else []
        return "(carries two states at once: %s)" % ", ".join(found)
    reasons = [label for label, _ in QUESTIONS if label in names]
    if reasons and "shaping" not in names:
        return "(carries %s without shaping)" % ", ".join(reasons)
    if "ready" in names and still_a_note(issue):
        return "(labelled ready with no Done when, so still an idea)"
    return ""

# The board. A repair and a parent sit outside the columns: a repair because
# somebody opening this file wants to know what is broken before what is next,
# and a parent because it carries no state of its own. A piece whose labels
# contradict each other prints once, under Needs attention, except a ready
# piece with no Done when, which is an idea and also needs a look.
needs_attention, broken, parents = [], [], []
columns = {s: [] for s in STATES}
held_up = []
for issue in sorted(issues, key=lambda i: i["number"]):
    names = labels(issue)
    note = attention(issue)
    if sub_summary(issue)[0] > 0:
        parents.append(issue)
        continue
    if note:
        needs_attention.append((issue, note))
        if not ("ready" in names and still_a_note(issue)
                and len(state_labels(issue)) == 1):
            continue
    if "broken" in names:
        broken.append(issue)
        continue
    found = state_labels(issue)
    state = found[0] if found else "idea"
    # Shape decides. A ready label on a piece nobody sized does not make it
    # ready, so it waits among the ideas.
    if state == "ready" and still_a_note(issue):
        state = "idea"
    if state == "ready" and blockers.get(issue["number"]):
        held_up.append(issue)
    else:
        columns[state].append(issue)

lines = ["Plan (local view, refreshed from GitHub, do not edit)",
         "Last refreshed: %s" % stamp, ""]

# The question label says why a piece is waiting, so it replaces the generic
# note marker rather than printing beside it.
#
# `(ready)` marks only a ready piece that has been sized. The commands that read
# this file name a piece to build only when it carries that mark.
def state_note(issue):
    text = waiting_on(issue)
    if text:
        return "(%s)" % text
    if still_a_note(issue):
        return "(still a note)"
    return "(ready)" if state_labels(issue) == ["ready"] else ""

# A piece held up by another names it, whichever column it sits in.
def held_note(issue):
    names = blockers.get(issue["number"])
    return "(needs %s)" % names if names else ""

# Under Needs attention the labels contradict each other, so the line names the
# mistake and nothing else. A `(ready)` mark there would read as a piece to build.
def render(heading, group, note, marked=True):
    if not group:
        return
    lines.append(heading)
    for issue in group:
        who = ", ".join(a["login"] for a in issue.get("assignees", []))
        mark = state_note(issue) if marked else ""
        suffix = " ".join(p for p in (note(issue), mark) if p)
        head = "  #%-4s %s" % (issue["number"], issue["title"])
        if who:
            head += "   (%s)" % who
        if suffix:
            head += "   %s" % suffix
        lines.append(head)
        lines.append("       %s" % issue["html_url"])
    lines.append("")

notes_by_number = {i["number"]: n for i, n in needs_attention}
render("Needs attention", [i for i, _ in needs_attention],
       lambda i: notes_by_number[i["number"]], marked=False)
render("Broken", broken, lambda i: "(being fixed)" if "building" in labels(i) else "")
render("Idea", columns["idea"], held_note)
render("Shaping", columns["shaping"], held_note)
render("To build", columns["ready"], lambda i: "")
render("Held up", held_up, held_note)
render("Building", columns["building"], held_note)
render("To check", columns["to check"], held_note)
render("Parked", columns["parked"], held_note)
render("Made of parts", parents,
       lambda i: "(%d of %d parts done, build the parts)" % (sub_summary(i)[1], sub_summary(i)[0]))

notes = [i for i in issues if still_a_note(i)]
if notes:
    if len(notes) == 1:
        lines.append("1 entry is still a note rather than a piece, "
                     "so it needs a few questions before building.")
    else:
        lines.append("%d entries are still notes rather than pieces, "
                     "so they need a few questions before building." % len(notes))
    lines.append("")

if not issues:
    lines.append("Nothing open. The list has run dry.")
    lines.append("")

open(out, "w").write("\n".join(lines) + "\n")
print("plan-refresh: wrote %s from %d open pieces" % (out, len(issues)))
PY
