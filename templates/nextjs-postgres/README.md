# Plain Postgres starter

This starter is under development. It lives outside the skill folders and is
absent from the release allowlist, so it is neither offered at founding nor
included in a public kit. The existing starter and recipes are unchanged.

It keeps the existing TypeScript, Next.js 16, Tailwind, shadcn, Vitest,
Playwright and ESLint base. It needs Node.js 22.23.2, Python 3.9 or later and Docker Compose for the
local database and check cleanup. The root page is a placeholder. The [sign-in module](SIGN-IN.md) supplies
company sign-in and email links for invited outsiders. [Jobs and schedules](JOBS.md)
describes the worker, protected timer route and database and heartbeat health check.

## Try it locally

Copy this folder to an empty working directory, then run:

```sh
npm ci
npm run check
```

For an interactive development session, run:

```sh
cp .env.example .env
sh scripts/docker-run.sh -- sh -c '
  docker compose up -d --wait && npm run db:bootstrap &&
  npm run db:migrate && npm run dev
'
```

The example credentials in `.env.example` are for a disposable local database.
Compose binds it to loopback and keeps its data in memory. Stopping and removing
the container loses its data. Use it only for development and tests.

`db:bootstrap` creates the three local database roles and gives the owner role
ownership of the public schema, so migrations can manage its grants. It refuses remote
connections, production mode and databases other than `tool_test` or
`tool_dev`. It requires all four URLs to point at the same database. Do not
use this script to provision a live database.

`db:migrate` connects as `tool_owner`, applies SQL files in filename order in
one transaction and records their checksums. It serialises concurrent runs
with a transaction advisory lock and rejects changes to an applied file.
Repeat it to check that applying migrations twice is harmless. A live database
needs separately provisioned roles and a rehearsed migration with a backup.
The app receives `DATABASE_URL` and the restricted `AUTH_DATABASE_URL`; keep
the migration and administrator URLs out of its environment. The worker uses the runtime settings listed in
[the handover](hosting/handover.json), including `DATABASE_URL`.

The checks create a disposable Postgres database and two local file servers.
Each run has its own Compose project name, and every container, image built by
a check, volume and network carries the kit's run label. An exit trap removes
those resources after success, failure or interruption. Registry base images
stay cached for later runs. If the computer or Docker stops before cleanup can
finish, `/maintain` can list labelled leftovers older than a day and offer to
remove them. It leaves unlabelled resources alone.

The starter and source workflows use the same disposable database runner.
It chooses a free loopback port and generates test credentials in memory.
These databases are for checks and local development only.

## Database choice

