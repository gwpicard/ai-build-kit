# Reach check

Run `python3` with this skill's `scripts/quality.py reach`, then act on its exit code.

Removed exports are checked by comparing direct exported declarations with
named imports in files that resolve to them. The read does not follow
re-exports, default or type-only imports, or dynamic imports.
