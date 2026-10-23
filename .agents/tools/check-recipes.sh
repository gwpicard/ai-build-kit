#!/usr/bin/env sh
# check-recipes.sh: check that each recipe folder has the shape the format asks
# for.
#
# The format lives in docs/RECIPES.md. A recipe is a folder: `recipe.md`, which
# the kit reads at run time, `scripts/`, which holds its checks and its
# `live-check.sh`, and `PROVEN.md`, the record of its real run, which the kit
# never loads. A recipe is only worth offering if every one of the nine
# sections, the eight a live tool needs and access, says how it works, what
# a pass means, which script checks it and who runs that check, and if the
# folder carries the dates that say when it was last read and when it was
# really run. A missing section or script is
# easy to miss by eye and costs the person a launch step nobody can check, so
# a machine reads for it.
#
# Usage:
#   check-recipes.sh RECIPE...              a recipe folder, or its recipe.md
#   check-recipes.sh --template FILE        the blank recipe.md
#   check-recipes.sh --part FILE...         a shared part in recipes/parts/
#   check-recipes.sh --rehearsal RECIPE REHEARSAL
#
# Each section carries `How it works:`, `How it is checked:`, `Script:` and
# `Who runs it:`, or a `Shared part:` link to a part in `../parts/` that
# carries them. A script path is read from the file it is written in, and the
# script must be there and executable. A section the kit does not run itself
# also carries `Ask:`, the fixed words the person or a companion hears. A
# recipe may add one section to the nine, "## Settings the kit can read",
# after access, at the end, held to the same lines, and then PROVEN.md
# gives it an outcome line too.
#
# With --template the dates may still read YYYY-MM-DD, and "Who runs it:" and
# "Script:" may still be placeholders, since the blank has nothing real to
# give. Every other rule applies to the blank as well, so it cannot drift away
# from the format it is copied from.
#
# With --rehearsal the second file must be a real rehearsal for the first: it
# sources the shared recipe rehearsal, runs the recipe's scripts against the
# tool stand-ins, and names the recipe folder. A rehearsal that only says
# `exit 0` would otherwise count as proof.
#
# Prints each problem and exits 1 when any recipe has one. Writes nothing.

set -eu

mode=recipe
case "${1:-}" in
  --template) mode=template; shift ;;
  --part) mode=part; shift ;;
  --rehearsal) mode=rehearsal; shift ;;
esac

[ "$#" -gt 0 ] || { echo "usage: check-recipes.sh [--template|--part] FILE... | RECIPE... | --rehearsal RECIPE REHEARSAL" >&2; exit 2; }

if [ "$mode" = rehearsal ]; then
  [ "$#" -eq 2 ] || { echo "usage: check-recipes.sh --rehearsal RECIPE REHEARSAL" >&2; exit 2; }
  name=$(basename -- "${1%/recipe.md}")
  if [ ! -f "$2" ]; then
    echo "$1: no rehearsal guards it; add $2"
    exit 1
  fi
  status=0
  if ! grep -Eq '^[[:space:]]*\.[[:space:]].*lib/recipe-rehearsal\.sh' "$2" \
      || ! grep -Eq '^[[:space:]]*rr_scripts' "$2"; then
    echo "$2: does not run the recipe's scripts through lib/recipe-rehearsal.sh"
    status=1
  fi
  if ! grep -qF "recipes/$name" "$2"; then
    echo "$2: does not name the recipe folder recipes/$name"
    status=1
  fi
  exit "$status"
fi

exec python3 - "$mode" "$@" <<'PY'
import datetime, os, re, sys

mode, paths = sys.argv[1], sys.argv[2:]
# A local date can be one day ahead of UTC. Use the same limit everywhere.
LATEST = (datetime.datetime.now(datetime.timezone.utc).date() + datetime.timedelta(days=1)).isoformat()
ORDER = ["Preview", "Going live", "Rollback", "Backup", "Restore", "Secrets", "Logs", "Health",
         "Access"]
EXTRA = "Settings the kit can read"
WHO = ("the kit", "a companion or the person, result read back", "a person looking")
STACK = ["Language", "Framework", "Typing", "User interface", "Database", "Sign-in", "Email", "Files",
         "Jobs", "Testing", "Linting", "Starter", "Optional parts"]
HEADS = ["Fits", "Recommended when"] + STACK + ["Work-team default", "Deploy target", "Health-check tool",
         "Command-line tools", "Last checked", "Last proven", "Proven on", "Superseded settings"]
STACK_SECTIONS = ["Sign-in and roles", "Row rules", "Files", "Jobs", "Email",
                  "User interface", "Project check", "Updates"]
