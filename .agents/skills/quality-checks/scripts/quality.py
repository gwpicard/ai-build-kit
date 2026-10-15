#!/usr/bin/env python3
"""Run the code-quality engines on a project and print what they find.

Run it from inside the project. Five reads:

    quality.py trim --base COMMIT [--fetch]
        What the change since COMMIT added that nothing needs.
    quality.py waste [--skip-offered] [--fetch]
        Copied code, unused code and unused dependencies across the project.
    quality.py loops (--base COMMIT | --skip-offered) [--reader auto|builtin]
        Import loops that were not there at COMMIT, or every loop in the
        project that no earlier visit offered.
    quality.py reach (--paths FILE... | --base COMMIT) [--piece N] [--run]
        Files, routes, tables and covering tests reached by a change.
    quality.py strength --base COMMIT [--fetch]
        Break the code changed since COMMIT on purpose, in a throwaway copy,
        and count how often the tests notice.
    quality.py tests --base COMMIT --piece NUMBER
        Run the red commit's tests before the change, map promises to tests,
        and list changed code lines that the tests did not run.
    quality.py offered (waste | loops) < LINES
        Record the finding lines on standard input as offered to the person.

Each finding is one line of fields separated by tabs. The first field says
what kind of line it is, and a place is always FILE:LINE. A `not-checked`
line names a part of the read that did not run, and why. The agent reads
that part of the code directly instead, which is the last resort.

Exit codes for the existing reads:

    0  nothing found, and every part of the read that applies ran
    1  findings printed, and every part of the read that applies ran
    2  a part could not run: not a project under Git, a commit that does not
       exist, or a part with no engine. Findings from the parts that did run
       are still printed.

For reach, the list is information unless `--piece` prints an `undeclared`
line, which returns 1. Under `--run`, exit 1 also means a covering test failed.
Exit 2 means Git, the undeclared check or a required test runner could not run.

It writes nothing into the project, apart from `offered`. Engines are taken
from the project's own `node_modules/.bin` or virtual environment, then from
PATH. With --fetch, a missing JavaScript engine is fetched for this run with
npx, and a missing Python engine with uvx or pipx, without adding it to the
project.

--skip-offered leaves out each finding an earlier visit offered the person,
as `offered` recorded it in `.ai-build-kit-maintenance`. A finding that never
reached the person, because it did not fit under the cap or its read failed,
comes back at the next visit.

Which paths are tests comes from the one rule check-tests.sh holds, in the
setup-ai-build-kit skill beside this one, so this script, trim-commit.sh and
the project check cannot disagree.
"""

import argparse
import ast
import csv
import fnmatch
import json
import os
import re
import shutil
import shlex
import subprocess
import sys
import tempfile
from datetime import date

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from reaches_line import REACHES_LINE  # noqa: E402

LIMIT = 15  # lizard's documented warning for cyclomatic complexity
JS_EXT = (".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs", ".mts", ".cts")
SOURCE_EXT = JS_EXT + (".py",)
SKIP_DIRS = {"node_modules", ".git", ".venv", "venv", "__pycache__", "dist",
             "build", ".next", "coverage"}
KIT_DIRS = {".agents", ".claude", ".cursor", ".gemini", ".codex", ".github",
            ".claude-plugin", "agent-plugin"}
# Engine output the strength read writes at the top of its throwaway copy.
TOP_LEVEL_OUTPUT = {"reports", "mutants", ".stryker-tmp"}
LOCKFILES = {"package-lock.json", "pnpm-lock.yaml", "yarn.lock", "bun.lockb",
             "bun.lock", "poetry.lock", "uv.lock", "Pipfile.lock"}
RECORD = ".ai-build-kit-maintenance"
TEST_RULE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..",
                         "setup-ai-build-kit", "templates", "foundation", "check-tests.sh")


def test_rule():
    """The test-path rule from check-tests.sh, or None when it cannot be read."""
    try:
        with open(TEST_RULE, encoding="utf-8") as handle:
            match = re.search(r"^TEST_PATH='([^']+)'$", handle.read(), re.M)
        return re.compile(match.group(1)) if match else None
    except (OSError, re.error):
        return None


TEST_PATH = test_rule()
TEST_FILE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..",
                              "setup-ai-build-kit", "templates", "foundation", "check-tests.sh")


def test_file_rule():
    try:
        with open(TEST_FILE_PATH, encoding="utf-8") as handle:
            match = re.search(r"^TEST_FILE_PATH='([^']+)'$", handle.read(), re.M)
        return re.compile(match.group(1)) if match else None
    except (OSError, re.error):
        return None


TEST_FILES = test_file_rule()
QUALITY_FLOOR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                             "references", "check-floor.md")
ENGINES = {
    # name: (npm package, Python package)
    "knip": ("knip@6", None),
    "jscpd": ("jscpd@5", None),
    "depcruise": ("dependency-cruiser@18", None),
    "vitest": (None, None),
    "stryker": ("@stryker-mutator/core@9", None),
    "lizard": (None, "lizard>=1.24,<2"),
    "vulture": (None, "vulture"),
    "deptry": (None, "deptry"),
    "mutmut": (None, None),
}

# A wide reach is named once here so the shape and build reads use the same
# limits.
WIDE_DEPENDENTS = 10
WIDE_ROUTES = 3
WIDE_TABLE_FILES = 5


def is_test(path):
    return bool(TEST_PATH.search(path))


def is_test_file(path):
    return bool(TEST_FILES and TEST_FILES.search(path))


# --- what earlier visits offered -------------------------------------------------

def offered_keys(root, read_name):
    """The findings of READ_NAME an earlier visit recorded as offered."""
    keys = set()
    try:
        with open(os.path.join(root, RECORD), encoding="utf-8") as handle:
            for line in handle.read().splitlines():
                parts = line.split("|", 3)
                if len(parts) == 4 and parts[0] == "offered" and parts[1] == read_name:
                    keys.add(parts[3])
    except OSError:
        pass
    return keys


def record_offered(root, read_name, keys):
    """Add one `offered` line for each key, keeping every other line."""
    path = os.path.join(root, RECORD)
    try:
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
    except OSError:
        text = ""
    known = offered_keys(root, read_name)
    lines = [f"offered|{read_name}|{date.today().isoformat()}|{key}"
             for key in dict.fromkeys(keys) if key not in known]
    if lines:
        if text and not text.endswith("\n"):
            text += "\n"
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(text + "\n".join(lines) + "\n")
    return len(lines)


# --- running things ------------------------------------------------------------

def run(cmd, cwd=".", timeout=900, env=None):
    try:
        result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True,
                                timeout=timeout, env=env)
    except (OSError, subprocess.TimeoutExpired) as error:
        return 127, "", str(error)
    return result.returncode, result.stdout, result.stderr


def git(*args, cwd="."):
    code, out, _ = run(["git", *args], cwd=cwd)
    return out if code == 0 else None


class Engines:
    def __init__(self, root, fetch):
        self.root, self.fetch, self.used = root, fetch, {}

    def find(self, name):
        if name in self.used:
            return self.used[name]
        found = None
        for local in (os.path.join(self.root, "node_modules", ".bin", name),
                      os.path.join(self.root, ".venv", "bin", name),
                      os.path.join(self.root, "venv", "bin", name)):
            if os.access(local, os.X_OK):
                found = [local]
                break
        if not found and shutil.which(name):
            found = [shutil.which(name)]
        npm, py = ENGINES.get(name, (None, None))
        if not found and self.fetch and npm and shutil.which("npx"):
            found = ["npx", "--yes", f"--package={npm}", name]
        if not found and self.fetch and py:
            if shutil.which("uvx"):
                found = ["uvx", "--from", py, name]
            elif shutil.which("pipx"):
                found = ["pipx", "run", "--spec", py, name]
        self.used[name] = found
        return found


# --- the project ---------------------------------------------------------------

def project_files(root):
    out = git("ls-files", "-co", "--exclude-standard", cwd=root)
    if out is None:
        out = ""
        for folder, dirs, files in os.walk(root):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
            for name in files:
                out += os.path.relpath(os.path.join(folder, name), root) + "\n"
    files = []
    for path in out.splitlines():
        parts = path.split("/")
        if any(p in SKIP_DIRS | KIT_DIRS for p in parts[:-1]):
            continue
        if os.path.isfile(os.path.join(root, path)):
            files.append(path)
    return sorted(set(files))


def read(root, path):
    try:
        with open(os.path.join(root, path), encoding="utf-8") as handle:
            return handle.read()
    except (OSError, UnicodeDecodeError):
        return ""


def languages(root, files):
    js = os.path.isfile(os.path.join(root, "package.json"))
    py = any(f.endswith(".py") for f in files) or any(
        os.path.isfile(os.path.join(root, n))
        for n in ("pyproject.toml", "requirements.txt", "setup.py"))
    return js, py


def changed_lines(root, base):
    """Lines the change since BASE added or changed, per file, untracked included."""
    out = git("diff", "-U0", "--no-color", "--no-ext-diff", base, "--", ".", cwd=root)
    if out is None:
        return None
    changed, current = {}, None
    for line in out.splitlines():
        if line.startswith("+++ "):
            current = None if line == "+++ /dev/null" else line[6:].split("\t", 1)[0]
            if current:
                changed.setdefault(current, set())
        hunk = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@", line)
        if hunk and current:
            start = int(hunk.group(1))
            count = 1 if hunk.group(2) is None else int(hunk.group(2))
            changed[current].update(range(start, start + count))
    untracked = git("ls-files", "-o", "--exclude-standard", cwd=root) or ""
    for path in untracked.splitlines():
        lines = read(root, path).count("\n") + 1
        changed[path] = set(range(1, lines + 1))
    return changed


def uses_of(root, files, name, skip):
    """Whole-name uses of NAME outside imports and the places SKIP excludes."""
    needle = re.compile(r"(?<![\w$-])" + re.escape(name) + r"(?![\w$-])")
    uses = []
    for path in files:
        # The visit record names findings it offered, which is not a use.
        if os.path.basename(path) in LOCKFILES or path == RECORD:
            continue
        for number, text in enumerate(read(root, path).split("\n"), 1):
            if skip(path, number):
                continue
            if re.match(r"^\s*(import|from)\b", text) and not path.endswith(".json"):
                continue
            if needle.search(text):
                uses.append((path, number))
    return uses


def line_of(root, path, text):
    for number, line in enumerate(read(root, path).split("\n"), 1):
        if text in line:
            return number
    return 1


def snapshot(root, commit, folder):
    """The project as it was at COMMIT, in FOLDER, read from Git history only."""
    if git("clone", "-q", "--shared", "--no-checkout", root, folder) is None:
        return False
    if git("checkout", "-q", "--detach", commit, cwd=folder) is None:
        return False
    modules = os.path.join(root, "node_modules")
    if os.path.isdir(modules) and not os.path.exists(os.path.join(folder, "node_modules")):
        os.symlink(modules, os.path.join(folder, "node_modules"))
    return True


# --- engines -------------------------------------------------------------------

