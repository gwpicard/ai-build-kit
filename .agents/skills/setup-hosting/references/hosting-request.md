# The hosting request

For a tool on a server this session cannot reach, on no recipe or on one whose
own request file does not cover it. The request lives in the masterplan's
"How it stays running" section. The person carries it to whoever runs the
server, and carries the answer back.

## Writing it

Fill it from the project, not by asking the person:

```
Hosting request
Repo:               <url with no sign-in in it>
Repo (build):       <url with no sign-in in it>
Branch (build):     main
Lane (runtime):     internal (private network) | public (internet)
Port (runtime):     <port the tool listens on>
Env vars:           <all names, or none>
Build vars (build): <names the build needs, or none>
Run vars (runtime): <names needed only while the tool runs, or none>
Persist (runtime): <paths that must survive a restart, or none>
Healthcheck (runtime): <path, or none>
Health-check tool (runtime): <tool used to read the healthcheck, or none>
Build (build):     Dockerfile at root, image has curl or wget | lock file or requirements.txt, plus a Procfile | neither yet
Bind (runtime):    0.0.0.0 | reads HOST and PORT | 127.0.0.1 (not hostable yet)
```

Take the lane from the fit check: internal unless somebody outside the team
signs in or relies on it. Build vars and Run vars name which values the build
needs and which it only needs while running. Read Build from the files at the
root and Bind from the address the server listens on. A tool bound to 127.0.0.1 cannot be
reached from outside its container: say so once, and record it. Never write a
value, key, password or token. Where the project does not say, write `none`.

Print the block in the reply and say once: "This tool needs a home. Take this
request to whoever runs the server. Paste what they send back here, and I will
record it for the next /setup-hosting."

## The answer, and a later run

Record the answer's address and names under the request, with no secret
value. The first launch is not finished until an address is recorded. A later
run reads the request back: with no address under it, say no answer came back
and print it again; where a field has changed, update it and print it again.
