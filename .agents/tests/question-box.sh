#!/usr/bin/env sh
# Guard interview routing without claiming to exercise a vendor's question UI.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"
CLARIFY="$ROOT/.agents/skills/clarify/SKILL.md"
rs_init "Question-box routing checks"
rs_exists "$CLARIFY"
rs_rule "one question at a time" 'one question at a time'
rs_rule "short question" 'one short sentence'
rs_rule "background stays short" 'background is at most two short sentences'
rs_rule "guess is labelled" 'label the best guess as a guess'
rs_rule "choices put the guess first" 'put the guess first'
rs_rule "open answers stay open" 'with the answer left open'
rs_rule "role is evidence" 'read the supplied session role and the exposed tool contract'
rs_rule "a terminal is insufficient" 'a terminal alone does not prove a person is present'
rs_rule "workers take precedence over a local tool" 'a worker uses the coordinator route even if a local question tool is exposed'
rs_rule "present person receives supported tool" 'use the actual exposed question tool when its supported schema can reach the present person'
rs_rule "free text survives" 'preserve free-text answers'
rs_rule "schema sets cardinality" 'follow the actual tool cardinality'
rs_rule "free text only is supported" 'if the tool supports free text without choices, use that'
rs_rule "no invented options" 'never invent choices to satisfy a minimum option count'
rs_rule "unavailable or unsuitable tool falls back" 'if no supported question tool is available, or its schema cannot express this question, ask in concise plain words'
rs_rule "same fallback question and guess" 'keep the same question and clearly labelled guess in the fallback'
rs_rule "empty submission supplies no answer" 'an empty submission, cancellation or preselected option never submitted is no answer'
rs_rule "answers and consent never fabricated" 'never invent a human answer or consent'
rs_rule "workers relay through supported channel" 'send the exact question and labelled guess to the coordinator through its supported channel'
rs_rule "only a returned answer settles the question" 'delivery alone is not an answer'
rs_rule "unavailable relay records and parks owning piece" 'if the relay is unavailable, leave the exact question and guess on the owning piece and park that piece'
rs_rule "independent work may continue" 'continue independent eligible work'
rs_rule "workers never open invisible UI" 'never open a human question ui in an unattended worker'
rs_rule "headless interlocutor receives text" 'a headless replay with a scripted plain-text interlocutor uses the plain-words route'
rs_rule "replay gates still see the question" 'leave the question in the reply text so the scripted turn gate can see it'
rs_rule "founding non-gates preserved" 'this routing does not turn a founding non-gate into a required answer'
rs_rule "acceptance is still earned" 'earned-acceptance rules still apply'
rs_guard "$CLARIFY" "clarify interview routing"
rs_done