def knip(root, engines, notes, what):
    cmd = engines.find("knip")
    if not cmd:
        notes.append(("not-checked", what, "knip is not installed"))
        return None
    code, out, err = run(cmd + ["--include", "files,exports,dependencies",
                                "--reporter", "json", "--no-progress"], cwd=root)
    try:
        return json.loads(out[out.index("{"):])
    except ValueError:
        notes.append(("not-checked", what, "knip did not finish: " + (err.strip().split("\n") or [""])[-1][:120]))
        return None


def jscpd(root, engines, notes):
    cmd = engines.find("jscpd")
    if not cmd:
        notes.append(("not-checked", "copies", "jscpd is not installed"))
        return []
    with tempfile.TemporaryDirectory() as report:
        run(cmd + ["--ignore-identifiers", "--reporters", "json", "--output", report,
                   "--silent", "--ignore",
                   "**/node_modules/**,**/.git/**,**/.venv/**,**/venv/**", "."], cwd=root)
        try:
            with open(os.path.join(report, "jscpd-report.json")) as handle:
                data = json.load(handle)
        except (OSError, ValueError):
            notes.append(("not-checked", "copies", "jscpd did not finish"))
            return []
    pairs = []
    for clone in data.get("duplicates", []):
        a, b = clone["firstFile"], clone["secondFile"]
        name_a, name_b = os.path.relpath(os.path.join(root, a["name"]), root), os.path.relpath(os.path.join(root, b["name"]), root)
        if is_test(name_a) and is_test(name_b):
            continue
        pairs.append(((name_a, a["start"], a["end"]), (name_b, b["start"], b["end"])))
    return pairs


def vulture(root, engines, notes, confidence):
    cmd = engines.find("vulture")
    if not cmd:
        notes.append(("not-checked", "unused-code", "vulture is not installed"))
        return []
    code, out, err = run(cmd + ["--min-confidence", str(confidence), "--exclude",
                                ".venv,venv,node_modules,mutants", "."], cwd=root)
    if code not in (0, 1, 3):
        notes.append(("not-checked", "unused-code", "vulture did not finish"))
        return []
    found = []
    for line in out.splitlines():
        m = re.match(r"^(?:\./)?(.+?):(\d+): (.+?) \((\d+)% confidence", line)
        if not m:
            continue
        path, number, message = m.group(1), int(m.group(2)), m.group(3)
        # Unused imports and unused local names are the linter's to report.
        if message.startswith(("unused import", "unused variable")) or is_test(path):
            continue
        name = re.search(r"'([^']+)'", message)
        found.append((path, number, name.group(1) if name else message, message))
    return found


def deptry(root, engines, notes):
    if not any(os.path.isfile(os.path.join(root, n)) for n in ("pyproject.toml", "requirements.txt", "setup.py")):
        return []
    cmd = engines.find("deptry")
    if not cmd:
        notes.append(("not-checked", "unused-dependency", "deptry is not installed"))
        return []
    with tempfile.TemporaryDirectory() as folder:
        report = os.path.join(folder, "deptry.json")
        run(cmd + [".", "--json-output", report], cwd=root)
        try:
            with open(report) as handle:
                data = json.load(handle)
        except (OSError, ValueError):
            notes.append(("not-checked", "unused-dependency", "deptry did not finish"))
            return []
    found = []
    for item in data:
        if item.get("error", {}).get("code") != "DEP002":
            continue
        manifest = (item.get("location") or {}).get("file") or "pyproject.toml"
        manifest = os.path.relpath(os.path.join(root, manifest), root)
        found.append((manifest, line_of(root, manifest, item["module"]), item["module"]))
    return found


def lizard(root, engines, notes, files, folder=None):
    """Functions in FILES: {(file, name): (ccn, start, end)}. None when lizard is missing."""
    cmd = engines.find("lizard")
    if not cmd:
        notes.append(("not-checked", "functions", "lizard is not installed"))
        return None
    if not files:
        return {}
    where = folder or root
    code, out, _ = run(cmd + ["--csv", *files], cwd=where)
    functions = {}
    for cells in csv.reader(out.splitlines()):
        if len(cells) < 11 or not cells[1].isdigit():
            continue
        path = os.path.relpath(os.path.join(where, cells[6]), where)
        functions[(path, cells[7])] = (int(cells[1]), int(cells[9]), int(cells[10]))
    return functions


# --- trim and waste ------------------------------------------------------------

def unused_findings(root, files, engines, notes, js, py, confidence):
    """(kind, file, line, name, span) for unused code and dependencies."""
    found = []
    if js:
        report = knip(root, engines, notes, "unused-code")
        for issue in (report or {}).get("issues", []):
            for item in issue.get("exports", []) + issue.get("types", []):
                found.append(("unused-export", issue["file"], item.get("line", 1), item["name"]))
            for item in issue.get("files", []):
                path = item.get("name", issue["file"])
                found.append(("unused-file", path, 1, os.path.splitext(os.path.basename(path))[0]))
            for item in issue.get("dependencies", []):
                found.append(("unused-dependency", issue["file"],
                              line_of(root, issue["file"], f'"{item["name"]}"'), item["name"]))
    if py:
        for path, number, name, message in vulture(root, engines, notes, confidence):
            if message.startswith("unreachable"):
                found.append(("unreachable-code", path, number, "-"))
            else:
                found.append(("unused-code", path, number, name))
        for manifest, number, name in deptry(root, engines, notes):
            found.append(("unused-dependency", manifest, number, name))
    return found


def definition_span(root, path, line):
    """The lines of the function or class starting at LINE, by indentation and braces."""
    lines = read(root, path).split("\n")
    if line < 1 or line > len(lines):
        return (line, line)
    if path.endswith(".py"):
        indent = len(lines[line - 1]) - len(lines[line - 1].lstrip())
        end = line
        for number in range(line + 1, len(lines) + 1):
            text = lines[number - 1]
            if text.strip() and len(text) - len(text.lstrip()) <= indent:
                break
            if text.strip():
                end = number
        return (line, end)
    depth, seen = 0, False
    for number in range(line, len(lines) + 1):
        depth += lines[number - 1].count("{") - lines[number - 1].count("}")
        seen = seen or "{" in lines[number - 1]
        if seen and depth <= 0:
            return (line, number)
        if not seen and lines[number - 1].rstrip().endswith(";"):
            return (line, number)
    return (line, line)


def second_look(root, files, kind, path, line, name):
    """True when the finding survives a search for its name outside its own definition."""
    if kind == "unreachable-code":
        return True
    if kind == "unused-file":
        return not uses_of(root, files, name, lambda p, n: p == path)
    if kind == "unused-dependency":
        return not uses_of(root, files, name, lambda p, n: p == path)
    start, end = definition_span(root, path, line)
    return not uses_of(root, files, name, lambda p, n: p == path and start <= n <= end)


def imports_of(root, path):
    """Package names a source file imports."""
    text = read(root, path)
    if path.endswith(".py"):
        return {m.group(1).split(".")[0] for m in re.finditer(
            r"^\s*(?:from|import)\s+([\w.]+)", text, re.M)}
    names = set()
    for m in re.finditer(r"""(?:\bfrom\s*|\brequire\(\s*|\bimport\(\s*|^\s*import\s+)['"]([^'"]+)['"]""", text, re.M):
        spec = m.group(1)
        if spec.startswith(".") or spec.startswith("/"):
            continue
        parts = spec.split("/")
        names.add("/".join(parts[:2]) if spec.startswith("@") else parts[0])
    return names


def declared_dependencies(root, changed):
    """(manifest, line, name) for each dependency on a line the change touched."""
    found = []
    if "package.json" in changed:
        try:
            data = json.loads(read(root, "package.json"))
        except ValueError:
            data = {}
        for name in data.get("dependencies", {}):
            number = line_of(root, "package.json", f'"{name}"')
            if number in changed["package.json"]:
                found.append(("package.json", number, name))
    for manifest in ("pyproject.toml", "requirements.txt"):
        for number, text in enumerate(read(root, manifest).split("\n"), 1):
            if number not in changed.get(manifest, ()):
                continue
            m = re.match(r'^\s*"?([A-Za-z0-9][A-Za-z0-9._-]*)\s*(?:[<>=!~;\[" ]|$)', text)
            if m and "=" not in text.split(m.group(1))[0] and not text.strip().startswith(("[", "#")):
                if manifest == "pyproject.toml" and not text.strip().startswith('"'):
                    continue
                found.append((manifest, number, m.group(1)))
    return found


def trim(root, base, engines):
    if git("rev-parse", "--verify", "-q", base + "^{commit}", cwd=root) is None:
        print(f"not-checked\tall\t{base} is not a commit in this project")
        return 2
    changed = changed_lines(root, base)
    files = project_files(root)
    js, py = languages(root, files)
    notes, out = [], []
    hit = lambda path, line: line in changed.get(path, ())
    span_hit = lambda path, a, b: any(n in changed.get(path, ()) for n in range(a, b + 1))

    # Unused code, files and dependencies the change added, kept after a second look.
    for kind, path, line, name in unused_findings(root, files, engines, notes, js, py, 60):
        if is_test(path):
            continue
        if kind == "unused-file":
            if path not in changed:
                continue
        elif not hit(path, line):
            continue
        if second_look(root, files, kind, path, line, name):
            out.append(("remove", kind, f"{path}:{line}", name, "-"))

    # Wrappers with one user, and functions past the limit.
    sources = [f for f in files if f.endswith(SOURCE_EXT) and f in changed and not is_test(f)]
    now = lizard(root, engines, notes, sources)
    if now is not None:
        run_by_tests = reached_from(builtin_graph(root), [f for f in files if is_test(f)])
        for (path, name), (ccn, start, end) in sorted(now.items()):
            if not hit(path, start) or end <= start:
                continue
            body = [l.strip() for l in read(root, path).split("\n")[start:end if path.endswith(".py") else end - 1]]
            body = [l for l in body if l and l not in ("{", "}", "};")]
            if len(body) != 1 or not re.match(r"return .*[\w$]\(", body[0]):
                continue
            short = name.split("::")[-1].split(".")[-1]
            users = uses_of(root, files, short, lambda p, n: p == path and start <= n <= end)
            if len(users) != 1 or is_test(users[0][0]):
                continue
            user_file, user_line = users[0]
            # Folded only when a test runs the user: a test imports its file,
            # or a file that leads to it, resolved to the file itself.
            tested = user_file in run_by_tests
            out.append(("fold" if tested else "report", "one-user" if tested else "untested-one-user",
                        f"{path}:{start}", short, f"{user_file}:{user_line}"))

        before = {}
        with tempfile.TemporaryDirectory() as old:
            for path in sources:
                code, text, _ = run(["git", "show", f"{base}:{path}"], cwd=root)
                if code != 0:
                    continue
                os.makedirs(os.path.dirname(os.path.join(old, path)) or old, exist_ok=True)
                with open(os.path.join(old, path), "w", encoding="utf-8") as handle:
                    handle.write(text)
            before = lizard(old, engines, [], [p for p in sources if os.path.exists(os.path.join(old, p))], old) or {}
        for (path, name), (ccn, start, end) in sorted(now.items()):
            if ccn <= LIMIT or not span_hit(path, start, end):
                continue
            earlier = before.get((path, name))
            if earlier and ccn <= earlier[0]:
                continue
            out.append(("report", "over-limit", f"{path}:{start}", name.split("::")[-1],
                        "raised" if earlier else "new"))

    # A dependency the change added for a single use.
    for manifest, line, name in declared_dependencies(root, changed):
        module = name.lower().replace("-", "_") if manifest != "package.json" else name
        users = [f for f in files if f.endswith(SOURCE_EXT) and not is_test(f) and module in imports_of(root, f)]
        if len(users) == 1 and not any(o[3] == name and o[1] == "unused-dependency" for o in out):
            out.append(("report", "one-use-dependency", f"{manifest}:{line}", name, users[0]))

    # A block the change added that copies code already in the project.
    pairs = jscpd(root, engines, notes)
    for first, second in pairs:
        for mine, theirs in ((first, second), (second, first)):
            if span_hit(mine[0], mine[1], mine[2]) and not is_test(mine[0]):
                out.append(("report", "copy", f"{mine[0]}:{mine[1]}", "-", f"{theirs[0]}:{theirs[1]}"))
                break

    for note in notes:
        print("\t".join(note))
    seen = set()
    for row in out:
        if row not in seen:
            seen.add(row)
            print("\t".join(row))
    return answer(notes, out)


