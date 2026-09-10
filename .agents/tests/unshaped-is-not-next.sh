#!/usr/bin/env sh
# unshaped-is-not-next.sh: guard the rules that keep the maintainer's issue
# review honest.
#
# The read exists to answer one question, which is what to pick up next. The way
# it goes wrong is not by failing loudly. It goes wrong by sounding confident:
# recommending a piece nobody has sized, ranking themes on a priority the
# repository has never written down, or grouping the backlog by the area labels
# instead of by what the issues say, which reproduces the gap it was supposed to
# find. Each of those reads perfectly well and is worth nothing.
#
# So the rules that stop it live as prose in the skill, and this check reads
# them back. It also proves each one is load-bearing by removing it and
# requiring the whole set to fail, because a check that cannot fail proves
# nothing.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

REVIEW="$ROOT/.agents/maintainer-skills/review-issues/SKILL.md"
AGENTS="$ROOT/AGENTS.md"
MAINTAINING="$ROOT/docs/MAINTAINING.md"
VALIDATOR="$ROOT/.agents/tools/validate-kit.sh"

rs_init "Issue review checks"
rs_exists "$REVIEW" "$AGENTS" "$MAINTAINING" "$VALIDATOR"

# The rule the check is named for. A piece nobody has sized cannot be the next
# thing built, however attractive it looks in a themed list.
rs_rule "an unsized piece is never the next thing to build" \
  'never recommend an unshaped piece as the next thing to build'
rs_rule "it can still be the next thing to shape" 'the next thing to shape'
rs_rule "the two readiness signals are both read" 'rather than quietly picking one'

# Themes come from the issues. Reading them off the labels would hand back the
# grouping that is already there, which is the one thing the read cannot be
# useful for.
rs_rule "themes are not read off the area labels" 'do not read them off the'

# The honesty rules. Both failures are silent ones.
rs_rule "an unreachable backlog stops the read" 'if github cannot be reached'
# Observed while trying the skill out: the REST call answered with an empty list
# while thirteen pieces were open, and recovered on the next attempt. An empty
# list is also the honest answer for an empty backlog, so nothing distinguishes
# the two except the other call disagreeing.
rs_rule "a silently empty answer stops it too" 'the two calls must agree'
rs_rule "no invented ranking" 'instead of inventing an order'

# The shape of the answer, and the line it never crosses.
#
# The printout is fixed rather than described, because a described shape gets
# followed loosely. The first read written against a described one grouped the
# backlog correctly and then buried the grouping in paragraphs about it.
rs_rule "the printout has a fixed shape" 'a printout with a fixed shape'
rs_rule "a theme is glossed in one line" 'the line under a theme heading is one line'
# A theme of one is the honest answer for a piece nothing else sits beside.
# Forcing it into the nearest theme is how the grouping stops meaning anything.
rs_rule "a piece no theme fits stands alone" 'where no theme fits a piece'
rs_rule "one thing is recommended" 'worth picking up names one thing'
rs_rule "the closing lists are capped" 'at most three pieces'
# Numbers are the reversal of an earlier rule, so the reason belongs next to it.
# The repository bans an issue number in a tracked file, whose reader cannot
# follow a pointer once the numbering has moved on. This printout is read beside
# the live backlog and the number is what the maintainer types next, so it is
# printed there and still never written down.
rs_rule "a piece is printed as its number" 'a piece appears as its number'
rs_rule "the number still never reaches a file" 'do not write one into a file'
rs_rule "it reports and never acts" 'reports and changes nothing'
rs_guard "$REVIEW" "the review-issues skill"

# The skill has no adapter and no slash command by design, so the only way
# anybody finds it is a document telling them where it is. If that line goes,
# the skill is still on disk and effectively gone.
rs_require_load_bearing "AGENTS.md says where to load it from" \
  "$AGENTS" 'maintainer-skills/review-issues/skill\.md'

# The folder now holds more than the one vendored skill, and the sentence
# saying otherwise was true when it was written.
rs_require_absent "no document still claims the folder holds one skill" \
  "$MAINTAINING" 'it is the only thing there'
rs_require "MAINTAINING.md accounts for both maintainer skills" \
  "$MAINTAINING" 'review-issues'

# Placement is the whole boundary, and the validator checks it by name. A skill
# missing from that list is not guarded at all.
rs_require "the validator guards this skill's placement" \
  "$VALIDATOR" 'review-issues'

rs_done
