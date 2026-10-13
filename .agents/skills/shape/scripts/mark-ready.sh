#!/usr/bin/env sh
# mark-ready.sh: mark a piece ready, but only once its shape says it is.
#
# Usage: sh mark-ready.sh <issue number>
#
# A piece is ready when it has a "Done when" section with something in it and
# waits on no question. A piece that carried a needs- label has had its
# question settled only when a "Decided" section says what settled it. The
# label is the only sign the question was ever open, so it never comes off
# before that record exists.
#
# The script reads the issue, refuses when either section is missing or empty,
# and otherwise takes every needs- label off and puts ready on in one change.
# It then reads the labels back, so a piece never carries ready and a needs-
# label together. Last, it refreshes the project's printout of pieces, so the
# person's list shows the piece as ready.
#
# Exit 0: the piece is ready, read back.
# Exit 1: refused; the line printed names the missing section. Nothing changed.
# Exit 2: usage error, or GitHub could not be read or changed.

set -u

[ "$#" -eq 1 ] || { echo "usage: mark-ready.sh <issue number>" >&2; exit 2; }
number=${1#\#}
case "$number" in ''|*[!0-9]*) echo "usage: mark-ready.sh <issue number>" >&2; exit 2 ;; esac

command -v gh >/dev/null 2>&1 || { echo "mark-ready: the GitHub command line tool is not installed" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "mark-ready: python3 is needed to read the issue" >&2; exit 2; }

read_issue() {
  gh issue view "$number" --json body,labels
}

issue=$(read_issue) || { echo "mark-ready: could not read issue $number" >&2; exit 2; }

# Prints "ok <needs-labels...>" or "missing <section>".
verdict=$(printf '%s' "$issue" | python3 -c '
import json, re, sys
data = json.load(sys.stdin)
body = data.get("body") or ""
labels = [l["name"] if isinstance(l, dict) else l for l in data.get("labels") or []]

def section(name):
    lines = body.splitlines()
    for i, line in enumerate(lines):
        if re.fullmatch(r"#{2,3}\s+%s\s*" % re.escape(name), line.strip(), re.I):
            text = []
            for rest in lines[i + 1:]:
                if re.match(r"#{1,3}\s", rest.strip()):
                    break
                text.append(rest)
            content = re.sub(r"<!--.*?-->", "", "\n".join(text), flags=re.S).strip()
            return content not in ("", "_No response_")
    return False

needs = [l for l in labels if l.startswith("needs-")]
if not section("Done when"):
    print("missing Done when")
elif needs and not section("Decided"):
    print("missing Decided")
else:
    print(" ".join(["ok"] + needs))
') || { echo "mark-ready: could not read issue $number" >&2; exit 2; }

case "$verdict" in
  "missing Done when")
    echo "not ready: issue $number has no Done when section, so it has not been sized"
    exit 1 ;;
  "missing Decided")
    echo "not ready: issue $number waits on a question, and its Decided section does not say what settled it"
    exit 1 ;;
esac

set -- --add-label ready
for label in ${verdict#ok}; do
  set -- "$@" --remove-label "$label"
done
gh issue edit "$number" "$@" >/dev/null || { echo "mark-ready: GitHub refused the label change on issue $number" >&2; exit 2; }

labels=$(read_issue | python3 -c '
import json, sys
data = json.load(sys.stdin)
print(" ".join(l["name"] if isinstance(l, dict) else l for l in data.get("labels") or []))
') || { echo "mark-ready: could not read issue $number back" >&2; exit 2; }

case " $labels " in
  *" ready "*) ;;
  *) echo "mark-ready: issue $number does not carry ready after the change" >&2; exit 2 ;;
esac
case " $labels " in
  *" needs-"*) echo "mark-ready: issue $number still carries a needs- label after the change" >&2; exit 2 ;;
esac
echo "ready: issue $number"
top=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if [ -f "$top/.agents/tools/plan-refresh.sh" ]; then
  (cd "$top" && sh .agents/tools/plan-refresh.sh >/dev/null 2>&1) \
    || echo "mark-ready: the printout was not refreshed; run sh .agents/tools/plan-refresh.sh" >&2
fi
exit 0