def answer(notes, found):
    """2 when any part of the read could not run, else 1 for findings, else 0."""
    if any(note[0] == "not-checked" for note in notes):
        return 2
    return 1 if found else 0


def waste_rows(root, engines, notes):
    files = project_files(root)
    js, py = languages(root, files)
    rows = []
    for kind, path, line, name in unused_findings(root, files, engines, notes, js, py, 100):
        if is_test(path):
            continue
        if second_look(root, files, kind, path, line, name):
            rows.append((kind, f"{path}:{line}", name))
    for first, second in jscpd(root, engines, notes):
        a, b = sorted([first, second])
        rows.append(("copy", f"{a[0]}:{a[1]}", f"{b[0]}:{b[1]}"))
    return rows


def waste_key(row):
    """A finding without its line numbers, which move as the code changes."""
    if row[0] == "copy":
        return "|".join(("copy", row[1].rsplit(":", 1)[0], row[2].rsplit(":", 1)[0]))
    return "|".join((row[0], row[1].rsplit(":", 1)[0], row[2]))


def loop_key(row):
    """A loop by its files, whichever one the line starts from."""
    return "|".join(sorted(step.split(":", 1)[0] for step in row[1:]))


def waste(root, engines, skip_offered):
    notes = []
    rows = waste_rows(root, engines, notes)
    if skip_offered:
        known = offered_keys(root, "waste")
        rows = [r for r in rows if waste_key(r) not in known]
    for note in notes:
        print("\t".join(note))
    for row in rows:
        print("\t".join(row))
    return answer(notes, rows)


# --- loops ---------------------------------------------------------------------

def jsonc(text):
    """JSON with comments and trailing commas, as tsconfig allows."""
    out, i, in_string = [], 0, False
    while i < len(text):
        c = text[i]
        if in_string:
            out.append(c)
            if c == "\\":
                out.append(text[i + 1:i + 2])
                i += 1
            elif c == '"':
                in_string = False
        elif c == '"':
            in_string = True
            out.append(c)
        elif text.startswith("//", i):
            i = text.find("\n", i)
            if i < 0:
                break
            continue
        elif text.startswith("/*", i):
            i = text.find("*/", i) + 2
            if i < 2:
                break
            continue
        else:
            out.append(c)
        i += 1
    return json.loads(re.sub(r",(\s*[}\]])", r"\1", "".join(out)))


def aliases(root):
    for name in ("tsconfig.json", "jsconfig.json"):
        try:
            options = jsonc(read(root, name)).get("compilerOptions", {})
        except ValueError:
            continue
        base = options.get("baseUrl", ".")
        return [(k.rstrip("*"), [os.path.normpath(os.path.join(base, t.rstrip("*"))) for t in v])
                for k, v in options.get("paths", {}).items()]
    return []


def resolve_js(root, known, path, spec, alias):
    if spec.startswith("."):
        targets = [os.path.normpath(os.path.join(os.path.dirname(path), spec))]
    else:
        targets = [os.path.normpath(os.path.join(t, spec[len(k):])) for k, ts in alias
                   if spec.startswith(k) for t in ts]
    for target in targets:
        stem = re.sub(r"\.(m|c)?js$", "", target)
        for candidate in [target] + [stem + e for e in JS_EXT] + [os.path.join(target, "index" + e) for e in JS_EXT]:
            if candidate in known:
                return candidate
    return None


def resolve_py(known, path, dots, module, names):
    if dots:
        folder = os.path.dirname(path)
        for _ in range(len(dots) - 1):
            folder = os.path.dirname(folder)
        bases = [os.path.join(folder, *module.split(".")) if module else folder]
    else:
        bases = [os.path.join(os.path.dirname(path), *module.split(".")),
                 os.path.join(*module.split(".")), os.path.join("src", *module.split("."))]
    found = []
    for base in bases:
        base = os.path.normpath(base)
        for candidate in (base + ".py", os.path.join(base, "__init__.py")):
            if candidate in known:
                found.append(candidate)
        for name in names:
            candidate = os.path.normpath(os.path.join(base, name + ".py"))
            if candidate in known:
                found.append(candidate)
    return found


def builtin_graph(root):
    files = [f for f in project_files(root) if f.endswith(SOURCE_EXT)]
    known, alias = set(files), aliases(root)
    edges = {}
    for path in files:
        for number, text in enumerate(read(root, path).split("\n"), 1):
            targets = []
            if path.endswith(".py"):
                m = re.match(r"^\s*from\s+(\.*)([\w.]*)\s+import\s+(.+)", text)
                if m:
                    names = [n.strip().split(" ")[0] for n in m.group(3).strip("()").split(",")]
                    targets = resolve_py(known, path, m.group(1), m.group(2), names)
                else:
                    m = re.match(r"^\s*import\s+([\w., ]+)", text)
                    if m:
                        for module in m.group(1).split(","):
                            targets += resolve_py(known, path, "", module.strip().split(" ")[0], [])
            else:
                for m in re.finditer(r"""(?:\bfrom\s*|^\s*import\s*|\brequire\(\s*|\bimport\(\s*)['"]([^'"]+)['"]""", text):
                    target = resolve_js(root, known, path, m.group(1), alias)
                    if target:
                        targets.append(target)
            for target in targets:
                if target != path:
                    edges.setdefault(path, {}).setdefault(target, number)
    return edges


def reached_from(edges, starts):
    """Every file the STARTS import, directly or through other files."""
    reached, stack = set(), list(starts)
    while stack:
        for target in edges.get(stack.pop(), {}):
            if target not in reached:
                reached.add(target)
                stack.append(target)
    return reached


def depcruise_graph(root, cmd):
    """dependency-cruiser's JavaScript graph, with Python read by the script's own reader.

    The project's tsconfig or jsconfig is passed in, so a path alias such as
    `@/` resolves. Where dependency-cruiser still misses an import the
    script's own reader resolves, its graph is not used, and None is returned.
    """
    folders = sorted({f.split("/")[0] for f in project_files(root)
                      if f.endswith(JS_EXT) and "/" in f}) or ["."]
    config = [n for n in ("tsconfig.json", "jsconfig.json") if os.path.isfile(os.path.join(root, n))]
    code, out, _ = run(cmd + ["--no-config", *(["--ts-config", config[0]] if config else []),
                              "--output-type", "json", *folders], cwd=root)
    try:
        modules = json.loads(out)["modules"]
    except (ValueError, KeyError):
        return None
    line_map = builtin_graph(root)
    edges = {source: dict(targets) for source, targets in line_map.items() if source.endswith(".py")}
    for module in modules:
        for dep in module.get("dependencies", []):
            if dep.get("coreModule") or "node_modules" in dep.get("resolved", "") or not dep.get("resolved"):
                continue
            source, target = module["source"], dep["resolved"]
            if source == target:
                continue
            number = line_map.get(source, {}).get(target) or line_of(
                root, source, os.path.splitext(os.path.basename(target))[0])
            edges.setdefault(source, {}).setdefault(target, number)
    if aliases(root):
        for source, targets in line_map.items():
            if any(target not in edges.get(source, {}) for target in targets):
                return None
    return edges


def strongly_connected(edges):
    index, low, stack, on, out, counter = {}, {}, [], set(), [], [0]
    nodes = sorted(set(edges) | {t for ts in edges.values() for t in ts})
    for start in nodes:
        if start in index:
            continue
        work = [(start, iter(sorted(edges.get(start, {}))))]
        index[start] = low[start] = counter[0]
        counter[0] += 1
        stack.append(start)
        on.add(start)
        while work:
            node, children = work[-1]
            advanced = False
            for child in children:
                if child not in index:
                    index[child] = low[child] = counter[0]
                    counter[0] += 1
                    stack.append(child)
                    on.add(child)
                    work.append((child, iter(sorted(edges.get(child, {})))))
                    advanced = True
                    break
                if child in on:
                    low[node] = min(low[node], index[child])
            if advanced:
                continue
            work.pop()
            if work:
                low[work[-1][0]] = min(low[work[-1][0]], low[node])
            if low[node] == index[node]:
                group = []
                while True:
                    member = stack.pop()
                    on.discard(member)
                    group.append(member)
                    if member == node:
                        break
                if len(group) > 1:
                    out.append(tuple(sorted(group)))
    return out


def loops(root, base, skip_offered, reader, engines):
    if base and git("rev-parse", "--verify", "-q", base + "^{commit}", cwd=root) is None:
        print(f"not-compared\t{base} is not a commit in this project")
        return 2
    cmd = engines.find("depcruise") if reader == "auto" and os.path.isfile(os.path.join(root, "package.json")) else None

    def graph(folder):
        if cmd:
            found = depcruise_graph(folder, cmd)
            if found is not None:
                return found, "dependency-cruiser"
        return builtin_graph(folder), "the script's own import reader"

    now, used = graph(root)
    print("reader: " + used, file=sys.stderr)
    known = set()
    if base:
        with tempfile.TemporaryDirectory() as folder:
            earlier = os.path.join(folder, "earlier")
            if not snapshot(root, base, earlier):
                print("not-compared\tthe project at the earlier commit could not be read")
                return 2
            known = set(strongly_connected(graph(earlier)[0]))
    offered = offered_keys(root, "loops") if skip_offered else set()
    found = 0
    for group in strongly_connected(now):
        if group in known or "|".join(group) in offered:
            continue
        members = set(group)
        steps = []
        for member in group:
            target = sorted(t for t in now.get(member, {}) if t in members)[0]
            steps.append(f"{member}:{now[member][target]} imports {target}")
        print("loop\t" + "\t".join(steps))
        found += 1
    return 1 if found else 0


# --- reach ---------------------------------------------------------------------

