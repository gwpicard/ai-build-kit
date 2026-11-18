# Dependency audit

On 18 November 2026, `npm audit --package-lock-only --json` with an isolated
npm cache reported 23 affected package entries: seven moderate and 16 high,
with none low or critical. The original manifest and lockfile reported 25:
nine moderate and 16 high with the same cache. npm counts affected dependants
separately, so these totals do not count distinct advisories.

With the pre-existing local npm cache, the same command reported 28 entries
before the changes (10 moderate and 18 high) and 25 afterwards (seven moderate
and 18 high). That run also listed `@vitest/mocker` and `better-auth` through
their Vite and Vitest dependency paths. Both are recorded below rather than
omitted from the assessment.

## Patched packages and runtime reach

The lockfile refresh updates `hono` from 4.13.13 to 4.13.19 and
`@hono/node-server` from 2.1.5 to 2.1.9, within their existing major versions
and dependency ranges. The refreshed audit no longer lists their advisories.
No direct dependency version changes, and no override is needed.

`shadcn` is a development dependency. The application and components import
only `shadcn/tailwind.css`, which Tailwind compiles during the build. Neither
application JavaScript nor the web, worker, migration and startup scripts
import the CLI or its registry code. The Dockerfile installs development
dependencies before building and prunes them before copying the worker and
migration dependencies into the runtime image. Moving the CLI therefore keeps
its build-time CSS available and removes its production dependency path.

The remaining entries reach build, test and lint tooling. Better Auth declares
Vitest as an optional peer dependency, and npm marks parts of that tooling tree
as `devOptional` in the lockfile. A production-only audit can therefore still
report Picomatch through that path. This record does not claim that every
flagged package is absent from a production installation or image.

## Remaining advisories

| Advisory | Severity | Reason it remains |
| --- | --- | --- |
| [Picomatch repeated-extglob denial of service](https://github.com/advisories/GHSA-fc5q-39xc-vjpf) | High | The advisory covers versions through 4.0.7 and lists no patched release. The installed 2.3.2 and 4.0.7 copies have no patched release in their current majors. |
| [minimatch glob-pattern amplification](https://github.com/advisories/GHSA-g3hv-75wg-m249) | Moderate | The installed 10.2.6 copy is affected. The patch starts at 11.0.1, outside its current major. Installed 3.1.5 copies are outside the advisory's range. |

In the table below, **P** means the entry inherits the unpatched Picomatch
advisory, and **M** means it inherits minimatch's advisory, whose patch requires
a new major. Updating a parent package cannot clear the entry while it still
reaches the affected package. No forced downgrade or cross-major override is
used to suppress these findings.

| Package entry | Severity | Affected dependency path | Reason retained |
| --- | --- | --- | --- |
| `@dotenvx/dotenvx` | High | `fdir`, `picomatch` | P |
| `@next/eslint-plugin-next` | High | `fast-glob` | P |
| `@shadcn/registry` | High | `@dotenvx/dotenvx`, `fast-glob` | P |
| `@ts-morph/common` | High | `fast-glob`, `minimatch` | P, M |
| `@typescript-eslint/eslint-plugin` | Moderate | `@typescript-eslint/type-utils`, `@typescript-eslint/utils` | P, M |
| `@typescript-eslint/parser` | Moderate | `@typescript-eslint/typescript-estree` | P, M |
| `@typescript-eslint/type-utils` | Moderate | `@typescript-eslint/typescript-estree`, `@typescript-eslint/utils` | P, M |
| `@typescript-eslint/typescript-estree` | High | `minimatch`, `tinyglobby` | P, M |
| `@typescript-eslint/utils` | Moderate | `@typescript-eslint/typescript-estree` | P, M |
| `@vitest/coverage-v8` | High | `vitest` | P |
| `eslint-config-next` | High | `@next/eslint-plugin-next` | P |
| `eslint-import-resolver-typescript` | High | `tinyglobby` | P |
| `fast-glob` | High | `micromatch` | P |
| `fdir` | High | `picomatch` | P |
| `micromatch` | High | `picomatch` | P |
| `minimatch` | Moderate | `minimatch` 10.2.6 | M |
| `picomatch` | High | `picomatch` 2.3.2 and 4.0.7 | P |
| `shadcn` | High | `@dotenvx/dotenvx`, `@shadcn/registry`, `fast-glob`, `ts-morph` | P, M |
| `tinyglobby` | High | `fdir`, `picomatch` | P |
| `ts-morph` | Moderate | `@ts-morph/common` | P, M |
| `typescript-eslint` | Moderate | TypeScript ESLint plugin, parser, estree and utils | P, M |
| `vite` | High | `picomatch`, `tinyglobby` | P |
| `vitest` | High | `@vitest/coverage-v8`, `picomatch`, `tinyglobby`, `vite` | P |

Additional entries reported with the pre-existing local cache:

| Package entry | Severity | Affected dependency path | Reason retained |
| --- | --- | --- | --- |
| `@vitest/mocker` | High | `vite` | P |
| `better-auth` | High | Optional peer `vitest` | P |

## Supabase starter

The shared Supabase starter uses the same patched Hono versions and the same
`shadcn` development dependency. Its application also imports only the
build-time CSS. Its Dockerfile builds with development dependencies and copies
the standalone application into the runtime image.

With the isolated cache, its audit reports the same 23 entries in the main
table above, down from 25 in the original manifest and lockfile. With the
pre-existing cache it reports 24 entries (seven moderate and 17 high), down
from 27 (10 moderate and 17 high). The additional entry is `@vitest/mocker`,
with reason P. It has no Better Auth dependency or corresponding audit entry.
All remaining entries have the reasons recorded above; shared direct pins and
patched transitive versions match the Postgres starter.
