#!/usr/bin/env sh
# starter-copy-rehearsal.sh: prove starter copying passes, refuses clashes and reports setup errors.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
COPY="$ROOT/.agents/skills/setup-ai-build-kit/scripts/use-starter.sh"
RECIPE=recipes/nextjs-supabase-on-vercel
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[ -x "$COPY" ] || fail "starter copy script is missing or not executable"
mkdir "$SCRATCH/clean" "$SCRATCH/clash" "$SCRATCH/bad"

"$COPY" "$RECIPE" "$SCRATCH/clean" >/dev/null || fail "clean project was refused"
for required in package.json Dockerfile .env.example public/.keep src/app/api/health/route.ts \
  src/lib/supabase/client.ts src/lib/supabase/server.ts src/app/login/page.tsx src/app/auth/callback/route.ts \
  src/app/api/admin/invitations/route.ts supabase/migrations/20261015000000_roles_and_access_token_hook.sql \
  scripts/check.sh types/database.ts; do
  [ -f "$SCRATCH/clean/$required" ] || fail "copied starter is missing $required"
done

printf 'keep this file\n' > "$SCRATCH/clash/package.json"
printf 'also keep this\n' > "$SCRATCH/clash/Dockerfile"
set +e
"$COPY" "$RECIPE" "$SCRATCH/clash" >"$SCRATCH/clash.out" 2>&1
status=$?
set -e
[ "$status" -eq 1 ] || fail "starter clash returned $status instead of 1"
grep -qF 'package.json' "$SCRATCH/clash.out" || fail "clash report omitted package.json"
grep -qF 'Dockerfile' "$SCRATCH/clash.out" || fail "clash report omitted Dockerfile"
[ "$(cat "$SCRATCH/clash/package.json")" = 'keep this file' ] || fail "package.json was overwritten"
[ "$(cat "$SCRATCH/clash/Dockerfile")" = 'also keep this' ] || fail "Dockerfile was overwritten"
[ ! -e "$SCRATCH/clash/src" ] || fail "starter copied files despite a clash"

if "$COPY" recipes/missing "$SCRATCH/bad" >"$SCRATCH/error.out" 2>&1; then
  fail "missing recipe was accepted"
else
  status=$?
fi
[ "$status" -eq 2 ] || fail "missing recipe returned $status instead of 2"
grep -qF 'could not run:' "$SCRATCH/error.out" || fail "exit 2 did not say it could not run"

echo "starter-copy-rehearsal.sh: exit 0, 1 and 2 behaved as promised"
