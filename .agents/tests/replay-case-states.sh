#!/usr/bin/env sh
# replay-case-states.sh: prove each new case has a sensitive disk assertion.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
REPLAY="$ROOT/.agents/tests/replay"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
for number in 60 61 62 63; do
  project="$WORK/s$number"
  mkdir -p "$project"
  cp -R "$REPLAY/fixture/app" "$project/app"
  cp "$REPLAY/fixture/AGENTS-additions.md" "$project/AGENTS.md"
  cp "$REPLAY/fixture/masterplan.md" "$project/masterplan.md"
  cp "$REPLAY/fixture/CHANGELOG.md" "$project/CHANGELOG.md"
  cp "$REPLAY/fixture/issues.json" "$project/.gh-fixture.json"
  prepare=$(awk -F': *' '/^# prepare:/ { print $2; exit }' "$REPLAY/cases/$number.txt")
  sh "$REPLAY/prepare/$prepare.sh" "$project"
  if [ "$number" = 61 ]; then
    git -C "$project" init -q -b main
    git -C "$project" config user.email rehearsal@example.invalid
    git -C "$project" config user.name 'Replay rehearsal'
    git -C "$project" add -A
    git -C "$project" commit -q -m 'Starting project'
    git init -q --bare -b main "$project.git"
    git -C "$project" remote add origin "$project.git"
    git -C "$project" push -q origin main
    git -C "$project" checkout -q -b auto-merge-exceeds
    git -C "$project" commit -q --allow-empty -m 'Unmerged pull request'
    git -C "$project" push -q origin auto-merge-exceeds
    git -C "$project" checkout -q main
    cp "$project/.gh-fixture.json" "$project.gh.json"
  fi
  "$REPLAY/scenario-state-check.sh" "$number" "$project" | grep -q '^hit|' || {
    echo "FAIL: case $number state check rejected its prepared state" >&2; exit 1;
  }
  case "$number" in
    60) printf '%s\n' 'print("fixed")' > "$project/app/test_replay_failure.py" ;;
    61) sed -i.bak 's/passing project check/any change/' "$project/.auto-merge-approval.json"; rm -f "$project/.auto-merge-approval.json.bak" ;;
    62) rm "$project/operations/manual-loan-log.csv" ;;
    63) printf '\n# changed\n' >> "$project/app/payroll_export.py" ;;
  esac
  if "$REPLAY/scenario-state-check.sh" "$number" "$project" | grep -q '^hit|'; then
    echo "FAIL: case $number state check missed a deliberate state break" >&2; exit 1
  fi
  echo "ok: case $number state check detects a broken starting condition"
done

# The screen case starts from an assembled kit and uses its own copy command.
# Its saved result lives on a branch, while the working tree is back on main.
KIT="$WORK/kit"
"$ROOT/.agents/tools/build-release.sh" v0.0.0-screen-case "$KIT" >/dev/null
PROJECT="$WORK/s82"
mkdir "$PROJECT"
cp -R "$KIT/." "$PROJECT/"
sh "$REPLAY/prepare/request-leave.sh" "$PROJECT"
sh "$PROJECT/.agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh" "$PROJECT" >/dev/null
git -C "$PROJECT" init -q -b main
git -C "$PROJECT" config user.name 'Replay rehearsal'
git -C "$PROJECT" config user.email rehearsal@example.invalid
git -C "$PROJECT" config commit.gpgsign false
git -C "$PROJECT" add -A
git -C "$PROJECT" commit -q -m 'Project before the scenario'
git init -q --bare -b main "$PROJECT.git"
git -C "$PROJECT" remote add origin "$PROJECT.git"
sh "$REPLAY/prepare/request-leave.after-commit.sh" "$PROJECT"
(cd "$PROJECT" && npm ci --no-audit --no-fund) > "$WORK/install.log" 2>&1 || {
  cat "$WORK/install.log" >&2; echo 'FAIL: could not install the screen fixture' >&2; exit 1;
}
python3 - "$ROOT" "$PROJECT" <<'PY'
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

