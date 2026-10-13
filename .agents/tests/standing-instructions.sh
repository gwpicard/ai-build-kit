#!/usr/bin/env sh
# standing-instructions.sh: drive the validator's line count for a founded
# project's AGENTS.md.
#
# If this breaks, the template could grow until a fresh founding comes out over
# the 200-line ceiling while the validator still passes.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
pass=0
ok() { echo "  ok: $1"; pass=$((pass + 1)); }
fail() { echo "FAIL: $1" >&2; exit 1; }

VALIDATOR="$ROOT/.agents/tools/validate-kit.sh"
FOUNDATION="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"

# Run the count block from the real validator in isolation, so this check
# cannot recurse when the validator runs the written-rule family.
awk '/^founding_budget=/ {copy=1} copy {print} copy && /^fi$/ {exit}' \
  "$VALIDATOR" > "$WORK/ceiling"
[ -s "$WORK/ceiling" ] || fail "the validator's ceiling block is missing"
budget=$(sed -n 's/^founding_budget=\([0-9][0-9]*\)$/\1/p' "$WORK/ceiling")
[ -n "$budget" ] || fail "the validator names no budget for founding's lines"
margin=$(sed -n 's/^founding_margin=\([0-9][0-9]*\)$/\1/p' "$WORK/ceiling")
[ -n "$margin" ] || fail "the validator names no margin under the ceiling"
[ "$margin" -ge 5 ] || fail "the margin under the ceiling is $margin lines, fewer than 5"
room=$((199 - budget - margin))
mkdir -p "$WORK/skills/setup-ai-build-kit/templates/foundation"
padded="$WORK/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"
count_passes() {
  sh -c 'SKILLS=$1; fail() { exit 1; }; pass() { :; }; . "$2"' \
    sh "$WORK/skills" "$WORK/ceiling"
}
cp "$FOUNDATION" "$padded"
count_passes || fail "the shipped foundation leaves no room for founding's $budget lines"
ok "the shipped foundation passes the real count, founding's $budget lines included"
awk -v n="$room" 'BEGIN {for (i=1; i<=n; i++) print "line"}' > "$padded"
count_passes || fail "$room lines should pass, since $room, $budget and $margin make 199"
ok "$room lines pass, since $room, $budget and $margin make 199"
printf 'line' >> "$padded"
if count_passes; then fail "$((room + 1)) lines passed without a final newline"; fi
ok "$((room + 1)) lines fail even without a final newline"
# The count this replaced read the template alone, and a template of 196
# lines passed it while a fresh founding came out at 219.
awk 'BEGIN {for (i=1; i<=196; i++) print "line"}' > "$padded"
if count_passes; then fail "a template of 196 lines passed with no room for founding"; fi
ok "a template of 196 lines no longer passes"

# The founded result. Fill the template the way founding does, with a
# project line, capability profile and stack section shaped like the recipe
# campaign's first launch and adding the 23 lines founding measured there,
# then append the rules block the Next.js starter writes into AGENTS.md. What
# founding adds has to fit the budget, and the founded file has to stay under
# the ceiling with the margin to spare.
cat > "$WORK/project" <<'PROJECT'
A sign-up list for the team's weekly football, with a shared page of who is
playing.
PROJECT
cat > "$WORK/profile" <<'PROFILE'
- Harness: Claude Code, checked on the founding day. File read and write,
  shell, Git: yes. Browser: no browser tool confirmed; the person opens pages in
  their own browser, and the agent checks addresses with `curl`.
- Local save identity: none set; checkpoints use the project-only label "Local
  project user" (open question in masterplan.md).
- Online repository: none yet; the pieces need one, set up with the founder's
  approval. GitHub command line tool: installed and signed in. Project check:
  `project-check` in `.github/workflows/checks.yml`.
- Independent review: a subagent, or a clean separate session. Reach-check
  engine: none; the agent reads imports and callers directly.
- Hooks: yes. SessionStart runs `.agents/hooks/session-start.sh`; command blocks
  live in `.claude/settings.json`.
- Online account access: GitHub, signed in. Vercel and Supabase: the person
  signs in during the first launch. Online authentication: the GitHub command
  line tool's own sign-in.
PROFILE
cat > "$WORK/stack" <<'STACK'
Recipe: nextjs-supabase-on-vercel.md

- Install `npm ci` (Node 22). Run `npm run dev`, then open
  http://localhost:3000.
- Test `npm test` (Vitest). Type check `npm run typecheck` (runs `next typegen`
  first). Lint `npm run lint` (Next.js starter rules). Run all three before
  hand-over; `project-check` runs the same.
- Sign-in, the database and the team list use hosted Supabase (managed
  email-link sign-in). Never hand-build sign-in.
- Next.js keeps its own agent rules in the block at the end of this file; read
  them before writing Next.js code.
- Hosting: Vercel, linked to the GitHub repository, so a merge to `main`
  deploys. The database runs on hosted Supabase.
- Launch checks: `/setup-hosting` runs the recipe's eight sections and records the
  address in the changelog.
- Design tool: none recorded.
STACK
founded="$WORK/founded-AGENTS.md"
# Each placeholder is a paragraph in brackets. Replace the project line and
# the two sections founding fills; leave the confidential-files note, which
# founding fills only for a project that has such files.
awk -v dir="$WORK" '
  function fill(name,   line) {
    while ((getline line < (dir "/" name)) > 0) print line
    close(dir "/" name)
  }
  /^## Capability profile$/ { want = "profile" }
  /^## Stack, and how to run and check it$/ { want = "stack" }
  /^\(One line, written by the setup-ai-build-kit skill\.\)$/ { fill("project"); next }
  want != "" && /^\(Filled in by the setup-ai-build-kit skill:/ { inside = 1 }
  inside {
    if ($0 ~ /\)$/) { inside = 0; fill(want); want = "" }
    next
  }
  { print }
' "$FOUNDATION" > "$founded"
template_lines=$(awk 'END { print NR }' "$FOUNDATION")
filled=$(( $(awk 'END { print NR }' "$founded") - template_lines ))
[ "$filled" -eq 23 ] || \
  fail "the stand-in founding adds $filled lines, not the 23 measured on the campaign"
ok "the stand-in founding adds the 23 lines measured on the campaign"
cat >> "$founded" <<'NEXTJS'

<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes. APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev`. Committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->
NEXTJS
if ! grep -qF 'Recipe: nextjs-supabase-on-vercel.md' "$founded" || \
   ! grep -qF -- '- Hooks: yes.' "$founded" || \
   ! grep -qF "A sign-up list for the team's weekly football" "$founded" || \
   grep -qF '(Filled in by the setup-ai-build-kit skill:' "$founded"; then
  fail "the founded rehearsal did not fill the template the way founding does"
fi
founded_lines=$(awk 'END { print NR }' "$founded")
added=$((founded_lines - template_lines))
[ "$added" -le "$budget" ] || \
  fail "a usual founding adds $added lines, more than the budget of $budget"
ok "a usual founding, the Next.js rules included, adds $added lines, within the budget of $budget"
[ $((founded_lines + margin)) -lt 200 ] || \
  fail "a usual founding leaves AGENTS.md at $founded_lines lines, inside the margin of $margin"
ok "a usual founding leaves AGENTS.md at $founded_lines lines, $margin or more under the ceiling"

echo
echo "$(basename -- "$0"): all $pass checks passed"
