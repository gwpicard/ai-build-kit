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

printf 'local-only/' > "$SCRATCH/clean/.gitignore"
printf 'LOCAL_ONLY=keep' > "$SCRATCH/clean/.env.example"
"$COPY" "$RECIPE" "$SCRATCH/clean" >/dev/null || fail "clean project was refused"
for required in package.json Dockerfile .env.example public/.keep src/app/api/health/route.ts \
  src/lib/supabase/client.ts src/lib/supabase/server.ts src/app/login/page.tsx src/app/auth/callback/route.ts \
  src/app/api/admin/invitations/route.ts supabase/migrations/20261015000000_roles_and_access_token_hook.sql \
  components.json src/app/globals.css e2e/accessibility.spec.ts \
  src/components/ui/button.tsx src/components/ui/input.tsx src/components/ui/label.tsx \
  src/components/ui/card.tsx src/components/ui/table.tsx src/components/ui/dialog.tsx \
  src/components/ui/select.tsx src/components/ui/field.tsx src/components/ui/separator.tsx src/components/ui/sonner.tsx \
  .github/workflows/check.yml scripts/rls.sh scripts/check-lib.sh scripts/check.sh types/database.ts; do
  [ -f "$SCRATCH/clean/$required" ] || fail "copied starter is missing $required"
done

cmp "$SCRATCH/clean/scripts/rls.sh" "$ROOT/.agents/skills/setup-hosting/recipes/parts/scripts/rls.sh" || fail "the copied row rules check differs from the recipe"
cmp "$SCRATCH/clean/scripts/check-lib.sh" "$ROOT/.agents/skills/setup-hosting/recipes/parts/scripts/check-lib.sh" || fail "the copied row rules helper differs from the recipe"

[ ! -e "$SCRATCH/clean/src/components/ui/form.tsx" ] || fail "copied starter still ships the legacy form component"

python3 - "$COPY" "$SCRATCH" <<'PY'
from pathlib import Path
import shutil
import subprocess
import sys

copy, scratch = Path(sys.argv[1]), Path(sys.argv[2])
skill = scratch / "kit/setup-ai-build-kit/scripts"
starter = scratch / "kit/setup-hosting/recipes/parts/starters/lists"
recipe = scratch / "kit/setup-hosting/recipes/lists"
project = scratch / "lists"
for folder in (skill, starter, recipe, project):
    folder.mkdir(parents=True)
shutil.copy2(copy, skill / copy.name)
(recipe / "recipe.md").write_text("Starter: ../parts/starters/lists\n")
originals = {
    ".gitignore": b"# project\r\nnode_modules/\r\nlocal/\nlocal/",
    ".env.example": b"# project\n SHARED =keep=whole\nLOCAL=stay\nLOCAL=also-stay",
}
sources = {
    ".gitignore": b"node_modules/\n.next/\n.next/\n.env\n",
    ".env.example": b"# shared\nSHARED=replace\n\n# new\n NEW =two=parts\nNEW=duplicate\nLAST=last",
}
expected = {
    ".gitignore": originals[".gitignore"] + b"\n.next/\n.env\n",
    ".env.example": originals[".env.example"] + b"\n NEW =two=parts\nLAST=last\n",
}
for name in originals:
    (project / name).write_bytes(originals[name])
    (starter / name).write_bytes(sources[name])

for attempt in range(2):
    result = subprocess.run([str(skill / copy.name), str(recipe), str(project)],
                            capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    for name, content in expected.items():
        assert (project / name).read_bytes() == content, f"list merge changed {name} on run {attempt + 1}"
    reports = [line for line in result.stdout.splitlines() if line.startswith("Added starter lines to:")]
    assert reports == (["Added starter lines to: .env.example, .gitignore"] if attempt == 0 else []), result.stdout

for name in originals:
    content = (scratch / "clean" / name).read_bytes()
    prefix = b"local-only/\n" if name == ".gitignore" else b"LOCAL_ONLY=keep\n"
    assert content.startswith(prefix), f"recipe merge lost project lines in {name}"
PY

printf 'keep this file\n' > "$SCRATCH/clash/package.json"
printf 'also keep this\n' > "$SCRATCH/clash/Dockerfile"
printf 'local-only/' > "$SCRATCH/clash/.gitignore"
printf 'LOCAL_ONLY=keep' > "$SCRATCH/clash/.env.example"
set +e
"$COPY" "$RECIPE" "$SCRATCH/clash" >"$SCRATCH/clash.out" 2>&1
status=$?
set -e
[ "$status" -eq 1 ] || fail "starter clash returned $status instead of 1"
grep -qF 'package.json' "$SCRATCH/clash.out" || fail "clash report omitted package.json"
grep -qF 'Dockerfile' "$SCRATCH/clash.out" || fail "clash report omitted Dockerfile"
[ "$(cat "$SCRATCH/clash/package.json")" = 'keep this file' ] || fail "package.json was overwritten"
[ "$(cat "$SCRATCH/clash/Dockerfile")" = 'also keep this' ] || fail "Dockerfile was overwritten"
[ "$(cat "$SCRATCH/clash/.gitignore")" = 'local-only/' ] || fail ".gitignore changed despite a clash"
[ "$(cat "$SCRATCH/clash/.env.example")" = 'LOCAL_ONLY=keep' ] || fail ".env.example changed despite a clash"
[ ! -e "$SCRATCH/clash/src" ] || fail "starter copied files despite a clash"

mkdir "$SCRATCH/link" "$SCRATCH/directory"
printf 'keep linked file\n' > "$SCRATCH/link-target"
ln -s "$SCRATCH/link-target" "$SCRATCH/link/.gitignore"
mkdir "$SCRATCH/directory/.env.example"
for project in link directory; do
  if "$COPY" "$RECIPE" "$SCRATCH/$project" >"$SCRATCH/$project.out" 2>&1; then
    fail "$project at a list path was accepted"
  else
    status=$?
  fi
  [ "$status" -eq 1 ] || fail "$project clash returned $status instead of 1"
  [ ! -e "$SCRATCH/$project/package.json" ] || fail "starter copied files despite a $project clash"
done
grep -qxF '.gitignore' "$SCRATCH/link.out" || fail "clash report omitted the link"
[ -L "$SCRATCH/link/.gitignore" ] || fail ".gitignore link was replaced"
[ "$(cat "$SCRATCH/link-target")" = 'keep linked file' ] || fail "linked file was changed"

if "$COPY" recipes/missing "$SCRATCH/bad" >"$SCRATCH/error.out" 2>&1; then
  fail "missing recipe was accepted"
else
  status=$?
fi
[ "$status" -eq 2 ] || fail "missing recipe returned $status instead of 2"
grep -qF 'could not run:' "$SCRATCH/error.out" || fail "exit 2 did not say it could not run"

echo "starter-copy-rehearsal.sh: list merges and exits 0, 1 and 2 behaved as promised"
