#!/usr/bin/env python3
"""Move a project's masterplan from an old path record to the risk record.

An older project records a build path: a `Path:` field, `Why:`, sensitive
areas and acceptances. The kit now reads a risk record instead. This script
reads the old section and writes the new one. It keeps every risk area,
acceptance date and word the person gave, and it adds nothing the person did
not say. It is the one place the mapping lives, so the same record always
moves the same way.

Usage:

    risk_move.py [PROJECT]            show the old section, the proposed
                                      record and the open pieces it would
                                      name; change nothing
    risk_move.py --apply [PROJECT]    write the record, name risk areas on the
                                      open pieces and add a changelog entry

PROJECT defaults to the current folder.

The show output has a before, an after and a pieces block, then `say` lines
holding the plain sentences the person hears. `--apply` prints `moved`,
`piece` and `changelog` lines, then the same `say` lines.

What moves, and how:

- `Access`, `Accepted`, `Runs on its own`, `Recheck when`, `Last checked` are
  copied as written. `Sensitive areas` becomes `Risk areas`, every area line
  as written, so an area marked accepted stays accepted and one marked not yet
  done stays open. Nothing is turned into a completed caution.
- `Path` and `Why` stay as `Earlier path` and `Earlier why`, as history.
- The four old control fields (`Required controls`, `Outside help`) become
  area lines. A control that names no area is a standing rule of the kit and
  leaves the record, named in the changelog entry.
- `Exposed`, `Data`, `Wrong answer` and `Recovery` start as "not yet
  answered". The fit check's three questions fill them.
- A check the moved project cannot yet run starts report-only, on a
  `Report-only:` line: an area with no `paths:` line, whose changes the
  project check cannot hold, and open pieces that name no risk area.

Exit codes: 0 shown or applied, 1 nothing to move, 2 could not run.
"""

import datetime
import fnmatch
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
INSTALLED = os.path.dirname(os.path.dirname(HERE))
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(INSTALLED, "quality-checks", "scripts"))
try:
    from reaches_line import REACHES_LINE
except ImportError:  # the check is run from a copy that lacks its sibling skill
    REACHES_LINE = r"^[ \t]*(?:[-*][ \t]*)?(?:\*\*Reaches:\*\*|Reaches:)[ \t]*(\S[^\r\n]*)"

# The values the old Path field took, from the first release to the last.
OLD_PATHS = ("Explore privately", "Build and run it", "Build with care",
             "Build with expert help", "Professional-led")
OLD_FIELD = re.compile(r"^(Path|Why|Required controls|Outside help|Access|Sensitive areas|Accepted|"
                       r"Runs on its own|Recheck when|Last checked):[ \t]*(.*?)\s*$")
OLD_RECORD = re.compile(r"^(Path:[ \t]*(%s)\b|Required controls:[ \t]*\S|Outside help:[ \t]*\S)"
                        % "|".join(re.escape(p) for p in OLD_PATHS))
# Comments the kit's own template put in the old section. Any other comment is
# the person's and stays.
KIT_COMMENTS = ("Rewritten only by re-running the fit check", "Build with care only.", "Who can get in.")
NOT_ANSWERED = "not yet answered"

AREAS = (
    ("personal or sensitive data", r"personal|sensitive data|health|salary|\bpay\b|home address|identity|"
                                   r"passport|client record|customer record|patient|private data"),
    ("money", r"money|payment|billing|invoice|refund|\bcard\b|\bprice|financial figure|\bbills?\b"),
    ("sign-in and permissions", r"sign-?in|log-?in|permission|who can see|access review|password|\broles?\b"),
    ("automatic action", r"\bsend|e-?mail|message|notif|scheduled|automatic action|irreversible"),
    ("irreplaceable live data", r"backup|only copy|irreplaceable|restore|cannot be recreated|\bmigrat"),
    ("regulated decisions", r"regulated|legal|clinic|medical|safety|compliance|employment|lawyer"),
)
# A control that names no area is a standing rule of the kit and of the save route.
STANDING = re.compile(r"secret|destructive|pull request|automatic check|checks? pass", re.I)
DATE = r"\d{4}-\d{2}-\d{2}"


