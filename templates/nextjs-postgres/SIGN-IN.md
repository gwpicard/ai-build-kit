# Sign-in module notes

`src/lib/sign-in/` owns sign-in. Better Auth 1.7.16 is pinned in the package
manifest and lockfile. App code imports only its `index.ts` entry point, which
exposes the HTTP handler, `sessionIdentity(headers)` and
`inviteOutsider(headers, email, expiresAt)`. ESLint rejects Better Auth imports
and access to module internals elsewhere, including re-exports and dynamic
imports. Tests may exercise the internals.

The root page remains a placeholder. The HTTP routes are ready for a project's
sign-in screen: POST `/api/auth/sign-in/social` with a `provider` of
`microsoft` or `google` and a local `callbackURL`, or POST
`/api/auth/sign-in/magic-link` with an `email`. Both accept JSON from the same
origin. Follow the social response's `url` in the browser. Sign out with POST
`/api/auth/sign-out`. `/api/identity` shows the verified session's user and role
after passing them through the database helper. It returns 401 without a
session. There is no endpoint that accepts a user ID or role from the caller.

## Directory restrictions

Choose one staff directory per tool. The module uses OpenID Connect (OIDC),
the standard protocol through which the directory proves who signed in.
Better Auth handles the authorisation code, state, nonce and PKCE checks.
PKCE binds the code exchange to the browser flow that started it. The module
also verifies the ID token's signature, audience, issuer and expiry using
`jose` 6.2.15 and the directory's public signing keys. It requires a subject,
email and issued-at claim. These checks run on returning sign-ins too.

