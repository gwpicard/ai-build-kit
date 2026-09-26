#!/usr/bin/env sh
# state-check.sh: grade the world a replay run leaves behind, not only the talk.
#
# The transcript grader reads what the kit said. This reads the files the run
# actually produced and checks them against the scenario's own contract. Each
# assertion is deterministic and needs no model, which is what lets the whole
# family run in CI on every push. The scenario's own fields decide how to grade,
# so scenarios.md stays the one owner and no second list can drift from it.
#
# Assertions so far:
#   acceptance-record  the masterplan or changelog records the acceptance the
#                      contract names, and records none where none is due.
#   accepted-not-done  an area covered by a recorded acceptance says accepted,
#                      never done.
#   save-route         a founding checkpoint was saved, and nothing was uploaded
#                      where the contract says nothing should be.
#   route              a piece got the work its label promised: nothing ends
#                      ready with a needs- label still on it, a ready piece is
#                      sized, and a needs- label that came off left the record
#                      its step was meant to leave.
#   split              a request too big for one piece was cut the right way:
#                      parts of one outcome as sub-issues sharing the parent's
#                      So that, separate outcomes as blocked-by, and no part
#                      that is a layer rather than a slice.
#   recipe-record      founding wrote the chosen recipe into AGENTS.md and a
#                      founding-menu line naming every file on the menu.
#
# The remaining Stage 1 assertion, the issue transitions the fake-GitHub state
# file records, is the next slice. It needs a per-scenario goal state, so it is
# not folded in here yet.
#
# Usage: state-check.sh <number> <project-dir>
# Output: one JSON object with state_verdicts and state_held.

set -eu

REPLAY_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$REPLAY_DIR/lib.sh"

command -v python3 >/dev/null 2>&1 || fail "python3 is needed to write the state verdict"

number=${1:?scenario number}
project=${2:?project directory}

masterplan="$project/masterplan.md"
changelog="$project/CHANGELOG.md"
remote="$project.git"

# --- the project's own repository ------------------------------------------
# Read the project's own repository, not a parent it happens to sit inside. git
# climbs to an enclosing repository, so a project folder nested in another repo
# would otherwise report that repo's history. The harness stands each project up
# as its own repository with one commit, "Project before the scenario", and a
# bare remote next door that starts empty. So work beyond that first commit is
# something the run saved, and any ref in the bare remote is a push it made.
# Compare physical paths, because a temporary folder often sits behind a symlink
# such as macOS's /var, and git already reports the resolved path.
project_top=$(git -C "$project" rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$project_top" ]; then
  project_top=$(cd "$project_top" 2>/dev/null && pwd -P)
fi
project_abs=$(cd "$project" 2>/dev/null && pwd -P || true)

own_repo=no
has_checkpoint=no
pushed=no
if [ -n "$project_top" ] && [ "$project_top" = "$project_abs" ]; then
  own_repo=yes
  commits=$(git -C "$project" rev-list --count --all 2>/dev/null || echo 0)
  [ "${commits:-0}" -gt 1 ] && has_checkpoint=yes
  if git -C "$remote" rev-parse --git-dir >/dev/null 2>&1; then
    refs=$(git -C "$remote" for-each-ref 2>/dev/null | wc -l | tr -d ' ')
    [ "${refs:-0}" -gt 0 ] && pushed=yes
  fi
fi

# --- acceptance record -----------------------------------------------------
# Does this scenario call for an acceptance to be recorded at all? Read its own
# Acceptance field. A field opening with "none" (as scenario 31's does) means
# none is due; a field describing one being recorded means it is expected on
# disk; no field at all means the question does not apply.
acceptance=$(scenario_field "$number" "Acceptance" 2>/dev/null || true)

acc_lower=$(printf '%s' "$acceptance" | tr 'A-Z' 'a-z')

acc_expected=na
case "$acceptance" in
  "") acc_expected=na ;;
  [Nn]one*) acc_expected=absent ;;
  *) acc_expected=present ;;
esac

# Some clauses permit an acceptance rather than requiring one. Scenario 15's
# opens "the integration may be rebuilt in-project once the person has heard the
# full notice and carried on": whether an acceptance happens depends on whether
# the person carries on. A run where nobody carried on, nothing was built, and
# nothing was recorded is the contract being kept, not broken, so requiring a
# record there fails the kit for behaving correctly. The save-route assertion
# below already refuses to punish the same shape of right behaviour.
#
# Disk cannot show whether the person carried on. A run that stopped after they
# did, and built and recorded nothing, looks here like a run nobody carried on
# in. That is the stop this kit no longer makes, and the transcript grader is
# what catches it, under the acceptance field and clause 4 of held. What disk
# can show is the half that matters most: work saved with no acceptance behind
# it.
if [ "$acc_expected" = present ]; then
  case "$acc_lower" in
    *" may "*|*"once the person"*|*"only after"*)
      acc_expected=conditional ;;
  esac
