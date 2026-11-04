# Dependency audit

On 4 November 2026, `npm audit --json` reported 20 moderate and two low affected
package entries, with no high or critical entries. These entries arise from
two advisories; transitive dependants are counted separately by npm.

| Advisory | Severity | Reach and decision |
| --- | --- | --- |
| [minimatch glob-pattern amplification](https://github.com/advisories/GHSA-g3hv-75wg-m249) | Moderate | Reached through ESLint and the shadcn CLI's ts-morph dependency. No sign-in or application runtime caller. Retained. The advisory names 11.0.1 as patched, but forcing its major version across the tooling tree is outside this integration. |
| [deepmerge prototype poisoning](https://github.com/advisories/GHSA-gcqx-w48m-w2h4) | Low | Reached through the shadcn CLI and registry tooling. No sign-in or application runtime caller. Retained; the advisory lists no patched version. |

The application imports only `shadcn/tailwind.css`, which is compiled into its
stylesheet. It imports no shadcn JavaScript, registry code, ts-morph, minimatch
or deepmerge. `npm explain minimatch deepmerge` identifies the tooling paths.
The production build's standalone package inventory contains none of those
packages; the worker imports only its database, queue and validation runtime
libraries. The Dockerfile also copies production dependencies for the worker
and migration scripts, so the shadcn CLI dependencies are present in that
image but are not called by the web, sign-in, worker or migration code. This
is an application reach assessment, not a claim that the image has no flagged
packages. Running the CLI inside that image would change the assessment.

No advisory reaches the sign-in path or executing production code, so no
advisory-driven version change is needed. Exact direct dependency pins are
preserved. The following table lists every npm audit entry, including the
transitive entries. “Tooling” means no sign-in or application runtime reach.

| Package entry | Severity | Dependency path and reach | Decision |
| --- | --- | --- | --- |
| `@eslint-community/eslint-utils` | Moderate | ESLint; tooling | Retain |
| `@eslint/config-array` | Moderate | ESLint; tooling | Retain |
| `@eslint/eslintrc` | Moderate | ESLint; tooling | Retain |
| `@next/eslint-plugin-next` | Moderate | ESLint; tooling | Retain |
| `@shadcn/registry` | Low | shadcn CLI; tooling | Retain |
| `@ts-morph/common` | Moderate | shadcn CLI; tooling | Retain |
| `@typescript-eslint/eslint-plugin` | Moderate | ESLint; tooling | Retain |
| `@typescript-eslint/parser` | Moderate | ESLint; tooling | Retain |
| `@typescript-eslint/type-utils` | Moderate | ESLint; tooling | Retain |
| `@typescript-eslint/typescript-estree` | Moderate | ESLint; tooling | Retain |
| `@typescript-eslint/utils` | Moderate | ESLint; tooling | Retain |
| `deepmerge` | Low | shadcn CLI; tooling | Retain |
| `eslint` | Moderate | ESLint; tooling | Retain |
| `eslint-config-next` | Moderate | ESLint; tooling | Retain |
| `eslint-plugin-better-tailwindcss` | Moderate | ESLint; tooling | Retain |
| `eslint-plugin-import` | Moderate | ESLint; tooling | Retain |
| `eslint-plugin-jsx-a11y` | Moderate | ESLint; tooling | Retain |
| `eslint-plugin-react` | Moderate | ESLint; tooling | Retain |
| `minimatch` | Moderate | ESLint and shadcn CLI; tooling | Retain |
| `shadcn` | Moderate | shadcn CLI; tooling | Retain |
| `ts-morph` | Moderate | shadcn CLI; tooling | Retain |
| `typescript-eslint` | Moderate | ESLint; tooling | Retain |
