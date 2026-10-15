#!/usr/bin/env sh
# recipe-ci-rehearsal.sh: founds a recipe starter and runs its parsed CI commands.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
PROJECT="$WORK/project"
mkdir -p "$PROJECT"
fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }

sh "$ROOT/.agents/skills/setup-ai-build-kit/scripts/use-starter.sh" recipes/nextjs-supabase-on-vercel "$PROJECT" >/dev/null
sh "$ROOT/.agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh" "$PROJECT" >/dev/null
sed -i.bak 's/^Recipe: none$/Recipe: nextjs-supabase-on-vercel/' "$PROJECT/AGENTS.md" 2>/dev/null || \
  sed -i 's/^Recipe: none$/Recipe: nextjs-supabase-on-vercel/' "$PROJECT/AGENTS.md"
[ -f "$PROJECT/.agents/hooks/check-review.sh" ] || fail "founding did not install check-review.sh"
[ -f "$PROJECT/.agents/hooks/review_boxes.py" ] || fail "founding did not install the shared review reader"

ruby -ryaml -rjson -e '
workflow = YAML.load_file(ARGV[0])
permissions = workflow.fetch("permissions")
raise "the pull-request token cannot read pull requests" unless permissions == {"contents"=>"read", "pull-requests"=>"read"}
steps = workflow.fetch("jobs").fetch("project-check").fetch("steps")
detect = steps.find { |step| step["name"] == "Detect the selected recipe" }
test = steps.find { |step| step["name"] == "Install and test" }
raise "recipe detection step is missing" unless detect && detect["run"].include?("Recipe:")
raise "recipe setup does not run only on a recipe" unless steps.any? { |step| step["uses"].to_s.start_with?("supabase/setup-cli") && step["if"] == "steps.recipe.outputs.selected == '\''true'\''" }
raise "Node setup does not run only on a recipe" unless steps.any? { |step| step["uses"].to_s.start_with?("actions/setup-node") && step["if"] == "steps.recipe.outputs.selected == '\''true'\''" }
raise "recipe test step is missing its recipe guard" unless test && test["if"] == "steps.recipe.outputs.selected == '\''true'\''"
["npm ci", "supabase start", "supabase db reset", "npx vitest run --coverage", "npx next typegen", "npx tsc --noEmit", "supabase gen types typescript --local", "diff", "npm run build", "npx next start", "npx playwright test"].each do |command|
  raise "missing CI command: #{command}" unless test["run"].include?(command)
end
File.write(ARGV[1], test.fetch("run"))
' "$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml" "$WORK/recipe-check.sh" || fail "foundation checks.yml does not parse or lacks recipe steps"
pass "the foundation workflow parses and limits recipe steps to the selected recipe"

mkdir -p "$WORK/bin"
cat > "$WORK/bin/log-command" <<'CMD'
#!/usr/bin/env sh
printf '%s %s\n' "$(basename "$0")" "$*" >> "$CI_COMMAND_LOG"
CMD
for command in npm npx curl; do cp "$WORK/bin/log-command" "$WORK/bin/$command"; chmod +x "$WORK/bin/$command"; done
cat > "$WORK/bin/supabase" <<'CMD'
#!/usr/bin/env sh
printf 'supabase %s\n' "$*" >> "$CI_COMMAND_LOG"
if [ "$1 $2 $3" = "gen types typescript" ]; then cat types/database.ts; fi
CMD
chmod +x "$WORK/bin/supabase"
printf '' > "$WORK/commands.log"
(cd "$PROJECT" && PATH="$WORK/bin:$PATH" CI_COMMAND_LOG="$WORK/commands.log" bash "$WORK/recipe-check.sh") || fail "recipe CI commands did not run in the founded starter"
for command in 'npm ci' 'supabase start' 'supabase db reset' 'npx vitest run --coverage' 'npx next typegen' 'npx tsc --noEmit' 'supabase gen types typescript --local' 'npm run build' 'npx next start' 'npx playwright test'; do
  grep -Fq "$command" "$WORK/commands.log" || fail "recipe CI did not run: $command"
done
pass "recipe CI commands ran in a founded recipe starter, including coverage, types, drift and Playwright"

