#!/usr/bin/env python3
"""Find stale document names and bounded explicit package-script mismatches.

Reads README.md and every document AGENTS.md points at. Where AGENTS.md points
at `docs/README.md`, the list of the project's concept files, each document
that list names is read too, since the list is how AGENTS.md points at them.
Nothing else under `docs/` is read. For each line it looks
for four kinds of name and checks that each still exists: a file or folder, a
link to another file, an `npm run`, `pnpm run`, `yarn run` or `make` command,
and an environment variable. It prints one line per name that does not exist,
as `document:line<TAB>kind<TAB>name`. Wiring results use the same columns,
with plain evidence as the final field. When there are no findings or verification limits, it prints nothing.

A file name is one that ends in a file ending, and a folder name one that ends
in a slash. So `/shape`, `owner/name` and `example.com/page` are not taken for
files. A name written from some other folder is found wherever the project
keeps a path that ends with it.

The `changes/` folder is part of the changelog. It is empty between folds and
a finished piece's file leaves it at the next one, so a name inside it is
never reported.

A document may describe less than the code does, and that is never flagged.
A missing name or a supported explicit route mismatch is flagged.
It never says a document is right,
because arbitrary prose and indirect shell wiring remain unverified.

Explicit Required command and Required check declarations are described in
references/document-read.md. They read only package.json script entries and
optional local file conditions, without running scripts or hooks. Root
AGENTS.md is read for these declarations only, not for stale names.

Documents changed longest ago, counted in commits since, come first. That order
says where to look first and is never printed.

It reads the project and writes nothing. Run it from the project root:

    python3 <sync skill folder>/scripts/document-claims.py
"""

import functools
import json
import os
import re
import subprocess
from pathlib import Path
import sys

KIT_OWNED = {"WORKFLOW.md", "AGENTS.md", "masterplan.md", "CHANGELOG.md", "plan.local.md"}
CHANGES = "changes"
CONCEPTS = os.path.join("docs", "README.md")
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
    result = subprocess.run(
        ["git", "-c", "core.fsmonitor=false", "-c", "core.hooksPath=/dev/null", *args],
        capture_output=True, text=True
    )
    return result.stdout if result.returncode == 0 else ""


def ignored(path):
    return subprocess.run(
        ["git", "-c", "core.fsmonitor=false", "-c", "core.hooksPath=/dev/null",
         "check-ignore", "-q", path], capture_output=True
    ).returncode == 0


def local_file(name):
    """Do not open a document or mechanism outside the project."""
    try:
        root = Path.cwd().resolve()
        path = Path(name).resolve()
        return (path == root or root in path.parents) and path.is_file()
    except (OSError, RuntimeError, ValueError):
        return False


def named_documents(source, found):
    """Add each Markdown document `source` names that exists, in order."""
    with open(source, encoding="utf-8") as handle:
        text = handle.read()
    named = LINK.findall(text) + CODE_SPAN.findall(text)
    for name in named:
        name = name.split("#")[0].strip()
        if not name.endswith(".md") or name.startswith(("http:", "https:")):
            continue
        # A name in the concept list may be written from the docs/ folder.
        candidates = [os.path.normpath(name)]
        if source != "AGENTS.md":
            candidates.append(os.path.normpath(os.path.join(os.path.dirname(source), name)))
        for name in candidates:
            if os.path.basename(name) in KIT_OWNED or name.startswith((".agents", CHANGES + "/")):
                break
            if local_file(name):
                if name not in found:
                    found.append(name)
                break


def documents():
    found = []
    if local_file("README.md"):
        found.append("README.md")
    if local_file("AGENTS.md"):
        named_documents("AGENTS.md", found)
    if CONCEPTS in found:
        named_documents(CONCEPTS, found)
    return found


def package_scripts():
    if not local_file("package.json"):
        return None
    try:
        with open("package.json", encoding="utf-8") as handle:
            scripts = json.load(handle).get("scripts", {})
            return scripts if isinstance(scripts, dict) else None
    except (OSError, ValueError, AttributeError):
        return None


def make_targets():
    if not local_file("Makefile"):
        return None
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
    if os.path.normpath(bare).split(os.sep)[0] == CHANGES:
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
        # Explicit declarations have their own conditional and syntax handling.
        if not fenced and re.match(r"^(?:[-*]\s+)?Required (?:command|check):", line.strip()):
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


# Declarations are whole lines, with an optional Markdown bullet and full stop.
RUN_LITERAL = r"(?:npm|pnpm|yarn) run [\w:.][\w:.-]*"
REQUIRED = re.compile(
    rf"^Required (command|check): `({RUN_LITERAL})`"
    rf"(?: via `({RUN_LITERAL})`)?(?: when (.+?))?\.?$"
)
EDGE = re.compile(rf"^({RUN_LITERAL})$")
# These exact terminal commands carry no package-script edges. Other command
# bodies are opaque, even if they happen to mention the required check.
TERMINALS = {"node --test", "tsc --noEmit", "true"}


