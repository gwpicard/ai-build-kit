# Tool masterplan

The owner, sign-in method and recovery targets must be settled at founding.

<!-- hosting:generated:start -->
## How it stays running

This section comes from hosting/handover.json. Update that file and run npm run hosting:render.

Sign-in: not configured. Data region: any. Recovery allows up to 24 hours of recent work to be lost and 8 hours to restore the tool.

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
| postgres / min major | 17 |
| postgres / extensions | None |
| postgres / roles / migrate | owner |
| postgres / roles / app | no-owner-no-bypassrls |
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
| sign in / outsiders | none |
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