Microsoft requires an exact company tenant UUID and its corresponding issuer.
A different or missing `tid` claim is refused. When the token includes `idp`,
that claim must identify the configured issuer or the company's own STS URI.
This also refuses guests whose home provider belongs to another tenant,
including personal Microsoft accounts. An absent `idp` uses the verified issuer,
as Microsoft documents. There is no
`common`, `organisations` or `consumers` authority. See Microsoft's
[ID-token claims](https://learn.microsoft.com/en-us/entra/identity-platform/id-token-claims-reference).

Google sends the configured domain in the `hd` request parameter and requires
the verified token's `hd` claim to match it exactly, with a verified email.
An email suffix is never the access check. Google's
[OIDC documentation](https://developers.google.com/identity/openid-connect/openid-connect)
explains why the request parameter alone does not restrict access.

New directory users receive `member`. Their later sign-ins preserve the role
stored in the database. Sessions accept only `admin`, `member`, `viewer` and
`unassigned`; `system` belongs to the fixed jobs identity. Account linking is off, including automatic linking by
email. Changing directories or resolving an existing email collision requires
an explicit account migration. Staff roles are assigned by a trusted
administrator through the project's administration process; this template has
no public role editor. The first administrator must be assigned through that
process, using a verified staff user's ID.

## Invitations and sessions

An administrator session can call `inviteOutsider` from server code. It writes
an expiring invitation under row-level security and the existing audit trigger.
Only administrators can read or change invitations through the app database
role. The authentication role can read them but cannot create them.

An email-link request checks the invitation and creates a viewer account only
for an invited address. Better Auth's public email sign-up is disabled. A
staff account cannot use the email-link route. Links expire after ten minutes;
only a hash of each link token is stored, and verification consumes it
atomically. The tests race two requests for the same link. An expired or
revoked invitation prevents new sessions and denies access through existing
sessions. Revoking an invitation is an administrator update to its `revoked`
field. A project may add an administration screen using the same database
helper and policy.

Cookies are Secure, HTTP-only and SameSite=Lax. HTTPS is required, including
for local browser sign-in. Sessions have an eight-hour absolute lifetime with
no automatic renewal and no cookie cache. Sign-out deletes the session on the
server, so replaying its cookie fails. Sign-out ends the tool's session; the
company directory may still have its own session. Retained access and refresh tokens
are encrypted with the sign-in secret. Stored ID tokens are signed JWTs whose
claims remain readable, including in a database backup. Treat the sign-in
secret and authentication database connection as privileged.

`tool_auth` has no role memberships, owns no tables and cannot bypass row
rules. It can operate only the authentication tables and read invitations.
`tool_app` cannot read or edit users, sessions, accounts or verification
records. Authentication tables force row-level security; they are deliberately
excluded from the business-record audit because their contents include tokens.
The separate sign-in permission suite checks their complete table inventory
and grants. Invitations remain audited. Ordinary business queries still use
`withDatabase` and its transaction-local user and role settings.

## Settings the host supplies

App registration belongs to AI Host Kit. This template reads these settings;
it does not register an application or alter a company's directory.

| Setting | Meaning |
| --- | --- |
| `AUTH_BASE_URL` | The tool's HTTPS origin, with no path. |
| `AUTH_SECRET_FILE` | Location of a file containing a random secret of at least 32 characters. Keep it stable across replicas. |
| `AUTH_DATABASE_URL` | Postgres connection for the restricted `tool_auth` role. |
| `STAFF_PROVIDER` | `microsoft`, `google` or `none`. `none` permits invited email users only. |
| `STAFF_ISSUER` | Microsoft: `https://login.microsoftonline.com/<tenant UUID>/v2.0`. Google: `https://accounts.google.com`. |
| `STAFF_CLIENT_ID` | The registered application's client ID. |
| `STAFF_CLIENT_SECRET_FILE` | Location of the client-secret file. |
| `MICROSOFT_TENANT_ID` | The one permitted company tenant UUID, in lower case. |
| `GOOGLE_WORKSPACE_DOMAIN` | The one permitted Workspace domain, in lower case. |
| Redirect path | `/api/auth/callback/microsoft` or `/api/auth/callback/google`, on `AUTH_BASE_URL`. |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_FROM` | Mail server, port (587 by default) and sender address for links. TLS is required. |
| `SMTP_USER`, `SMTP_PASSWORD_FILE` | Optional SMTP username and password-file location. Port 465 uses implicit TLS. |

Secret files are read on the server; their contents are never put in the
repository or printed. Supply them from the host's secret store. The app also
needs the existing `DATABASE_URL` for `tool_app`. It must not receive the
migration or database-administrator connection. Provision all three restricted
roles before applying migrations. The local bootstrap script creates
`tool_auth` alongside `tool_owner` and `tool_app` on a disposable database.

The SMTP sender is confined to `mail.ts`. It uses pinned Nodemailer 10.3.1 and
can be replaced by the template's shared mail function when that lands. Tests
capture mail in memory and send nothing externally. The library's production
rate limiter uses process memory; a deployment with several replicas needs a
shared rate-limit store or an equivalent ingress limit.

## Checks and second opinion

`npm test` runs the in-process OIDC stub and real Postgres. The stub publishes
signing keys, exchanges single-use codes and checks PKCE. Tests follow the
actual Better Auth handler through both company sign-in flows. They prove
rejection of another tenant or domain, invalid signatures, wrong issuers and
audiences, expired tokens and wrong nonces, as well as invitation, session and
permission behaviour. Stub HTTP issuers are accepted only when both Vitest and
test mode are present. No production switch enables the stub identity factory.
The existing CI workflow runs these tests through `npm run check`.

`npm run check:sign-in-review` compares the current SHA-256 digest with
`reviews/sign-in.json`. The digest covers the module, auth routes, sign-in
migration, user-role definitions, package manifest and lockfile, and the boundary and review scripts.
It includes file names and contents, so additions and deletions change it.
`npm run check` runs this before the other checks. A fault test changes code,
a dependency lockfile, the user-role definitions and the migration, and adds a file; each fails with the
old record.

After a change, the `second-opinion` step must review those files and the fresh
test evidence in a separate context. Resolve its findings, then run
`node scripts/sign-in-review.mjs --digest` and write that digest into the
record with `review: "second-opinion"`, `outcome: "pass"`, the review date and
an evidence list. Never refresh the record just to pass a check. The digest
proves that a record matches the code; it cannot prove who performed the
review or prevent a repository writer from forging a record. Pull request
review remains necessary.

Replacing Better Auth means replacing this module, preserving its three
entry points, migrating users and invitations, and revoking existing sessions.
The business schema and permission helper need no library-specific changes.
Run the same OIDC, invitation and session tests against the replacement before
recording its second opinion. A real directory registration and SMTP delivery
still need a host-side trial; the local stub does not establish those results.

## Integration review

The integration with files and jobs keeps user roles separate from the jobs
system role. The session check uses the user-role list, and the review digest
covers that list so changing it requires another review. Both storage adapters
are exercised with real company sign-in sessions against the local provider.
Queued test handlers obtain the current session identity separately from the
payload. A role change applies on the next attempt; queue access does not give
the handler system privileges. The starter's production worker still handles
only its fixed system tasks and exposes no user-job submission endpoint.

The authentication catalogue names users, sessions, accounts, verification
records and invitations explicitly. Effective table and column privileges are
checked for both app and authentication roles, including grants inherited from
PUBLIC. The authentication role is also checked for access to business and
queue tables, schema creation, role membership and callable functions.
