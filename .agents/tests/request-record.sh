#!/usr/bin/env sh
# request-record.sh: guard the record that lets a live fault be traced.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SHIP="$ROOT/.agents/skills/ship/SKILL.md"
FIX="$ROOT/.agents/skills/fix/SKILL.md"
FOUNDATION="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "Request-record rules"
rs_exists "$SHIP" "$FIX" "$FOUNDATION" "$WORKFLOW"

rs_rule "checks the record before live use" 'before any first live use.*check that the tool records what each request did'
rs_rule "keeps one line per event" 'one line per event'
rs_rule "links one request by its run id" 'with a run id shared by that request.s events'
rs_rule "records when and which step" 'a time, a level and the step'
rs_rule "uses disposable inputs" 'check this with disposable inputs'
rs_rule "applies the project data rules" 'apply agents\.md.s secrets and confidential files rules to the record'
rs_rule "excludes personal data and confidential contents" 'it must contain no personal data, keys, passwords, tokens or confidential file contents'
rs_rule "does not print forbidden contents during checking" 'never print those contents while checking it'
rs_rule "keeps field names out of the report" 'keep the field names out of the person.s report'
rs_rule "names one piece when the record is absent or unusable" 'if the record is absent or cannot trace a request, name or reuse one piece before go-live and say once'
rs_rule "keeps the missing-record line" 'the tool does not yet keep a record of what each request did, so a report cannot be traced\. that is one piece, before it goes live'
rs_rule "waits for the piece or an explicit choice" 'leave launch waiting until that piece is built or the person explicitly chooses to go live without the record'
rs_rule "records what the person chose to leave out" 'record that choice in changelog\.md, with the date and what remains untraceable'
rs_rule "does not invent a sensitive area for an ordinary gap" 'do not add a sensitive area or an `accepted:` line for this operational gap'
rs_rule "does not waive forbidden data" 'accepting a missing record never waives the data exclusions'
rs_rule "gives the caution once unless a recipient is named" 'give the monitoring caution once, unless the fit check already names an alert recipient'
rs_rule "keeps the monitoring caution" 'once real people use this, the only record of what went wrong will be the record the tool writes\. if you want somebody to be told when it breaks, that is a service somebody runs and pays for, and the kit does not set one up'
rs_rule "remembers that the caution was given" 'record that the caution was given in changelog\.md'
rs_rule "does not repeat the caution across areas or visits" 'for another area, or on a later /ship visit'
# A replay gave the caution in all three replies of one visit, and listed
# "someone to receive alerts" as a piece, because the readiness list above
# required a recipient while this caution treated one as optional.
rs_rule "does not repeat the caution within one visit" 'do not repeat it in a later reply of the same visit'
rs_rule "nobody to alert is never a piece" 'it is never a piece on the readiness list'
rs_rule "treats an alert recipient as satisfying the caution" 'a named alert recipient satisfies this caution'
rs_rule "sets up no service dashboard or alerting" 'do not set up a hosted service, dashboard or alerting as part of this check'
rs_rule "care areas use the same request-record rules" 'operational readiness check \(including the request record and monitoring rules above, without repeating their notices\)'
rs_rule "ordinary care work uses the live readiness step" 'outside every named area, follow the same four steps as build and run it above'
rs_guard "$SHIP" "ship's live readiness rules"
rs_require_absent "the readiness list does not require an alert recipient" "$SHIP" 'actually applies: a named alert recipient'

rs_reset
rs_rule "reads the tool record only after launch on live paths" 'after launch on build and run it or build with care, read the tool.s own request record alongside the person.s report as a source for the reproduction'
rs_rule "uses the record to find a repeatable case" 'use it to find the failed step and the smallest repeatable case'
rs_rule "reports missing evidence and uses other sources" 'if the record is absent or cannot be reached, say what evidence is missing and continue with the other sources below'
rs_rule "never asks the person to read logs" 'never ask the person to read logs'
rs_rule "keeps data rules during repairs" 'the project.s secrets and confidential files rules still apply to anything read or reported'
rs_guard "$FIX" "fix's request-record read"

rs_require "foundation excludes keys passwords and tokens" "$FOUNDATION" 'keys, passwords, and tokens.*never print, commit, or copy'
rs_require "foundation excludes confidential contents" "$FOUNDATION" 'never stage, commit, print, or copy their contents'
rs_require_load_bearing "WORKFLOW names both live paths" "$WORKFLOW" 'on both live paths, /ship checks that the tool keeps a plain record of what each request did'
rs_require_load_bearing "WORKFLOW leaves exploration alone" "$WORKFLOW" 'explore privately gets neither check nor caution'
rs_require_load_bearing "WORKFLOW explains the repair read" "$WORKFLOW" '/fix also reads the tool.s own record of what each request did alongside your report'
rs_require_order "record check starts inside the live path" "$SHIP" '^### Build and run it$' 'Check that the tool records'
rs_require_order "monitoring caution stays inside the live path" "$SHIP" 'Give the monitoring caution once' '^### Build with care$'

if [ -z "${RS_LIST:-}" ]; then
  awk '/^### Explore privately$/ {show=1; next} /^### Build and run it$/ {show=0} show' "$SHIP" > "$rs_dir/private"
  rs_require_absent "private exploration has no request-record check" "$rs_dir/private" 'request record|one line per event|monitoring caution'
fi

rs_done
