#!/usr/bin/env sh
# run-recipe.sh: run a recipe's nine checks in its order, print one plain line
# for each, and write the run's dated entry into CHANGELOG.md.
#
# Usage: run-recipe.sh [options] <recipe>
#
#   <recipe>               the recipe's folder, or its name as AGENTS.md's
#                          Recipe: line gives it, with or without `.md`, or
#                          `none` for a project on no recipe
#   --project <dir>        the project's folder; the current one by default
#   --set NAME=VALUE       passed to every check, such as LIVE_ADDRESS,
#                          DB_PASSWORD_FILE, PREVIEW_ADDRESS, BACKUP_DIR, PLAN
#   --pasted <section>=<file>
#                          what the person or a companion pasted back for a
#                          section the kit cannot reach. live-health and
#                          live-names feed the live check on a later run, and
#                          so does access.
#   --looked <section>=yes|no
#                          what the person said after looking, for a section
#                          only a person can judge
#   --request-record yes|no
#                          whether the tool records what each request did
#   --alerts named|none    whether somebody is named to receive alerts
#   --needs NAME,NAME      setting names an open piece says the live side needs
#   --note <text>          a line for the entry, such as a repair made
#   --chose <words>        the person's own words choosing to go on with no
#                          recipe, said after the notice
#   --later                a later run: compare the live copy with main first
#   --asks                 print the fixed question for each section the
#                          person or a companion runs, and nothing else
#   --no-record            print the lines and write nothing
#
# The sections are preview, going-live, rollback, backup, restore, secrets,
# logs, health and access. Each section in recipe.md names its script with `Script:`
# and who runs it with `Who runs it:`. The kit's own checks run here. A check
# the person or a companion runs reads back what they pasted, and with nothing
# pasted it is a warning carrying the recipe's fixed question. A check only a
# person can judge takes their answer from --looked.
#
# A check that failed or could not run is a warning: one line, written in the
# changelog, and the launch goes on. Two are not warnings. On a recipe, a live
# tool with no way back or no backup is held: the backup check must pass, a
# later run's rollback check must pass, and a first launch's recipe must name
# its rollback. A held launch prints a line starting "Launch held:" with the
# one step to take, and exits 4. Where the newest changelog line for the
# same check says the same words, the warning is a one-line pointer to it
# instead. The rollback line goes on a line of its own, and says "possible,
# not tried" when an earlier build is listed, since a rollback is never tried
# to prove it.
#
# With `none` there is no recipe, so no check can run and nothing is
# guaranteed. The first run prints one notice, leaves a marker that it was
# given, writes nothing else and exits 5. `--chose` without that marker prints
# the notice instead. The run that follows, with `--chose` carrying the
# person's words, writes
# those words and the date in the changelog and goes on. It never holds a
# launch. A later run finds the record and prints one pointer, not the notice.
#
# Where any check is a warning, the last line starts "Left:" and names the
# checks still open, pointing to the changelog. It is the whole answer when the
# person asks what is left.
#
# Exit 0 when every check passed, 1 when any is a warning, 3 when no live
# address is set, so the tool is not live yet, 4 when the launch is held for
# want of a way back or a backup, 5 when there is no recipe and the notice is
# given but not yet answered, and 2 when it could not run.

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec python3 - "$here" "$@" <<'PY'
import datetime, os, re, subprocess, sys

here, args = sys.argv[1], sys.argv[2:]
recipes_dir = os.path.join(os.path.dirname(here), "recipes")

ORDER = [("Preview", "preview", "Preview up"),
         ("Going live", "going-live", "Live address updated"),
         ("Rollback", "rollback", "Rollback possible"),
         ("Backup", "backup", "Backup present"),
         ("Restore", "restore", "Restore works"),
         ("Secrets", "secrets", "No secret in the repo"),
         ("Logs", "logs", "Logs readable"),
         ("Health", "health", "Health answers"),
         ("Access", "access", "Access as recorded")]
IDS = {ident for _, ident, _ in ORDER}
NOTICE = ("No recipe: the kit guarantees no way back to an earlier version, no backup "
          "and no checked launch here. It can still help you set the host up by hand. "
          "If you go on, your words and the date are recorded.")


