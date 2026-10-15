# The hosting request

For a tool on a server this session cannot reach, on no recipe or on one whose
own request file does not cover it. The request lives in the masterplan's
"How it stays running" section. The person carries it to whoever runs the
server, and carries the answer back.

## Writing it

Fill it from the project, not by asking the person:

```
Hosting request
Repo:               <url with no sign-in in it>, branch <branch>
Lane:               internal (private network) | public (internet)
Port:               <port the tool listens on>
Env vars:           <runtime names that are not build names, or none>
Build vars:         <names the build needs, also set at build time, or none>
Persist:            <paths that must survive a restart, or none>
Healthcheck:        <path, or none>
Build:              Dockerfile at root, image has curl or wget | lock file or requirements.txt, plus a Procfile | neither yet
Bind:               0.0.0.0 | reads HOST and PORT | 127.0.0.1 (not hostable yet)
Previews:           no | yes, <what the preview needs>
```

Take the lane from the fit check: internal unless somebody outside the team
signs in or relies on it. `Env vars` lists runtime names other than build
names. `Build vars` lists names the build needs; those names are not repeated
under `Env vars`, and the companion creates each at build time and runtime.
Read Build from the files at the root and Bind
from the address the server listens on. A tool bound to 127.0.0.1 cannot be
reached from outside its container: say so once, and record it. Previews are
`no` by default. If the person wants previews, copy the exact wording from the
recipe, including what the preview needs. Only a line starting with `yes`
turns previews on. Follow the recipe for preview-scoped settings and access
protection, and record any requested confirmation in the address block's
`Preview:` line. Never write a value, key, password or token. Where the project
does not say, write `none`.

Print the block in the reply and say once: "This tool needs a home. Take this
request to whoever runs the server. Paste what they send back here, and I will
record it for the next /setup-hosting."

## The answer, and a later run

Record the answer's address and names under the request, with no secret
value. Keep the companion's complete address block with the answer, including
`Deploys on merge: yes` or `Deploys on merge: no (after each merge, the server
operator runs /host "redeploy <name>", or presses Redeploy on the application
in <host service>; <why>)`.
After a merge, that line says whether the host deploys by itself. When it says
no, `/host "redeploy <name>"` or the host's Redeploy button puts the merge live.
The first launch is not finished until an address is recorded. A later run
reads the request back: with no address under it, say no answer came back and
print it again; where a field has changed, update it and print it again.