Kysely 0.29.8 is pinned with node-postgres 8.23.1. Kysely's typed query builder
fits the small schema without a runtime model layer. Its
[transaction API](https://kysely-org.github.io/kysely-apidoc/classes/Kysely.html#transaction)
provides the callback used by the database helper. Drizzle can also use SQL
migrations, but its schema-builder API is unnecessary for this slice. Kysely
keeps query types in interfaces while SQL remains the schema authority. This
is a choice for this starter, rather than a claim that one library is better
in general.

All migrations are handwritten SQL in `db/migrations/`. Kysely does not own
the migration format. `src/lib/db/schema.ts` describes query types and must
change with the SQL. Replacing the query builder leaves the database schema,
policies, triggers and migration history intact.

## Query and identity boundary

Every app query uses `withDatabase(identity, async transaction => ...)` from
`src/lib/db/with-database.ts`. Its pool is private. It starts a transaction,
sets `app.user_id` and `app.role` with parameterised `set_config(..., true)`,
runs the callback and commits, or rolls back on error. This is the
[transaction-local equivalent of SET LOCAL](https://www.postgresql.org/docs/17/functions-admin.html#FUNCTIONS-ADMIN-SET).
The initial pool limit is one connection, which also lets the tests prove
identity isolation on reuse and concurrent calls. Size the pool for the tool
when its workload is known. Use the transaction only inside its callback.

ESLint rejects app imports of raw drivers and pool or client modules, including
re-exports, `require` and dynamic imports. It also restricts Kysely runtime
imports to `sql` outside the helper; type-only imports remain available.
Migration scripts and tests live outside the app source and use privileged
connections only for setup or inspection. Lint tests exercise the real ESLint
configuration with deliberately invalid query code.

`sessionIdentity(headers)` from the sign-in module constructs the identity from
an authenticated server session. `/api/identity` passes it to `withDatabase`.
The [sign-in notes](SIGN-IN.md) explain directory restrictions, invitations,
role assignment and the review check. `tests/support/identity.ts` remains a
test-only factory; it throws unless both test mode and Vitest are present, and
app imports of test support fail lint. No request header or production flag
lets a caller choose a user or role.

These settings trust the server application. The helper and lint rule prevent
accidental bypasses; they do not protect against arbitrary SQL execution or
stolen app credentials, which could set their own identity. Authentication and
query review remain part of that boundary.

## Row rules and audit

Postgres's
[default-deny row security](https://www.postgresql.org/docs/17/ddl-rowsecurity.html)
is enabled and forced on every record table, including audit events and the
private migration ledger. `tool_owner` runs migrations and owns the tables.
`tool_app` has no memberships, owns no tables, cannot create roles or databases,
and has `NOBYPASSRLS`. Its SQL grants exclude schema changes, temporary table
creation and truncation.

The example `records` table lets members read and change their own records,
viewers read their own records, and administrators read and change all
records. An unassigned role has no access. The fixed jobs system identity has narrower
permissions described in [Jobs and schedules](JOBS.md#permissions-and-duplicate-effects). `withheld` demonstrates denial when
a table has SQL grants but no policy. Tests check that its seeded rows remain
invisible to every app role.

Triggers on the business tables write inserts, updates and deletes to
`audit.events`, with actor, before and after values, and a timestamp. The
function has a fixed search path and runs as the owner, which has only an
insert policy on the forced audit table. The app has only an administrator
read policy and a SELECT grant there. Tests prove it cannot forge, update or
delete events, and that a rollback removes both a change and its audit event.
A privileged database administrator or table owner can change these controls;
the audit table is append-only for the app role.

## Permission evidence

`tests/role-matrix.ts` is the single list of expected access. The generated
suite tries reading and each change for every role, table and ownership scope.
Positive cases make a removed permission visible; negative cases check row
isolation and denied writes. Schema inspection requires every business table to
appear in the matrix, every record table to force row rules, and every
business table to have the audit trigger. The separate sign-in suite checks
authentication tables and invitation permissions.

`npm run test:policy-fault` removes the `records_read` policy on the disposable
local database and runs the generated member read test. That test must fail.
The script restores the saved policy in `finally`; run `npm test` afterwards
to check the restored database. Keep the database disposable: a terminated
process cannot run its restoration code. If interrupted, start a fresh local
database and apply its migrations again.


## Private files

`src/lib/files/index.ts` exports `files()`, the server's permission-checked file
port. Its five actions are `save(identity, title, bytes)`, `fetch(identity, id)`,
`temporaryLink(identity, id)`, `delete(identity, id)` and `list(identity)`.
`save` returns the new file record; `fetch` returns bytes; `list` returns only
records the caller may read in the configured store. These operations need the
same verified server identity as database queries. Server code obtains that identity from `sessionIdentity(headers)`. The starter
has no file HTTP route.

The `files` table forces row-level security. Members manage their own files,
viewers read their own files, administrators manage all files, and unassigned
users and the jobs system identity have no access. Every
metadata change writes an audit event. The app can update a title, but cannot
change a file's ID, owner or storage location. Object keys come from generated
IDs rather than filenames. Metadata includes a hash of the storage location,
so switching stores cannot issue links for records from the previous store.
Moving files between stores needs a separate migration.

App code imports the file port, never a storage SDK or adapter. ESLint rejects
SDK imports, re-exports, CommonJS and dynamic imports outside the two exact
adapter files. It also rejects app imports of the adapters, except from the
file port. Administration scripts and tests remain outside this app boundary;
the local fixture script creates private test storage.

Choose storage through environment variables. `FILES_ADAPTER` defaults to `s3`;
`FILES_LINK_SECONDS` defaults to 60 and accepts whole seconds from 1 to 300.
Configuration is validated when `files()` is created, before any operation.
HTTPS is required except for loopback emulators outside production.

| Adapter | Configuration |
| --- | --- |
| S3 | `FILES_S3_BUCKET`, `FILES_S3_REGION`; optional `FILES_S3_ENDPOINT` and `FILES_S3_FORCE_PATH_STYLE=true` for compatible stores. Use workload credentials through the SDK credential chain, or supply static `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and optional `AWS_SESSION_TOKEN` through the environment. |
| Azure Blob | `FILES_AZURE_ACCOUNT`, `FILES_AZURE_ACCOUNT_KEY`, `FILES_AZURE_CONTAINER`; optional `FILES_AZURE_ENDPOINT`, otherwise the account's standard HTTPS Blob endpoint. |

The host must supply a private bucket or container and credentials restricted
to the tool's storage. This module creates no hosted storage and grants no
public access. Keep anonymous reads and listing disabled, including through
bucket policies, account settings, gateways and CDNs. The local tests prove
these settings for the emulators; they do not verify a hosted store's access.
The Azure SDK is pinned to 12.29.1, whose Blob API version matches Azurite
3.35.0. The AWS SDK and request presigner are pinned to 3.1161.0. The Azure
adapter uses an account key to sign blob-scoped, read-only SAS links,
following the [service SAS API](https://learn.microsoft.com/en-us/azure/storage/blobs/sas-service-create-javascript).
The S3 adapter uses the SDK's
[request presigner](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/Package/-aws-sdk-s3-request-presigner/).

Only a successful row-rule read can issue a temporary link. Links allow anyone
holding them to read that one file until expiry, including after a role change;
do not log, persist or share them. Downloads use attachment disposition and
`Cache-Control: no-store`. Expiry prevents a new request after the deadline;
it cannot retract bytes already downloaded or interrupt an accepted download.

Postgres and object storage do not share a transaction. A failed upload rolls
back its metadata, and a failed object deletion rolls back the metadata
deletion. A process crash, partial upload or failed database commit can leave
an orphaned object or a metadata record whose object is missing. Orphans stay
private; recovery needs a reconciliation of metadata and objects using separate
administration credentials. `save` buffers bytes in memory. Set upload size
limits at the eventual HTTP route for the tool's workload.

Run `npm run test:files` with Docker available. It creates a separate disposable
Postgres database, RustFS 1.0.4 (an S3-compatible server) and Azurite 3.35.0 on
random loopback ports. It generates test credentials in memory and removes its
own containers afterwards. No `.env` or existing service is used. The same
suite exercises all five adapter actions against both servers, follows listing
pages, denies unsigned GET, HEAD and listing requests, and proves expiry with
real HTTP requests. It checks link and byte access for every role and owner
scope, denied writes, immutable storage locations and a removed read policy.
The ordinary `npm test` suite also covers file row rules, configuration and the
ESLint boundary. `npm run check` includes both suites, so CI runs the container
tests as part of the starter check.

The shared storage suite also claims a queued file job, reads its input through
`files()` and writes one audited result through `withDatabase()`. Its handler
receives an identity from a real sign-in session separately from the payload. It proves that
the queue's fixed system identity and another user cannot read that file, while
the owner can process it and replay the result without a second audit event.
Changing that user to viewer or unassigned changes the next attempt's file and
record permissions, even when the payload claims administrator access.
The example worker and timer retain their existing record-only handlers; a
project that adds file processing must choose its verified identity and row
policies explicitly. Queue access grants no access to user files.

`npm run test:privilege-fault` plants excessive grants on records, files, the
queue and runtime tables, a writable file ownership column, a public trigger
grant, a privileged queue function, schema creation and owner membership. Sign-in
table and column grants are checked for both database roles across all schemas;
authentication tables have a separate exact catalogue. Each
must fail its named catalogue assertion. The script restores each fault in
`finally` and runs the boundary suite before and after the faults. Like the
policy check, it requires a disposable local database.

## Runtime handover

[hosting/handover.json](hosting/handover.json) describes the template today.
The [canonical schema](../../hosting/handover.schema.json) owns its fields and
the requests to AI Host Kit. It ships separately in the kit release; copy it
to `hosting/handover.schema.json` when copying this template to a standalone
project. The project check reads that copy, or the canonical file when run
inside this repository. AI Host Kit vendors the published file unchanged.

The `config` list is the names-only list of secrets and settings.
`src/lib/config.ts` is their typed home. The project check compares the lists
in both directions, checks storage and schedule declarations, and requires
the migration step. It rejects environment reads elsewhere in app code.
Local bootstrap and test tools have separate inputs, including the local
administrator URL, which never belongs in a deployed app environment.

The image accepts `web`, `worker` and `migrate`. Run migration before sending
traffic to a new version, using only the migration URL. Web and worker start
with the app URL, files and SMTP configuration; configuration is validated
before either starts. The web process listens on `0.0.0.0` and the declared
port. App events are JSON on standard output. Framework diagnostics retain
severity only, because their text can contain request data.

`sendMail` in `src/lib/mail.ts` sends plain-text mail through SMTP. The host
supplies the sender and credentials. Production requires encrypted SMTP and
refuses a missing credential pair. Loopback SMTP without authentication is
allowed only outside production. Delivery tests use a local SMTP server;
they do not prove delivery to an external mailbox or domain configuration.

`npm run hosting:render` generates the masterplan's hosting section from the
file. `npm run handover:check` fails on a hand edit or code mismatch.
`npm run test:handover` plants these mismatches and checks all three founding
sign-in choices. The founding script exposes the questions with `--questions`
and records an answer file with `--answers`. The current founding menu still
does not offer this template. Company sign-in adds Microsoft or Google staff to invited email users;
email-only sign-in uses `STAFF_PROVIDER=none`. A company choice requires an
existing outside-account test reference. AI Host Kit supplies the selected
`STAFF_PROVIDER`, directory registration and secret files declared in the
handover. Its callback must use the HTTPS origin in `AUTH_BASE_URL`.
The example recovery targets are placeholders for the founding conversation.

`npm run test:image` builds one image, runs each role against a fresh local
database and checks health before, during and after the worker runs. It also
checks database failure and JSON output, then removes its containers and image.
The database and website receive Docker-assigned loopback ports.
Dependency advisory findings and their runtime reach are recorded in
[Dependency audit](DEPENDENCIES.md).
