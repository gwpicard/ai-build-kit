# The hosting request

On this recipe the tool runs on a server this session never reaches, so a first
launch writes a short request the person carries to whoever runs the server,
and the address comes back with the answer. The request lives in the
masterplan's "How it stays running" section.

## Writing it

`scripts/hosting-request.sh --lane <internal|public>` prints the request,
filled from the project rather than by asking the person. Take the lane from
the masterplan's `Access:` line: internal for private. If intended users cannot
join the private network, explain that private access is unavailable on this
recipe for them and ask for another access choice or recipe. Record that
decision before continuing. Open address with invitation only, and public,
take the public lane with no network gate. Copy the block it prints into the
masterplan and put it in the reply, followed by the script's last line, so the
person can paste it. `Env vars` lists runtime names that are not build names.
`Build vars` lists the names the build needs; those names are set at build time
and are not repeated under `Env vars`. The request defaults `Previews` to `no`.
If the person wants them, write `Previews: yes, second Supabase project <ref>,
Basic Authentication in front`. Only a line starting with `yes` turns previews
on. The companion creates each `Env vars` and `Build vars` name again for the
second project, scoped to previews, and reports Basic Authentication as a step
for the person. The address block's `Preview:` line records whether Basic
Authentication is confirmed: `basic auth: set by hand, confirmed` or
`basic auth: set by hand, not yet confirmed`. The request names settings and
never carries a value, key, password or token.

Exit 1 means the tool cannot be hosted yet, such as a server that listens only
on 127.0.0.1. Say so once, record it, and leave the request out until the
project is fixed.

## Recording the answer

Whenever the person pastes an answer, in this session or a later one, record
its address and names under the request, keep the companion's complete address
block, and leave out any secret value it carries. Record `Deploys on merge:`
from that block. The first launch is not finished until an address is recorded
there.

## A later /setup-hosting

Read the recorded request back instead of asking again. Where no address is
recorded under it, the request went out and no answer came back: say so
plainly, print it again for the person to carry, and ask them to paste the
answer here when it arrives. Run the script again, and where a line differs
from the recorded one, record the new block and print it for the person to
carry.
