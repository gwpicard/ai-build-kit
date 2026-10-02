#!/usr/bin/env sh
# Guard the handoff boundary; subprocess stubs cannot measure model context.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"
HANDOFF="$ROOT/.agents/skills/section-builder/references/task-handoff.md"
rs_init "Task handoff checks"
rs_rule "fresh means no inherited conversation" 'start a new builder without inherited conversation or a prior task.s agent id'
rs_rule "only exposed writable tools qualify" 'confirm the exposed delegation tool can start fresh and permits edits and project commands'
rs_rule "supported reset is evidenced" 'a reset/resume route qualifies only when its exposed contract supports autonomous fresh re-entry from saved records'
rs_rule "unsupported stops resumably" 'leave waiting pieces waiting, record the limit and stop at a resumable boundary'
rs_rule "no false forgetting" 'compaction and an instruction to forget do not establish a fresh context'
rs_rule "current requirements" 'read the current issue body and latest comments before preparing the brief'
rs_rule "exact checked base" 'identify the branch and exact checked baseline commit'
rs_rule "bounded sources" 'pass relevant record pointers and saved artifact paths, never earlier transcripts'
rs_rule "one writer" 'only the coordinator writes authoritative run state, progress and the live page'
rs_rule "bounded authority" 'builders never claim, push, review, open pull requests or merge'
rs_rule "saved lookup" 'later builders read earlier artifacts from those saved sources'
rs_rule "bounded return" 'return a bounded result with commit ids, check commands and exits, flags, unseen cases and evidence or failure paths'
rs_rule "resource ownership" 'record the browser identity, serving computer, owner, server working directory and port'
rs_rule "explicit transfer" 'a transfer requires the previous owner.s release and the new owner.s acknowledgement'
rs_rule "locality still applies" 'ownership never proves browser locality'
rs_rule "interrupted writer" 'a missing report counts as a failed attempt only after the builder is known to have ended'
rs_rule "resume recovery" 'resume through the existing checked-baseline recovery rules before another builder starts'
rs_guard "$HANDOFF" "task-handoff.md"
rs_require_load_bearing "section-builder loads handoff" "$ROOT/.agents/skills/section-builder/SKILL.md" 'load `references/task-handoff\.md`'
rs_require_load_bearing "compatibility owns evidence" "$ROOT/docs/COMPATIBILITY.md" '## task context capabilities'
rs_done
python3 "$ROOT/.agents/tests/fixtures/task-handoff-stubs.py" "$HANDOFF"
