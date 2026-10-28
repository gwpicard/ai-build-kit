#!/usr/bin/env sh
# approval-gate.sh: the one approval gate lets a named online change through only on the person's recorded yes for exactly that change, once.
#
# merge.py and the recipe steps that change something live call it, and their
# own rehearsals prove they stop without it. This proves the gate itself: a
# yes needs the person's words, names one change, is spent when used, and is
# kept in the project's Git folder, never in a tracked file.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
GATE="$ROOT/.agents/skills/records/scripts/approval.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
FAILED=0
fail() { echo "FAIL: $1" >&2; FAILED=1; }
pass() { echo "ok: $1"; }

git -C "$WORK" init -q project
cd "$WORK/project"

out=$(python3 "$GATE" use --step "promote dpl_1 abc" 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'no recorded approval for "promote dpl_1 abc"' \
  && pass "a change with no recorded yes is refused, and the refusal names the change" \
  || fail "no yes returned $code: $out"

out=$(python3 "$GATE" yes "promote dpl_1 abc" 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "a yes without the person's words is not recorded" || fail "a yes with no words returned $code: $out"

python3 "$GATE" yes "promote dpl_1 abc" --words "yes, put that build live" >/dev/null
out=$(python3 "$GATE" use --step "promote dpl_2 def" 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && pass "a yes for one change does not open another" || fail "another change returned $code: $out"

out=$(python3 "$GATE" use --step "promote dpl_1 abc" 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s' "$out" | grep -q 'yes, put that build live' \
  && pass "the named change goes through on its yes, quoting the person's words" || fail "the named change returned $code: $out"
out=$(python3 "$GATE" use --step "promote dpl_1 abc" 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && pass "a yes is spent once used" || fail "a spent yes returned $code: $out"

[ -f .git/ai-build-kit-approvals ] && [ -z "$(git status --porcelain)" ] \
  && pass "the record lives in the Git folder, so nothing tracked changes" || fail "the record was not kept in the Git folder"

python3 - "$ROOT" "$WORK" <<'PY' && pass "recipe steps spend only their own approval, once" \
  || fail "recipe approval names or spending did not hold"
from pathlib import Path
import shutil
import subprocess
import sys

root, work = map(Path, sys.argv[1:])
project = work / "steps"
project.mkdir()
subprocess.run(["git", "init", "-q", str(project)], check=True)
skills = project / ".agents/skills"
scripts = skills / "setup-hosting/recipes/parts/scripts"
scripts.mkdir(parents=True)
gate = skills / "records/scripts/approval.py"
gate.parent.mkdir(parents=True)
shutil.copyfile(root / ".agents/skills/records/scripts/approval.py", gate)
shutil.copyfile(root / ".agents/skills/setup-hosting/recipes/parts/scripts/check-lib.sh",
                scripts / "check-lib.sh")
step = scripts / "migrate.sh"
step.write_text('#!/bin/sh\nset -eu\n. "$(dirname -- "$0")/check-lib.sh"\n'
                'cl_approved\nprintf "changed\\n" >> changes\ncl_pass "The step ran."\n')


def run(*args, code=0):
    result = subprocess.run(args, cwd=project, capture_output=True, text=True)
    assert result.returncode == code, (args, result.returncode, result.stdout, result.stderr)
    return result.stdout + result.stderr


def record(change, words="yes, apply the migration"):
    return run("python3", str(gate), "yes", change, "--words", words)


def unspent():
    return run("python3", str(gate), "list")


record("promote --apply", "put that build live")
before = unspent()
run("sh", str(step), "--apply", code=2)
assert unspent() == before and not (project / "changes").exists()
record("migrate --apply")
before = unspent()
out = run("python3", str(gate), "use", "migrate --apply", code=2)
assert "a step spends its own approval" in out and "run the step itself" in out
assert unspent() == before
run("sh", str(step), "--apply")
run("sh", str(step), "--apply", code=2)
assert (project / "changes").read_text() == "changed\n"

out = record("  migrate.sh   --apply  ")
assert "recorded for migrate --apply; the step spends it when it runs" in out
assert "\tmigrate --apply\t" in unspent() and "migrate.sh" not in unspent()
run("sh", str(step), "--apply")
record("./.agents/skills/setup-hosting/recipes/parts/scripts/migrate.sh --apply")
run("sh", str(step), "--apply")
# A row an older gate wrote under the script's file name still matches, once.
record_file = Path(run("git", "rev-parse", "--absolute-git-dir").strip()) / "ai-build-kit-approvals"
with open(record_file, "a") as handle:
    handle.write("2026-10-27\tmigrate.sh --apply\tyes, apply it\n")
run("sh", str(step), "--apply")
run("sh", str(step), "--apply", code=2)
# The gate also normalises a caller's name and whitespace.
record("migrate --apply")
run("python3", str(gate), "use", " ./somewhere/migrate.sh   --apply ", "--step")

record("migrate.sh --apply 20261005090000_x.sql", "yes, apply only that file")
before = unspent()
out = run("sh", str(step), "--apply", code=2)
assert unspent() == before
assert 'unspent "migrate --apply 20261005090000_x.sql", recorded words: "yes, apply only that file"' in out
assert 'approval.py yes "migrate --apply" --words "<their words>"' in out
assert "ask the person only if they do not" in out
assert (project / "changes").read_text() == "changed\n" * 4
# Combining the streams preserves the step's final sentence as the last line.
result = subprocess.run(["sh", str(step), "--apply"], cwd=project,
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
assert result.returncode == 2
assert 'approval.py yes "migrate --apply"' in result.stdout.splitlines()[-1]
assert len(result.stdout.splitlines()[-1].split(". ")) == 1
for number in range(4):
    record("migrate --apply file%s.sql" % number, "approve file %s" % number)
before = unspent()
out = run("python3", str(gate), "use", "migrate --apply", "--step", code=1)
assert out.count("approval: unspent ") == 3 and unspent() == before
PY

# Callers at once must not both spend one yes. Each round records one yes and
# starts four callers together. Exactly one may pass.
cd "$WORK"
RACE=$(mktemp)
cat > "$RACE" <<'RACE_END'
import subprocess, sys, tempfile, threading
gate = sys.argv[1]
for _ in range(40):
    with tempfile.TemporaryDirectory() as folder:
        subprocess.run(["git", "init", "-q", folder], check=True)
        subprocess.run(["python3", gate, "yes", "publish", "--words", "yes"], cwd=folder,
                       stdout=subprocess.DEVNULL, check=True)
        start = threading.Barrier(5)
        codes = []
        def use():
            start.wait()
            codes.append(subprocess.run(["python3", gate, "use", "publish", "--step"], cwd=folder,
                                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode)
        workers = [threading.Thread(target=use) for _ in range(4)]
        for worker in workers:
            worker.start()
        start.wait()
        for worker in workers:
            worker.join()
        if codes.count(0) != 1:
            sys.exit(1)
RACE_END
python3 "$RACE" "$GATE" && pass "four simultaneous callers spend one yes only once" \
  || fail "one yes was spent more than once by simultaneous callers"
rm -f "$RACE"
cd "$WORK/project"

mkdir -p "$WORK/plain"
out=$(cd "$WORK/plain" && python3 "$GATE" use --step "merge pull request 1" 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "outside a project the gate could not run, and nothing goes through" || fail "outside a project returned $code: $out"

[ "$FAILED" -eq 0 ] && echo "approval-gate.sh: all checks passed"
exit "$FAILED"
