# Project checks reading kit files

If a project check reports faults inside `.agents/skills/` or `.claude/skills/`,
read the command and its configuration. Offer to exclude those installed skill
folders from that check. Show the file and proposed change, explain that the
project's own code stays checked, and apply it only with the person's approval.
Preserve existing rules and ignore patterns. A no leaves the configuration as
it is, and the report names the failing check.

For ESLint's flat configuration, add `.agents/skills/**` and `.claude/skills/**`
to an object containing only `ignores`. For an older ESLint configuration, add
them to its existing `ignorePatterns` or `.eslintignore`. For XO, use the ignore
setting supported by the project's installed version; do not migrate its
configuration. If TypeScript also reads kit source, add the two skill folders
to `tsconfig.json`'s `exclude`. Run the affected check again and report any
remaining failures. Do not edit installed kit files to satisfy a project check.