# --- reading ------------------------------------------------------------------

def read_text(project):
    path = os.path.join(project, "masterplan.md")
    if os.path.islink(path):
        raise RuntimeError("masterplan.md is a link, so it was left alone")
    try:
        with open(path, encoding="utf-8", newline="") as handle:
            return handle.read()
    except OSError as error:
        raise RuntimeError("could not read masterplan.md: %s" % error)


def outside_comments(lines):
    """Index and text of each line that sits outside an HTML comment."""
    inside = False
    for index, line in enumerate(lines):
        text = line.rstrip("\r")
        if inside:
            inside = "-->" not in text
            continue
        if text.lstrip().startswith("<!--"):
            inside = "-->" not in text
            continue
        yield index, text


def first_old_line(lines):
    """Line number (from 1) and text of the first old path or control field."""
    for index, text in outside_comments(lines):
        if OLD_RECORD.match(text):
            return index + 1, text.strip()
    return None


def has_old_record(project):
    try:
        found = first_old_line(read_text(project).split("\n"))
    except RuntimeError:
        return None
    return found


def section_bounds(lines, at):
    """The `## ` section holding line index `at`, as start and end indexes."""
    starts = [i for i in range(at) if re.match(r"^#{1,2} ", lines[i])]
    if not starts or not lines[starts[-1]].startswith("## "):
        return None
    end = next((i for i in range(at + 1, len(lines)) if re.match(r"^#{1,2} ", lines[i])), len(lines))
    return starts[-1], end


def parse_section(body):
    """Split the lines under the heading into fields, comments and other text.
    A field keeps every line that follows it up to a blank line or the next
    field. Text that is no field is kept, never dropped."""
    fields, extras, comments = [], [], []
    current = None
    block = None
    for raw in body:
        text = raw.rstrip("\r")
        if block is not None:
            block.append(text)
            if "-->" in text:
                if not any(marker in "\n".join(block) for marker in KIT_COMMENTS):
                    comments.append(block)
                block = None
            continue
        if text.startswith("<!--"):
            block = [text]
            current = None
            if "-->" in text:
                if not any(marker in text for marker in KIT_COMMENTS):
                    comments.append(block)
                block = None
            continue
        match = OLD_FIELD.match(text)
        if match:
            current = [match.group(1), match.group(2), []]
            fields.append(current)
        elif not text.strip():
            current = None
            if extras and extras[-1] != "":
                extras.append("")
        elif current is not None:
            current[2].append(text)
        else:
            extras.append(text)
    while extras and extras[-1] == "":
        extras.pop()
    return fields, extras, comments


# --- mapping ------------------------------------------------------------------

def area_of(text):
    for name, pattern in AREAS:
        if re.search(pattern, text, re.I):
            return name
    return None


def controls_to_areas(fields):
    """Area lines from the four-path control fields, and the controls that
    left the record because they name no area."""
    order, left = [], []
    notes = {}

    def add(area, touch, caution):
        if area not in notes:
            notes[area] = {"touch": None, "cautions": []}
            order.append(area)
        if touch and not notes[area]["touch"]:
            notes[area]["touch"] = touch
        if caution and caution not in notes[area]["cautions"]:
            notes[area]["cautions"].append(caution)

    for name, value, rest in fields:
        text = " ".join([value] + [r.strip() for r in rest]).strip()
        if name == "Outside help" and text and text.lower() != "none":
            level, _, scope = text.partition(", for ")
            level, scope = level.strip(), scope.strip().replace(";", ",")
            add(area_of(scope) or "unplaced", scope or None, level)
        elif name == "Required controls" and text and text.lower() != "none":
            for entry in re.split(r"[,;]\s+", text.rstrip(". ")):
                entry = entry.strip()
                if not entry:
                    continue
                if STANDING.search(entry):
                    left.append(entry)
                else:
                    add(area_of(entry) or "unplaced", None, entry)
    lines = []
    for area in order:
        touch = notes[area]["touch"] or "from the old required controls"
        lines.append("  %s: %s; caution: %s; not yet done" % (area, touch, " and ".join(notes[area]["cautions"])))
    return lines, left