def stop(message, code=2):
    print(message)
    sys.exit(code)


SCANNER = os.path.join(os.path.dirname(os.path.dirname(here)), "setup-ai-build-kit", "templates",
                       "foundation", "scan-secrets.py")


def unsafe_record(text, name):
    """Stop before a saved record takes a secret. Names the file, never the value."""
    try:
        done = subprocess.run([sys.executable, SCANNER, "--text", name], input=text,
                              capture_output=True, text=True, cwd=project)
    except OSError:
        stop("run-recipe.sh: the secret check could not run, so %s was not written." % name)
    if done.returncode:
        stop(done.stderr.strip() or
             "run-recipe.sh: the secret check could not run, so %s was not written." % name)


project, recipe, sets, pasted, looked = ".", None, {}, {}, {}
request_record = alerts = needs = chose = None
notes, later, asks, record = [], False, False, True
i = 0
while i < len(args):
    arg = args[i]
    value = args[i + 1] if i + 1 < len(args) else None
    if arg in ("--project", "--set", "--pasted", "--looked", "--request-record",
               "--alerts", "--needs", "--note", "--chose"):
        if value is None:
            stop("run-recipe.sh: %s needs a value." % arg)
        i += 2
        if arg == "--project":
            project = value
        elif arg == "--set":
            name, eq, val = value.partition("=")
            if not eq or not re.match(r"^[A-Z_][A-Z0-9_]*$", name):
                stop("run-recipe.sh: --set takes NAME=VALUE, not %s." % value)
            sets[name] = val
        elif arg in ("--pasted", "--looked"):
            name, eq, val = value.partition("=")
            if not eq:
                stop("run-recipe.sh: %s takes <section>=<value>." % arg)
            (pasted if arg == "--pasted" else looked)[name] = val
        elif arg == "--request-record":
            if value not in ("yes", "no"):
                stop("run-recipe.sh: --request-record is yes or no.")
            request_record = value
        elif arg == "--alerts":
            if value not in ("named", "none"):
                stop("run-recipe.sh: --alerts is named or none.")
            alerts = value
        elif arg == "--needs":
            needs = value
        elif arg == "--chose":
            chose = " ".join(value.split())
            if not chose:
                stop("run-recipe.sh: --chose needs the person's words.")
        else:
            notes.append(value)
        continue
    if arg == "--later":
        later = True
    elif arg == "--asks":
        asks = True
    elif arg == "--no-record":
        record = False
    elif arg.startswith("-"):
        stop("run-recipe.sh: unknown option %s." % arg)
    elif recipe is None:
        recipe = arg
    else:
        stop("run-recipe.sh: one recipe at a time.")
    i += 1

if recipe is None:
    stop("usage: run-recipe.sh [options] <recipe folder | name | none>")
for name in list(pasted) + list(looked):
    if name not in IDS and name not in ("live-health", "live-names"):
        stop("run-recipe.sh: there is no section called %s." % name)
for name, val in looked.items():
    if val not in ("yes", "no"):
        stop("run-recipe.sh: --looked %s is yes or no." % name)
project = os.path.abspath(project)
if not os.path.isdir(project):
    stop("run-recipe.sh: no project folder at %s." % project)

password_files = [os.path.abspath(value) for key, value in sets.items()
                  if key in ("DB_PASSWORD_FILE", "PREVIEW_DB_PASSWORD_FILE") and value]
masterplan = os.path.join(project, "masterplan.md")
if record and password_files and os.path.isfile(masterplan):
    with open(masterplan, encoding="utf-8") as source:
        lines = source.read().splitlines()
    start = next((i for i, line in enumerate(lines) if line.strip() == "## How it stays running"), None)
    if start is not None:
        end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("## ")), len(lines))
        existing = []
        for line in lines[start + 1:end]:
            match = re.match(r"\s*Password files:\s*(.*)$", line, re.I)
            if match:
                existing.extend(item.strip().strip("`'\"") for item in match.group(1).split(",") if item.strip())
        paths = list(dict.fromkeys(existing + password_files))
        record_line = "Password files: " + ", ".join(paths)
        lines = [line for line in lines if not re.match(r"\s*Password files:\s*", line, re.I)]
        start = next(i for i, line in enumerate(lines) if line.strip() == "## How it stays running")
        lines.insert(start + 1, record_line)
        unsafe_record("\n".join(lines), "masterplan.md")
        with open(masterplan, "w", encoding="utf-8") as target:
            target.write("\n".join(lines) + "\n")