def route_for(path):
    """Next App Router address or scoped boundary for a route file."""
    match = re.match(r"^(?:src/)?app/(.*?)/(page|route|layout|error|loading|template)\.(?:js|jsx|ts|tsx)$", path)
    if not match:
        if re.match(r"^(?:src/)?app/(?:layout|template|error|loading)\.(?:js|jsx|ts|tsx)$", path):
            return "all"
        if re.match(r"^(?:src/)?app/(?:page|route)\.(?:js|jsx|ts|tsx)$", path):
            return "/"
        return None
    raw_parts = [part for part in match.group(1).split("/") if part]
    kind = match.group(2)
    if not raw_parts:
        return "all" if kind in {"layout", "template", "loading", "error"} else "/"
    parts = []
    scoped = []
    for part in raw_parts:
        if part.startswith("@"):
            scoped.append(part)
            continue
        if re.match(r"^\(\.\.?(?:\.?)\)", part):
            intercepted = re.sub(r"^\(\.\.?(?:\.?)\)", "", part)
            if intercepted:
                parts.append(intercepted)
            scoped.append(part)
            continue
        if part.startswith("(") and part.endswith(")"):
            scoped.append(part)
            continue
        parts.append(part)
    address = "/" + "/".join(parts)
    if kind in {"layout", "template", "loading", "error"}:
        return "scope:" + "/".join(raw_parts)
    return address


def routes_for(path, files):
    """Routes reached by a route file, expanding non-root boundaries in its subtree."""
    route = route_for(path)
    if route is None or route == "all" or not route.startswith("scope:"):
        return {route} if route else set()
    boundary = path.rsplit("/", 1)[0] + "/"
    descendants = {route_for(candidate) for candidate in files
                   if candidate.startswith(boundary)
                   and re.search(r"/(?:page|route)\.(?:js|jsx|ts|tsx)$", candidate)
                   and route_for(candidate) and route_for(candidate) != "all"}
    return descendants


def done_names_screen(body, route):
    """Whether a Done when line names this screen or its route."""
    if route == "all":
        return False
    section = re.search(r"^[ \t]*#{2,3}[ \t]+Done when[ \t]*$([\s\S]*?)(?=^[ \t]*#{1,3}[ \t]+|\Z)",
                        body, re.I | re.M)
    if not section:
        return False
    if route == "/":
        names = {"home"}
    else:
        names = {part.lower() for part in route.split("/") if part and not part.startswith("[")}
        names.update(name[:-1] for name in list(names) if name.endswith("s") and len(name) > 3)
    for line in section.group(1).splitlines():
        lower = line.lower()
        names_screen = re.search(r"\b(?:page|screen|view|route)\b", lower)
        if names_screen and (route.lower() in lower or any(re.search(r"(?<![\w-])" + re.escape(name) + r"(?![\w-])", lower) for name in names)):
            return True
    return False


def table_names(root, files, changed_migrations=()):
    """Map database table names to files that mention them."""
    found = {}
    patterns = (re.compile(r"\bTables\s*<\s*['\"]([\w-]+)['\"]\s*>"),)
    migration = re.compile(r"\b(?:create\s+table\s+(?:if\s+not\s+exists\s+)?|alter\s+table\s+(?:if\s+exists\s+)?)(?:public\.)?[\"`]?([\w-]+)", re.I)
    for path in files:
        text = read(root, path)
        names = set()
        for pattern in patterns:
            names.update(pattern.findall(text))
        from_re = re.compile(
            r"(?P<receiver>[A-Za-z_$][\w$]*)\s*\.\s*from\(\s*['\"]([\w-]+)['\"]\s*\)"
            r"(?P<tail>(?:\s*\.\s*(?:select|insert|update|delete|upsert)\b)?)", re.S)
        for match in from_re.finditer(text):
            receiver, name, tail = match.group("receiver"), match.group(2), match.group("tail")
            known_client = receiver.lower() in {"sup" + "abase", "client", "db", "sb"} or receiver.lower().endswith("client")
            if (known_client or re.search(r"\.\s*(?:select|insert|update|delete|upsert)\b", tail, re.I)) and receiver.lower() not in {"buffer", "array"}:
                names.add(name)
        names.update("rpc:" + name for name in
                     re.findall(r"\.rpc\(\s*['\"]([\w-]+)['\"]", text))
        if "migrations" in path.split("/") and path.endswith(".sql"):
            if path in changed_migrations:
                names.update(migration.findall(text))
        for name in names:
            found.setdefault(name, set()).add(path)
    return found


def reach_changed(root, base, paths):
    if paths is not None:
        return sorted(set(paths)), []
    if git("rev-parse", "--verify", "-q", base + "^{commit}", cwd=root) is None:
        return None, None
    out = git("diff", "--name-status", "--no-renames", base, "--", ".", cwd=root)
    if out is None:
        return None, None
    changed, deleted = [], []
    for line in out.splitlines():
        fields = line.split("\t")
        if len(fields) < 2:
            continue
        path = fields[-1]
        if fields[0] == "D":
            deleted.append(path)
        elif os.path.isfile(os.path.join(root, path)):
            changed.append(path)
    untracked = git("ls-files", "-o", "--exclude-standard", cwd=root) or ""
    changed.extend(path for path in untracked.splitlines() if os.path.isfile(os.path.join(root, path)))
    return sorted(set(changed)), deleted


