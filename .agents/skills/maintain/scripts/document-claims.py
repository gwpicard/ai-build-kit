#!/usr/bin/env python3
"""List the names a project's documents mention that no longer exist.

Reads README.md and every document AGENTS.md points at. For each line it looks
for five kinds of name and checks that each still exists: a file or folder, a
link to another file, an `npm run`, `pnpm run`, `yarn run` or `make` command,
and an environment variable. It prints one line per name that does not exist,
as `document:line<TAB>kind<TAB>name`, and prints nothing when every name it
found still exists.

A file name is one that ends in a file ending, and a folder name one that ends
in a slash. So `/shape`, `owner/name` and `example.com/page` are not taken for
files. A name written from some other folder is found wherever the project
keeps a path that ends with it.

A document may describe less than the code does, and that is never flagged.
Only a name that points at nothing is. It never says a document is right,
because a described flow can change shape without any name going missing.

Documents changed longest ago, counted in commits since, come first. That order
says where to look first and is never printed.

With --since-visit it prints only what is new since the last visit: a name
already missing on the `last-light-pass` date in `.ai-build-kit-maintenance`
was raised then, so it is left out. That earlier state is read again from Git
history, in a temporary copy, and never saved.

Exit codes: 0 nothing to report, 1 findings printed, 2 not a project under
Git.

It reads the project and writes nothing. Run it from the project root:

    python3 <maintain skill folder>/scripts/document-claims.py [--since-visit]
"""

import functools
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

KIT_OWNED = {"WORKFLOW.md", "AGENTS.md", "masterplan.md", "CHANGELOG.md", "plan.local.md"}
EXTENSIONS = (
    ".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs", ".py", ".rb", ".go", ".rs",
    ".java", ".kt", ".cs", ".php", ".md", ".json", ".yml", ".yaml", ".toml",
    ".sh", ".sql", ".html", ".css", ".txt", ".csv", ".ini", ".cfg",
)
CODE_SPAN = re.compile(r"`([^`\n]+)`")
LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
COMMAND = re.compile(r"\b(npm|pnpm|yarn) run ([\w:.-]+)|\bmake ([\w.-]+)")
ENV_NAME = re.compile(r"^[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+$")


def git(*args):
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    return result.stdout if result.returncode == 0 else ""


def ignored(path):
    return subprocess.run(
        ["git", "check-ignore", "-q", path], capture_output=True
    ).returncode == 0


def documents():
    found = []
    if os.path.isfile("README.md"):
        found.append("README.md")
    if os.path.isfile("AGENTS.md"):
        with open("AGENTS.md", encoding="utf-8") as handle:
            text = handle.read()
        named = LINK.findall(text) + CODE_SPAN.findall(text)
        for name in named:
            name = name.split("#")[0].strip()
            if not name.endswith(".md") or name.startswith(("http:", "https:")):
                continue
            name = os.path.normpath(name)
            if os.path.basename(name) in KIT_OWNED or name.startswith(".agents"):
                continue
            if os.path.isfile(name) and name not in found:
                found.append(name)
    return found


def package_scripts():
    try:
        with open("package.json", encoding="utf-8") as handle:
            return set(json.load(handle).get("scripts", {}))
    except (OSError, ValueError):
        return None


def make_targets():
    try:
        with open("Makefile", encoding="utf-8") as handle:
            return {m.group(1) for m in re.finditer(r"^([\w.-]+)\s*:", handle.read(), re.M)}
    except OSError:
        return None


def looks_like_path(name):
    if " " in name or name.startswith(("http:", "https:", "-", "$")):
        return False
    if any(mark in name for mark in "<>*?{}|=@~"):
        return False
    if name.startswith("node_modules") or "://" in name:
        return False
    # A file name ends in a file ending, and a folder name ends in a slash.
    # Anything else with a slash in it is a command such as /shape, a
    # repository such as owner/name, or a web address, and is not checked.
    if "/" in name and "." in name.split("/")[0].lstrip("."):
        return False
    return name.endswith(EXTENSIONS) or name.endswith("/")


@functools.lru_cache(maxsize=None)
def saved_paths():
    """Every file git tracks, and every folder holding one."""
    paths = set()
    for path in git("ls-files").split("\n"):
        parts = [part for part in path.split("/") if part]
        paths.update("/".join(parts[:end]) for end in range(1, len(parts) + 1))
    return paths


