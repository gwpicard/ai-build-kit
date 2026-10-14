# Shared part: the Next.js container and its health route

Every recipe that builds with Next.js and hosted Supabase links this part,
whichever host runs the app. The project always carries the same Dockerfile. On
a host that runs containers, it is what runs in production. On a host that
builds the app its own way, the host ignores it, and it still gives a local
check that matches production and a way off that host.

How it works: The Dockerfile builds Next.js with `output: "standalone"` and runs `node server.js` with `HOSTNAME=0.0.0.0` and `PORT=3000`, so the server answers from outside the container. It starts from a Node Alpine image, which carries `wget`, because a host that checks health from inside the container needs `curl` or `wget`. It carries no `HEALTHCHECK` line, since one would override the host's own check. The route at `/api/health` makes one real round trip to the database and answers 200 with `status`, `database`, `commit` and `project`, or 503 when the query fails. It sets `export const dynamic = "force-dynamic"`, so Next.js never answers it from a copy made at build time. Next.js fixes public settings when it builds, so the image is built with the public Supabase address and key as build arguments. The container gets its values from `.env.container`, which git ignores and which holds only names in `.env.example`, never `.env.local`, where other tools keep their own tokens.
How it is checked: With Docker running, the image builds, its container answers 200 with the database reachable, and an image built with the database pointed nowhere answers 503 rather than claiming the tool is up.
Script: scripts/container-check.sh
Who runs it: the kit
