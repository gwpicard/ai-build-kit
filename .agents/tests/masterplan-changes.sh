#!/usr/bin/env sh
# masterplan-changes.sh: guard the record that a finished piece leaves on the
# masterplan. A missing change or a mark advanced past unread work can make a
# stale page look current, so each rule must fail when removed.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

RECORD="$ROOT/.agents/skills/setup-ai-build-kit/references/masterplan-changes.md"
PIECES="$ROOT/.agents/skills/setup-ai-build-kit/references/pieces.md"
FORM="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/piece-issue.yml"
TEMPLATE="$ROOT/.agents/skills/setup-ai-build-kit/templates/masterplan.md"
SHAPE="$ROOT/.agents/skills/shape/SKILL.md"
BUILDER="$ROOT/.agents/skills/section-builder/SKILL.md"
SYNC="$ROOT/.agents/skills/maintain/references/truing.md"
MAINTAIN="$ROOT/.agents/skills/maintain/SKILL.md"
COVERAGE="$ROOT/.agents/skills/setup-ai-build-kit/references/coverage-read.md"

rs_init "Masterplan change checks"

rs_rule "every build path carries the record" 'these rules apply on every build path'
rs_rule "save applies the recorded change to checked behaviour" 'at save time, read the piece.*apply it to the named section, checking it against the behaviour that was actually built'
rs_rule "nothing leaves the page alone" 'a value of "nothing" leaves the prose alone'
rs_rule "a blocked capability is never described as live" 'a safely blocked capability stays described as waiting'
rs_rule "recovery reads landed pieces including closed ones" 'pieces whose work landed, including closed pieces'
rs_rule "recovery applies only the missing change" 'apply only what is still missing'
rs_rule "later changes take precedence" 'follow landing order and the current tool'
rs_rule "repeating recovery cannot duplicate or restore removed behaviour" 'repeating the truing must not add the same line twice or restore something deliberately removed'
rs_rule "a missing old field is not nothing" 'recover its change from that work rather than treating absence as "nothing"'
rs_rule "the mark records the checked code state" 'one `trued against: <full commit hash>` line beside the masterplan'
rs_rule "the person never maintains the mark" 'never ask the person to understand or maintain it'
rs_rule "the mark never skips unread changes" 'never move it past work that has not been checked'
rs_rule "dirty work cannot advance the mark" 'or past uncommitted work that the truing must leave alone'
rs_rule "building saves the checked code before its mark, where it can be used" 'saves the checked code, then, where the mark could be used, writes that saved commit into the mark'
rs_rule "record save stays on the piece's route" 'both commits belong to the same piece and pull request'
rs_rule "the truing marks the saved state it reconciled" 'the truing uses the current saved commit it has just reconciled'
rs_rule "the mark cannot contain its own future hash" 'neither tries to write the hash of the commit that will contain the mark'
rs_rule "every visit reads the gap before the mark moves" 'every /maintain visit reads this first, in its truing, before anything moves the mark'
rs_rule "drift reads the shared branch" 'read the mark on the current shared branch'
rs_rule "merged work counts once" 'count each change once along the first-parent history'
rs_rule "saving the mark cannot create drift" 'leave records-only commits out'
rs_rule "unmerged work does not count as landed" 'do not include unmerged work'
rs_rule "the count follows code subjects, including moved paths" 'data, permissions or connections sections\. follow renamed paths'
rs_rule "the map is optional on other paths" 'do not require one on the other build paths'
rs_rule "several files do not multiply one subject change" 'count a change once for each subject it touched'
rs_rule "non-zero subject counts earn one line and the check" 'when any subject count is non-zero, give one line with the total and the affected subjects, then say in that same line that the truing now checks the page'
rs_rule "zero subject counts stay quiet" 'stay quiet when all three counts are zero'
rs_rule "missing history cannot become a guessed count" 'available history is incomplete, do not invent a count or reset the mark'
rs_rule "an unusable mark means checking the whole page" 'compare the whole page with the code instead'
rs_rule "the count never marks work as checked" 'the count reports the gap; it never moves the mark itself'
rs_rule "only the truing moves the mark" 'only the truing moves it, once it has checked the page'
# A build that met a masterplan with no usable mark compared nothing and wrote
# "not yet checked", while the rules told it to compare the whole page first.
# The whole page is /maintain's, so a build now says so and carries on, and
# whether the mark can be used is read by a shipped script, not judged.
rs_rule "a shipped script says whether the mark can be used" 'whether the mark can be used is a fact, and the `setup-ai-build-kit` skill.s `scripts/trued-mark\.sh` reads it'
rs_rule "its exit code says why not" 'exit 0 prints the commit the mark names, and any other exit says why it cannot be used'
rs_rule "only the truing compares the whole page" 'where the mark is absent or unusable, only the truing compares the whole page against the code and sets a starting point'
rs_rule "the truing reads the mark with the same script" 'read the mark with `scripts/trued-mark\.sh`, as a build does, so the two agree'
rs_rule "a squash merge would strand the mark" 'a squash merge would leave the marked commit outside `main`.s history'
rs_rule "a build leaves the mark, says so once, and carries on" 'a build leaves the mark as it is, says in one line that /maintain checks the whole masterplan against the code, and carries on with its save'
rs_guard "$RECORD" "the masterplan change rules"