def reach(root, paths, base, piece, should_run, engines):
    files = project_files(root)
    depcruise = engines.find("depcruise") if os.path.isfile(os.path.join(root, "package.json")) else None
    graph = depcruise_graph(root, depcruise) if depcruise else None
    if graph is None:
        graph = builtin_graph(root)
    if paths:
        changed, deleted = reach_changed(root, None, paths)
    else:
        changed, deleted = reach_changed(root, base, None)
    if changed is None:
        print("not-checked\tgit\tGit could not read the requested base commit")
        return 2
    raw_changed = changed
    changed = [os.path.normpath(p.removeprefix("./")) for p in changed
               if p.split("/")[0] not in KIT_DIRS]
    deleted = [os.path.normpath(p.removeprefix("./")) for p in deleted
               if p.split("/")[0] not in KIT_DIRS]
    if raw_changed and not changed and not deleted and all(
            os.path.normpath(p.removeprefix("./")).split("/")[0] in KIT_DIRS
            for p in raw_changed):
        return 0
    seeds = [path for path in changed if path in files]
    new_paths = [path for path in changed if path not in files and
                 os.path.splitext(path)[1] in SOURCE_EXT]
    if not graph and not any(p.endswith(SOURCE_EXT) for p in files) and not new_paths:
        print("not-checked\tgraph\tno local imports were found")
        return 2
    if not seeds and not deleted and not new_paths:
        print("not-checked\tgraph\tno changed source files were found")
        return 2

    reverse = {}
    for source, targets in graph.items():
        for target in targets:
            reverse.setdefault(target, set()).add(source)
    deleted_importers = {}
    if deleted and base:
        alias = aliases(root)
        for path in deleted:
            former = set()
            for candidate in files:
                old_text = git("show", f"{base}:{candidate}", cwd=root)
                if old_text is None:
                    continue
                if candidate.endswith(".py"):
                    for line in old_text.splitlines():
                        match = re.match(r"\s*from\s+(\.*)([\w.]*)\s+import\s+(.+)", line)
                        if match:
                            names = [n.strip().split(" ")[0] for n in match.group(3).strip("()").split(",")]
                            targets = resolve_py(set(files) | {path}, candidate, match.group(1), match.group(2), names)
                        else:
                            match = re.match(r"\s*import\s+([\w., ]+)", line)
                            targets = []
                            if match:
                                for module in match.group(1).split(","):
                                    targets.extend(resolve_py(set(files) | {path}, candidate, "", module.strip().split(" ")[0], []))
                        if path in targets:
                            former.add(candidate)
                    continue
                for spec in re.findall(r"(?:\bfrom\s*|\bimport\s*|\brequire\(\s*|\bimport\(\s*)['\"]([^'\"]+)['\"]", old_text):
                    if resolve_js(root, set(files) | {path}, candidate, spec, alias) == path:
                        former.add(candidate)
            deleted_importers[path] = former
    seeds = sorted(set(seeds) | set().union(*deleted_importers.values()) if deleted_importers else set(seeds))
    reached, stack = set(), list(seeds)
    while stack:
        target = stack.pop()
        for source in reverse.get(target, ()):
            if source not in reached and source not in seeds:
                reached.add(source)
                stack.append(source)

    for path in seeds:
        print(f"changed\t{path}")
    for path in deleted:
        print(f"deleted\t{path}")
    for path in new_paths:
        print(f"new\t{path}")
    for path in sorted(reached):
        via = next((seed for seed in seeds if seed in reached_from(graph, [path])), "")
        print(f"reaches\t{path}" + (f"\tvia {via}" if via else ""))

    routes = sorted(set().union(*(routes_for(path, files) for path in reached | set(seeds))))
    for route in routes:
        print(f"route\t{route}")
    changed_migrations = {p for p in seeds if "migrations" in p.split("/") and p.endswith(".sql")}
    tables = table_names(root, files, changed_migrations)
    touched_tables = sorted(name for name, users in tables.items()
                            if users & (reached | set(seeds)))
    for name in touched_tables:
        used_count = sum(not p.endswith(".sql") for p in tables[name])
        kind, label = ("rpc", name[4:]) if name.startswith("rpc:") else ("table", name)
        print(f"{kind}\t{label}\tused-in {used_count} files")

    importers, stack = set(), list(reached | set(seeds))
    while stack:
        target = stack.pop()
        for source in reverse.get(target, ()):
            if source not in importers:
                importers.add(source)
                stack.append(source)
    tests = sorted(path for path in files if is_test(path) and path in importers)
    for path in tests:
        print(f"tests\t{path}")
    wide = set()
    for path in reached | set(seeds):
        dependents = len(reached_from(reverse, [path]))
        if dependents >= WIDE_DEPENDENTS:
            wide.add(path)
            print(f"wide\t{path}\tdependents {dependents}")
    deleted_imports = {}
    for path in deleted:
        importers = sorted(deleted_importers.get(path, set()))
        if importers:
            deleted_imports[path] = importers
            print(f"wide\t{path}\tdeleted export imported in {len(importers)} files")
    if base:
        for path in seeds:
            if path not in changed:
                continue
            old_text = git("show", f"{base}:{path}", cwd=root) or ""
            new_text = read(root, path)
            export_re = re.compile(r"\bexport\s+(?:declare\s+)?(?:const|let|var|function|class|type|interface|enum)\s+(\w+)")
            old_exports, new_exports = set(export_re.findall(old_text)), set(export_re.findall(new_text))
            removed = old_exports - new_exports
            if not removed:
                continue
            importers = set()
            for candidate in files:
                for match in re.finditer(r"import\s*\{([^}]+)\}\s*from\s*['\"]([^'\"]+)['\"]", read(root, candidate)):
                    target = resolve_js(root, set(files), candidate, match.group(2), aliases(root))
                    names = {x.strip().split(" as ")[0].strip() for x in match.group(1).split(",")}
                    if target == path and names & removed:
                        importers.add(candidate)
            if importers:
                deleted_imports[path] = sorted(set(deleted_imports.get(path, [])) | importers)
                print(f"wide\t{path}\tremoved export still imported in {len(importers)} files (named imports only)")
    routes_wide = len(routes) >= WIDE_ROUTES or "all" in routes
    if routes_wide:
        print(f"wide\troutes\tcount {len(routes)}")
    for name in touched_tables:
        used_count = sum(not p.endswith(".sql") for p in tables[name])
        if used_count >= WIDE_TABLE_FILES:
            kind, label = ("rpc", name[4:]) if name.startswith("rpc:") else ("table", name)
            print(f"wide\t{kind} {label}\tfiles {used_count}")

    declared = None
    declaration_status = 0
    declared_text = ""
    piece_body = ""
    if piece:
        gh = shutil.which("gh")
        if gh:
            code, body, _ = run([gh, "issue", "view", str(piece), "--json", "body",
                                 "--jq", ".body"], cwd=root)
            if code == 0:
                piece_body = body
                match = re.search(REACHES_LINE, body, re.I | re.M)
                declared_text = match.group(1) if match else ""
                declared = set(re.findall(
                    r"[\w./-]+\.(?:m|c)?(?:js|jsx|ts|tsx|mts|cts|py|go|rs)", declared_text
                ))
            else:
                print("not-checked\tundeclared\tGitHub could not read the piece's Reaches line")
                declaration_status = 2
        else:
            print("not-checked\tundeclared\tGitHub CLI is not installed")
            declaration_status = 2
    undeclared = False
    if piece and declared is not None:
        for path in sorted(wide):
            if path not in declared:
                undeclared = True
                print(f"undeclared\t{path}\tnot in piece {piece}'s Reaches line")
        for path in sorted(deleted_imports):
            if path not in declared:
                undeclared = True
                print(f"undeclared\t{path}\tnot in piece {piece}'s Reaches line")
        if routes_wide:
            route_tokens = [token.rstrip(").,}") for token in re.findall(r"(?<![\w.-])/[\w/@\[\].-]*(?:/[\w/@\[\].-]*)*", declared_text)]
            if re.search(r"(?<![\w-])all(?![\w-])", declared_text):
                route_tokens.append("all")
            for route in routes:
                if route not in route_tokens:
                    undeclared = True
                    print(f"undeclared\troute {route}\tnot in piece {piece}'s Reaches line")
        for name in touched_tables:
            table_tokens = set(re.findall(r"(?<![\w-])[\w-]+(?![\w-])", declared_text))
            used_count = sum(not p.endswith(".sql") for p in tables[name])
            declared_name = name[4:] if name.startswith("rpc:") else name
            if used_count >= WIDE_TABLE_FILES and declared_name not in table_tokens:
                undeclared = True
                print(f"undeclared\ttable {name}\tnot in piece {piece}'s Reaches line")

    if should_run:
        recorded_command = test_command(root)
        recorded_text = " ".join(recorded_command or []).lower()
        package_text = read(root, "package.json").lower()
        uses_vitest = "vitest" in recorded_text or "vitest" in package_text
        runner = engines.find("vitest") if uses_vitest or not recorded_command else None
        targets = sorted(set(seeds) | reached)
        test_status = 0
        if runner:
            code, out, err = run(runner + ["related", *targets, "--run", "--passWithNoTests"], cwd=root)
            if out.strip():
                print("\n".join("test-output\t" + line for line in out.rstrip().splitlines()), file=sys.stderr)
            if code == 1 and re.search(r"\b(?:Test Files|Test Suites|Tests)\s+\d+", out + err, re.I):
                test_status = 1
            elif code != 0:
                print("not-checked\ttests\tVitest did not produce a test result summary")
                test_status = 2
        elif not recorded_command or "pytest" in recorded_text:
            pytest = [sys.executable, "-m", "pytest"]
            pytests = sorted(p for p in files if p.endswith(".py") and is_test(p) and
                             (p in set(seeds) | reached or p in importers))
            if pytests:
                code, out, err = run([*pytest, *pytests], cwd=root)
                if out.strip():
                    print("\n".join("test-output\t" + line for line in out.rstrip().splitlines()), file=sys.stderr)
                test_status = 1 if code and re.search(r"\d+ (?:passed|failed)", out + err) else (0 if not code else 2)
                if test_status == 2:
                    print("not-checked\ttests\tpytest did not produce a test result")
            elif any(path.endswith(".py") for path in seeds + sorted(reached)):
                if pytests:
                    print("not-checked\ttests\tpytest is not installed")
                    test_status = 2
                else:
                    print("not-checked\ttests\tno covering Python test was found")
            else:
                print("not-checked\ttests\tVitest is not installed")
                test_status = 2
        else:
            print("not-checked\ttests\tThe recorded test runner is not supported by reach")
            test_status = 2
        if test_status == 0:
            playwright = engines.find("playwright")
            screen_routes = {route for route in routes if done_names_screen(piece_body, route)}
            if playwright:
                def has_route_tokens(path, route):
                    if route == "/":
                        return os.path.basename(path).lower().startswith(("home.", "index."))
                    route_name = re.sub(r"\[[^]]+\]", "", route.lower())
                    wanted = [token for token in re.split(r"[^a-z0-9]+", route_name) if token]
                    actual = [token for token in re.split(r"[^a-z0-9]+", os.path.basename(path).lower()) if token]
                    return any(actual[index:index + len(wanted)] == wanted
                               for index in range(len(actual) - len(wanted) + 1))
                specs = [p for p in files if p.endswith((".spec.ts", ".spec.tsx", ".spec.js"))
                         and any(route not in ("all",) and has_route_tokens(p, route)
                                 for route in screen_routes)]
                if specs:
                    code, out, err = run(playwright + ["test", *specs], cwd=root)
                    if out.strip():
                        print("\n".join("test-output\t" + line for line in out.rstrip().splitlines()), file=sys.stderr)
                    if code:
                        test_status = 1 if re.search(r"\d+ failed", out + err) else 2
                        if test_status == 2:
                            print("not-checked\ttests\tPlaywright did not produce a test result")
            elif screen_routes:
                print("not-checked\ttests\tPlaywright is not installed")
                test_status = 2
        if test_status == 1:
            print("failed\ttests\tA covering test failed")
    final_test_status = test_status if should_run else 0
    if undeclared or final_test_status == 1:
        return 1
    if declaration_status == 2 or final_test_status == 2:
        return 2
    return 0


# --- strength ------------------------------------------------------------------

def ranges(lines):
    out, start, last = [], None, None
    for n in sorted(lines):
        if start is None:
            start = last = n
        elif n == last + 1:
            last = n
        else:
            out.append((start, last))
            start = last = n
    if start is not None:
        out.append((start, last))
    return out


def throwaway_copy(root, folder):
    """A copy to break code in, with no real records and nothing that reaches a live service.

    It leaves out Git, installed packages, and every `.env` file but
    `.env.example`, since a test run with real keys can act on live data.
    Earlier engine output is left out only at the top, where the engines
    write it, so a project folder that happens to share its name is kept.
    """
    top = os.path.abspath(root)

    def ignore(directory, names):
        left_out = [n for n in names if n in (".git", "node_modules")
                    or (n.startswith(".env") and n != ".env.example")]
        if os.path.abspath(directory) == top:
            left_out += [n for n in names if n in TOP_LEVEL_OUTPUT]
        return left_out
    shutil.copytree(root, folder, ignore=ignore, symlinks=True)
    if os.path.isdir(os.path.join(root, "node_modules")):
        os.symlink(os.path.join(root, "node_modules"), os.path.join(folder, "node_modules"))


def strength_js(root, changed, engines):
    targets = [f"{p}:{a}-{b}" for p, lines in sorted(changed.items())
               if p.endswith(JS_EXT) and not is_test(p) for a, b in ranges(lines)]
    if not targets:
        return [], None
    cmd = engines.find("stryker")
    if not cmd:
        return None, "StrykerJS is not installed"
    try:
        scripts = json.loads(read(root, "package.json")).get("scripts", {})
    except ValueError:
        scripts = {}
    if "test" not in scripts:
        return None, "the project has no test command"
    with tempfile.TemporaryDirectory() as folder:
        copy = os.path.join(folder, "copy")
        throwaway_copy(root, copy)
        code, out, err = run(cmd + ["run", "--mutate", ",".join(targets), "--testRunner", "command",
                                    "--reporters", "json", "--concurrency", "2",
                                    "--logLevel", "error", "--fileLogLevel", "off"], cwd=copy, timeout=3600)
        try:
            with open(os.path.join(copy, "reports", "mutation", "mutation.json")) as handle:
                report = json.load(handle)
        except (OSError, ValueError):
            return None, "StrykerJS did not finish: " + (err.strip().split("\n") or [""])[-1][:120]
    results = []
    for path, data in report.get("files", {}).items():
        rel = os.path.relpath(os.path.join(copy, path), copy) if os.path.isabs(path) else path
        for mutant in data.get("mutants", []):
            line = mutant["location"]["start"]["line"]
            results.append((mutant["status"], rel, line,
                            f'{mutant.get("mutatorName", "")}: {mutant.get("replacement", "")}'.strip()))
    if not results:
        return None, "StrykerJS found nothing to break in the changed lines"
    status = {"Killed": "caught", "Survived": "missed", "NoCoverage": "missed"}
    return [(status.get(s, "unchecked:" + s), p, l, d) for s, p, l, d in results], None


def python_functions(root, path):
    """(mutmut's name, first line, last line) for each function mutmut breaks.

    mutmut 3 breaks module-level functions, named `x_<function>`, and the
    methods of module-level classes, named `xǁ<Class>ǁ<method>`. A function
    nested inside another is not broken on its own, so it is not listed.
    """
    try:
        tree = ast.parse(read(root, path))
    except SyntaxError:
        return []
    kinds = (ast.FunctionDef, ast.AsyncFunctionDef)
    out = []
    for node in tree.body:
        if isinstance(node, kinds):
            out.append((f"x_{node.name}", node.lineno, getattr(node, "end_lineno", node.lineno)))
        elif isinstance(node, ast.ClassDef):
            for item in node.body:
                if isinstance(item, kinds):
                    out.append((f"xǁ{node.name}ǁ{item.name}", item.lineno,
                                getattr(item, "end_lineno", item.lineno)))
    return out


