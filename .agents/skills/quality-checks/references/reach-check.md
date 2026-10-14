# Reach check

Run `python3` with this skill's `scripts/quality.py reach`, then act on its exit code.

At build, run `quality.py reach --base <start commit> --piece <number> --run`:

- An `undeclared` line means the build grew past the piece. Stop and ask:
  "this piece, or a new one?" Name the `wide` line.
- Exit 1 otherwise: a covering test failed. Fix it.
- Exit 2: say what could not run, and read the changed imports yourself.
- Exit 0 with other parts reached: say "This change also reaches <part>, and
  the <count> tests that cover it passed." Say nothing when no other part is
  reached.

Removed exports are checked by comparing direct exported declarations with
named imports in files that resolve to them. The read does not follow
re-exports, default or type-only imports, or dynamic imports.