rs_reset
rs_rule "the field is always plain and on the surface" '`## masterplan change` is always on the surface, in plain words'
rs_rule "a piece names what the page gains, changes or loses" 'name the section and what it gains, changes or loses when this piece lands'
rs_rule "most pieces may say nothing" 'most pieces say "nothing"'
rs_rule "writing the change does not apply it early" 'writing it does not apply it early'
# A replayed piece that sorted a list wrote "nothing", because the masterplan
# already promised the list. The rule never reached the page, and nothing
# downstream could notice, since save applies the field exactly as written.
rs_rule "nothing is tested line by line against the page" 'read each line of `## done when` against the masterplan alone, and write "nothing" only when the masterplan already says it'
rs_rule "a narrower checkable rule is still a change" 'is a change even when it narrows a promise the masterplan already makes'
rs_guard "$PIECES" "the piece shape"

rs_reset
rs_rule "the issue form carries the field" 'id: masterplan-change'
rs_rule "the form asks for plain words and allows nothing" 'in plain words, name the section and what it gains, changes or loses when this lands\. write "nothing"'
rs_rule "the form requires the field" 'placeholder: what it does gains a weekly summary email\. validations: required: true'
rs_guard "$FORM" "the issue form"

rs_require_load_bearing "a new page starts honestly unchecked" "$TEMPLATE" 'trued against: not yet checked'
rs_require_load_bearing "shape writes the field before ready" "$SHAPE" 'write `## masterplan change` on the surface before marking it ready'
rs_require_load_bearing "shape reads the change back in plain words" "$SHAPE" 'when this lands, the masterplan gains a weekly summary email'
rs_require_load_bearing "shape writes nothing only after the test" "$SHAPE" 'write "nothing" only when the masterplan already says every line of `## done when`'
rs_require_load_bearing "shape reads the change back where the piece is reported" "$SHAPE" 'read it back in the reply that reports the piece'
rs_require_load_bearing "the issue form says a new rule is a change" "$FORM" 'a new rule, such as a sort order, is a change'
rs_require_load_bearing "WORKFLOW says a checkable rule is a change" "$ROOT/WORKFLOW.md" 'a new rule you could check, such as a list now sorted by name, counts as a change'
rs_require_load_bearing "building applies it before saving on every route" "$BUILDER" 'before saving on any route, apply the piece'
rs_require_load_bearing "building updates the mark using its owner" "$BUILDER" 'update the trued-against mark as the `setup-ai-build-kit` skill.s `references/masterplan-changes\.md` describes'
rs_require_load_bearing "building reads the mark with the script and leaves the page to /maintain" "$BUILDER" 'read the mark with the `setup-ai-build-kit` skill.s `scripts/trued-mark\.sh`; where it exits other than 0, leave the mark as it is, say in one line that /maintain checks the whole masterplan against the code, and carry on'
rs_require_load_bearing "the merge keeps the marked commit" "$BUILDER" '`gh pr merge --merge`, which keeps the piece.s commits, so the masterplan.s trued-against mark still names a commit on `main`'
rs_require_load_bearing "WORKFLOW says a build leaves the first check to /maintain" "$ROOT/WORKFLOW.md" 'where the masterplan.s last check against the code cannot be found, /implement says in one line that /maintain does that check, and carries on'
rs_require_load_bearing "the truing recovers unapplied changes and moves the mark" "$SYNC" 'merge each landed piece.*that has not yet been applied, and move the trued-against mark'
rs_require_load_bearing "a current changelog cannot hide an older mark" "$SYNC" 'read from the older of that mark and the last changelog entry'
rs_require_load_bearing "the truing reads the count rules before the mark moves" "$SYNC" 'read the gap first, as its "read the gap at each visit" says, before anything moves the mark'
rs_require_load_bearing "the monthly part does not read the gap a second time" "$MAINTAIN" 'the masterplan.s gap since its trued-against mark was already read in the truing, on every visit'
rs_require_load_bearing "coverage reads the recorded change" "$COVERAGE" 'read each piece.*masterplan change.*alongside its promised result'
rs_require_load_bearing "coverage does not turn unapplied work into a new piece" "$COVERAGE" 'it must not be offered as a new piece'
rs_require_load_bearing "WORKFLOW explains what the person sees" "$ROOT/WORKFLOW.md" 'each piece says what it changes in the masterplan'
rs_require_load_bearing "WORKFLOW explains the count each visit gives" "$ROOT/WORKFLOW.md" 'each visit uses the last such point to say how much work has since touched'

