#!/usr/bin/env sh
# document-read-rehearsal.sh: run the shipped document-claims script against a
# throwaway project whose documents name things that are gone, and things that
# are not.
#
# Each of the four kinds of stale name has to be found at its line: a file, a
# link, a command and an environment variable. Just as much, nothing true may be
# flagged: a file that exists, a command the project has, a setting the code
# reads, a file git ignores on purpose, and a document that simply says less
# than the project does. A document AGENTS.md never points at is not read at
# all. A clean project produces no output, and the script writes nothing.
#
# A piece's changelog file in `changes/` is part of the changelog: never read
# as a document, and never stale once the last fold has taken it away.
#
# The false-positive half is the one that matters most. A read that flags true
# things gets ignored, and then the stale name it also found is ignored with it.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/sync/scripts/document-claims.py"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[ -x "$SCRIPT" ] || fail "the document-claims script is missing or not runnable"
command -v python3 >/dev/null 2>&1 || fail "python3 is needed to run this rehearsal"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PROJECT="$WORK/project"
mkdir -p "$PROJECT/src" "$PROJECT/docs"
cd "$PROJECT"

commit() {
  git -c user.name=Rehearsal -c user.email=rehearsal@example.invalid \
    commit -q -m "$1"
}

git init -q
printf '%s\n' '{"name":"shop","scripts":{"dev":"node src/index.js","test":"node --test"}}' > package.json
printf '%s\n' 'const key = process.env.SHOP_API_KEY;' > src/index.js
printf '%s\n' '.env' > .gitignore
printf '%s\n' '# Agents' '' 'Setup is in `docs/setup.md`. Read [the workflow](WORKFLOW.md) too.' > AGENTS.md
printf '%s\n' '# How this project runs' '' 'It names `gone/by/design.js`, and is the kit'"'"'s, not the project'"'"'s.' > WORKFLOW.md
printf '%s\n' '# Unlisted notes' '' 'Nothing points here, so `missing/unlisted.js` is never read.' > docs/unlisted.md
cat > docs/setup.md <<'EOF'
# Setup

Copy `.env` and set `SHOP_API_KEY`.
EOF
cat > README.md <<'EOF'
# Shop

It sells things. Each finished piece's entry waits in `changes/` until it is folded into the changelog.
EOF
git add -A
commit "A project whose documents are true"

# --- a clean project --------------------------------------------------------

out=$(python3 "$SCRIPT")
[ -z "$out" ] || fail "a clean project should produce nothing, got: $out"
echo "  ok: documents that name only real things produce nothing"
[ -z "$(git status --porcelain)" ] || fail "the script wrote into the project"
echo "  ok: the script writes nothing"

# --- stale names, beside true ones ------------------------------------------

cat > README.md <<'EOF'
# Shop

Start it with `npm run dev`, then `npm run serve` for the preview.

Set `SHOP_API_KEY` and `PAYMENT_SECRET_KEY` before the first run.

The entry point is `src/index.js`. Deployment lives in `scripts/deploy.sh`.
See [the setup guide](docs/setup.md) and [the old notes](docs/old.md).

```sh
npm run test
```

Type `/implement` to build. The code is at `owner/shop` and `github.com/owner/shop`, the entry file is `index.js`, and releases use `release.sh`.

The last fold took in `changes/12-old-login.md`.
EOF
# A piece's changelog file is part of the changelog. It is never read as a
# document, even when AGENTS.md names it, and a name in `changes/` that the last
# fold took away is not stale.
mkdir -p changes
printf '%s\n' 'Signing in now remembers you, as `src/remember.js` does.' > changes/7-sign-in.md
printf '%s\n' '' 'The newest entry is `changes/7-sign-in.md`.' >> AGENTS.md
git add -A
commit "The README drifts"

out=$(python3 "$SCRIPT")
printf '%s\n' "$out" | sed 's/^/    /'

expect() {
  printf '%s\n' "$out" | grep -qF "$(printf '%s\t%s\t%s' "$1" "$2" "$3")" ||
    fail "expected $2 '$3' at $1"
  echo "  ok: the stale $2 '$3' is named at $1"
}
expect README.md:3 command 'npm run serve'
expect README.md:5 'environment variable' PAYMENT_SECRET_KEY
expect README.md:7 file scripts/deploy.sh
expect README.md:8 link docs/old.md

expect README.md:14 file release.sh

[ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = 5 ] ||
  fail "expected exactly five findings, got: $out"
echo "  ok: nothing true is flagged: a real file, command, link and setting, and an ignored .env"
echo "  ok: a slash command, a repository name and a web address are not taken for files"
echo "  ok: a bare file name kept in a folder is found there"

printf '%s\n' "$out" | grep -q 'unlisted' && fail "a document AGENTS.md never points at was read"
printf '%s\n' "$out" | grep -q 'gone/by/design' && fail "the kit's own WORKFLOW.md was read"
printf '%s\n' "$out" | grep -q 'changes' && fail "a changelog file in changes/ was read or reported"
echo "  ok: the changes/ folder and the files in it are part of the changelog, never reported"
echo "  ok: only the README and the documents AGENTS.md points at are read"