# --- the recipe ------------------------------------------------------------
folder = None
if recipe != "none":
    candidates = [recipe, os.path.join(recipes_dir, recipe)]
    if recipe.endswith(".md"):
        # A project founded before recipes became folders names the file.
        candidates.append(os.path.join(recipes_dir, recipe[:-3]))
    for candidate in candidates:
        if os.path.isfile(os.path.join(candidate, "recipe.md")):
            folder = os.path.abspath(candidate)
            break
    if folder is None:
        stop("run-recipe.sh: no recipe called %s is on the menu." % recipe)


def section_info(path):
    """Each section's script, who runs it and its question, following a
    shared part where the section links one."""
    info, current = {}, None
    for line in open(path):
        line = line.rstrip("\n")
        if line.startswith("## "):
            current = line[3:]
            info[current] = {"base": os.path.dirname(path)}
            continue
        if current is None:
            continue
        here_info = info[current]
        part = re.match(r"^Shared part: .*\]\((\.\./parts/[^)]+)\)", line)
        if part:
            part_path = os.path.join(os.path.dirname(path), part.group(1))
            base = os.path.dirname(os.path.abspath(part_path))
            here_info["base"] = base
            for pline in open(part_path):
                read_line(here_info, pline.rstrip("\n"))
        else:
            read_line(here_info, line)
    return info


def read_line(target, line):
    for key, label in (("script", "Script: "), ("who", "Who runs it: "), ("ask", "Ask: ")):
        if line.startswith(label):
            target[key] = line[len(label):].strip()


title = "no recipe"
info = {}
if folder:
    recipe_md = os.path.join(folder, "recipe.md")
    found = re.search(r"^# Recipe: (.+)$", open(recipe_md).read(), re.M)
    title = found.group(1) if found else os.path.basename(folder)
    info = section_info(recipe_md)
    missing = [heading for heading, _, _ in ORDER if heading not in info]
    if missing:
        stop("run-recipe.sh: the recipe has no section for %s." % ", ".join(missing))

if asks:
    for heading, ident, _ in ORDER:
        entry = info.get(heading, {})
        if entry.get("who") and entry["who"] != "the kit" and entry.get("ask"):
            print("Ask for %s: %s" % (ident, entry["ask"]))
    sys.exit(0)

env = dict(os.environ)
env.update(sets)


def run(command):
    """Run one check; return its exit code and its last line."""
    try:
        done = subprocess.run(command, cwd=project, env=env, capture_output=True, text=True)
    except OSError as error:
        return 2, "The check could not start: %s." % error
    lines = [l for l in done.stdout.splitlines() if l.strip()]
    if done.stderr:
        sys.stderr.write(done.stderr)
    code = done.returncode if done.returncode in (0, 1, 2) else 2
    return code, (lines[-1].strip() if lines else "The check said nothing.")


def outcome(heading, ident):
    entry = info[heading]
    who = entry.get("who", "")
    script = entry.get("script", "")
    path = os.path.join(entry["base"], script) if script else ""
    if not script or not os.path.isfile(path):
        return 2, "The recipe names no script for this check."
    ask = entry.get("ask", "")
    if who.startswith("a companion or the person"):
        if ident not in pasted:
            return 2, "Nothing was pasted back yet. %s" % ask
        return run(["sh", path, "--pasted", os.path.abspath(pasted[ident])])
    code, detail = run(["sh", path])
    if who == "a person looking":
        if code == 1:
            return code, detail
        answer = looked.get(ident)
        if answer == "yes":
            return 0, "The person looked, and it was as expected."
        if answer == "no":
            return 1, "The person looked, and it was not as expected."
        if code == 2:
            return code, detail
        return 2, "%s Waiting for the person to look. %s" % (detail, ask)
    return code, detail


