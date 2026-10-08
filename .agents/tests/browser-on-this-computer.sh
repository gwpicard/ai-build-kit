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
rs_guard "$CAPABILITY" "the capability check"

rs_require "the prototype points to the rule" "$PROTOTYPE" 'in a browser on this computer as the `setup-ai-build-kit` skill.s `references/capability-check\.md` says'

rs_done