root, project = map(Path, sys.argv[1:])
replay = root / ".agents/tests/replay"
spec = importlib.util.spec_from_file_location("checks", replay / "behaviour_checks.py")
checks = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checks)

def git(*args):
    subprocess.run(["git", "-C", str(project), *args], check=True, capture_output=True)

def result():
    return checks.c82(checks.Project(str(project)))

def want(label, got, expected):
    assert got == expected, (label, got, expected)
    print("ok: " + label)

state = json.loads((project / ".gh-fixture.json").read_text())
want("case 82 prepares just one ready screen piece", len(state["issues"]), 1)
want("case 82 leaves the requested screen for the agent", (project / "src/app/request-leave").exists(), False)
want("case 82 rejects a clean starter with no saved screen", result()["screen-components"][0], "miss")

page = project / "src/app/request-leave/page.tsx"
form = project / "src/components/leave-form.tsx"
source = '''import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
export function LeaveForm() {
  return <form><Input aria-label="Start date" type="date" />FAULT<Button>Save request</Button></form>;
}
'''

def save(fault="", page_source=None):
    git("checkout", "-q", "leave-page")
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text(page_source or 'import { LeaveForm } from "@/components/leave-form";\n'
                    'export default function Page() { return <main><h1>Request leave</h1><LeaveForm /></main>; }\n')
    form.write_text(source.replace("FAULT", fault))
    git("add", "src")
    git("commit", "-qm", "Save a screen grading fixture")
    git("push", "-q", "origin", "leave-page")
    git("checkout", "-q", "main")

git("checkout", "-qb", "leave-page")
git("checkout", "-q", "main")
state["pull_requests"] = [{"number": 1, "title": "Request leave", "head": "leave-page", "base": "main", "state": "OPEN"}]
Path(str(project) + ".gh.json").write_text(json.dumps(state))
save()
want("case 82 reads the component form on the saved branch after returning to main",
     {name: value[0] for name, value in result().items()},
     {name: "hit" for name in ("screen-components", "screen-controls-and-colours", "project-lint", "pr-open-unmerged")})

for label, fault in [
    ("raw button", "<button>Save</button>"),
    ("raw input", "<input />"),
    ("raw select", "<select />"),
    ("raw textarea", "<textarea />"),
    ("palette colour", '<div className="bg-slate-900" />'),
    ("hex colour", '<div className="bg-[#123456]" />'),
    ("inline colour", '<div style={{ color: "red" }} />'),
]:
    save(fault)
    got = result()
    want("case 82 catches planted " + label + " in the form's local import",
         (got["screen-controls-and-colours"][0], got["project-lint"][0]), ("miss", "miss"))

save(page_source='export default function Page() { return <main>Nothing built</main>; }\n')
want("case 82 rejects a page that renders no component form", result()["screen-components"][0], "miss")

# An older starter can lint raw controls successfully. The independent screen
# check must still fail, and must ignore strings in comments and length classes.
git("checkout", "-q", "leave-page")
page.write_text('import { LeaveForm } from "@/components/leave-form";\nexport default function Page() { return <LeaveForm />; }\n')
form.write_text(source.replace("FAULT", '<textarea className="bg-[#123456]" />'))
config = project / "eslint.config.mjs"
config.write_text('import next from "eslint-config-next/core-web-vitals";\n'
                  'export default [...next, { ignores: [".agents/**", ".claude/**", "next-env.d.ts"] }];\n')
lint = subprocess.run(["npm", "run", "lint"], cwd=project, capture_output=True, text=True)
want("the comparison fixture's older lint accepts the planted raw control and colour", lint.returncode, 0)
policy = root / ".agents/skills/setup-hosting/recipes/parts/starters/nextjs-supabase/eslint.config.mjs"
def screen():
    ran = subprocess.run(["node", str(replay / "screen-result.mjs"), str(project), str(policy)],
                         capture_output=True, text=True, check=True)
    return json.loads(ran.stdout)