def strength_py(root, changed, engines):
    targets = [p for p in sorted(changed) if p.endswith(".py") and not is_test(p)]
    if not targets:
        return [], None
    cmd = engines.find("mutmut")
    if not cmd:
        return None, "mutmut is not installed in the project's environment"
    wanted = {}
    for path in targets:
        for name, start, end in python_functions(root, path):
            if any(n in changed[path] for n in range(start, end + 1)):
                module = os.path.splitext(path)[0].replace("/", ".")
                module = module[4:] if module.startswith("src.") else module
                wanted[f"{module}.{name}"] = (path, start)
    if not wanted:
        return None, "the changed Python lines are outside any function mutmut can break"
    with tempfile.TemporaryDirectory() as folder:
        copy = os.path.join(folder, "copy")
        throwaway_copy(root, copy)
        config = os.path.join(copy, "pyproject.toml")
        text = read(copy, "pyproject.toml")
        text = re.sub(r"(?ms)^\[tool\.mutmut\].*?(?=^\[|\Z)", "", text)
        folders = sorted({p.split("/")[0] if "/" in p else p for p in targets})
        with open(config, "w", encoding="utf-8") as handle:
            paths = json.dumps(folders)
            handle.write(text + "\n[tool.mutmut]\nsource_paths = " + paths +
                         "\npaths_to_mutate = " + paths + "\n")
        setup_config = os.path.join(copy, "setup.cfg")
        setup_text = read(copy, "setup.cfg")
        setup_text = re.sub(r"(?ms)^\[mutmut\].*?(?=^\[|\Z)", "", setup_text)
        with open(setup_config, "w", encoding="utf-8") as handle:
            handle.write(setup_text + "\n[mutmut]\nsource_paths = " + ",".join(folders) +
                         "\npaths_to_mutate = " + ",".join(folders) + "\n")
        code, out, err = run(cmd + ["run", *[name + "__mutmut_*" for name in sorted(wanted)]],
                             cwd=copy, timeout=3600)
        if code != 0:
            # mutmut first runs the tests on the unbroken code. When that run
            # fails, nothing was tried, and no result below means anything.
            detail = (err or out).strip().splitlines()
            suffix = ": " + detail[-1][:160] if detail else ""
            return None, "the tests failed before any code was broken, so nothing was tried" + suffix
        code, out, err = run(cmd + ["results", "--all", "true"], cwd=copy)
        if code != 0:
            return None, "mutmut did not finish"
        results = []
        for line in out.splitlines():
            m = re.match(r"^\s*(\S+?)__mutmut_\d+: (.+)$", line)
            if not m or m.group(1) not in wanted:
                continue
            path, start = wanted[m.group(1)]
            name = line.strip().split(":")[0]
            _, shown, _ = run(cmd + ["show", name], cwd=copy)
            where, detail = start, ""
            hunk = re.search(r"^@@ -\d+(?:,\d+)? \+(\d+)", shown, re.M)
            body = shown[hunk.end():].split("\n")[1:] if hunk else []
            offset = 0
            for row in body:
                if row.startswith("+"):
                    detail = row[1:].strip()
                    break
                if not row.startswith("-"):
                    offset += 1
            if hunk:
                where = start + offset
            status = {"killed": "caught", "survived": "missed", "no tests": "missed"}.get(m.group(2).strip())
            results.append((status or "unchecked:" + m.group(2).strip(), path, where, detail))
    return results, None


def strength(root, base, engines):
    if git("rev-parse", "--verify", "-q", base + "^{commit}", cwd=root) is None:
        print(f"not-checked\tstrength\t{base} is not a commit in this project")
        return 2
    changed = {p: l for p, l in changed_lines(root, base).items() if os.path.isfile(os.path.join(root, p))}
    files = project_files(root)
    js, py = languages(root, files)
    results, reasons = [], []
    for wanted, runner in ((js, strength_js), (py, strength_py)):
        if not wanted:
            continue
        found, reason = runner(root, changed, engines)
        if reason:
            reasons.append(reason)
        else:
            results += found
    caught = sum(1 for r in results if r[0] == "caught")
    missed = [r for r in results if r[0] == "missed"]
    if results and not caught + len(missed):
        reasons.append("every breakage crashed or timed out, so the tests were not checked")
    for reason in reasons:
        print(f"not-checked\tstrength\t{reason}")
    if not results and reasons:
        return 2
    print(f"tried\t{caught + len(missed)}")
    print(f"caught\t{caught}")
    for status, path, line, detail in sorted(missed, key=lambda r: (r[1], r[2])):
        print(f"missed\t{path}:{line}\t{detail}")
    for status, path, line, detail in sorted((r for r in results if r[0].startswith("unchecked")),
                                             key=lambda r: (r[1], r[2])):
        print(f"unchecked\t{path}:{line}\t{status.split(':', 1)[1]}")
    if reasons:
        return 2
    return 1 if missed else 0


# --- tests that prove the change -----------------------------------------------

def test_command(root):
    """Use the check's recorded command before inferring a runner."""
    agents = read(root, "AGENTS.md")
    recorded = re.search(r"(?im)^\s*(?:[-*]\s*)?\*{0,2}(?:test(?:\s+command)?|tests)\*{0,2}\s*:\s*`?([^`\n]+)`?\s*$", agents)
    if recorded:
        return shlex.split(recorded.group(1).strip())
    recipe_project = bool(re.search(r"(?im)^\s*Recipe:\s*\S+", agents))
    # AGENTS.md records the project's stack. Prefer its test command so local
    # quality reads use the same runner as the person.
    for path in (".github/workflows/checks.yml", "checks.yml", QUALITY_FLOOR):
        text = read(root, path)
        if not text:
            continue
        commands = []
        in_run = False
        run_indent = 0
        recipe_only = False
        for line in text.splitlines():
            if re.match(r"^\s*- name:", line):
                recipe_only = False
            if re.match(r"^\s*if:\s*steps\.recipe\.outputs\.selected\s*==\s*'true'", line):
                recipe_only = True
            match = re.match(r"^(\s*)(?:-\s*)?run:\s*(.*)$", line)
            if match:
                in_run = True
                run_indent = len(match.group(1))
                if not (recipe_only and not recipe_project) and match.group(2).strip() and match.group(2).strip() != "|":
                    commands.append(match.group(2).strip().strip("'\""))
                continue
            if in_run:
                indent = len(line) - len(line.lstrip())
                if line.strip() and indent <= run_indent:
                    in_run = False
                elif line.strip() and not (recipe_only and not recipe_project):
                    commands.append(line.strip())
        for command in commands:
            if re.search(r"\bpytest\b", command):
                return shlex.split(command)
            if re.search(r"\b(?:vitest|playwright)\b", command):
                return shlex.split(command)
    try:
        package = json.loads(read(root, "package.json"))
        script = package.get("scripts", {}).get("test", "")
        if script:
            return ["npm", "test", "--", "--run"] if "vitest" in script else ["npm", "test"]
    except (ValueError, TypeError):
        pass
    if any(os.path.isfile(os.path.join(root, n)) for n in ("pyproject.toml", "pytest.ini", "pytest.toml", "setup.cfg")):
        return [sys.executable, "-m", "pytest", "-q"]
    return None


def pytest_module_command(command):
    """Use the active Python environment when a project records pytest directly."""
    if command and os.path.basename(command[0]) in ("pytest", "pytest.exe"):
        if not os.path.isabs(command[0]) and os.path.dirname(command[0]):
            return command
        interpreter = sys.executable
        if os.path.isabs(command[0]):
            sibling = os.path.join(os.path.dirname(command[0]), "python3")
            if os.path.isfile(sibling) and os.access(sibling, os.X_OK):
                interpreter = sibling
        return [interpreter, "-m", "pytest", *command[1:]]
    return command


def red_commits(root, base):
    """All Test: commits after BASE, identified from their subjects."""
    out = git("log", "--format=%H%x09%s", f"{base}..HEAD", cwd=root) or ""
    return [line.split("\t", 1)[0] for line in out.splitlines()
            if "\t" in line and line.split("\t", 1)[1].startswith("Test:")]


def done_when(root, piece):
    """Read the issue, or an explicitly supplied rehearsal fixture."""
    rehearsal = os.environ.get("QUALITY_TEST_PIECE_FILE")
    candidates = ([rehearsal] if rehearsal else []) + [
        f".agents/tmp/pieces/{piece}.md", f".agents/tmp/pieces/{piece}.txt"]
    for path in candidates:
        text = read(root, path)
        if text:
            return text
    code, out, _ = run(["gh", "issue", "view", str(piece), "--json", "body", "--jq", ".body"], cwd=root, timeout=30)
    return out if code == 0 else None


def junit_cases(path):
    import xml.etree.ElementTree as ET
    try:
        return {case.attrib.get("name", ""): case for case in ET.parse(path).iter("testcase")}
    except (OSError, ET.ParseError):
        return None


def playwright_specs(root, files):
    """Playwright specs whose test titles name a numbered Done when line."""
    configs = [p for p in files if re.fullmatch(r"(?:.*/)?playwright\.config\.[^/]+", p)]
    configured_dirs, configured_matches = ["tests"], []
    for config in configs:
        config_text = read(root, config)
        match = re.search(r"\btestDir\s*:\s*['\"]([^'\"]+)", config_text)
        if match:
            configured_dirs.append(match.group(1).strip("./"))
        match = re.search(r"\btestMatch\s*:\s*(?:\[(.*?)\]|['\"]([^'\"]+)['\"])", config_text, re.S)
        if match:
            configured_matches.extend(re.findall(r"['\"]([^'\"]+)['\"]", match.group(1) or match.group(2)))
    specs = {}
    for path in files:
        if not path.endswith(".spec.ts"):
            continue
        text = read(root, path)
        is_configured = any(path == directory or path.startswith(directory.rstrip("/") + "/")
                            for directory in configured_dirs)
        is_configured = is_configured or any(fnmatch.fnmatch(path, pattern.lstrip("./"))
                                             for pattern in configured_matches)
        is_configured = is_configured or any(re.search(re.escape(path), read(root, c)) for c in configs)
        if not is_configured:
            continue
        titles = re.findall(r"\b(?:test|it)\s*\(\s*(['\"])(.*?)\1", text, re.S)
        for _, title in titles:
            for number in re.findall(r"(?i)(?<![A-Za-z0-9])D(\d+)(?![A-Za-z0-9])", title):
                specs.setdefault(int(number), []).append(path)
    return specs


def mapped_paths(masterplan):
    """Every inline paths list in the sensitive-area map."""
    paths = []
    for line in masterplan.splitlines():
        match = re.match(r"^\s+paths:\s*(.*)$", line)
        if match and match.group(1).strip():
            paths.extend(item.strip().removeprefix("./") for item in match.group(1).split(","))
    return paths