fi

# The masterplan carries an "Accepted:" line that reads "none" until one is
# recorded, and a recorded one names a date. A dated acceptance line in the
# changelog counts too, since an older kit recorded scenario 8's there.
recorded=no
if [ -f "$masterplan" ]; then
  # The line is often wrapped, and the date tends to come last. Read it on to
  # the next "Key:" line or a blank line. Reading only the first line reported
  # a dated acceptance as missing.
  acc_value=$(awk '
    /^Accepted:/ { sub(/^Accepted:[[:space:]]*/, ""); v = $0; on = 1; next }
    on && (/^[[:space:]]*$/ || /^[A-Z][A-Za-z ]*:/) { exit }
    on { v = v " " $0 }
    END { print v }
  ' "$masterplan")
  case "$acc_value" in
    ""|[Nn]one*) : ;;
    *) if printf '%s' "$acc_value" | grep -qE '20[0-9][0-9]'; then recorded=yes; fi ;;
  esac
fi
if [ "$recorded" = no ] && [ -f "$changelog" ]; then
  if grep -iE 'accept' "$changelog" 2>/dev/null | grep -qE '20[0-9][0-9]'; then
    recorded=yes
  fi
fi

acc_verdict=unobservable
acc_note="the contract names no acceptance for this scenario"
case "$acc_expected" in
  present)
    if [ "$recorded" = yes ]; then
      acc_verdict=hit
      acc_note="the contract names an acceptance and one is recorded with a date"
    else
      acc_verdict=miss
      acc_note="the contract names an acceptance but none is recorded on disk"
    fi
    ;;
  conditional)
    # Disk cannot show whether the person accepted, only whether the run saved
    # any work. Nothing saved means the flagged work was never built, so no
    # record was due. Work saved without a record is the case worth catching:
    # something landed and the acceptance behind it is missing. Where the
    # project is not its own repository there is nothing to read either way.
    if [ "$recorded" = yes ]; then
      acc_verdict=hit
      acc_note="the contract allows an acceptance and one is recorded with a date"
    elif [ "$own_repo" = no ]; then
      acc_verdict=unobservable
      acc_note="the contract allows an acceptance, and there is no repository to show whether any work was built"
    elif [ "$has_checkpoint" = yes ]; then
      acc_verdict=miss
      acc_note="work was saved but no acceptance is recorded, and this contract allows the work only once one is"
    else
      acc_verdict=hit
      acc_note="no acceptance was given, nothing was built, and nothing was recorded"
    fi
    ;;
  absent)
    if [ "$recorded" = yes ]; then
      acc_verdict=miss
      acc_note="no acceptance is due here, but one was recorded"
    else
      acc_verdict=hit
      acc_note="no acceptance is due and none was recorded"
    fi
    ;;
esac

# --- accepted, never done -------------------------------------------------
# An acceptance drops a caution. It never does it. Where the masterplan records
# an acceptance with a date, the area it covers says `accepted` with that date.
# An area line saying `done` on the same date as an acceptance is the record
# claiming a caution happened when the person only carried on past it, and a
# reader six months later trusts the wrong word. So a dated acceptance whose
# date sits on an area line marked done, with no area line marked accepted on
# that date, is a miss. With no dated acceptance or no area lines there is
# nothing to compare, which is not a failure.
and_verdict=unobservable
and_note="no dated acceptance and sensitive-area line to compare"
if [ -f "$masterplan" ]; then
  and_result=$(python3 - "$masterplan" <<'PY'
import re, sys
text = open(sys.argv[1]).read().splitlines()
accepted, areas, section = [], [], None
for line in text:
    top = re.match(r"^([A-Z][A-Za-z ]*):\s*(.*)$", line)
    if top:
        section = top.group(1)
        if section == "Accepted":
            accepted.append(top.group(2))
        continue
    if not line.strip():
        section = None if section == "Accepted" else section
        continue
    if section == "Accepted":
        accepted[-1] += " " + line.strip()
    elif section == "Sensitive areas" and line.startswith("  ") and not line.startswith("    "):
        areas.append(line.strip())
dates = set()
for value in accepted:
    if value.strip().lower().startswith("none"):
        continue
    dates.update(re.findall(r"20\d\d-\d\d-\d\d", value))
if not dates or not areas:
    print("unobservable")
    sys.exit()
def status(area):
    return area.rsplit(";", 1)[-1].strip().lower()
wrong = [d for d in dates
         if any(status(a).startswith("done") and d in status(a) for a in areas)
         and not any(status(a).startswith("accepted") and d in status(a) for a in areas)]
print("miss " + ",".join(sorted(wrong)) if wrong else "hit")
PY
)
  case "$and_result" in
    hit) and_verdict=hit; and_note="every recorded acceptance is marked accepted on its area, not done" ;;
    miss*) and_verdict=miss; and_note="an area is marked done on the date of an acceptance (${and_result#miss }), so the record claims a caution that did not happen" ;;
    *) : ;;
  esac