def path_exists(name, document):
    bare = name.split("#")[0].split(":")[0].rstrip("/")
    if not bare:
        return True
    beside = os.path.join(os.path.dirname(document), bare)
    for candidate in (os.path.normpath(bare), os.path.normpath(beside)):
        if os.path.exists(candidate) or ignored(candidate):
            return True
    # Written from some other folder, a name is still present if a saved path
    # ends with it: `deploy.sh` or `lib/check.sh` wherever the project keeps it.
    tail = "/".join(p for p in bare.split("/") if p not in ("", ".", ".."))
    return any(path == tail or path.endswith("/" + tail) for path in saved_paths())


def env_named_in_code(name, documents_read):
    hits = git("grep", "-l", "-w", "-F", name).split()
    return any(hit not in documents_read and not hit.endswith(".md") for hit in hits)


def claims(document, documents_read, scripts, targets):
    missing = []
    fenced = False
    with open(document, encoding="utf-8") as handle:
        lines = handle.read().split("\n")
    for number, line in enumerate(lines, start=1):
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        for target in LINK.findall(line):
            if target.startswith(("http:", "https:", "mailto:", "#")):
                continue
            if not path_exists(target, document):
                missing.append((number, "link", target))
        for match in COMMAND.finditer(line):
            if match.group(3):
                if targets is not None and match.group(3) not in targets:
                    missing.append((number, "command", "make " + match.group(3)))
            elif scripts is not None and match.group(2) not in scripts:
                missing.append((number, "command", f"{match.group(1)} run {match.group(2)}"))
        spans = CODE_SPAN.findall(line) if not fenced else []
        for span in spans:
            span = span.strip()
            if ENV_NAME.match(span):
                if not env_named_in_code(span, documents_read):
                    missing.append((number, "environment variable", span))
            elif looks_like_path(span) and not path_exists(span, document):
                missing.append((number, "file", span))
    return missing


def commits_since(document):
    last = git("log", "-1", "--format=%H", "--", document).strip()
    if not last:
        return 0
    count = git("rev-list", "--count", f"{last}..HEAD").strip()
    return int(count) if count.isdigit() else 0


def findings():
    saved_paths.cache_clear()
    read = documents()
    scripts, targets = package_scripts(), make_targets()
    found = []
    for document in read:
        for number, kind, name in claims(document, read, scripts, targets):
            found.append((commits_since(document), document, number, kind, name))
    found.sort(key=lambda f: (-f[0], f[1], f[2]))
    return [f[1:] for f in found]


def at_last_visit(line_name):
    """The findings as they stood at the last visit, or None when there is none."""
    try:
        with open(".ai-build-kit-maintenance", encoding="utf-8") as handle:
            record = handle.read()
    except OSError:
        return None
    date = re.search(r"^" + line_name + r":?\s*(\d{4}-\d{2}-\d{2})", record, re.M)
    commit = git("rev-list", "-1", f"--before={date.group(1)} 23:59:59", "HEAD").strip() if date else ""
    if not commit:
        return None
    here, folder = os.getcwd(), tempfile.mkdtemp()
    copy = os.path.join(folder, "earlier")
    try:
        cloned = subprocess.run(["git", "clone", "-q", "--shared", "--no-checkout", here, copy],
                                capture_output=True).returncode == 0
        if not cloned or subprocess.run(["git", "checkout", "-q", "--detach", commit], cwd=copy,
                                        capture_output=True).returncode != 0:
            return None
        os.chdir(copy)
        return findings()
    finally:
        os.chdir(here)
        saved_paths.cache_clear()
        shutil.rmtree(folder, ignore_errors=True)


def main():
    if subprocess.run(["git", "rev-parse", "--git-dir"], capture_output=True).returncode != 0:
        print("This folder is not a project under Git.", file=sys.stderr)
        return 2
    found = findings()
    if "--since-visit" in sys.argv[1:]:
        earlier = at_last_visit("last-light-pass")
        if earlier is not None:
            known = {(document, kind, name) for document, _, kind, name in earlier}
            found = [f for f in found if (f[0], f[2], f[3]) not in known]
    for document, number, kind, name in found:
        print(f"{document}:{number}\t{kind}\t{name}")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