COMING_SECTIONS = set(STACK_SECTIONS) - {"User interface"}
FIT_CATEGORIES = {
    "Dashboards and reporting on existing data",
    "Admin panels and back office over an existing database",
    "Approvals and request workflows",
    "CRMs, contact trackers and sales tools",
    "Light ERP: stock, orders, purchasing, assets",
    "Client, vendor and partner portals",
    "Project and task trackers",
    "Document processing: upload, extract, review, export",
    "AI assistants over team documents",
    "HR and onboarding",
    "Case management, tickets and incident logs",
    "Booking and scheduling",
    "Forms and data collection",
    "Field, inspection and service apps",
    "Screenless sync and automation",
}
bad = False


def realdate(value):
    try:
        datetime.date.fromisoformat(value)
    except ValueError:
        return False
    return bool(re.match(r"^\d{4}-\d{2}-\d{2}$", value))


def problem(where, message):
    global bad
    print("%s: %s" % (where, message))
    bad = True


def datecheck(where, label, value):
    if mode == "template" and value == "YYYY-MM-DD":
        return
    if not realdate(value):
        problem(where, "%s is not a real date written YYYY-MM-DD: %s" % (label, value))
    elif value > LATEST:
        problem(where, "%s is in the future: %s" % (label, value))


def lines_of(text):
    """The labelled lines of a section or part, as {label: value}."""
    found = {}
    for line in text.splitlines():
        for label in ("How it works", "How it is checked", "Script", "Who runs it", "Ask",
                      "Shared part"):
            if line.startswith(label + ": ") and line[len(label) + 2:].strip():
                found[label] = line[len(label) + 2:].strip()
            elif line.rstrip() == label + ":":
                found.setdefault(label, "")
    return found


def body_check(where, base, found):
    for label in ("How it works", "How it is checked", "Script", "Who runs it"):
        if not found.get(label):
            problem(where, "does not say \"%s:\"" % label)
    who = found.get("Who runs it", "")
    if who and not (mode == "template" and who.startswith("<")) and who not in WHO:
        problem(where, "says \"Who runs it: %s\", which is not one of: %s" % (who, "; ".join(WHO)))
    if who and who != "the kit" and not found.get("Ask"):
        problem(where, "is not run by the kit, so it needs \"Ask:\", the words the person hears")
    script = found.get("Script", "")
    if script.startswith("coming in part "):
        section = where.rsplit(" ## ", 1)[-1]
        allowed = section in COMING_SECTIONS and script in ("coming in part B", "coming in part C", "coming in part D")
        if not allowed:
            problem(where, "may defer its script only in a named shared-stack section for parts B to D")
    elif script and not (mode == "template" and "<" in script):
        path = os.path.normpath(os.path.join(base, script))
        if not script.startswith("scripts/") or not script.endswith(".sh"):
            problem(where, "names a script outside its scripts/ folder: %s" % script)
        elif not os.path.isfile(path):
            problem(where, "names a script that is not there: %s" % script)
        elif not os.access(path, os.X_OK):
            problem(where, "names a script that is not executable: %s" % script)


def sections(text):
    out, order, current = {}, [], None
    for line in text.splitlines():
        if line.startswith("## "):
            current = line[3:].strip()
            order.append(current)
            out[current] = []
        elif current is not None:
            out[current].append(line)
    return order, {k: "\n".join(v) for k, v in out.items()}