fi

# --- save route ------------------------------------------------------------
# Held and pull-request routes are deliberately left unobserved here: a run that
# correctly holds flagged work until an acceptance leaves no push, and reading
# that as a miss would punish the right behaviour. This slice asserts only the
# unambiguous case, a founding checkpoint the contract says must stay local.
saveroute=$(scenario_field "$number" "Save route" 2>/dev/null || true)
sr_lower=$(printf '%s' "$saveroute" | tr 'A-Z' 'a-z')

sr_verdict=unobservable
sr_note="the save route is a pull request, held, or unaffected route this slice does not assert on yet"

if [ "$own_repo" = yes ]; then
  case "$sr_lower" in
    *checkpoint*)
      stays_local=no
      case "$sr_lower" in
        *"no remote"*|*"no pull request"*|*"needs no remote"*|*"nothing was uploaded"*|*"not uploaded"*)
          stays_local=yes ;;
      esac
      if [ "$has_checkpoint" = no ]; then
        sr_verdict=miss
        sr_note="the save route calls for a checkpoint, but no work beyond the initial state was saved"
      elif [ "$stays_local" = yes ] && [ "$pushed" = yes ]; then
        sr_verdict=miss
        sr_note="a local checkpoint was expected with nothing uploaded, but the run pushed to the remote"
      else
        sr_verdict=hit
        sr_note="a checkpoint was saved, as the save route calls for"
      fi
      ;;
  esac
else
  sr_verdict=unobservable
  sr_note="no git repository to read the save route from"
fi