def local_condition(condition):
    """Return active, inactive or unknown without reading the file's contents."""
    match = re.fullmatch(r"file `([^`]+)` exists", condition)
    if not match:
        return None, "condition is outside the supported file-exists syntax"
    name = match.group(1)
    path = Path(name)
    if path.is_absolute() or ".." in path.parts or not path.parts:
        return None, "condition must name a file inside the project"
    root = Path.cwd().resolve()
    try:
        resolved = path.resolve()
        if resolved != root and root not in resolved.parents:
            return None, "condition leads outside the project"
        # A broken link is not evidence that the condition is inactive.
        for parent in (path, *path.parents):
            if parent.is_symlink() and not parent.exists():
                return None, "condition contains a broken file link"
        if path.exists() and not path.is_file():
            return None, "condition names something other than a file"
        return path.is_file(), f"file {name!r} {'exists' if path.is_file() else 'is absent'}"
    except (OSError, RuntimeError, ValueError):
        return None, "condition file cannot be inspected safely"


def route_evidence(route, check, scripts):
    """Inspect literal run edges only; return reached, unknown, evidence."""
    evidence, visiting, visited = [], set(), set()
    reached = False
    unknown = False

    def visit(name):
        nonlocal reached, unknown
        if name in visiting:
            unknown = True
            evidence.append(f"scripts.{name}: cycle")
            return
        if name in visited:
            return
        if len(visited) >= 100:
            unknown = True
            evidence.append("route exceeds the 100-entry inspection limit")
            return
        visited.add(name)
        visiting.add(name)
        hooks = [prefix + name for prefix in ("pre", "post") if prefix + name in scripts]
        if hooks:
            unknown = True
            evidence.append(f"scripts.{name}: lifecycle entries {json.dumps(hooks)}")
        body = scripts.get(name)
        evidence.append(f"scripts.{name} = {json.dumps(body, ensure_ascii=True)}")
        if name == check:
            reached = True
            visiting.remove(name)
            return
        if not isinstance(body, str):
            unknown = True
        else:
            for part in body.split("&&"):
                part = part.strip()
                edge = EDGE.fullmatch(part)
                if edge:
                    visit(part.split()[-1])
                elif part not in TERMINALS:
                    unknown = True
        visiting.remove(name)

    visit(route)
    return reached, unknown, "package.json " + "; ".join(evidence)


def wiring_claims(document, scripts):
    findings = []
    fenced = None
    with open(document, encoding="utf-8") as handle:
        for number, line in enumerate(handle, start=1):
            if fenced:
                mark, length = fenced
                if re.fullmatch(r" {0,3}" + re.escape(mark) + "{" + str(length) + r",}[ \t]*", line.rstrip("\r\n")):
                    fenced = None
                continue
            fence = re.match(r"^ {0,3}(`{3,}|~{3,})([^\r\n]*)$", line.rstrip("\r\n"))
            if fence and (fence.group(1)[0] != "`" or "`" not in fence.group(2)):
                fenced = (fence.group(1)[0], len(fence.group(1)))
                continue
            line = line.strip()
            line = re.sub(r"^[-*]\s+", "", line)
            if not line.startswith(("Required command:", "Required check:")):
                continue
            match = REQUIRED.fullmatch(line)
            if not match or (match.group(1) == "check") != bool(match.group(3)):
                findings.append((number, "unverified rule", "Declaration is outside the supported command/check syntax."))
                continue
            _, command, route, condition = match.groups()
            label = f"{route} must run {command}" if route else f"{command} must exist"
            if condition:
                active, reason = local_condition(condition)
                if active is not True:
                    kind = "inactive rule" if active is False else "unverified rule"
                    findings.append((number, kind, f"{label}: {reason}; wiring was not judged."))
                    continue
            if scripts is None:
                findings.append((number, "unverified rule", f"{label}: package.json scripts cannot be read."))
                continue
            check = command.split()[-1]
            route_name = route.split()[-1] if route else None
            missing = [name for name in (check, route_name) if name is not None and name not in scripts]
            if missing:
                findings.append((number, "wiring mismatch", f"{label}: package.json has no script {', '.join(missing)}; inspected scripts keys {json.dumps(sorted(scripts))}."))
                continue
            if not isinstance(scripts[check], str) or not scripts[check].strip():
                findings.append((number, "unverified rule", f"{label}: package.json scripts.{check} is not a non-empty command string."))
                continue
            if route:
                reached, unknown, evidence = route_evidence(route_name, check, scripts)
                if unknown:
                    findings.append((number, "unverified rule", f"{label}: shell indirection, an unreadable script or a cycle prevents verification; inspected {evidence}."))
                elif not reached:
                    findings.append((number, "wiring mismatch", f"{route} does not call required check {command}; inspected {evidence}."))
    return findings


def commits_since(document):
    last = git("log", "-1", "--format=%H", "--", document).strip()
    if not last:
        return 0
    count = git("rev-list", "--count", f"{last}..HEAD").strip()
    return int(count) if count.isdigit() else 0


def main():
    read = documents()
    scripts, targets = package_scripts(), make_targets()
    found = []
    for document in read:
        for number, kind, name in claims(document, read, scripts, targets):
            found.append((commits_since(document), document, number, kind, name))
    for document in read + (["AGENTS.md"] if local_file("AGENTS.md") else []):
        for number, kind, name in wiring_claims(document, scripts):
            found.append((commits_since(document), document, number, kind, name))
    found.sort(key=lambda f: (-f[0], f[1], f[2]))
    for _, document, number, kind, name in found:
        print(f"{document}:{number}\t{kind}\t{name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