def test_read(root, base, piece):
    if git("rev-parse", "--verify", "-q", base + "^{commit}", cwd=root) is None:
        print(f"not-checked\ttests\t{base} is not a commit in this project")
        return 2
    commits = red_commits(root, base)
    command = pytest_module_command(test_command(root))
    changed = {p: lines for p, lines in changed_lines(root, base).items()
               if os.path.isfile(os.path.join(root, p))}
    changed_tests = [p for p in changed if is_test_file(p)]
    if commits and not changed_tests:
        print("not-checked\ttests\tTest: commits added no test files")
        return 2
    notes = done_when(root, piece)
    if notes is None:
        print(f"not-checked\ttests\tcould not read Done when lines for piece {piece}")
        return 2
    section_text = re.search(r"(?ims)(?:^## Under the hood\s*\n|<summary>Under the hood</summary>)(.*?)(?=^## |</details>|\Z)", notes)
    refactor = bool(section_text and re.search(r"(?im)^\s*Kind:\s*refactor\s*$", section_text.group(1)))
    section = re.search(r"(?ms)^#{2,3} Done when\s*\n(.*?)(?=^#{2,3} |\Z)", notes)
    done_lines, item_count, bullets = [], 0, []
    if section:
        for line in section.group(1).splitlines():
            item = re.match(r"^\s*(?:[-*]|\d+[.)])\s+(?:\[[ xX]\]\s*)?(.*)$", line)
            if item:
                if bullets:
                    detail = " ".join(part.strip() for part in bullets)
                    if not detail.endswith("(try it)"):
                        done_lines.append((item_count, detail))
                item_count += 1
                bullets = [item.group(1).strip()]
            elif bullets and line.strip():
                bullets.append(line.strip())
        if bullets:
            detail = " ".join(part.strip() for part in bullets)
            if not detail.endswith("(try it)"):
                done_lines.append((item_count, detail))
    all_manual = item_count > 0 and not done_lines
    if not done_lines and not all_manual:
        print("not-checked\ttests\tno Done when lines found")
        return 1
    if not commits and all_manual:
        print("tests\tvisual-only piece: every Done when condition is for a person to try")
        return 0
    if not command:
        print("not-checked\ttests\tno recorded test command was found")
        return 2
    test_files = [p for p in project_files(root) if is_test_file(p)]
    status, unavailable = 0, False
    skipped_patterns = (r"\b(?:it|test|describe)\s*\.\s*(?:skip|only)\b", r"\bx(?:it|test)\s*\(",
                        r"@pytest\.mark\.skip", r"@unittest\.skip")
    diff = git("diff", "--unified=0", "--no-color", base, "--", *test_files, cwd=root) or ""
    current, current_line = None, 0
    for line in diff.splitlines():
        if line.startswith("+++ "):
            current = line[6:].split("\t", 1)[0]
        elif line.startswith("@@"):
            hunk = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@", line)
            current_line = int(hunk.group(1)) if hunk else 0
        elif line.startswith("+") and not line.startswith("+++") and current in test_files:
            if any(re.search(pattern, line[1:]) for pattern in skipped_patterns):
                print(f"skipped\t{current}:{current_line}")
                status = 1
            current_line += 1
    for source in (p for p in changed if p.endswith(SOURCE_EXT) and not is_test(p)):
        stem = os.path.splitext(os.path.basename(source))[0]
        for test_path in test_files:
            if re.search(r"(?:vi|jest)\s*\.\s*mock\s*\([^\n]*" + re.escape(stem), read(root, test_path)):
                print(f"stands-in\t{test_path} replaces {source}, which this change edits")
    for path in test_files:
        old = git("show", f"{base}:{path}", cwd=root)
        if old is None:
            continue
        now = read(root, path)
        if path.endswith(".py"):
            cases = re.compile(r"(?m)^\s*def\s+(test_[A-Za-z0-9_]+)\s*\(")
        else:
            cases = re.compile(r"(?m)^\s*(?:it|test)\s*\([^\n]*")
        if set(cases.findall(old)) - set(cases.findall(now)):
            print(f"removed\t{path}")
    for row in (git("diff", "--name-status", base, "--", cwd=root) or "").splitlines():
        fields = row.split("\t", 1)
        if len(fields) == 2 and fields[0] == "D" and is_test_file(fields[1]):
            print(f"removed\t{fields[1]}")
    playwright = playwright_specs(root, project_files(root))
    with tempfile.TemporaryDirectory(prefix="quality-tests-") as folder:
        start, before_root = os.path.join(folder, "start"), os.path.join(folder, "before")
        os.makedirs(start)
        archive = subprocess.run(["git", "archive", base], cwd=root, capture_output=True)
        if archive.returncode:
            print("not-checked\ttests\tcould not make a copy of the start commit")
            return 2
        if subprocess.run(["tar", "-x", "-C", start], input=archive.stdout, capture_output=True).returncode:
            print("not-checked\ttests\tcould not unpack the start commit")
            return 2
        modules = os.path.join(root, "node_modules")
        if os.path.isdir(modules) and not os.path.exists(os.path.join(start, "node_modules")):
            os.symlink(modules, os.path.join(start, "node_modules"))
        red_tests = sorted({path for commit in commits for path in
            (git("diff-tree", "--root", "--no-commit-id", "--name-only", "-r", commit, cwd=root) or "").splitlines()
            if is_test_file(path)})
        for path in red_tests:
            source, dest = os.path.join(root, path), os.path.join(start, path)
            if os.path.isfile(source):
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                shutil.copy2(source, dest)
        throwaway_copy(start, before_root)
        before_xml, after_xml = os.path.join(folder, "before.xml"), os.path.join(folder, "after.xml")
        before_cmd, after_cmd = list(command), list(command)
        command_text = " ".join(command)
        is_vitest = "vitest" in command_text or '"vitest"' in read(root, "package.json")
        is_pytest = "pytest" in command_text
        is_playwright = "playwright" in command_text
        cov_before = cov_after = None
        if is_vitest:
            before_cmd += ["--reporter=junit", f"--outputFile={before_xml}"]
            after_cmd += ["--reporter=junit", f"--outputFile={after_xml}"]
            if os.path.isdir(os.path.join(root, "node_modules", "@vitest", "coverage-v8")):
                cov_before, cov_after = os.path.join(folder, "coverage-before"), os.path.join(folder, "coverage-after")
                before_cmd += ["--coverage", f"--coverage.reportsDirectory={cov_before}"]
                after_cmd += ["--coverage", f"--coverage.reportsDirectory={cov_after}"]
            else:
                print("not-checked\tcoverage\t@vitest/coverage-v8 provider is not installed")
        elif is_pytest:
            before_cmd += [f"--junitxml={before_xml}"]
            after_cmd += [f"--junitxml={after_xml}"]
            cov_available = run([*command, "--help"], cwd=before_root, timeout=30)[0] == 0
            help_text = run([*command, "--help"], cwd=before_root, timeout=30)[1] if cov_available else ""
            # Read json only from the --cov-report option's own help, not anywhere in pytest's help.
            cov_help = re.search(r"--cov-report[\s\S]*?(?=\n\s{0,4}--|\Z)", help_text)
            if cov_help and re.search(r"\bjson\b", cov_help.group(0)):
                cov_before, cov_after = os.path.join(folder, "coverage-before.json"), os.path.join(folder, "coverage-after.json")
                before_cmd += ["--cov", f"--cov-report=json:{cov_before}"]
                after_cmd += ["--cov", f"--cov-report=json:{cov_after}"]
            elif "--cov" in help_text:
                print("not-checked\tcoverage\tinstalled pytest-cov does not support JSON output")
            else:
                print("not-checked\tcoverage\tpytest-cov (coverage.py provider) is not installed")
        else:
            if is_playwright and playwright:
                runner = os.path.join(root, "node_modules", ".bin", "playwright")
                if not os.access(runner, os.X_OK) and not shutil.which("playwright"):
                    print("not-checked\tplaywright\tPlaywright is not installed")
                    return 2
                for n in sorted(playwright):
                    test_cmd = ["npx", "--no-install", "playwright", "test", "--grep", f"D{n}\\b"]
                    before_code, _, _ = run(test_cmd, cwd=before_root, timeout=900)
                    after_code, _, _ = run(test_cmd, cwd=root, timeout=900)
                    print(f"playwright\tD{n}\t{'passed' if after_code == 0 else 'failed'}")
                    if before_code == 0:
                        print(f"passes-before\tD{n}")
                        status = 1
                    elif after_code:
                        print(f"fails-after\tD{n}")
                        status = 1
                    else:
                        print(f"fails-before\tD{n}")
                if status == 0:
                    print("tests\tpassed")
                return 1 if status else 0
            print("not-checked\ttests\trecorded test command has no per-test report")
            return 2
        before_env, after_env = os.environ.copy(), os.environ.copy()
        if is_pytest:
            before_env["COVERAGE_FILE"] = os.path.join(folder, ".coverage-before")
            after_env["COVERAGE_FILE"] = os.path.join(folder, ".coverage-after")
        before_code, before_out, before_err = run(before_cmd, cwd=before_root, timeout=900, env=before_env)
        after_code, after_out, after_err = run(after_cmd, cwd=root, timeout=900, env=after_env)
        before_cases, after_cases = junit_cases(before_xml), junit_cases(after_xml)
        if before_cases is None or after_cases is None:
            print("not-checked\ttests\tthe runner could not produce JUnit results")
            return 2
        def failed(case):
            return case.find("failure") is not None or case.find("error") is not None
        missing_module_cases = {name: case for name, case in before_cases.items()
            if failed(case) and re.search(r"Cannot find module|Failed to load|No module named|ModuleNotFoundError",
                " ".join(case.itertext()))}
        missing_module_d_numbers = set()
        for name, case in missing_module_cases.items():
            junit_path = (name + " " + case.attrib.get("classname", "")).replace("\\", "/")
            matched_paths = [path for path in red_tests if path.replace("\\", "/") in junit_path]
            if not matched_paths:
                leaf = os.path.basename(junit_path.split()[-1]) if junit_path.split() else ""
                same_leaf = [path for path in red_tests if os.path.basename(path) == leaf]
                matched_paths = same_leaf if len(same_leaf) == 1 else []
            for path in matched_paths:
                missing_module_d_numbers.update(int(number) for number in re.findall(
                    r"(?i)(?<![A-Za-z0-9])D(\d+)(?![A-Za-z0-9])", read(root, path)))
        d_results = []
        for n, detail in ([] if refactor else done_lines):
            pat = re.compile(r"(?i)(?<![A-Za-z0-9])D" + str(n) + r"(?![A-Za-z0-9])")
            before_matches = [c for name, c in before_cases.items()
                              if pat.search(name + " " + c.attrib.get("classname", ""))]
            after_matches = [c for name, c in after_cases.items()
                             if pat.search(name + " " + c.attrib.get("classname", ""))]
            file_module_failure = n in missing_module_d_numbers
            if not after_matches or any(c.find("skipped") is not None for c in after_matches):
                print(f"untested\tD{n}\t{detail}")
                status = 1
            elif any(failed(c) for c in after_matches):
                print(f"fails-after\tD{n}")
                status = 1
            elif any(not failed(c) for c in before_matches):
                print(f"passes-before\tD{n}")
                status = 1
            elif file_module_failure or any(failed(c) for c in before_matches):
                print(f"fails-before\tD{n}")
            else:
                print(f"passes-before\tD{n}")
                status = 1
            d_results.append(n)
        unrelated_before = [name for name, case in before_cases.items()
                            if failed(case) and name not in missing_module_cases
                            and not any(re.search(r"(?i)(?<![A-Za-z0-9])D" + str(n) + r"(?![A-Za-z0-9])",
                                name + " " + case.attrib.get("classname", "")) for n in d_results)]
        if unrelated_before:
            print("not-checked\ttests\tother existing tests fail on the start copy")
            unavailable = True
        unrelated_after = [name for name, case in after_cases.items()
                           if failed(case) and not any(re.search(r"(?i)(?<![A-Za-z0-9])D" + str(n) + r"(?![A-Za-z0-9])",
                               name + " " + case.attrib.get("classname", "")) for n in d_results)]
        if unrelated_after:
            print("fails-after\tother existing tests fail on the current code")
            status = 1
        if after_code != 0 and not unrelated_after and not any(failed(c) for c in after_cases.values()):
            print("fails-after\tthe recorded test command exited non-zero")
            status = 1
        if refactor and before_code != 0:
            print("fails-before\trefactor baseline tests must pass on the start copy")
            status = 1
        if refactor and after_code != 0:
            print("fails-after\trefactor tests must pass on the current code")
            status = 1
        if not refactor and not commits:
            print("missing-red-commit\tbehaviour piece needs a Test: commit whose tests fail before the change")
            status = 1
        report = os.path.join(cov_after, "coverage-final.json") if is_vitest and cov_after else cov_after
        covered = set()
        if report and os.path.isfile(report):
            try:
                with open(report, encoding="utf-8") as handle:
                    data = json.load(handle)
                if is_pytest:
                    for path, item in data.get("files", {}).items():
                        for line in item.get("executed_lines", []):
                            rel = os.path.relpath(path, root) if os.path.isabs(path) else path
                            covered.add((rel, int(line)))
                else:
                    for path, item in data.items():
                        rel = os.path.relpath(os.path.realpath(path), os.path.realpath(root)) if os.path.isabs(path) else path
                        for key, count in item.get("s", {}).items():
                            line = item.get("statementMap", {}).get(key, {}).get("start", {}).get("line")
                            if line and count:
                                covered.add((rel, line))
            except (OSError, ValueError, TypeError):
                report = None
        if cov_after is not None and (not report or not os.path.isfile(report)):
            print(f"not-checked\tcoverage\t{'@vitest/coverage-v8' if is_vitest else 'pytest-cov (coverage.py)'} report is missing")
        changed_code = set()
        for path, lines in changed.items():
            if path.endswith(SOURCE_EXT) and not is_test(path):
                source_lines = read(root, path).splitlines()
                changed_code.update((path, line) for line in lines
                                    if line <= len(source_lines) and source_lines[line - 1].strip())
        uncovered = sorted(changed_code - covered)
        if report and os.path.isfile(report):
            by_file = {}
            for path, line in uncovered:
                by_file.setdefault(path, []).append(line)
            for path, lines in sorted(by_file.items()):
                lines = sorted(lines)
                first = previous = lines[0]
                for line in lines[1:] + [None]:
                    if line is not None and line == previous + 1:
                        previous = line
                        continue
                    print(f"uncovered\t{path}:{first}-{previous}")
                    if line is not None:
                        first = previous = line
        if report and os.path.isfile(report):
            print(f"covered\t{len(changed_code & covered)}")
            if changed_code and not (changed_code & covered):
                status = 1
        if playwright:
            runner = os.path.join(root, "node_modules", ".bin", "playwright")
            if not os.access(runner, os.X_OK) and not shutil.which("playwright"):
                print("not-checked\tplaywright\tPlaywright is not installed")
                unavailable = True
            else:
                for n in sorted(playwright):
                    code, _, _ = run(["npx", "--no-install", "playwright", "test", "--grep", f"D{n}\\b"], cwd=root, timeout=900)
                    print(f"playwright\tD{n}\t{'passed' if code == 0 else 'failed'}")
                    if code:
                        status = 1
    if git("show", f"{base}:masterplan.md", cwd=root) is not None:
        masterplan = read(root, "masterplan.md")
        if re.search(r"(?m)^Path:\s*Build with care\s*$", masterplan):
            mapped = mapped_paths(masterplan)
            if any(path == item or path.startswith(item.rstrip("/") + "/")
                   for path in changed for item in mapped):
                result = subprocess.run([sys.executable, os.path.abspath(__file__), "strength", "--base", base],
                                        cwd=root, capture_output=True, text=True)
                for line in result.stdout.splitlines():
                    if line.startswith("missed\t"):
                        print("strength\t" + line.split("\t", 1)[-1])
                    elif line.startswith("not-checked\tstrength\t"):
                        print("not-checked\tstrength\t" + line.split("\t", 2)[-1])
    if status == 0 and not unavailable:
        print("tests\tpassed")
    if status == 1:
        return 1
    return 2 if unavailable else 0