def accepted_texts(field_lines):
    """Every acceptance record in the old section: the Accepted fields, and
    any indented Accepted line under an area."""
    found = []
    for name, value, rest in field_lines:
        if name == "Accepted":
            found.append(" ".join([value] + [r.strip() for r in rest]))
        for line in rest:
            if re.match(r"^\s+Accepted:", line):
                found.append(line.strip())
    return found


def area_entries(area_lines):
    """Name, path lines and the line itself for each area under Risk areas."""
    areas = []
    for line in area_lines:
        match = re.match(r"^  ([^ :][^:]*):", line)
        if match and match.group(1).strip() != "none":
            areas.append({"name": match.group(1).strip(), "paths": [], "line": line})
        elif areas:
            paths = re.match(r"^\s+paths:\s*(.*)$", line)
            if paths:
                areas[-1]["paths"] += [p.strip().removeprefix("./") for p in paths.group(1).split(",") if p.strip()]
    return areas


def plan_record(project, today):
    """The new section's parts, read from the old one. Nothing is written."""
    text = read_text(project)
    lines = text.split("\n")
    found = first_old_line(lines)
    if not found:
        return None
    bounds = section_bounds(lines, found[0] - 1)
    if not bounds:
        raise RuntimeError("the old fields sit under no section heading of their own, so I left them as they are")
    start, end = bounds
    fields, extras, comments = parse_section(lines[start + 1:end])
    named = {}
    for name, value, rest in fields:
        named.setdefault(name, []).append((value, rest))
    area_lines, left = [], []
    if "Sensitive areas" in named:
        value, rest = named["Sensitive areas"][0]
        area_lines = [l for l in rest]
        areas_value = value
    else:
        areas_value = ""
    if "Required controls" in named or "Outside help" in named:
        built, left = controls_to_areas(fields)
        area_lines = area_lines + built
    return {
        "lines": lines, "start": start, "end": end, "fields": fields, "named": named,
        "extras": extras, "comments": comments, "area_value": areas_value,
        "area_lines": area_lines, "left": left, "eol": "\r" if "\r\n" in text else "",
        "old": lines[start:end], "today": today,
    }


def field_lines(plan, name, default=None):
    """Every field of this name, as written, ready to place. A field left
    empty takes the default, so an empty acceptance reads none."""
    entries = plan["named"].get(name, [])
    if default is not None and not any(value or rest for value, rest in entries):
        return ["%s: %s" % (name, default)]
    out = []
    for value, rest in entries:
        out.append(("%s: %s" % (name, value)).rstrip())
        out += rest
    return out


def render(plan, report_only):
    """The new section as a list of lines, without line endings."""
    out = ["## Risk record", ""]
    for block in plan["comments"]:
        out += block + [""]
    out += ["Exposed: " + NOT_ANSWERED, "Data: " + NOT_ANSWERED,
            "Wrong answer: " + NOT_ANSWERED, "Recovery: " + NOT_ANSWERED]
    out += field_lines(plan, "Access")
    if plan["area_lines"]:
        out.append(("Risk areas: " + plan["area_value"]).rstrip() if plan["area_value"] else "Risk areas:")
        out += plan["area_lines"]
    else:
        out.append("Risk areas: " + (plan["area_value"] or "none"))
    out += field_lines(plan, "Accepted", "none")
    out += field_lines(plan, "Runs on its own", "off")
    if report_only:
        out.append("Report-only: " + report_only)
    out += field_lines(plan, "Recheck when")
    out += field_lines(plan, "Last checked")
    path = plan["named"].get("Path")
    if path:
        out.append("Earlier path: %s (until %s)" % (path[0][0], plan["today"]))
    if "Why" in plan["named"]:
        value, rest = plan["named"]["Why"][0]
        out.append("Earlier why: " + value)
        out += rest
    if plan["extras"]:
        out += [""] + plan["extras"]
    out.append("")
    return out