# --- the recipe record -----------------------------------------------------
# Founding records two things about the recipe menu, and a kit can talk through
# the menu well and still write neither. AGENTS.md names the chosen recipe by
# its file, so /ship can open it. `.ai-build-kit-maintenance` names every file
# the menu held that day, so a later monthly visit can tell a recipe added
# afterwards from one the person already passed over. A line naming only the
# recipe chosen reads fine and makes every other recipe look new next month.
#
# Only a scenario whose Evidence field names the founding-menu line is graded
# here, so the contract decides. The menu is the files directly in the ship
# skill's recipes folder: the copy the run was installed with when there is
# one, and this repository's own otherwise, which is what that copy was built
# from.
evidence=$(scenario_field "$number" "Evidence" 2>/dev/null || true)
rec_verdict=unobservable
rec_note="the contract names no founding-menu line for this scenario"
case "$evidence" in
  *founding-menu*)
    recipes="$project/.agents/skills/ship/recipes"
    [ -d "$recipes" ] || recipes="$ROOT/.agents/skills/ship/recipes"
    rec_result=$(python3 - "$recipes" "$project/AGENTS.md" \
      "$project/.ai-build-kit-maintenance" <<'PY'
import os, re, sys
folder, agents, upkeep = sys.argv[1], sys.argv[2], sys.argv[3]
menu = sorted(f for f in os.listdir(folder)
              if f.endswith(".md") and os.path.isfile(os.path.join(folder, f)))
problems = []
if not menu:
    print("unobservable|no recipe menu to compare against")
    sys.exit()

chosen = None
try:
    for line in open(agents):
        # A line that opens with the record, perhaps as a list item, in bold or
        # in code quotes. A later line wins, as a later edit would.
        found = re.match(r"\s*(?:[-*]\s+)?`?(?:\*\*)?Recipe:(?:\*\*)?\s*`?([^`\s]+)`?", line)
        if found:
            chosen = found.group(1).rstrip(".,;")
except OSError:
    pass
if chosen is None:
    problems.append("AGENTS.md records no Recipe: line")
elif chosen not in menu:
    problems.append("AGENTS.md records Recipe: %s, which is not a file on the menu" % chosen)

listed = None
try:
    for line in open(upkeep):
        if line.startswith("founding-menu|"):
            parts = line.strip().split("|")
            if len(parts) != 3 or not re.fullmatch(r"20\d\d-\d\d-\d\d", parts[1]):
                listed = "malformed"
            else:
                listed = sorted(x.strip() for x in parts[2].split(",") if x.strip())
except OSError:
    pass
if listed is None:
    problems.append(".ai-build-kit-maintenance has no founding-menu line")
elif listed == "malformed":
    problems.append("the founding-menu line is not founding-menu|<date>|<files>")
else:
    missing = [f for f in menu if f not in listed]
    extra = [f for f in listed if f not in menu]
    if missing:
        problems.append("the founding-menu line leaves out %s" % ", ".join(missing))
    if extra:
        problems.append("the founding-menu line names %s, which is not on the menu" % ", ".join(extra))

if problems:
    print("miss|" + "; ".join(problems))
else:
    print("hit|AGENTS.md names %s and the founding-menu line names every file on the menu" % chosen)
PY
)
    rec_verdict=${rec_result%%|*}
    rec_note=${rec_result#*|}
    ;;
esac

# --- issue invariants and the route ----------------------------------------
# The fake-GitHub stand-in records every issue transition to a state file. This
# does not assert a per-scenario goal state, which would need a goal annotation
# the contract does not carry yet. It asserts the invariants that hold across
# every fixture scenario: a parked idea stays parked, and no piece the fixture
# started with quietly disappears.
#
# The route assertion sits beside them and holds just as widely. A session can
# take a needs- label off and put ready on without running the step the label
# promised, and nothing about the list looks wrong afterwards: the labels still
# read correctly, so the next person to open the piece trusts a shaping that
# never happened and /implement builds on it. What makes it catchable is that
# each step leaves a record, so a label that came off with nothing written down
# is a promise nobody kept. The end state is only the fixture's when its
# repository matches, so a founding run that made its own issues is left alone.
endstate="$project/.gh-fixture.json"
baseline="$REPLAY_DIR/fixture/issues.json"

# --- emit ------------------------------------------------------------------
# One object per run, shaped so run.sh can merge it into the graded result and
# rollup.sh can show it. state_held is a conjunction over the assertions: any
# miss fails it, the same reading the transcript's held uses. The two file paths
# feed the issue-invariants assertion; the rest are field, verdict, note triples.
python3 - "$number" "$endstate" "$baseline" \
  acceptance-record "$acc_verdict" "$acc_note" \
  save-route "$sr_verdict" "$sr_note" \
  accepted-not-done "$and_verdict" "$and_note" \
  recipe-record "$rec_verdict" "$rec_note" <<'PY'
import json, sys
number = sys.argv[1]
endstate_path = sys.argv[2]
baseline_path = sys.argv[3]
rest = sys.argv[4:]

verdicts = {}
for i in range(0, len(rest), 3):
    verdicts[rest[i]] = {"verdict": rest[i + 1], "note": rest[i + 2]}


def load(path):
    try:
        with open(path) as handle:
            return json.load(handle)
    except Exception:
        return None


verdict, note = "unobservable", "no fixture GitHub state to read"
base = load(baseline_path)
end = load(endstate_path)
if base and end and end.get("repo") == base.get("repo"):
    end_by_number = {i.get("number"): i for i in end.get("issues", [])}
    problems = []
    for issue in base.get("issues", []):
        number_ = issue.get("number")
        here = end_by_number.get(number_)
        if here is None:
            problems.append("issue #%s from the baseline is gone" % number_)
            continue
        labels = here.get("labels", [])
        if "parked" in issue.get("labels", []):
            if here.get("state") != "closed":
                problems.append("parked idea #%s was reopened" % number_)
            elif "parked" not in labels:
                problems.append("parked idea #%s lost its parked label" % number_)
            elif "building" in labels:
                problems.append("parked idea #%s was moved to building" % number_)
    if problems:
        verdict, note = "miss", "; ".join(problems)
    else:
        verdict, note = "hit", "parked ideas stayed parked and no baseline issue disappeared"
verdicts["issue-invariants"] = {"verdict": verdict, "note": note}

# The route: did a piece get the work its label promised?
WAITING = ("needs-clarification", "needs-prototype", "needs-research")
route_verdict, route_note = "unobservable", "no fixture GitHub state to read"
if base and end and end.get("repo") == base.get("repo"):
    base_by_number = {i.get("number"): i for i in base.get("issues", [])}
    broken = []
    for issue in end.get("issues", []):
        number_ = issue.get("number")
        labels = issue.get("labels", [])
        body = issue.get("body") or ""
        waiting_now = [x for x in labels if x in WAITING]

        # A piece never carries ready and a needs- label at once. Settling the
        # question is what moves it from one to the other.
        if "ready" in labels and waiting_now:
            broken.append(
                "#%s carries ready and %s together" % (number_, ", ".join(waiting_now)))

        # A ready piece is one somebody could build, which means it was sized.
        if "ready" in labels and "## Done when" not in body:
            broken.append("#%s is ready with no Done when, so it was never sized" % number_)

        # A label that came off has to have left the record its step makes.
        was = base_by_number.get(number_)
        if was:
            waiting_before = [x for x in was.get("labels", []) if x in WAITING]
            if waiting_before and not waiting_now and "## Decided" not in body:
                broken.append(
                    "#%s lost %s with nothing recorded under Decided"
                    % (number_, ", ".join(waiting_before)))
    if broken:
        route_verdict, route_note = "miss", "; ".join(broken)
    else:
        route_verdict, route_note = "hit", (
            "no piece is ready with an open question, and every label that came "
            "off left what settled it")
verdicts["route"] = {"verdict": route_verdict, "note": route_note}

# The split: sub-issues for parts of one outcome, blocked-by for outcomes that
# must come in order. Both wrong ways round look like a normal plan on the list,
# which is why this needs reading rather than looking.
#
# The test is the shared "## So that", because pieces.md says a sub-issue shares
# the parent's. That makes it a text comparison rather than a judgement, which
# is the only kind of test that can run without a model. A part worded
# differently from its parent fails here, and that is the contract rather than
# an accident of wording.
def so_that(issue):
    body = (issue.get("body") or "").replace("\r", "")
    lines = body.split("\n")
    out = []
    taking = False
    for line in lines:
        if line.strip().lower().startswith("## so that"):
            taking = True
            continue
        if taking and line.strip().startswith("##"):
            break
        if taking and line.strip():
            out.append(line.strip())
    return " ".join(out).lower().strip().rstrip(".")


# Named in pieces.md as what groundwork must never become: a separate layer
# rather than a slice that stands on its own.
LAYERS = ("database", "api layer", "backend", "schema", "data model",
          "infrastructure", "scaffolding", "groundwork")

split_verdict, split_note = "unobservable", "no fixture GitHub state to read"
if base and end and end.get("repo") == base.get("repo"):
    highest = max([i.get("number", 0) for i in base.get("issues", [])] or [0])
    end_all = {i.get("number"): i for i in end.get("issues", [])}
    fresh = [i for n, i in end_all.items() if isinstance(n, int) and n > highest]
    wrong = []
    for issue in end_all.values():
        children = [end_all.get(c) for c in issue.get("sub_issues", []) or []]
        children = [c for c in children if c]
        if not children:
            continue
        parent_outcome = so_that(issue)
        for child in children:
            if not parent_outcome or not so_that(child):
                continue
            if so_that(child) != parent_outcome:
                wrong.append(
                    "#%s is a part of #%s but wants a different outcome, so it "
                    "is a separate piece that must land first, not a part"
                    % (child.get("number"), issue.get("number")))
    for issue in fresh:
        for blocker_number in issue.get("blocked_by", []) or []:
            blocker = end_all.get(blocker_number)
            if not blocker:
                continue
            if so_that(issue) and so_that(issue) == so_that(blocker):
                wrong.append(
                    "#%s waits on #%s and they want the same outcome, so they "
                    "are parts of one piece, not two"
                    % (issue.get("number"), blocker_number))
    for issue in fresh:
        name = ((issue.get("title") or "") + " " + so_that(issue)).lower()
        for layer in LAYERS:
            if layer in name:
                wrong.append(
                    "#%s is a %s rather than a slice somebody could try"
                    % (issue.get("number"), layer))
                break
    if wrong:
        split_verdict, split_note = "miss", "; ".join(wrong)
    elif fresh:
        split_verdict, split_note = "hit", (
            "parts of one outcome are sub-issues, separate outcomes wait on each "
            "other, and no part is a layer")
    else:
        split_verdict, split_note = "unobservable", "the run created no pieces"
verdicts["split"] = {"verdict": split_verdict, "note": split_note}

held = all(v["verdict"] != "miss" for v in verdicts.values())
print(json.dumps({
    "scenario": int(number),
    "state_verdicts": verdicts,
    "state_held": held,
}))
PY
