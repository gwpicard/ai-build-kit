#!/usr/bin/env sh
# plan-refresh.sh: print the project's open pieces into plan.local.md.
#
# Information flows one way. The issues are the record; this file is a printout
# of them and never a source. Nothing here reads plan.local.md, and nothing
# anywhere writes back to an issue from it. If the printout looks stale, print
# it again.
#
# The file is gitignored, so it is one person's view of a shared record and can
# never collide with anyone else's.
#
# Run from anywhere inside the project.

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

repo=$(gh repo view --json nameWithOwner 2>/dev/null \
  | python3 -c 'import json,sys; print(json.load(sys.stdin).get("nameWithOwner",""))' \
  2>/dev/null || true)
[ -n "$repo" ] || {
  echo "plan-refresh: cannot tell which GitHub repository this project belongs to" >&2
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
  exit 1
}

blockers_for() {
  gh api "repos/$repo/issues/$1/dependencies/blocked_by" 2>/dev/null \
    | python3 -c '
import json, sys
try:
    items = json.load(sys.stdin)
except Exception:
    raise SystemExit(0)
print(", ".join("#%s" % i["number"] for i in items if i.get("state") == "open"))
' 2>/dev/null || true
}

# Names of the blockers, gathered before the printout is written so a failure
# part-way through leaves the previous printout intact rather than a half one.
blocked_numbers=$(printf '%s' "$listing" | python3 -c '
import json, sys
for i in json.load(sys.stdin):
    if i.get("pull_request"):
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
issues = [i for i in json.load(open(listing_file)) if not i.get("pull_request")]

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

# A repair goes at the top. Somebody opening this file wants to know what is
# broken before they read what is next.
broken, building, parents, blocked, to_build = [], [], [], [], []
for issue in sorted(issues, key=lambda i: i["number"]):
    names = labels(issue)
    if sub_summary(issue)[0] > 0:
        parents.append(issue)
    elif "broken" in names:
        broken.append(issue)
    elif "building" in names:
        building.append(issue)
    elif "blocked" in names or blockers.get(issue["number"]):
        blocked.append(issue)
    else:
        to_build.append(issue)

lines = ["Plan (local view, refreshed from GitHub, do not edit)",
         "Last refreshed: %s" % stamp, ""]

# The question label says why a piece is waiting, so it replaces the generic
# note marker rather than printing beside it.
def state_note(issue):
    text = waiting_on(issue)
    if text:
        return "(%s)" % text
    return "(still a note)" if still_a_note(issue) else ""

def render(heading, group, note):
    if not group:
        return
    lines.append(heading)
    for issue in group:
        who = ", ".join(a["login"] for a in issue.get("assignees", []))
        suffix = " ".join(p for p in (note(issue), state_note(issue)) if p)
        head = "  #%-4s %s" % (issue["number"], issue["title"])
        if who:
            head += "   (%s)" % who
        if suffix:
            head += "   %s" % suffix
        lines.append(head)
        lines.append("       %s" % issue["html_url"])
    lines.append("")

render("Broken", broken, lambda i: "(being fixed)" if "building" in labels(i) else "")
render("Building", building, lambda i: "")
render("Made of parts", parents,
       lambda i: "(%d of %d parts done, build the parts)" % (sub_summary(i)[1], sub_summary(i)[0]))
render("To build", to_build, lambda i: "")
render("Blocked", blocked,
       lambda i: "(needs %s)" % blockers[i["number"]] if blockers.get(i["number"]) else "(waiting)")

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
