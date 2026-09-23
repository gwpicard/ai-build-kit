#!/usr/bin/env sh
# hosting-request.sh: guard the hosting request /ship writes on a first launch.
#
# A tool that runs on a server somebody else runs gets its address from that
# server, and the kit never contacts it. The person carries a short request
# there by hand. The rules that matter most are the ones whose loss would be
# silent: that the request carries names and never a value, that the kit never
# contacts the server, and that a later launch reads the request back rather
# than asking the person again. The skills also stay free of any product name,
# because the kit does not tie its instructions to a tool it does not control.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SHIP="$ROOT/.agents/skills/ship/SKILL.md"
SETUP="$ROOT/.agents/skills/setup-ai-build-kit/SKILL.md"
MASTERPLAN="$ROOT/.agents/skills/setup-ai-build-kit/templates/masterplan.md"
WORKFLOW="$ROOT/WORKFLOW.md"
README="$ROOT/README.md"
SOURCES="$ROOT/docs/SOURCES.md"

rs_init "Hosting request rules"
rs_exists "$SHIP" "$SETUP" "$MASTERPLAN" "$WORKFLOW" "$README" "$SOURCES"

# When it applies.
rs_rule "it applies to a server this session cannot reach" 'where the tool will run on a server this session cannot reach'
rs_rule "the kit never contacts the server" 'the kit never contacts that server'
rs_rule "the person carries it by hand" 'the person carries a short request there by hand'

# The first launch.
rs_rule "it is written into How it stays running" 'on a first launch, read the masterplan.s "how it stays running" section\. when it holds no hosting request, write one there'
rs_rule "it is filled from the project, not by asking" 'filled from the project itself rather than by asking the person'
rs_rule "the repo and branch field" 'repo: +<url>, branch <branch>'
rs_rule "the lane field" 'lane: +internal \(private network\) \| public \(internet\)'
rs_rule "the port field" 'port: +<port the tool listens on>'
rs_rule "the env var field" 'env vars: +<names only>'
rs_rule "the persisted paths field" 'persist: +<paths that must survive a restart, or none>'
rs_rule "the health check field" 'healthcheck: +<path, or none>'
rs_rule "the lane comes from the fit check" 'take the lane from the fit check'
rs_rule "values are entered on the server" 'values are entered on the server'
rs_rule "no secret value is written" 'never write a value, key, password or token into the request'
rs_rule "an unknown field is none, not a guess" 'write `none` rather than guess'
rs_rule "the block is printed for pasting" 'print the same block in the reply, so the person can paste it'
rs_rule "the one line the person hears" 'this tool needs a home\. take this request to whoever runs the server\.'

# The answer. The launch waits for it, and it is recorded whenever it arrives,
# not only in the session that wrote the request. A person often carries the
# request away and comes back days later, in a new session.
rs_rule "the launch waits for an address" 'the first launch is not finished until an address is recorded under the request'
rs_rule "the person hears it is not live yet" 'tell the person plainly that the tool is not live yet and is waiting on the server.s answer'
rs_rule "it is not recorded as live meanwhile" 'do not write it into changelog\.md as live'
rs_rule "an answer is recorded in any session" 'whenever the person pastes an answer, in this session or a later one, record its address and names under the request'
rs_rule "a secret in the answer is left out" 'leave out any secret value it carries'

# A later launch.
rs_rule "a later launch reads it back" 'on a later /ship, read the recorded hosting request back instead of asking again'
rs_rule "a missing answer is noticed" 'where no address is recorded under it, the request went out and no answer came back'
rs_rule "a missing answer is said and the request printed again" 'say so plainly, print the request again for the person to carry, and ask them to paste the answer here when it arrives'
rs_rule "a changed field is updated and printed again" 'where the project has changed a field since, update that line from the project and print the request again'
rs_guard "$SHIP" "ship's hosting request"

# Only the live paths. Explore privately never moves work to a live address, so
# the request must sit after that branch ends and before Build with care begins.
rs_require_order "the request sits after Explore privately" "$SHIP" \
  '^### Build and run it' 'Hosting request$'
rs_require_order "the request sits inside Build and run it" "$SHIP" \
  'Hosting request$' '^### Build with care'

# The skills name no product.
rs_require_absent "ship names no hosting product" "$SHIP" 'coolify'
rs_require_absent "setup names no hosting product" "$SETUP" 'coolify'
rs_require_absent "the masterplan template names no hosting product" "$MASTERPLAN" 'coolify'

rs_require_load_bearing "setup step 11 names the hand-off" "$SETUP" \
  'where a hosting companion or whoever runs the server will host it, /ship writes the hosting request on the first launch'
rs_require_load_bearing "the masterplan template has a place for it" "$MASTERPLAN" \
  '/ship writes a hosting request here on the first launch'
rs_require "the masterplan template keeps it to names" "$MASTERPLAN" 'names only, never a value'
rs_require "WORKFLOW tells the story" "$WORKFLOW" 'so /ship writes a hosting request into the masterplan'
rs_require "WORKFLOW says it holds names only" "$WORKFLOW" 'it holds names only, never a password or key'
rs_require "WORKFLOW says a later launch reads it back" "$WORKFLOW" 'on a later launch /ship reads the request back'
rs_require "the README FAQ answers where it runs" "$README" 'where does the tool run once it is built\?'
rs_require "the README says the companion is a separate install" "$README" 'it is a separate install on the server'
rs_require "SOURCES credits the hosting request" "$SOURCES" 'kasperhonore/coolify-devops'

rs_done
