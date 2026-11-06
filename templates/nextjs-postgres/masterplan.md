# Tool masterplan

The owner, sign-in method and recovery targets must be settled at founding.

<!-- hosting:generated:start -->
## How it stays running

This section comes from hosting/handover.json. Update that file and run npm run hosting:render.

Sign-in: email link. Data region: any. Recovery allows up to 24 hours of recent work to be lost and 8 hours to restore the tool.

The requirements below describe what the tool needs. They do not confirm that a live copy exists.

| Requirement | Value |
| --- | --- |
| schema version | 1.0 |
| tool / name | team-tool-postgres |
| tool / owner | To be named at founding |
| image / dockerfile | Dockerfile |
| processes / web / command | web |
| processes / web / port | 3000 |
| processes / worker / command | worker |
| processes / migrate / command | migrate |
| processes / migrate / when | before-release |
| health / path | /api/health |
| health / checks / 0 | database |
| health / checks / 1 | worker |
| health / commit env | SOURCE_COMMIT |
| config / 0 / name | DATABASE_URL |
| config / 0 / kind | secret |
| config / 0 / phase | runtime |
| config / 0 / source | host |
| config / 1 / name | MIGRATION_DATABASE_URL |
| config / 1 / kind | secret |
| config / 1 / phase | runtime |
| config / 1 / source | host |
| config / 2 / name | NODE_ENV |
| config / 2 / kind | setting |
| config / 2 / phase | runtime |
| config / 2 / source | host |
| config / 3 / name | PORT |
| config / 3 / kind | setting |
| config / 3 / phase | runtime |
| config / 3 / source | host |
| config / 4 / name | HOSTNAME |
| config / 4 / kind | setting |
| config / 4 / phase | runtime |
| config / 4 / source | host |
| config / 5 / name | SOURCE_COMMIT |
| config / 5 / kind | setting |
| config / 5 / phase | runtime |
| config / 5 / source | host |
| config / 6 / name | JOBS_MODE |
| config / 6 / kind | setting |
| config / 6 / phase | runtime |
| config / 6 / source | host |
| config / 7 / name | JOBS_TIMER_TOKEN |
| config / 7 / kind | secret |
| config / 7 / phase | runtime |
| config / 7 / source | generated |
| config / 8 / name | FILES_ADAPTER |
| config / 8 / kind | setting |
| config / 8 / phase | runtime |
| config / 8 / source | host |
| config / 9 / name | FILES_LINK_SECONDS |
| config / 9 / kind | setting |
| config / 9 / phase | runtime |
| config / 9 / source | host |
| config / 10 / name | FILES_S3_BUCKET |
| config / 10 / kind | setting |
| config / 10 / phase | runtime |
| config / 10 / source | host |
| config / 11 / name | FILES_S3_REGION |
| config / 11 / kind | setting |
| config / 11 / phase | runtime |
| config / 11 / source | host |
| config / 12 / name | FILES_S3_ENDPOINT |
| config / 12 / kind | setting |
| config / 12 / phase | runtime |
| config / 12 / source | host |
| config / 13 / name | FILES_S3_FORCE_PATH_STYLE |
| config / 13 / kind | setting |
| config / 13 / phase | runtime |
| config / 13 / source | host |
| config / 14 / name | AWS_ACCESS_KEY_ID |
| config / 14 / kind | secret |
| config / 14 / phase | runtime |
| config / 14 / source | host |
| config / 15 / name | AWS_SECRET_ACCESS_KEY |
| config / 15 / kind | secret |
| config / 15 / phase | runtime |
| config / 15 / source | host |
| config / 16 / name | AWS_SESSION_TOKEN |
| config / 16 / kind | secret |
| config / 16 / phase | runtime |
| config / 16 / source | host |
| config / 17 / name | FILES_AZURE_ACCOUNT |
| config / 17 / kind | setting |
| config / 17 / phase | runtime |
| config / 17 / source | host |
| config / 18 / name | FILES_AZURE_ACCOUNT_KEY |
| config / 18 / kind | secret |
| config / 18 / phase | runtime |
| config / 18 / source | host |
| config / 19 / name | FILES_AZURE_CONTAINER |
| config / 19 / kind | setting |
| config / 19 / phase | runtime |
| config / 19 / source | host |
| config / 20 / name | FILES_AZURE_ENDPOINT |
| config / 20 / kind | setting |
| config / 20 / phase | runtime |
| config / 20 / source | host |
| config / 21 / name | SMTP_HOST |
| config / 21 / kind | setting |
| config / 21 / phase | runtime |
| config / 21 / source | host |
| config / 22 / name | SMTP_PORT |
| config / 22 / kind | setting |
| config / 22 / phase | runtime |
| config / 22 / source | host |
| config / 23 / name | SMTP_SECURE |
| config / 23 / kind | setting |
| config / 23 / phase | runtime |
| config / 23 / source | host |
| config / 24 / name | SMTP_USER |
| config / 24 / kind | secret |
| config / 24 / phase | runtime |
| config / 24 / source | host |
| config / 25 / name | SMTP_PASSWORD |
| config / 25 / kind | secret |
| config / 25 / phase | runtime |
| config / 25 / source | host |
| config / 26 / name | MAIL_FROM |
| config / 26 / kind | setting |
| config / 26 / phase | runtime |
| config / 26 / source | host |
| config / 27 / name | AUTH_BASE_URL |
| config / 27 / kind | setting |
| config / 27 / phase | runtime |
| config / 27 / source | host |
| config / 28 / name | AUTH_SECRET_FILE |
| config / 28 / kind | secret |
| config / 28 / phase | runtime |
| config / 28 / source | host |
| config / 29 / name | AUTH_DATABASE_URL |
| config / 29 / kind | secret |
| config / 29 / phase | runtime |
| config / 29 / source | host |
| config / 30 / name | STAFF_PROVIDER |
| config / 30 / kind | setting |
| config / 30 / phase | runtime |
| config / 30 / source | host |
| config / 31 / name | STAFF_ISSUER |
| config / 31 / kind | setting |
| config / 31 / phase | runtime |
| config / 31 / source | host |
| config / 32 / name | STAFF_CLIENT_ID |
| config / 32 / kind | setting |
| config / 32 / phase | runtime |
| config / 32 / source | host |
| config / 33 / name | STAFF_CLIENT_SECRET_FILE |
| config / 33 / kind | secret |
| config / 33 / phase | runtime |
| config / 33 / source | host |
| config / 34 / name | MICROSOFT_TENANT_ID |
| config / 34 / kind | setting |
| config / 34 / phase | runtime |
| config / 34 / source | host |
| config / 35 / name | GOOGLE_WORKSPACE_DOMAIN |
| config / 35 / kind | setting |
| config / 35 / phase | runtime |
| config / 35 / source | host |
| config / 36 / name | SMTP_FROM |
| config / 36 / kind | setting |
| config / 36 / phase | runtime |
| config / 36 / source | host |
| config / 37 / name | SMTP_PASSWORD_FILE |
| config / 37 / kind | secret |
| config / 37 / phase | runtime |
| config / 37 / source | host |
| config / 38 / name | VITEST |
| config / 38 / kind | setting |
| config / 38 / phase | runtime |
| config / 38 / source | host |
| postgres / min major | 17 |
| postgres / extensions | None |
| postgres / roles / migrate | owner |
| postgres / roles / app | no-owner-no-bypassrls |
| postgres / roles / auth | no-owner-no-bypassrls |
| postgres / sign in / schema | sign_in |
| postgres / sign in / tables / 0 | user |
| postgres / sign in / tables / 1 | session |
| postgres / sign in / tables / 2 | account |
| postgres / sign in / tables / 3 | verification |
| postgres / sign in / tables / 4 | invitations |
| postgres / sign in / owner | tool_owner |
| postgres / sign in / migration | db/migrations/002_sign_in.sql |
| postgres / sign in / runtime role | tool_auth |
| postgres / sign in / permissions | tool_auth can operate authentication tables and read invitations; tool_app can manage invitations only as an administrator through row-level security. |
| files / port | s3 |
| files / buckets / 0 / name | private-files |
| files / buckets / 0 / private | true |
| files / buckets / 0 / link minutes | 1 |
| email / transport | smtp |
| email / sender domain | example.test |
| email / inbound | false |
| jobs / library | pg-boss |
| jobs / runner | worker |
| jobs / longest job seconds | 2 |
| jobs / schedules / 0 / name | weekly-reminder |
| jobs / schedules / 0 / cron | 0 9 * * 1 |
| sign in / staff | Not configured |
| sign in / outsiders | email-link |
| sign in / staff provider | none |
| sign in / public origin env | AUTH_BASE_URL |
| sign in / configuration / AUTH BASE URL | HTTPS public origin without a path, used for cookies and callback addresses. |
| sign in / configuration / AUTH SECRET FILE | Host-mounted file containing a random sign-in encryption secret of at least 32 characters, stable across replicas. |
| sign in / configuration / AUTH DATABASE URL | Postgres connection for tool_auth; never an owner or administrator connection. |
| sign in / configuration / STAFF PROVIDER | none for invited email users only; microsoft or google for one company directory alongside invited email users. |
| sign in / configuration / STAFF ISSUER | Company tenant issuer for Microsoft, or the Google accounts issuer for Google. |
| sign in / configuration / STAFF CLIENT ID | Client ID of the company directory application registered by AI Host Kit. |
| sign in / configuration / STAFF CLIENT SECRET FILE | Host-mounted file containing the directory application client secret; needed for staff sign-in. |
| sign in / configuration / MICROSOFT TENANT ID | One permitted company tenant UUID in lower case; required for Microsoft staff sign-in. |
| sign in / configuration / GOOGLE WORKSPACE DOMAIN | One permitted Workspace domain in lower case; required for Google staff sign-in. |
| sign in / configuration / SMTP FROM | Sender address for invited outsider sign-in links; ordinary application mail uses MAIL_FROM. |
| sign in / configuration / SMTP PASSWORD FILE | Host-mounted SMTP password file for sign-in mail when SMTP_USER is supplied; ordinary mail uses SMTP_PASSWORD. |
| sign in / configuration / VITEST | Test-runner marker only; leave unset in deployed processes. Local stub issuers also require NODE_ENV test. |
| sign in / host setup / owner | AI Host Kit |
| sign in / host setup / request | For company sign-in, register one company directory application and supply issuer, client ID and the client-secret file through the host secret store. Register the callback on AUTH_BASE_URL. No directory registration is needed for email-only sign-in. |
| sign in / host setup / microsoft | Single-tenant application; request acct in optionalClaims.idToken so only numeric acct 0 members can sign in. |
| sign in / host setup / google | Restrict access to the configured Workspace domain using the verified hd claim. |
| sign in / host setup / callbacks / microsoft | /api/auth/callback/microsoft |
| sign in / host setup / callbacks / google | /api/auth/callback/google |
| sign in / email link / verification path | /api/auth/magic-link/verify |
| sign in / email link / requires | HTTPS origin, SMTP settings and a current administrator-created invitation; links expire after ten minutes and work once. |
| access | private |
| residency | any |
| data risk | None |
| recovery / max data loss hours | 24 |
| recovery / max restore hours | 8 |
| limits / longest request seconds | 15 |
| limits / memory mb | 512 |
| limits / outbound internet | true |
| previews / wanted | false |
| previews / data | separate-database |
<!-- hosting:generated:end -->