# --- what the changelog already holds -----------------------------------------
changelog = os.path.join(project, "CHANGELOG.md")
# For each label, the newest line the changelog holds that is not a pointer,
# newest first: its full text and date when it is a warning. A label whose
# newest line is a pass holds nothing.
held, decided = {}, set()
if os.path.isfile(changelog):
    date = None
    for line in open(changelog, errors="replace"):
        heading = re.match(r"^##\s+(\d{4}-\d{2}-\d{2})", line)
        if heading:
            date = heading.group(1)
            continue
        body = re.sub(r"^\s*(?:[-*]\s+)?", "", line).strip()
        if body.startswith("Rollback possible, not tried"):
            decided.add("rollback possible")
            continue
        found = re.match(r"^\**([A-Za-z ]+?)\**:\s*(.*)$", body)
        if not found or date is None:
            continue
        label, rest = found.group(1).strip().lower(), found.group(2).lower()
        if label in decided or rest.startswith("still "):
            continue
        decided.add(label)
        if re.match(r"warning|no\b|not checked", rest):
            held[label] = (body, date)
prior_choice = None
if os.path.isfile(changelog):
    for line in open(changelog, errors="replace"):
        found = re.match(r"^\s*(?:[-*]\s+)?Chosen without a recipe on (\d{4}-\d{2}-\d{2})", line)
        if found:
            prior_choice = found.group(1)
            break
caution_given = os.path.isfile(changelog) and \
    "monitoring caution given" in open(changelog, errors="replace").read().lower()


def line_for(label, code, detail):
    """The plain line, and whether it is a pointer to a warning already held."""
    rollback = label == "Rollback possible"
    if code == 0:
        return ("Rollback possible, not tried. %s" % detail if rollback
                else "%s: yes. %s" % (label, detail)), False
    if code == 1:
        text = ("Rollback possible: no. %s" % detail if rollback
                else "%s: warning. %s" % (label, detail))
    else:
        text = ("Rollback possible: not checked. %s" % detail if rollback
                else "%s: warning, not checked. %s" % (label, detail))
    # A pointer only where the newest entry for this label says the same.
    newest = held.get(label.lower())
    if newest and newest[0] == text:
        if rollback:
            return "Rollback possible: still no, as the changelog has recorded since %s." % newest[1], True
        return "%s: still a warning, as the changelog has recorded since %s." % (label, newest[1]), True
    return text, False


# --- a later run compares first ------------------------------------------
compared = []
if later and folder:
    live_check = os.path.join(folder, "scripts", "live-check.sh")
    if os.path.isfile(live_check):
        command = ["sh", live_check]
        if needs:
            command += ["--needs", needs]
        if "live-health" in pasted:
            command += ["--pasted-health", os.path.abspath(pasted["live-health"])]
        if "live-names" in pasted:
            command += ["--pasted-names", os.path.abspath(pasted["live-names"])]
        if "access" in pasted:
            command += ["--pasted-access", os.path.abspath(pasted["access"])]
        done = subprocess.run(command, cwd=project, env=env, capture_output=True, text=True)
        compared = [l.strip() for l in done.stdout.splitlines() if l.strip()]
        if done.returncode == 0:
            compared.append("No gap between the live copy and main.")
        print("Compared with main:")
        for line in compared:
            print("- " + line)
        print()

# --- the nine ------------------------------------------------------------------
lines, warnings, rollback_line, codes, results_seen = [], 0, None, [], []
today = datetime.date.today().isoformat()
no_recipe_open = []
if folder is None:
    # No recipe, so no check runs. The notice comes once; the person's words
    # and the date are the record. Nothing here holds a launch.
    marker = os.path.join(project, ".agents", "tmp", "no-recipe-notice-given")
    if prior_choice is None and not (chose and os.path.isfile(marker)):
        print(NOTICE)
        try:
            os.makedirs(os.path.dirname(marker), exist_ok=True)
            open(marker, "w").close()
        except OSError:
            pass
        sys.exit(5)
    if chose:
        text = "Chosen without a recipe on %s: %s" % (today, chose)
    else:
        text = ("No recipe, as chosen on %s and recorded in the changelog. "
                "No check ran." % prior_choice)
    warnings += 1
    no_recipe_open.append("Launch checks")
    lines.append(text)
    print(text)
