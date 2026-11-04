# Jobs and schedules

The queue is pg-boss 12.38.0, pinned in the lockfile. Jobs, schedule cursors and
heartbeats live in the same Postgres database as the records. No database
extension or second queue service is needed.

## Library trial

On 4 November 2026, pg-boss 12.38.0 and Graphile Worker 0.18.0 ran the same
example against disposable Postgres 17.6: a Monday reminder at 09:00 UTC and a
document job with a 700 ms asynchronous generation step. Each handler recorded
its starts and inserted an output with a unique effect key. The trial used
separate queue schemas and the same code to evaluate the weekly occurrence.
It supplied that due occurrence to each queue; it did not wait a week or test
either library's native cron loop. Only pg-boss remains in the starter.

| Check | pg-boss | Graphile Worker |
|---|---|---|
| Restart | Passed: killed the child process after it claimed the document, then reclaimed it after its one-second trial lease expired. | Passed with simulated lock age: killed the child after claim, advanced the abandoned lock timestamps by five hours, then recovered it through a new continuous runner. |
| Retry | Passed: the first attempt threw, the next attempt produced one output. | Passed: the first attempt threw, then the trial made its deferred retry due immediately and ran it again. |
| Concurrent claims | Passed: two simultaneous drains started the document once and produced one output. | Passed: two simultaneous one-shot runners started the document once and produced one output. |
| Timer mode | Passed: explicit maintenance, fetch, execution and completion processed the due reminder and document without a resident worker. | Passed for due work: the one-shot runner processed both jobs. Abandoned-lock recovery required the continuous runner. |

The choice is pg-boss because its manual claim and acknowledgement API lets a
request stop fetching at its deadline, while `supervise()` also recovers
expired claims. Graphile Worker's `runOnce()` drains available work without
running its scheduler or resetting abandoned locks. Its continuous runner
could be stopped for a timer request, but that adds lifecycle work and its
default abandoned-lock interval is four hours. The trial simulated that
interval; it did not measure four hours of elapsed time.

The primary references are pg-boss's [worker API](https://github.com/timgit/pg-boss/blob/12.38.0/docs/api/workers.md)
and [maintenance API](https://github.com/timgit/pg-boss/blob/12.38.0/docs/api/ops.md),
Graphile Worker's [one-shot implementation](https://github.com/graphile/worker/blob/v0.18.0/src/runner.ts)
and [configuration reference](https://worker.graphile.org/docs/config).

## Run it

After database bootstrap and migration, run `npm run build`, then start
`npm run worker` in a second terminal alongside the website. The worker polls
for work, evaluates schedules and refreshes its heartbeat after a successful
burst. SIGTERM and SIGINT stop new claims and abort supported work before
marking that worker stopped. A crash leaves the claim leased for up to 30
seconds, then maintenance retries it. Failed jobs retry up to five times with
exponential backoff. Exhausted jobs remain failed for inspection through the
queue API; processing errors log the queue name and job ID without payloads.

The container uses the same image for both processes. Its default command
starts the website; `node dist/worker.mjs` starts the worker. Give each process
only `DATABASE_URL` and the jobs configuration. SQL migrations and queue
installation run separately as `tool_owner` through `npm run db:migrate`.
Repeat migration is safe. A queue library upgrade needs a migration rehearsal
on a database copy before release.

`src/lib/jobs/schedules.ts` is the schedule list. A schedule's first tick
registers a database cursor at the current database time, so deployment does
not create historic reminders. Each later tick enqueues at most one missed
occurrence per schedule. Cursor movement and enqueue share one transaction
and a row lock, including when worker and timer requests overlap. The cursor
cannot move backwards if the database clock is behind it. After a long
outage, repeated bursts catch up one occurrence at a time. Removing a schedule
from the list stops new occurrences; already queued work still runs. Schedule
times are UTC. The starter deliberately evaluates this list in both runners
instead of enabling pg-boss's resident cron loop.

## Timer configuration

Set `JOBS_MODE=timer` and supply a randomly generated `JOBS_TIMER_TOKEN` of at
least 32 characters through environment configuration. The example file leaves
the token empty. Arrange an HTTPS POST to `/api/jobs/tick` once a minute with
`Authorization: Bearer <token>`. Do not put a real token in a URL, source file
or log. The host's trigger supplies the header; this starter configures no
external trigger.

The route refuses an absent or incorrect token with 401. It returns 503 for
missing timer configuration, and 404 in worker mode. An authorised request
performs maintenance and processes due work for a five-second burst. Each
handler has a two-second deadline; the example document honours cancellation.
Database statements have a one-second timeout and locks a half-second timeout.
The route declares a 15-second host limit, leaving time for acknowledgement
and connection cleanup. Concurrent requests claim different jobs.

Handlers added later must honour cancellation and bound their I/O. Split work
that cannot fit in a burst into durable, idempotent steps, or run it on a
worker with a deliberately changed limit. A time limit cannot interrupt
synchronous code that blocks the event loop. The starter's slow example is a
bounded stand-in for document generation, not a document renderer.

`/api/health` performs a database round trip and checks the configured runner's
heartbeat. It returns 503 before the first successful burst, for a stopped
worker, or after 90 seconds without a worker heartbeat. Timer mode allows 180
seconds between successful calls. A timer heartbeat does not make worker mode
healthy. No database errors or connection details appear in the response.

## Permissions and duplicate effects

Queue SQL uses the existing helper's private pool. Its SQL batch function
preserves all result sets, which pg-boss maintenance needs and Kysely's
Postgres dialect does not return. Ordinary record queries still use the typed
transaction callback. Both paths set a verified identity within the
transaction and roll back on failure.

The fixed system identity in `src/lib/jobs/identity.ts` has the `system` app
role. It can read and insert records owned by that identity, and cannot read
another user's record, update or delete records, or read `withheld` or audit
events. Record changes keep the existing audit trigger and system actor.
Payloads cannot choose an identity. Queue and runtime tables force row-level
security and accept only this fixed identity. They hold operational state,
so the record audit and business-table permission matrix exclude these two
schemas; dedicated tests check their row rules and ordinary-role denial.
The app owns no tables and cannot create queue partitions or run queue DDL.

Both libraries deliver work at least once. A crash can replay a handler after
its effect committed and before queue acknowledgement. Each example uses the
durable job ID as the output record's primary key, with conflict handling in
the same transaction as its audit event. Retries therefore cannot create a
second output. This does not promise exactly-once handler execution or make
external effects such as email idempotent. Such integrations need their own
durable idempotency key or transactional outbox before they send anything.

## Evidence in the starter

`tests/jobs.test.ts` kills a real worker process during a claimed document job
and waits for the real 30-second production lease to expire. It also holds an
output lock to force a database failure, then checks the successful retry and
its retry count. Two worker processes compete for a job, with their claims observed over IPC;
replay after a
committed effect leaves one audit event. Separate tests run the actual weekly
schedule through the worker and through concurrent authorised timer requests,
using a cursor just before the most recent Monday occurrence.

The suite checks missing and wrong tokens, missing configuration, disabled
timer mode, cancellation at a short deadline, fresh and stale heartbeats, a
stopped worker, and a blocked database round trip. A timer request with a full
queue returns within its limit and leaves unfinished jobs durable. Permission
tests show that
the system identity cannot act on a user's records and ordinary roles cannot
read queue or runtime tables. The browser check exercises the health and timer
routes through the production website.