def check_recipe(md, proven):
    where = md
    base = os.path.dirname(md)
    text = open(md).read()
    head = text.split("\n## ", 1)[0]
    for label in HEADS:
        if not re.search(r"^%s: \S" % re.escape(label), head, re.M):
            problem(where, "the opening lines lack \"%s:\"" % label)
    if re.search(r"^Build stack:", head, re.M):
        problem(where, "uses the old Build stack line instead of the fixed stack fields")
    framework = re.search(r"^Framework: (.*)$", head, re.M)
    if framework and not (mode == "template" and "<" in framework.group(1)):
        value = framework.group(1)
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9 .+-]*?\s+\d+", value) or re.search(r"\b(or|latest)\b", value, re.I):
            problem(where, "Framework must name one tool and one pinned major version")
    allowed_tools = {
        "Language": {"TypeScript", "Python"}, "Framework": {"Next.js 16"},
        "User interface": {"Tailwind CSS 4 and shadcn/ui on Radix"},
        "Typing": {"TypeScript tsc", "mypy"}, "Database": {"Supabase Postgres", "PostgreSQL", "SQLite"},
        "Sign-in": {"Supabase Auth"}, "Email": {"Resend", "Postmark"},
        "Files": {"Supabase Storage"}, "Jobs": {"Supabase Cron and Queues", "Vercel Cron"},
        "Testing": {"Vitest and Playwright"}, "Linting": {"ESLint"},
    }
    for label, choices in allowed_tools.items():
        match = re.search(r"^%s: (.*)$" % re.escape(label), head, re.M)
        if match and not (mode == "template" and "<" in match.group(1)):
            value = match.group(1).strip()
            valid = value in choices
            if not valid:
                problem(where, "%s must name one tool from the allowed list" % label)
    optional = re.search(r"^Optional parts: (.*)$", head, re.M)
    if optional and not (mode == "template" and "<" in optional.group(1)):
        value = optional.group(1).strip()
        part_files = {
            "read-only existing database": "read-only-existing-database.md",
            "Python document worker": "python-document-worker.md",
        }
        parts_dir = os.path.join(base, "..", "parts")
        available_parts = {
            name for name, filename in part_files.items()
            if os.path.isfile(os.path.join(parts_dir, filename))
        }
        choices = {"none"}
        if "read-only existing database" in available_parts:
            choices.add("read-only existing database")
        if "Python document worker" in available_parts:
            choices.add("Python document worker")
        if available_parts == {"read-only existing database", "Python document worker"}:
            choices.add("read-only existing database and Python document worker")
        coming = re.fullmatch(r"[A-Za-z0-9 ,&-]+ \(coming in part [BCD]\)", value)
        if value not in choices and not coming:
            problem(where, "Optional parts must name the parts the recipe accepts, or none")
        deploy = re.search(r"^Deploy target: (.*)$", head, re.M)
        if "Python document worker" in value and (not deploy or "Coolify" not in deploy.group(1)):
            problem(where, "Python document worker is available only on Coolify")
    health_tool = re.search(r"^Health-check tool: (.*)$", head, re.M)
    if health_tool and not (mode == "template" and "<" in health_tool.group(1)) and health_tool.group(1) not in {"curl", "wget", "none"}:
        problem(where, "Health-check tool must be curl, wget or none")
    default = re.search(r"^Work-team default: (.*)$", head, re.M)
    if default and not (mode == "template" and "<" in default.group(1)) and not re.fullmatch(r"(?:no|yes \([A-Za-z0-9 ,+-]+\))", default.group(1)):
        problem(where, "Work-team default must be no or yes with the plans it needs")
    starter = re.search(r"^Starter: (.*)$", head, re.M)
    if starter and not (mode == "template" and "<" in starter.group(1)):
        value = starter.group(1).strip()
        if value != "coming" and not os.path.exists(os.path.join(base, value)):
            problem(where, "Starter must say coming or name an existing path")
    fits = re.search(r"^Fits: (.*)$", head, re.M)
    if fits and not (mode == "template" and "<" in fits.group(1)):
        categories = [value.strip() for value in fits.group(1).split(";")]
        if not categories or any(value not in FIT_CATEGORIES for value in categories):
            problem(where, "Fits must use the category names from the stack research")
    found = re.search(r"^Last checked: (.*)$", head, re.M)
    if found:
        datecheck(where, "Last checked", found.group(1).strip())
    proven_date = re.search(r"^Last proven: (.*)$", head, re.M)
    if proven_date:
        datecheck(where, "Last proven", proven_date.group(1).strip())
    versions = re.search(r"^Proven on: (.*)$", head, re.M)
    if versions and not (mode == "template" and "<" in versions.group(1)) and not versions.group(1).strip():
        problem(where, "Proven on must name the versions used in the real run")
    superseded = re.search(r"^Superseded settings: (.*)$", head, re.M)
    if superseded and not (mode == "template" and "<" in superseded.group(1)) and superseded.group(1).strip() != "none":
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*(?:, [A-Z][A-Z0-9_]*)*", superseded.group(1).strip()):
            problem(where, "Superseded settings must be comma-separated environment variable names or none")
    if mode != "template" and os.path.isfile(proven):
        proof_text = open(proven).read()
        proof_date = re.search(r"^Last proven: (.*)$", proof_text, re.M)
        run_date = re.search(r"^Real run: (.*)$", proof_text, re.M)
        proof_versions = re.search(r"^Versions: (.*)$", proof_text, re.M)
        if not run_date or not proof_versions:
            problem(proven, "must record Real run and Versions")
        if not proof_date or not proven_date or proof_date.group(1) != proven_date.group(1):
            problem(where, "Last proven must match PROVEN.md")
        recipe_versions = re.search(r"^Proven on: (.*)$", head, re.M)
        if proof_versions and (not recipe_versions or proof_versions.group(1).strip() != recipe_versions.group(1).strip()):
            problem(where, "Proven on must match Versions in PROVEN.md")
        if proof_date:
            datecheck(proven, "Last proven", proof_date.group(1).strip())
    for line in re.findall(r"^Plan terms:.*$", head, re.M):
        shaped = re.match(r"^Plan terms: [^(]+ \(read (\S+) at [^)]+\)$", line)
        if not shaped:
            problem(where, "\"Plan terms:\" does not read as a sentence ending \"(read YYYY-MM-DD at <source page>)\"")
        else:
            datecheck(where, "Plan terms", shaped.group(1))
    order, body = sections(text)
    if "Proven" in order:
        problem(where, "carries a \"## Proven\" section; the real run belongs in PROVEN.md")
    wanted = [s for s in order if s in ORDER]
    for name in ORDER:
        if name not in order:
            problem(where, "no \"## %s\" section" % name)
    if wanted != [s for s in ORDER if s in order]:
        problem(where, "the nine sections are out of order")
    stack_line = re.search(r"^Shared stack: .*\((\.\./parts/[A-Za-z0-9_.-]+\.md)\)$", head, re.M)
    if mode == "template" and re.search(r"^Shared stack: <", head, re.M):
        stack_line = None
    elif not stack_line:
        problem(where, "does not link its shared stack part")
    if stack_line:
        stack_path = os.path.normpath(os.path.join(base, stack_line.group(1)))
        if not os.path.isfile(stack_path):
            problem(where, "links a shared stack part that does not exist")
        else:
            stack_order, stack_body = sections(open(stack_path).read())
            if stack_order != STACK_SECTIONS:
                problem(stack_path, "does not hold the required shared stack sections in order")
            for stack_section in STACK_SECTIONS:
                if stack_section in stack_body:
                    body_check("%s ## %s" % (stack_path, stack_section), os.path.dirname(stack_path),
                               lines_of(stack_body[stack_section]))
    extra = EXTRA in order
    if extra and order.index(EXTRA) != len(order) - 1:
        problem(where, "\"## %s\" does not come after \"## Access\", at the end" % EXTRA)
    if extra and "Access" in order and order.index(EXTRA) < order.index("Access"):
        problem(where, "\"## %s\" does not come after \"## Access\"" % EXTRA)
    for name in ORDER + ([EXTRA] if extra else []):
        if name not in body:
            continue
        found = lines_of(body[name])
        if "Shared part" in found:
            link = re.match(r"^.*\]\((\.\./parts/[A-Za-z0-9_.-]+\.md)\)", found["Shared part"])
            if not link:
                problem(where, "\"## %s\" has a shared part that is not a link into ../parts/" % name)
                continue
            part = os.path.normpath(os.path.join(base, link.group(1)))
            if not os.path.isfile(part):
                problem(where, "\"## %s\" links a shared part that does not exist: %s" % (name, link.group(1)))
                continue
            body_check("%s (linked from \"## %s\" in %s)" % (part, name, md), os.path.dirname(part),
                       lines_of(open(part).read()))
        else:
            body_check("%s \"## %s\"" % (md, name), base, found)
    if mode == "template":
        return
    live = os.path.join(base, "scripts", "live-check.sh")
    if not os.path.isfile(live) or not os.access(live, os.X_OK):
        problem(where, "the folder has no executable scripts/live-check.sh")
    if not os.path.isfile(proven):
        problem(proven, "missing; the record of the real run belongs here")
        return
    ptext = open(proven).read()
    run = re.search(r"^Real run: (.*)$", ptext, re.M)
    if not run:
        problem(proven, "does not say \"Real run:\" and a date")
    else:
        datecheck(proven, "Real run", run.group(1).strip())
    for name in ORDER + ([EXTRA] if extra else []):
        if not re.search(r"^%s: \S" % re.escape(name), ptext, re.M):
            problem(proven, "has no outcome line for %s" % name)


def check_part(path):
    text = open(path).read()
    order, body = sections(text)
    if order:
        if order != STACK_SECTIONS:
            problem(path, "does not hold the required shared stack sections in order")
        for name in STACK_SECTIONS:
            if name in body:
                body_check("%s ## %s" % (path, name), os.path.dirname(path), lines_of(body[name]))
    else:
        body_check(path, os.path.dirname(path), lines_of(text))


for path in paths:
    if mode == "part":
        if not os.path.isfile(path):
            problem(path, "no such file")
        else:
            check_part(path)
        continue
    if mode == "template":
        if not os.path.isfile(path):
            problem(path, "no such file")
        else:
            check_recipe(path, None)
        continue
    folder = path[:-len("/recipe.md")] if path.endswith("/recipe.md") else path
    md = os.path.join(folder, "recipe.md")
    if not os.path.isfile(md):
        problem(path, "no recipe.md in this folder")
        continue
    check_recipe(md, os.path.join(folder, "PROVEN.md"))

sys.exit(1 if bad else 0)
PY