else:
    for heading, ident, label in ORDER:
        code, detail = outcome(heading, ident)
        codes.append(code)
        results_seen.append((code, detail))
        text, _ = line_for(label, code, detail)
        if code:
            warnings += 1
        if ident == "rollback":
            rollback_line = text
        else:
            lines.append(text)
        print(text)

extra = []
if request_record:
    if request_record == "yes":
        text, _ = line_for("Request record", 0, "The tool records what each request did.")
    else:
        warnings += 1
        text, _ = line_for("Request record", 1,
                           "The tool keeps no record of what each request did, so a fault "
                           "reported after launch cannot be traced. Adding the record is one "
                           "piece whenever you want it.")
    extra.append(text)
    print(text)
if alerts == "none" and not caution_given:
    text = ("Monitoring caution given: once real people use this, the only record of what "
            "went wrong will be the record the tool writes. If you want somebody to be told "
            "when it breaks, that is a service somebody runs and pays for, and the kit does "
            "not set one up.")
    extra.append(text)
    print(text)

live = bool(sets.get("LIVE_ADDRESS") or env.get("LIVE_ADDRESS"))


def way_back_and_backup():
    """The launch-held lines: a live tool needs a way back and a backup."""
    held_lines = []
    if folder is None:
        return held_lines
    by_ident = {ident: (code, detail) for (_, ident, _), (code, detail) in zip(ORDER, results_seen)}
    code, detail = by_ident["backup"]
    if code:
        held_lines.append("Launch held: no backup was confirmed. %s Take the recipe's backup step, "
                          "then run /setup-hosting again." % detail)
    code, detail = by_ident["rollback"]
    if later and code:
        held_lines.append("Launch held: no way back to an earlier version was confirmed. %s Make sure "
                          "an earlier working build is listed on the host, then run /setup-hosting "
                          "again." % detail)
    elif not info.get("Rollback", {}).get("script"):
        held_lines.append("Launch held: the recipe names no way back to an earlier version. "
                          "Choose a recipe that does, then run /setup-hosting again.")
    return held_lines


launch_held = way_back_and_backup() if live else []
for text in launch_held:
    print(text)
if not live:
    closing = "The tool is not live yet: no live address is recorded."
elif launch_held:
    closing = ("The launch is held until it has a way back and a backup. "
               "Do not record the live address yet.")
elif warnings:
    closing = "Each warning is written in CHANGELOG.md, and none of them holds the launch."
else:
    closing = "Every check passed."

# --- the record -------------------------------------------------------------------
if record:
    if folder is None:
        intro = ("/setup-hosting ran on no recipe, so no way back, backup or launch check is "
                 "guaranteed:")
    elif later:
        intro = "/setup-hosting compared the live copy with main and ran the %s recipe's checks again:" % title
    elif live:
        intro = "/setup-hosting ran the launch checks on the %s recipe:" % title
    else:
        intro = "Not live yet: no address is recorded. /setup-hosting ran the launch checks on the %s recipe:" % title
    block = ["## %s" % today, "", intro, ""]
    block += ["- " + l for l in compared + notes + lines + extra + launch_held]
    block += [""] + ([rollback_line, ""] if rollback_line else [])
    text = open(changelog).read() if os.path.isfile(changelog) else "# Changelog\n\n"
    found = re.search(r"^## ", text, re.M)
    if found:
        text = text[:found.start()] + "\n".join(block) + "\n" + text[found.start():]
    else:
        text = text.rstrip("\n") + "\n\n" + "\n".join(block)
    unsafe_record("\n".join(block), "CHANGELOG.md")
    with open(changelog, "w") as handle:
        handle.write(text)
    closing += " The entry is in CHANGELOG.md."

print(closing)
# The one line to give when the person asks what is left. A warning they have
# heard, or the changelog holds, is named and pointed to, and nothing more.
still = [label for (heading, ident, label), code in zip(ORDER, codes) if code] + no_recipe_open
if request_record == "no":
    still.append("Request record")
if still:
    names = [s[0].lower() + s[1:] for s in still]
    listed = names[0] if len(names) == 1 else ", ".join(names[:-1]) + " and " + names[-1]
    print("Left: the checks still open are written in CHANGELOG.md: %s." % listed)
if not live:
    sys.exit(3)
if launch_held:
    sys.exit(4)
sys.exit(1 if warnings else 0)
PY