printf '%s\n' "$out" | grep -qE '[0-9]+ *%|score|grade' && fail "a score reached the output"
echo "  ok: no score, grade or percentage"

[ -z "$(git status --porcelain)" ] || fail "the script wrote into the project"
echo "  ok: the script still writes nothing"

# --- the document changed longest ago comes first ---------------------------

printf '%s\n' 'Run `make release` to ship.' >> docs/setup.md
git add -A
commit "The setup guide drifts"
printf '%s\n' 'const extra = 1;' > src/extra.js
git add -A
commit "Later work"
printf '%s\n' '' 'Nothing else.' >> README.md
git add -A
commit "The README is touched again"
: > Makefile
git add -A
commit "A Makefile arrives with no release target"

first=$(python3 "$SCRIPT" | head -1)
case "$first" in
  docs/setup.md:*) echo "  ok: the document changed longest ago is listed first" ;;
  *) fail "expected docs/setup.md first, got: $first" ;;
esac
python3 "$SCRIPT" | grep -qF "$(printf 'docs/setup.md:4\tcommand\tmake release')" ||
  fail "a make target the Makefile does not have was not named"
echo "  ok: a make target the Makefile does not have is named"

# --- the concept list: AGENTS.md points at docs/README.md, which lists them ---

# A founded project lists its concept files in docs/README.md and points at
# that list from AGENTS.md, so a concept file is read through the list. A file
# in docs/ the list does not name, such as a whole copy's own documents, is not.
printf '%s\n' '# Concept files' '' '- `sign-in.md`: how signing in works.' > docs/README.md
printf '%s\n' '# Sign-in' '' '## Where it lives' '' 'In `src/sign-in.js`.' > docs/sign-in.md
printf '%s\n' '' 'Concept files are listed in `docs/README.md`.' >> AGENTS.md
git add -A
commit "A concept list and one concept file"
out=$(python3 "$SCRIPT")
printf '%s\n' "$out" | grep -qF "$(printf 'docs/sign-in.md:5\tfile\tsrc/sign-in.js')" ||
  fail "a concept file listed in docs/README.md was not read: $out"
echo "  ok: a concept file listed in docs/README.md is read through the list"
printf '%s\n' "$out" | grep -q 'unlisted' && fail "a docs file the list does not name was read"
echo "  ok: a file in docs/ the list does not name is still not read"
[ -z "$(git status --porcelain)" ] || fail "the script wrote into the project"

echo
echo "document-read-rehearsal.sh: stale names found at their lines, true ones left alone"

# Explicit declarations: names can remain while their route stops calling them.
python3 - "$SCRIPT" "$WORK" <<'PY'
import ast
import hashlib
import json
from pathlib import Path
import subprocess
import sys

script, work = map(Path, sys.argv[1:])
project = work / "wiring"
project.mkdir()
(project / "AGENTS.md").write_text("Required check: `npm run guard` via `npm run check`.\n")
(project / "README.md").write_text("Required command: `pnpm run guard`.\n")
package = project / "package.json"

def scripts(route):
    package.write_text(json.dumps({"scripts": {"check": route, "guard": "node --test", "unit": "node --test"}}))

def snapshot():
    return {str(p.relative_to(project)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in project.rglob("*") if p.is_file()}

def run(detector=script):
    before = snapshot()
    result = subprocess.run([sys.executable, str(detector)], cwd=project,
                            capture_output=True, text=True, check=True)
    assert snapshot() == before, "detector changed project files"
    return result.stdout

scripts("npm run guard && pnpm run unit")
assert run() == "", "intact route produced findings"
unchanged = (project / "AGENTS.md").read_bytes()
scripts("npm run unit")
broken = run()
assert "AGENTS.md:1\twiring mismatch\t" in broken, broken
assert "npm run check" in broken and "npm run guard" in broken, broken
assert "package.json scripts.check" in broken and "npm run unit" in broken, broken
assert (project / "AGENTS.md").read_bytes() == unchanged
print("  ok: changed route with unchanged document names the missing check and inspected evidence")
package.write_text(json.dumps({"scripts": {"check": "pnpm run bridge", "bridge": "yarn run guard", "guard": "node --test"}}))
assert run() == "", "transitive intact route produced findings"
package.write_text(json.dumps({"scripts": {"check": "pnpm run bridge", "bridge": "true", "guard": "node --test"}}))
assert "wiring mismatch" in run() and "scripts.bridge" in run()
scripts("npm run unit")
print("  ok: transitive package edges are inspected and a removed middle edge is named")

# Removing the production detector must remove the broken finding.
source = script.read_text()
tree = ast.parse(source)
function = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "wiring_claims")
lines = source.splitlines(keepends=True)
lines[function.lineno - 1:function.end_lineno] = ["def wiring_claims(document, scripts):\n    return []\n"]
mutant = work / "without-wiring.py"
mutant.write_text("".join(lines))
assert "wiring mismatch" not in run(mutant), "removing detector did not defeat broken case"
print("  ok: removing detection defeats the broken case")