def acceptance_notes(plan):
    """Area lines that say accepted on a date no acceptance record carries.
    They move as written, and the project check holds them open."""
    records = " ".join(accepted_texts(plan["fields"]))
    notes = []
    for area in area_entries(plan["area_lines"]):
        said = re.search(r";\s*accepted\s+(%s)\s*$" % DATE, area["line"], re.I)
        if said and said.group(1) not in records:
            notes.append((area["name"], said.group(1)))
    return notes


# --- the open pieces ----------------------------------------------------------

def gh_json(project, args):
    try:
        result = subprocess.run(["gh"] + args, cwd=project, capture_output=True, text=True, timeout=120)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    try:
        return json.loads(result.stdout)
    except ValueError:
        return None


NAMES_AREAS = re.compile(r"^[ \t]*(?:[-*][ \t]*)?(?:\*\*Risk areas:\*\*|Risk areas:)[ \t]*\S", re.I | re.M)
DONE_WHEN = re.compile(r"^#{2,3}\s+Done when\b", re.I | re.M)


def reached(body):
    match = re.search(REACHES_LINE, body, re.M)
    if not match or "undeclared" in match.group(1).casefold():
        return None
    parts = [p.strip().strip("`.,") for p in re.split(r"[,;]", match.group(1))]
    return [p for p in parts if p and "new files only" not in p.casefold()]


def touches(entry, pattern):
    entry, pattern = entry.rstrip("/"), pattern.rstrip("/")
    if any(c in pattern for c in "*?["):
        return fnmatch.fnmatchcase(entry, pattern) or any(
            fnmatch.fnmatchcase("/".join(entry.split("/")[:i]), pattern) for i in range(1, entry.count("/") + 2))
    return entry == pattern or entry.startswith(pattern + "/") or pattern.startswith(entry + "/")


def decide_piece(body, areas):
    """The Risk areas value for one piece, or None when only a person can tell."""
    if not areas:
        return "none"
    entries = reached(body)
    if not entries:
        return None
    hit = [a["name"] for a in areas if any(touches(e, p) for e in entries for p in a["paths"])]
    if hit:
        return ", ".join(hit)
    return "none" if all(a["paths"] for a in areas) else None


def with_line(body, value):
    eol = "\r\n" if "\r\n" in body else "\n"
    lines = body.split(eol)
    line = "Risk areas: " + value
    at = next((i for i, l in enumerate(lines) if l.lstrip().startswith("<details")), None)
    if at is None:
        while lines and not lines[-1].strip():
            lines.pop()
        lines += ["", line]
    else:
        lines[at:at] = [line, ""]
    return eol.join(lines)


def piece_plan(project, areas):
    """What to write on each open piece that names no risk area. `read` is
    False when GitHub could not be read."""
    issues = gh_json(project, ["issue", "list", "--state", "open", "--json", "number,body", "--limit", "1000"])
    if not isinstance(issues, list):
        return {"read": False, "set": [], "undecided": []}
    chosen, undecided = [], []
    for issue in issues:
        if not isinstance(issue, dict):
            continue
        body = issue.get("body") or ""
        number = issue.get("number")
        if not isinstance(number, int) or not DONE_WHEN.search(body) or NAMES_AREAS.search(body):
            continue
        value = decide_piece(body, areas)
        if value is None:
            undecided.append(number)
        else:
            chosen.append((number, value, body))
    return {"read": True, "set": chosen, "undecided": sorted(undecided)}