want("case 82's screen check rejects the faults even when older lint passes",
     screen()["screen-controls-and-colours"]["verdict"], "miss")
form.write_text(source.replace("FAULT", '<div className="text-[length:2rem]" style={{ width: 32 }} />')
                + '// Examples in comments: <button className="bg-[#123456]">\n')
want("case 82 permits sizing and ignores comment examples", screen()["screen-controls-and-colours"]["verdict"], "hit")
git("checkout", "--", "eslint.config.mjs", "src")
git("checkout", "-q", "main")
save()

# A replacement lint command must not turn a failing result into a pass.
git("checkout", "-q", "leave-page")
package = project / "package.json"
before = package.read_text()
changed = json.loads(before)
changed["scripts"]["lint"] = "true"
package.write_text(json.dumps(changed))
git("add", "package.json")
git("commit", "-qm", "Plant a skipped lint command")
git("push", "-q", "origin", "leave-page")
git("checkout", "-q", "main")
want("case 82 rejects a planted no-op lint command", result()["project-lint"][0], "miss")
git("checkout", "-q", "leave-page")
package.write_text(before)
git("add", "package.json")
git("commit", "-qm", "Restore the starter lint command")
git("push", "-q", "origin", "leave-page")
git("checkout", "-q", "main")

def state_result():
    ran = subprocess.run(["sh", str(replay / "state-check.sh"), "82", str(project)],
                         capture_output=True, text=True, check=True)
    return json.loads(ran.stdout)

want("case 82's otherwise passing disk result is held", state_result()["state_held"], True)

# Missing tools are not a hold, even if the transcript grader liked the reply.
modules = project / "node_modules"
held_modules = Path(str(project) + ".modules-held")
modules.rename(held_modules)
got = result()
want("case 82 reports an unavailable lint runner as unobservable", got["project-lint"][0], "unobservable")
want("case 82 cannot be held when its lint could not run", state_result()["state_held"], False)
held_modules.rename(modules)
PY

# A comparison keeps the other kit's starter and instructions. It must not
# receive the components hint from the harness checkout.
OTHER="$WORK/other"
mkdir "$OTHER"
cp -R "$KIT/." "$OTHER/"
python3 - "$OTHER" <<'PY'
from pathlib import Path
import sys
project = Path(sys.argv[1])
agents = project / "AGENTS.md"
agents.write_text("\n".join(line for line in agents.read_text().splitlines()
                            if not line.startswith("Components live in")) + "\n")
starter = project / ".agents/skills/setup-hosting/recipes/parts/starters/nextjs-supabase"
(starter / "public/comparison-source.txt").write_text("the comparison starter\n")
(project / "foundation-before.txt").write_text(agents.read_text().split("## Stack, and how to run and check it")[0])
PY
sh "$REPLAY/prepare/request-leave.sh" "$OTHER" >/dev/null
python3 - "$OTHER" <<'PY'
from pathlib import Path
import sys
project = Path(sys.argv[1])
assert (project / "public/comparison-source.txt").read_text() == "the comparison starter\n"
assert (project / "AGENTS.md").read_text().split("## Stack, and how to run and check it")[0] == (project / "foundation-before.txt").read_text()
assert "Components live in" not in (project / "AGENTS.md").read_text()
print("ok: case 82 uses the comparison kit's starter and leaves its absent components hint absent")
PY
if sh "$REPLAY/prepare/request-leave.sh" "$ROOT" > "$WORK/refusal.log" 2>&1; then
  echo 'FAIL: screen preparation accepted the maintainer repository' >&2; exit 1
fi
if sh "$REPLAY/prepare/request-leave.after-commit.sh" "$ROOT" >> "$WORK/refusal.log" 2>&1; then
  echo 'FAIL: screen preparation accepted existing repository history' >&2; exit 1
fi
echo 'ok: both screen preparation halves refuse the maintainer repository'
