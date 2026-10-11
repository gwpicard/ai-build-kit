#!/usr/bin/env sh
# browser-on-this-computer.sh: guard the rule that the agent looks at a page
# only in a browser on this computer.
#
# A browser tool can list every browser signed in to the same account. In a
# real project the agent opened a page in the only connected browser, which
# was on a colleague's Windows machine, so the page ran on somebody else's
# computer while the agent reported what it saw. Nothing mechanical can hold
# this across harnesses, so the rule lives as prose and this check reads it
# back, and proves each part is load-bearing.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && cd .. && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

CAPABILITY="$ROOT/.agents/skills/setup-ai-build-kit/references/capability-check.md"
PROTOTYPE="$ROOT/.agents/skills/clarify/references/prototype-structure.md"

rs_init "Browser-on-this-computer checks"
rs_exists "$CAPABILITY" "$PROTOTYPE"

rs_rule "only a browser on this computer" 'use only a browser on this computer'
rs_rule "why another computer is wrong" 'a page opened there runs on somebody else.s machine'
rs_rule "choose the one marked local" 'where the tool says which browser is local, choose that one'
rs_rule "a headless browser or say so" 'use a headless browser here, or say that you could not see the page'
# In a real build the agent clicked "Stop listening" and reloaded the tab the
# person was testing in, and an older build's preview stayed running on the
# usual address, so the person tried the old version on it.
rs_rule "a tab of its own" 'open a tab of your own for a check, and never act in a tab the person is using'
rs_guard "$CAPABILITY" "the capability check"

rs_require "the prototype points to the rule" "$PROTOTYPE" 'in a browser on this computer as the `setup-ai-build-kit` skill.s `references/capability-check\.md` says'

BUILDER="$ROOT/.agents/skills/section-builder/SKILL.md"
rs_require_load_bearing "a build gives one address" "$BUILDER" 'give one address to try it on'
rs_require_load_bearing "an earlier preview is stopped first" "$BUILDER" 'before starting a preview, stop any preview this session started earlier, and use the project.s recorded preview address'
rs_require_load_bearing "no second preview on another address" "$BUILDER" 'do not start a second preview on another address'
rs_require_load_bearing "the person's tab is left alone" "$BUILDER" 'never click, type or reload in a browser tab the person is using'
rs_require_load_bearing "previews stop at the end" "$BUILDER" 'stop the previews you started and say so in one line'
rs_require_load_bearing "WORKFLOW tells it" "$ROOT/WORKFLOW.md" 'you get one address to try it on'

rs_done