def write_piece(project, number, body):
    try:
        result = subprocess.run(["gh", "issue", "edit", str(number), "--body-file", "-"], cwd=project,
                                input=body, capture_output=True, text=True, timeout=120)
    except (OSError, subprocess.TimeoutExpired):
        return False
    return result.returncode == 0


# --- the whole move -----------------------------------------------------------

def report_only_line(plan, pieces, today):
    parts = []
    bare = [a["name"] for a in area_entries(plan["area_lines"]) if not a["paths"]]
    if bare:
        parts.append("area paths for %s, so the project check cannot hold changes to them (since %s)"
                     % (", ".join(bare), today))
    if not pieces["read"]:
        parts.append("piece risk areas, because the open pieces could not be read (since %s)" % today)
    elif pieces["undecided"]:
        n = len(pieces["undecided"])
        parts.append("piece risk areas, because %d open %s name none (since %s)"
                     % (n, "piece does" if n == 1 else "pieces do", today))
    return "; ".join(parts)


def changelog_line(plan, pieces, done, report_only):
    areas = area_entries(plan["area_lines"])
    accepted = [t for t in accepted_texts(plan["fields"]) if t.strip().lower() not in ("", "none")]
    line = ("Moved the masterplan from a path record to the risk record. Kept %d risk %s and %d accepted "
            "%s with their dates and the person's words, and the earlier path and why as history."
            % (len(areas), "area" if len(areas) == 1 else "areas", len(accepted),
               "risk" if len(accepted) == 1 else "risks"))
    if pieces["read"]:
        line += " Named risk areas on %d open %s." % (len(done), "piece" if len(done) == 1 else "pieces")
    if report_only:
        line += " Report-only: " + report_only + "."
    if plan["left"]:
        line += (" Standing rules of the kit that left the record, since they name no area: "
                 + "; ".join(plan["left"]) + ".")
    return line


def check_changelog(project):
    if os.path.islink(os.path.join(project, "CHANGELOG.md")):
        raise RuntimeError("CHANGELOG.md is a link, so it was left alone")


def add_changelog(project, today, line):
    check_changelog(project)
    path = os.path.join(project, "CHANGELOG.md")
    try:
        with open(path, encoding="utf-8", newline="") as handle:
            text = handle.read()
    except FileNotFoundError:
        text = "# Changelog\n\nPlain-language history of the project, newest first.\n"
    except OSError as error:
        raise RuntimeError("could not read CHANGELOG.md: %s" % error)
    eol = "\r\n" if "\r\n" in text else "\n"
    lines = text.split(eol)
    heading = "## " + today
    first = next((i for i, l in outside_comments(lines) if l.startswith("## ")), None)
    entry = "- " + line
    if first is not None and lines[first] == heading:
        lines.insert(first + 2 if first + 1 < len(lines) and not lines[first + 1].strip() else first + 1, entry)
    else:
        at = first if first is not None else len(lines)
        block = [heading, "", entry, ""]
        if first is None and lines and lines[-1].strip():
            block = [""] + block
        lines[at:at] = block
    with open(path, "w", encoding="utf-8", newline="") as handle:
        handle.write(eol.join(lines))


def sentences(plan, pieces, report_only):
    said = []
    path = plan["named"].get("Path")
    if path and path[0][0].startswith("Explore privately"):
        said.append("This project was recorded as private only. The kit now expects every project to be a "
                    "tool that can be shared and go live: a repository with issues switched on, and access "
                    "to a host and a database. Nothing changes for that here, and I can run the conditions "
                    "check and tell you what is missing.")
    if plan["left"]:
        said.append("These controls name no risk area, so they are standing rules of the kit and leave the "
                    "record: %s." % "; ".join(plan["left"]))
    for line in plan["area_lines"]:
        if line.startswith("  unplaced:"):
            said.append("One old control fits none of the six risk areas. I kept its words on a line called "
                        "unplaced, and the next fit check places it.")
            break
    for name, date in acceptance_notes(plan):
        said.append("The line for %s says accepted on %s, but no acceptance record carries that date. It moves "
                    "as written and the project check keeps it open." % (name, date))
    if report_only:
        said.append("These checks cannot run in this project yet, so they start report-only. They say what "
                    "they find and hold nothing: %s. Moving one to enforced is your decision, recorded with "
                    "the date." % report_only)
    said.append("The first four lines of the record say not yet answered. After your yes I ask the three plain "
                "questions that fill them: who is exposed if it fails, what data it holds, and how you would "
                "recover.")
    return said


