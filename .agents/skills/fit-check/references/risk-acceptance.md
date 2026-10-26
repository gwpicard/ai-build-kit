# Recording a risk choice

The person carries on by instructing you to do the flagged work after hearing
the full notice. "Go ahead", "build it anyway", "try it again" and "it is on
me, build it" count. Do not ask for clearer approval or reject a reply because it
does not repeat the risk back.

Silence, a question, "I am not sure", a change of subject, or a reply that does
not ask for the flagged work is not acceptance. Neither is an instruction given
before the notice: give the full notice, then wait for the person to carry on.
An instruction about work outside the named area does not accept the risk for
that area. If no notice was due, there is nothing to accept or record.

During `/shape`, record acceptance only in the piece's `## Decided` section:
the date, the person's words and the named risk area or unchecked fact.
Read it back and finish shaping; building waits for `/implement`.

During `/implement`, run `records/scripts/piece-labels.sh start` before changing
files. Copy any named-risk-area acceptance from the piece into the masterplan's
`Accepted:` line, keeping the original date and words; do not ask again.
An unchecked fact alone needs no masterplan acceptance.

Before flagged work starts, add an `Accepted:` line to the masterplan's
risk record. Include the date and the person's own words after hearing
who is exposed. Change the area's own line to `accepted` with the date. Read
the risk record back; do not start until the acceptance appears there.
An acceptance recorded after the work starts is too late.

Do this in the reply that answers the person carrying on: write the line and
read it back, using only the piece during `/shape`. During `/implement`,
continue the build. Do not end that reply with a second permission
question, such as asking whether they are sure or want to wait for the caution.
A question about scope is still valid if its answer changes what gets built.

Acceptance covers only the risk and area named in that notice. It does not
settle another area's caution. If the plan has a lock whose only purpose is to
wait for this caution, remove that lock in the same reply and say so; during
`/shape`, propose its removal on the piece. Keep it only if the person asks.
The named person has still not looked, so the record
must say `accepted`, never `done`. The launch report also says which caution
did not happen.

Do not infer acceptance from a reply that does not request the work. The notice
remains in force until the person carries on after hearing it.

Once the acceptance is in the masterplan, that caution no longer holds the piece back:
the project check reports the area in one line and passes.