(project / "AGENTS.md").write_text("Required check: `yarn run guard` via `pnpm run check` when file `care.flag` exists.\n")
inactive = run()
assert "inactive rule" in inactive and "wiring mismatch" not in inactive, inactive
(project / "care.flag").write_text("active")
active = run()
assert "wiring mismatch" in active, active
scripts("yarn run guard")
assert run() == "", "active intact route produced findings"
(project / "AGENTS.md").write_text("Required check: `npm run guard` via `npm run check` when the project handles money.\n")
unknown = run()
assert "unverified rule" in unknown and "condition" in unknown and "wiring mismatch" not in unknown, unknown
print("  ok: inactive, active broken, active intact and indeterminate conditions stay distinct")

(project / "AGENTS.md").write_text(unchanged.decode())
for route in ('sh scripts/check.sh', 'npm run "$CHECK"', 'npm run guard || true',
              'echo "npm run guard"', 'npm run guard && sh scripts/extra.sh',
              'npm run check'):
    scripts(route)
    out = run()
    assert "unverified rule" in out and "wiring mismatch" not in out, (route, out)
package.write_text(json.dumps({"scripts": {"check": "npm run unit", "unit": "node --test", "guard": "node --test", "precheck": "npm run guard"}}))
assert "unverified rule" in run() and "wiring mismatch" not in run()
package.write_text(json.dumps({"scripts": {"check": "npm run guard", "guard": None}}))
assert "unverified rule" in run() and "wiring mismatch" not in run()
print("  ok: shell indirection, lifecycle hooks, malformed check entries and cycles remain unverified")

(project / "AGENTS.md").write_text("Required check: run all important checks through the normal route.\n")
assert "unverified rule" in run()
(project / "AGENTS.md").write_text("Required command: `yarn run absent`.\n")
assert "wiring mismatch" in run() and "yarn run absent" in run()
package.write_text("not json")
assert "unverified rule" in run() and "wiring mismatch" not in run()
print("  ok: unsupported prose and unreadable mechanisms never become a pass")

scripts("npm run guard")
(project / "AGENTS.md").write_text("Required check: `npm run guard` via `npm run check` when file `../outside.flag` exists.\n")
assert "unverified rule" in run()
(project / "outside-link").symlink_to(work)
(project / "AGENTS.md").write_text("Required check: `npm run guard` via `npm run check` when file `outside-link/flag` exists.\n")
assert "unverified rule" in run()
print("  ok: conditions cannot inspect outside the project")

# Install layouts use the installed sync folder, including a path with spaces.
(project / "AGENTS.md").write_bytes(unchanged)
scripts("npm run unit")
for relative in (".agents/skills/sync", ".claude/skills/sync", "plugin cache/skills/sync", "agent-plugin/skills/sync"):
    installed = work / relative / "scripts/document-claims.py"
    installed.parent.mkdir(parents=True, exist_ok=True)
    installed.write_text(source)
    assert run(installed) == broken, relative
print("  ok: detector works from shared, Claude-only and external plugin layouts")
# Project scripts and a configured Git hook would leave a marker if executed.
subprocess.run(["git", "init", "-q"], cwd=project, check=True)
subprocess.run(["git", "add", "AGENTS.md", "README.md", "package.json"], cwd=project, check=True)
(project / "README.md").write_text("The entry point is `missing.js`.\n")
hooks = project / ".git/hooks"
hook = hooks / "watch"
hook.write_text("#!/bin/sh\ntouch hook-ran\n")
hook.chmod(0o755)
subprocess.run(["git", "config", "core.fsmonitor", str(hook)], cwd=project, check=True)
subprocess.run(["git", "config", "core.hooksPath", str(hooks)], cwd=project, check=True)
(project / "danger.sh").write_text("touch script-ran\n")
scripts("sh danger.sh")
sentinel_out = run()
assert "unverified rule" in sentinel_out and "missing.js" in sentinel_out
assert not (project / "hook-ran").exists() and not (project / "script-ran").exists()
print("  ok: project scripts and configured Git hooks leave no execution marker")

# The selected documentation boundary also applies to relationship declarations.
(project / "AGENTS.md").write_text("See `docs/selected.md`.\n")
(project / "docs").mkdir()
claim = "Required check: `npm run guard` via `npm run check`.\n"
(project / "docs/selected.md").write_text(claim)
(project / "docs/unselected.md").write_text(claim)
scripts("npm run unit")
assert "docs/selected.md:1\twiring mismatch" in run()
assert "unselected" not in run()
(project / "README.md").write_text("```text\n" + claim + "```\n")
assert "README.md" not in run()
external = work / "external.md"
external.write_text(claim)
(project / "docs/selected.md").unlink()
(project / "docs/selected.md").symlink_to(external)
assert run() == "", "external document was inspected"
package.unlink()
external_package = work / "external-package.json"
external_package.write_text(json.dumps({"scripts": {"check": "npm run guard", "guard": "true"}}))
package.symlink_to(external_package)
(project / "AGENTS.md").write_text(claim)
assert "unverified rule" in run()
print("  ok: selected documents are read, fenced examples and outside documents are left alone")
print("  ok: every fixture kept its files unchanged; no project scripts or hooks were executed")
PY