def build(project, today):
    plan = plan_record(project, today)
    if plan is None:
        return None
    areas = area_entries(plan["area_lines"])
    return plan, areas, piece_plan(project, areas)


def show(project):
    today = datetime.date.today().isoformat()
    built = build(project, today)
    if built is None:
        print("risk_move.py: %s holds no old path record" % project, file=sys.stderr)
        return 1
    plan, areas, pieces = built
    report_only = report_only_line(plan, pieces, today)
    print("--- before ---")
    print("\n".join(l.rstrip("\r") for l in plan["old"]).rstrip())
    print("--- after ---")
    print("\n".join(render(plan, report_only)).rstrip())
    print("--- pieces ---")
    if not pieces["read"]:
        print("not read: GitHub could not be reached, so no open piece is changed")
    for number, value, _ in pieces["set"]:
        print("piece %d: Risk areas: %s" % (number, value))
    for number in pieces["undecided"]:
        print("piece %d: stays without a line, since only a person can tell" % number)
    if pieces["read"] and not pieces["set"] and not pieces["undecided"]:
        print("none to change")
    for sentence in sentences(plan, pieces, report_only):
        print("say\trisk-move\t" + sentence)
    return 0


def apply(project):
    today = datetime.date.today().isoformat()
    built = build(project, today)
    if built is None:
        print("risk_move.py: %s holds no old path record" % project, file=sys.stderr)
        return 1
    plan, areas, pieces = built
    check_changelog(project)
    done = []
    for number, value, body in pieces["set"]:
        if write_piece(project, number, with_line(body, value)):
            done.append(number)
            print("piece\t%d\tRisk areas: %s" % (number, value))
        else:
            pieces["undecided"].append(number)
    pieces["undecided"].sort()
    report_only = report_only_line(plan, pieces, today)
    eol = plan["eol"]
    new = [l + eol for l in render(plan, report_only)]
    lines = plan["lines"]
    merged = lines[:plan["start"]] + new + lines[plan["end"]:]
    # Every line but the last ends with the file's own ending once joined; the
    # section's last line is the blank one that separates it from the next.
    text = "\n".join(merged)
    path = os.path.join(project, "masterplan.md")
    temp = path + ".risk-move"
    with open(temp, "w", encoding="utf-8", newline="") as handle:
        handle.write(text)
    os.replace(temp, path)
    print("moved\tmasterplan.md\t## Risk record")
    line = changelog_line(plan, pieces, done, report_only)
    add_changelog(project, today, line)
    print("changelog\tCHANGELOG.md\t" + line)
    for sentence in sentences(plan, pieces, report_only):
        print("say\trisk-move\t" + sentence)
    return 0


def main(argv):
    args = list(argv)
    applying = "--apply" in args
    args = [a for a in args if a != "--apply"]
    if len(args) > 1 or any(a.startswith("--") for a in args):
        print("usage: risk_move.py [--apply] [PROJECT]", file=sys.stderr)
        return 2
    project = os.path.abspath(args[0] if args else ".")
    if not os.path.isfile(os.path.join(project, "masterplan.md")):
        print("risk_move.py: %s holds no masterplan.md" % project, file=sys.stderr)
        return 2
    try:
        return apply(project) if applying else show(project)
    except RuntimeError as error:
        print("risk_move.py: %s" % error, file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
