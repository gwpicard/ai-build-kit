#!/usr/bin/env sh
# site-links.sh: checks the site's source links point to real repository paths, each stage link finds its heading, and the built pages link to no .md file.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$ROOT"

# The built site is checked too. Build it when it is missing or older than its
# sources; say so and skip that part when it cannot be built here.
BUILD=skip
dist="$ROOT/site/dist"
if [ ! -f "$dist/index.html" ] ||
   [ -n "$(find "$ROOT/site/src" "$ROOT/site/data" "$ROOT/site/scripts" "$ROOT/site/astro.config.mjs" "$ROOT/docs" "$ROOT/llms.txt" -newer "$dist/index.html" -type f 2>/dev/null | head -n 1)" ]; then
  if [ -d "$ROOT/site/node_modules" ] && command -v npm >/dev/null 2>&1 &&
     (cd "$ROOT/site" && npm run build >/dev/null 2>&1); then
    BUILD=built
  else
    echo "site links: the built site is missing or stale and could not be built here, so the built-page check is skipped" >&2
  fi
else
  BUILD=present
fi
export BUILD

python3 - <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path.cwd()
docs_root = root / "site/src/content/docs"
workflow_path = root / "site/data/workflow.json"
steps_path = docs_root / "how-it-works.mdx"
rules_path = docs_root / "what-it-checks.md"
source_link = re.compile(
    r"https://github\.com/gwpicard/ai-build-kit/(blob|tree)/stable/([^\)\s\"'#?<>]+)"
)


def fail(message):
    print(f"site links: {message}", file=sys.stderr)
    raise SystemExit(1)


files = [
    path for path in docs_root.rglob("*")
    if path.is_file()
    and path.suffix in {".md", ".mdx"}
    and "generated" not in path.relative_to(docs_root).parts
]
files.append(workflow_path)
link_count = 0

for path in files:
    relative = path.relative_to(root).as_posix()
    content = path.read_text(encoding="utf-8")
    for kind, target in source_link.findall(content):
        link_count += 1
        if not (root / target).exists():
            fail(f"{relative} links to {target}, which is not in the repository")

try:
    page = steps_path.read_text(encoding="utf-8")
    rules = rules_path.read_text(encoding="utf-8")
except OSError as error:
    fail(f"cannot read the steps or rules page: {error}")

heading_lines = list(re.finditer(r"(?m)^## (.+?)\s*$", page))
checks_section = None
for index, match in enumerate(heading_lines):
    if match.group(1) == "Step by step":
        end = heading_lines[index + 1].start() if index + 1 < len(heading_lines) else len(page)
        checks_section = page[match.end():end]
        break
if checks_section is None:
    fail("how-it-works.mdx has no step sections")

stage_sections = list(re.finditer(r"(?m)^### (.+?)\s*$", checks_section))
if not stage_sections:
    fail("the steps page has no stage headings")
for index, match in enumerate(stage_sections):
    end = stage_sections[index + 1].start() if index + 1 < len(stage_sections) else len(checks_section)
    body = checks_section[match.end():end]
    if not source_link.search(body):
        fail(f"stage section '{match.group(1)}' has no source link")

rule_heading = re.search(r"(?m)^## Rules checked in every project\s*$", rules)
if not rule_heading:
    fail("what-it-checks.md has no rules section")
rule_end = re.search(r"(?m)^## ", rules[rule_heading.end():])
rule_body_end = rule_heading.end() + rule_end.start() if rule_end else len(rules)
rule_body = rules[rule_heading.end():rule_body_end]
rows = [line for line in rule_body.splitlines() if line.startswith("|")]
data_rows = [line for line in rows if not re.match(r"^\|\s*:?-+", line)]
if len(data_rows) < 2:
    fail("the rules table has no data rows")
for row_number, row in enumerate(data_rows[1:], start=1):
    cells = [cell.strip() for cell in row.strip("|").split("|")]
    if len(cells) < 2 or not source_link.search(cells[1]):
        fail(f"rules row {row_number} has no source link in its checker")

try:
    stages = json.loads(workflow_path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as error:
    fail(f"cannot read site/data/workflow.json: {error}")

headings = re.findall(r"(?m)^#{1,6}\s+(.+?)\s*#*\s*$", page)


def slugify(heading):
    clean = re.sub(r"[^a-z0-9 -]", "", heading.lower())
    return re.sub(r"\s+", "-", clean.strip())


heading_slugs = {slugify(heading) for heading in headings}
for stage in stages:
    stage_id = stage.get("id", "(missing id)")
    anchor = stage.get("checks_anchor")
    if not isinstance(anchor, str) or not anchor:
        fail(f"stage {stage_id} has no checks_anchor")
    if anchor not in heading_slugs:
        fail(f"stage {stage_id} checks_anchor '{anchor}' has no matching heading")
    section = next((item for item in stage_sections if slugify(item.group(1)) == anchor), None)
    if section is None:
        fail(f"stage {stage_id} has no matching step section")
    section_index = stage_sections.index(section)
    section_end = stage_sections[section_index + 1].start() if section_index + 1 < len(stage_sections) else len(checks_section)
    body = checks_section[section.end():section_end]
    listed_paths = set(re.findall(r"https://github\.com/gwpicard/ai-build-kit/blob/stable/([^\)]+)", body))
    mapped_paths = {check.get("path") for check in stage.get("checks", [])}
    if listed_paths != mapped_paths:
        fail(f"stage {stage_id} checks differ between the page and workflow map")

import os
if os.environ.get("BUILD") in {"built", "present"}:
    href = re.compile(r"""href=(?:"([^"]*)"|'([^']*)')""")
    built = 0
    for page_path in (root / "site/dist").rglob("*.html"):
        built += 1
        for match in href.finditer(page_path.read_text(encoding="utf-8", errors="replace")):
            target = match.group(1) if match.group(1) is not None else match.group(2)
            if re.match(r"^(https?:)?//", target) or target.startswith(("mailto:", "#")):
                continue
            if re.search(r"\.md(#[^\s]*)?$", target.split("?")[0]):
                fail(f"{page_path.relative_to(root).as_posix()} has an internal link to {target}, which ends in .md")
    print(f"site links: {built} built pages checked for .md links")

print(f"site links: {link_count} links checked")
PY
