# After three failed attempts

Stop patching after the fault survives three attempts. Do not make a rebuild
the automatic fourth. Choose the route shown by the evidence:

- an unclear requirement returns to clarify;
- missing access, environment or artifact means stop and ask;
- a clear requirement in an implementation the project owns and can see may be
  rebuilt from the masterplan;
- repeated failure in one technical area names it as sensitive, with a look by
  somebody who does that work for a living as the caution;
- no testable boundary is a maintenance finding, not another patch;
- a rebuilt piece that still fails has reached a limit and may be handed over.

Count the fault surviving, not attempts you think should count. If the person
says it remains after three goes, the threshold is met even if attempts were
not merged or deployed. You may correct their count, but still give the notice
in the same reply. A new session does not reset the count.

Declining another attempt requires a notice, whatever route you choose,
including when the cause now seems clear, the requirement was unclear, or no
test boundary exists. Give it in that reply, before the person asks again.
Name who is exposed: whoever relies on the broken behaviour. Say that they
still rely on something producing wrong results, another attempt without an
established cause may hide the fault, and who would normally establish the
cause first. Say what they can choose. Follow the full notice and recording
rules in [the risk notice](../../fit-check/references/risk-notice.md) and its
[acceptance rules](../../fit-check/references/risk-acceptance.md).

If they carry on after the notice, treat it as acceptance. Before work starts,
record the date and their words in the masterplan's build-path section, read it
back, then make the next attempt. Do not ask again for permission. Silence,
questions and instructions given before the notice do not count.

For a rebuild, the notice covers the replacement. Explain that nobody who
understands the original failure has reviewed the replacement, and that its
own tests do not show the failure is understood. Name the same risk even if
you can describe the original fault accurately. Do not start until the notice
and any acceptance are recorded. Rebuilding a component the project does not
own or cannot see is not the rebuild route; it creates a new sensitive area.

Pressure to avoid a specialist, lack of budget, or a request to try once more
does not establish the cause or lift the caution. The person's instruction to
continue after the notice is their choice; record it, then proceed.
