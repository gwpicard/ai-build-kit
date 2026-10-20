#!/usr/bin/env sh
# site-links.sh: checks the site's source links point to real repository paths and each stage link finds its heading.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$ROOT"

python3 - <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path.cwd()
docs_root = root / "site/src/content/docs"
workflow_path = root / "site/data/workflow.json"
page_path = docs_root / "what-it-checks.md"
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
    page = page_path.read_text(encoding="utf-8")
except OSError as error:
    fail(f"cannot read site/src/content/docs/what-it-checks.md: {error}")

heading_lines = list(re.finditer(r"(?m)^## (.+?)\s*$", page))
checks_section = None
for index, match in enumerate(heading_lines):
    if match.group(1) == "Checks at each step":
        end = heading_lines[index + 1].start() if index + 1 < len(heading_lines) else len(page)
        checks_section = page[match.end():end]
        break
if checks_section is None:
    fail("what-it-checks.md has no 'Checks at each step' section")

stage_sections = list(re.finditer(r"(?m)^### (.+?)\s*$", checks_section))
if not stage_sections:
    fail("'Checks at each step' has no stage headings")
for index, match in enumerate(stage_sections):
    end = stage_sections[index + 1].start() if index + 1 < len(stage_sections) else len(checks_section)
    body = checks_section[match.end():end]
    if not source_link.search(body):
        fail(f"stage section '{match.group(1)}' has no source link")

table_heading = re.search(r"(?m)^## What the kit always holds\s*$", page)
if not table_heading:
    fail("what-it-checks.md has no 'What the kit always holds' section")
table_end = re.search(r"(?m)^## ", page[table_heading.end():])
table_body_end = table_heading.end() + table_end.start() if table_end else len(page)
table_body = page[table_heading.end():table_body_end]
rows = [line for line in table_body.splitlines() if line.startswith("|")]
data_rows = [line for line in rows if not re.match(r"^\|\s*:?-+", line)]
if len(data_rows) < 2:
    fail("'What the kit always holds' has no data rows")
for row_number, row in enumerate(data_rows[1:], start=1):
    cells = [cell.strip() for cell in row.strip("|").split("|")]
    if len(cells) < 2 or not source_link.search(cells[1]):
        fail(f"'What the kit always holds' row {row_number} has no source link in How")

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

print(f"site links: {link_count} links checked")
PY