# --- the script that reads the mark -----------------------------------------
# Run in throwaway repositories, one for each answer it can give.
if [ -z "${RS_LIST:-}" ]; then
  MARK="$ROOT/.agents/skills/setup-ai-build-kit/scripts/trued-mark.sh"
  rs_exists "$MARK"
  repo="$rs_dir/repo"
  git init -q "$repo"
  git -C "$repo" config user.email rehearsal@example.com
  git -C "$repo" config user.name Rehearsal
  git -C "$repo" config commit.gpgsign false
  printf '# Masterplan\n\nTrued against: not yet checked\n' > "$repo/masterplan.md"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m first
  first=$(git -C "$repo" rev-parse HEAD)
  mark_is() {
    # mark_is <expected exit> <description> <mark line or "none">
    if [ "$3" = none ]; then
      printf '# Masterplan\n' > "$repo/masterplan.md"
    else
      printf '# Masterplan\n\n%s\n' "$3" > "$repo/masterplan.md"
    fi
    set +e
    out=$(cd "$repo" && sh "$MARK")
    got=$?
    set -e
    [ "$got" -eq "$1" ] || rs_fail "$2: exited $got, not $1 ($out)"
    rs_ok "$2"
  }
  mark_is 0 "a mark naming a commit in this branch is usable" "Trued against: $first"
  [ "$out" = "usable: $first" ] || rs_fail "a usable mark does not print its commit: $out"
  rs_ok "and the commit is printed for the build to move it on from"
  mark_is 1 "a page never checked is not usable" "Trued against: not yet checked"
  mark_is 1 "a page with no mark is not usable" none
  mark_is 1 "an empty mark is not usable" "Trued against:"
  mark_is 1 "a short hash is not usable" "Trued against: $(printf '%s' "$first" | cut -c1-12)"
  mark_is 1 "a hash naming no commit is not usable" "Trued against: 0123456789abcdef0123456789abcdef01234567"
  mark_is 1 "two marks are not usable" "Trued against: $first
Trued against: $first"
  git -C "$repo" checkout -q -b elsewhere
  git -C "$repo" commit -q --allow-empty -m "off to one side"
  aside=$(git -C "$repo" rev-parse HEAD)
  git -C "$repo" checkout -q -
  mark_is 1 "a commit outside this branch is not usable" "Trued against: $aside"
  git -C "$repo" commit -q --allow-empty -m second
  mark_is 0 "an older commit in this branch is still usable" "Trued against: $first"
  shallow="$rs_dir/shallow"
  git clone -q --depth 1 "file://$repo" "$shallow" 2>/dev/null
  printf '# Masterplan\n\nTrued against: %s\n' "$(git -C "$shallow" rev-parse HEAD)" > "$shallow/masterplan.md"
  set +e
  out=$(cd "$shallow" && sh "$MARK")
  got=$?
  set -e
  [ "$got" -eq 1 ] || rs_fail "a mark in incomplete history was called usable: $out"
  rs_ok "a mark in incomplete history is not usable"
  before=$(cd "$repo" && git status --porcelain && cat masterplan.md)
  (cd "$repo" && sh "$MARK" >/dev/null 2>&1) || true
  [ "$(cd "$repo" && git status --porcelain && cat masterplan.md)" = "$before" ] ||
    rs_fail "the script changed something in the project"
  rs_ok "the script changes nothing in the project"
fi

rs_done