def overlap(root, pieces):
    """Refuse parallel pieces whose recorded reaches share work."""
    if len(pieces) < 2 or len(pieces) > 3 or len(set(pieces)) != len(pieces):
        print("overlap: give two or three different piece numbers", file=sys.stderr)
        return 2
    plan = git("show", "main:masterplan.md", cwd=root)
    if plan is None:
        plan = read(root, "masterplan.md")
    else:
        plan = plan
    setting = re.search(r"(?m)^Runs on its own:.*$", plan)
    path_line = re.search(r"(?m)^Path:\s*(.+?)\s*$", plan)
    parallel = re.search(r"\bparallel\s+([23])\b", setting.group(0), re.I) if setting else None
    if not parallel or not path_line or path_line.group(1) == "Explore privately":
        print("overlap: parallel building is off on main", file=sys.stderr)
        return 1
    if len(pieces) > int(parallel.group(1)):
        print("overlap: the setting on main allows %s parallel pieces" % parallel.group(1), file=sys.stderr)
        return 1
    reaches = {}
    for number in pieces:
        try:
            result = subprocess.run(["gh", "issue", "view", str(number), "--json", "body"],
                                    cwd=root, capture_output=True, text=True)
        except OSError as error:
            print("overlap: GitHub CLI could not run: " + str(error), file=sys.stderr)
            return 2
        if result.returncode:
            print("overlap: could not read piece " + str(number), file=sys.stderr)
            return 2
        try:
            body = json.loads(result.stdout)["body"]
        except (ValueError, KeyError, TypeError):
            print("overlap: piece " + str(number) + " has unreadable details", file=sys.stderr)
            return 2
        match = re.search(REACHES_LINE, body, re.M)
        if not match or "undeclared" in match.group(1).casefold():
            print("overlap: piece %s has no usable Reaches line" % number, file=sys.stderr)
            return 2
        reaches[number] = {part.strip().strip("`.,") for part in re.split(r"[,;]", match.group(1))
                           if part.strip() and "new files only" not in part.casefold()}
    all_files = project_files(root)
    tables = table_names(root, all_files)
    masterplan = read(root, "masterplan.md")
    areas = []
    inside = False
    for line in masterplan.splitlines():
        if line.strip() == "Sensitive areas:":
            inside = True
            continue
        if inside and line and not line[0].isspace():
            inside = False
        if inside and line.strip().startswith("paths:"):
            areas.extend(x.strip().strip("`.,") for x in line.split(":", 1)[1].split(","))
    settings = {".env.example", "checks.yml", "checks.yaml", "package.json",
                "pyproject.toml", "pnpm-lock.yaml", "package-lock.json", "yarn.lock", "uv.lock"}
    bad_pairs = []
    numbers = list(reaches)
    for index, left in enumerate(numbers):
        for right in numbers[index + 1:]:
            shared = reaches[left] & reaches[right]
            if shared:
                bad_pairs.append((left, right, "shared file " + sorted(shared)[0]))
                continue
            left_migrations = {p for p in reaches[left] if "migrations/" in p and p.endswith(".sql")}
            right_migrations = {p for p in reaches[right] if "migrations/" in p and p.endswith(".sql")}
            if left_migrations or right_migrations:
                bad_pairs.append((left, right, "migration work"))
                continue
            left_tables = {name for name, paths in tables.items() if paths & reaches[left]}
            right_tables = {name for name, paths in tables.items() if paths & reaches[right]}
            shared_tables = left_tables & right_tables
            if shared_tables:
                bad_pairs.append((left, right, "shared table " + sorted(shared_tables)[0]))
                continue
            if any(os.path.basename(path).casefold() in settings or
                   path.casefold().endswith("/checks.yml") or
                   path.casefold().endswith("/checks.yaml")
                   for path in reaches[left] | reaches[right]):
                bad_pairs.append((left, right, "project setting"))
                continue
            if any(path == pattern or path.startswith(pattern.rstrip("/") + "/")
                   or fnmatch.fnmatchcase(path, pattern)
                   for path in reaches[left] | reaches[right] for pattern in areas):
                bad_pairs.append((left, right, "sensitive area"))
    if bad_pairs:
        for left, right, reason in bad_pairs:
            print("overlap\t%s\t%s\t%s" % (left, right, reason))
        return 1
    print("overlap\tclear\t%d pieces" % len(pieces))
    return 0

def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = parser.add_subparsers(dest="read", required=True)
    for name in ("trim", "strength"):
        p = sub.add_parser(name)
        p.add_argument("--base", required=True)
        p.add_argument("--fetch", action="store_true")
    p = sub.add_parser("waste")
    p.add_argument("--skip-offered", action="store_true")
    p.add_argument("--fetch", action="store_true")
    p = sub.add_parser("loops")
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument("--base")
    group.add_argument("--skip-offered", action="store_true")
    p.add_argument("--reader", choices=("auto", "builtin"), default="auto")
    p = sub.add_parser("reach")
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument("--paths", nargs="+")
    group.add_argument("--base")
    p.add_argument("--piece")
    p.add_argument("--run", action="store_true")
    p = sub.add_parser("offered")
    p.add_argument("which", choices=("waste", "loops"))
    p = sub.add_parser("tests")
    p.add_argument("--base", required=True)
    p.add_argument("--piece", required=True)
    p = sub.add_parser("overlap")
    p.add_argument("--pieces", nargs="+", required=True, type=int)
    try:
        args = parser.parse_args()
    except SystemExit:
        return 2
    if TEST_PATH is None or TEST_FILES is None:
        print("not-checked\tall\tthe test-path rules could not be read from " + TEST_RULE)
        return 2
    top = git("rev-parse", "--show-toplevel")
    if top is None:
        print("not-checked\tall\tthis folder is not a project under Git")
        return 2
    root = top.strip()
    os.chdir(root)
    if args.read == "overlap":
        return overlap(root, args.pieces)
    if args.read == "offered":
        rows = [line.rstrip("\n").split("\t") for line in sys.stdin if line.strip()]
        key = waste_key if args.which == "waste" else loop_key
        if args.which == "loops":
            rows = [r for r in rows if r[0] == "loop" and len(r) >= 3]
        else:
            rows = [r for r in rows if len(r) >= 3 and not r[0].startswith("not-")]
        print(f"recorded\t{record_offered(root, args.which, [key(r) for r in rows])}")
        return 0
    engines = Engines(root, getattr(args, "fetch", False))
    if args.read == "trim":
        return trim(root, args.base, engines)
    if args.read == "waste":
        return waste(root, engines, args.skip_offered)
    if args.read == "loops":
        return loops(root, args.base, args.skip_offered, args.reader, engines)
    if args.read == "reach":
        return reach(root, args.paths, args.base, args.piece, args.run, engines)
    if args.read == "tests":
        return test_read(root, args.base, args.piece)
    return strength(root, args.base, engines)


if __name__ == "__main__":
    sys.exit(main())
