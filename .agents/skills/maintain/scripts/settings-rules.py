#!/usr/bin/env python3
"""Find, and on a yes add, the Claude Code safety rules a project is missing.

Founding copies the kit's Claude Code settings into `.claude/settings.json`
once, and no update touches that file again. A later release can refuse more
ways of writing a dangerous command, and ask before a merge, and a project
founded earlier keeps the older rules. This script compares the project's
`permissions.deny` and `permissions.ask` lists with the installed founding
template, so the comparison never rests on memory or on a hand edit of JSON.

Usage:

    settings-rules.py [PROJECT]             list the rules to offer
    settings-rules.py --apply [PROJECT]     add them
    settings-rules.py --decline [PROJECT]   record a no
    settings-rules.py --merge-box [PROJECT] say whether a merge asks first

PROJECT defaults to the current folder. Each line has fields separated by
tabs:

    deny       RULE     a refusal the template holds and the project lacks
    ask        RULE     a question before a merge the project lacks
    declined   LIST  RULE
                        a rule the person said no to; the no stands
    left       .claude/settings.json  WHY
                        the file could not be read, so it was left alone

Which rules are offered. A deny rule that names both `git push` and `main` is
always offered. One that stops a force push is offered only while the project
still holds `Bash(git push --force:*)`, and one that stops a forced delete only
while it holds `Bash(rm -rf:*)`, since a person may have taken those out on
purpose. Every ask rule is offered. Any other rule the project lacks is left
out, for the same reason.

A no is the line `push-rules-declined|<date>|<rules separated by " ; ">` in
`.ai-build-kit-maintenance`. While that line lists every rule still missing,
the earlier no stands and the rules print as `declined`. A release that adds a
rule the line does not list brings the offer back.

`--apply` adds only the offered rules, each to the end of the list it came
from, and changes no other character of the file where it can find those lists
in the text; otherwise it writes the file again with the same indent. It reads
the file back and stops with exit 3, the file untouched, if the result would not
hold every earlier entry and setting plus the new rules.

Exit codes. List mode: 1 when a rule is offered, 0 when none is (a declined
rule or a `left` line included), 2 on a usage error. `--merge-box`: 0 when the
project's settings make Claude Code ask before `gh pr merge`, 1 when they do
not. `--apply` and `--decline`: 0 on success.
"""

import datetime
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
INSTALLED = os.path.dirname(os.path.dirname(HERE))
TEMPLATE = os.path.join(INSTALLED, "setup-ai-build-kit", "templates", "foundation",
                        "claude-settings.json")
SETTINGS = os.path.join(".claude", "settings.json")
MAINTENANCE = ".ai-build-kit-maintenance"
DECLINED = "push-rules-declined|"
FORCE_PUSH = "Bash(git push --force:*)"
FORCED_DELETE = "Bash(rm -rf:*)"
MERGE = "Bash(gh pr merge:*)"


# --- reading ----------------------------------------------------------------


def linked_path(project, relative):
    current = os.path.abspath(project)
    for part in relative.split("/"):
        current = os.path.join(current, part)
        if os.path.islink(current):
            return True
    return False

def load(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def lists(data):
    perms = data.get("permissions") if isinstance(data, dict) else None
    perms = perms if isinstance(perms, dict) else {}
    out = {}
    for key in ("deny", "ask"):
        value = perms.get(key, [])
        out[key] = [r for r in value if isinstance(r, str)] if isinstance(value, list) else []
    return out


def offered(project_lists, template_lists):
    """The rules to offer, as (key, rule) in template order."""
    have = project_lists
    out = []
    for rule in template_lists["deny"]:
        if rule in have["deny"]:
            continue
        if "git push" in rule and "main" in rule:
            out.append(("deny", rule))
        elif rule.startswith("Bash(git push") and FORCE_PUSH in have["deny"]:
            out.append(("deny", rule))
        elif rule.startswith("Bash(rm ") and FORCED_DELETE in have["deny"]:
            out.append(("deny", rule))
    for rule in template_lists["ask"]:
        if rule not in have["ask"]:
            out.append(("ask", rule))
    return out


def declined_rules(project):
    try:
        lines = load(os.path.join(project, MAINTENANCE)).splitlines()
    except (OSError, UnicodeDecodeError):
        return None
    for line in lines:
        if line.startswith(DECLINED):
            parts = line.split("|", 2)
            if len(parts) == 3:
                return {r.strip() for r in parts[2].split(" ; ") if r.strip()}
    return None


def read(project):
    """(text, data, offers) or raises ValueError with the reason."""
    path = os.path.join(project, SETTINGS)
    try:
        text = load(path)
    except UnicodeDecodeError:
        raise ValueError("it is not readable text")
    try:
        data = json.loads(text)
    except ValueError:
        raise ValueError("it is not valid JSON, so it was left alone")
    if not isinstance(data, dict):
        raise ValueError("it does not hold a settings object, so it was left alone")
    try:
        template = json.loads(load(TEMPLATE))
    except (OSError, ValueError):
        raise ValueError("the installed founding template could not be read")
    return text, data, offered(lists(data), lists(template))


# --- writing without disturbing the rest of the file -------------------------

class Spans:
    """A small JSON reader that records where each value sits in the text."""

    def __init__(self, text):
        self.text = text

    def skip(self, i):
        while i < len(self.text) and self.text[i] in " \t\r\n":
            i += 1
        return i

    def string(self, i):
        assert self.text[i] == '"'
        i += 1
        while self.text[i] != '"':
            i += 2 if self.text[i] == "\\" else 1
        return i + 1

    def value(self, i):
        """(start, end, members) where members maps a key to its value's
        (start, end, members) for an object, or lists items for an array."""
        i = self.skip(i)
        start = i
        char = self.text[i]
        if char == "{":
            members = {}
            i = self.skip(i + 1)
            if self.text[i] == "}":
                return start, i + 1, members
            while True:
                i = self.skip(i)
                key_end = self.string(i)
                key = json.loads(self.text[i:key_end])
                i = self.skip(key_end)
                assert self.text[i] == ":"
                members[key] = self.value(i + 1)
                i = self.skip(members[key][1])
                if self.text[i] == ",":
                    i += 1
                    continue
                assert self.text[i] == "}"
                return start, i + 1, members
        if char == "[":
            items = []
            i = self.skip(i + 1)
            if self.text[i] == "]":
                return start, i + 1, items
            while True:
                items.append(self.value(i))
                i = self.skip(items[-1][1])
                if self.text[i] == ",":
                    i += 1
                    continue
                assert self.text[i] == "]"
                return start, i + 1, items
        if char == '"':
            return start, self.string(i), None
        match = re.compile(r"-?[0-9.eE+-]+|true|false|null").match(self.text, i)
        return start, match.end(), None


def line_indent(text, position):
    begin = text.rfind("\n", 0, position) + 1
    match = re.match(r"[ \t]*", text[begin:])
    return match.group(0)


def insert_in_place(text, additions):
    """The text with each rule added at the end of its list, or None when the
    lists cannot be found in a shape this can edit safely."""
    try:
        root = Spans(text).value(0)
    except (AssertionError, IndexError, ValueError, AttributeError):
        return None
    if not isinstance(root[2], dict) or "permissions" not in root[2]:
        return None
    perms = root[2]["permissions"]
    if not isinstance(perms[2], dict):
        return None
    edits = []
    for key in ("deny", "ask"):
        rules = [r for k, r in additions if k == key]
        if not rules:
            continue
        if key in perms[2]:
            start, end, items = perms[2][key]
            if not isinstance(items, list) or not items:
                return None
            last = items[-1]
            indent = line_indent(text, last[0])
            newline = "\r\n" if "\r\n" in text else "\n"
            same_line = "\n" not in text[items[0][0]:last[1]] and len(items) > 1
            if same_line:
                piece = "".join(", " + json.dumps(r) for r in rules)
            else:
                piece = "".join("," + newline + indent + json.dumps(r) for r in rules)
            edits.append((last[1], piece))
        else:
            # A list the project never had, such as `ask` in a file founded
            # before it existed: add it after the last member of permissions.
            members = perms[2]
            if not members:
                return None
            last_key = max(members, key=lambda k: members[k][1])
            last_end = members[last_key][1]
            key_start = text.rfind('"' + last_key + '"', perms[0], members[last_key][0])
            if key_start < 0:
                return None
            key_indent = line_indent(text, key_start)
            newline = "\r\n" if "\r\n" in text else "\n"
            sibling = members[last_key][2]
            if isinstance(sibling, list) and sibling:
                item_indent = line_indent(text, sibling[0][0])
                if item_indent == key_indent:
                    item_indent = key_indent + "  "
            else:
                item_indent = key_indent + "  "
            body = ("," + newline).join(item_indent + json.dumps(r) for r in rules)
            piece = ("," + newline + key_indent + json.dumps(key) + ": [" + newline + body +
                     newline + key_indent + "]")
            edits.append((last_end, piece))
    out = text
    for position, piece in sorted(edits, reverse=True):
        out = out[:position] + piece + out[position:]
    return out


def expected(data, additions):
    want = json.loads(json.dumps(data))
    perms = want.setdefault("permissions", {})
    for key, rule in additions:
        perms.setdefault(key, [])
        perms[key].append(rule)
    return want


def apply(project):
    path = os.path.join(project, SETTINGS)
    if linked_path(project, SETTINGS):
        print("left\t%s\tit is a link, so it was left alone" % SETTINGS)
        return 0
    try:
        text, data, offers = read(project)
    except (OSError, ValueError) as error:
        if isinstance(error, OSError):
            return 0
        print("left\t%s\t%s" % (SETTINGS, error))
        return 0
    if not offers:
        return 0
    permissions = data.get("permissions", {})
    if not isinstance(permissions, dict) or any(
            key in permissions and not isinstance(permissions[key], list)
            for key, _ in offers):
        print("left\t%s\tits permission lists have an unexpected shape" % SETTINGS)
        return 0
    want = expected(data, offers)
    new = insert_in_place(text, offers)
    if new is None or json.loads(new) != want:
        match = re.search(r'\n([ \t]+)"', text)
        indent = match.group(1) if match else "  "
        new = json.dumps(want, indent=indent, ensure_ascii=False) + "\n"
    if json.loads(new) != want:
        print("left\t%s\tthe new rules could not be added without changing something else" % SETTINGS)
        return 3
    with open(path, "w", encoding="utf-8", newline="") as handle:
        handle.write(new)
    return 0


def decline(project, today=None):
    if linked_path(project, MAINTENANCE):
        print("left\t%s\tit is a link, so it was left alone" % MAINTENANCE)
        return 0
    try:
        _, _, offers = read(project)
    except (OSError, ValueError):
        return 0
    if not offers:
        return 0
    today = today or datetime.date.today().isoformat()
    line = DECLINED + today + "|" + " ; ".join(rule for _, rule in offers)
    path = os.path.join(project, MAINTENANCE)
    try:
        with open(path, encoding="utf-8", newline="") as handle:
            lines = handle.readlines()
    except OSError:
        lines = []
    ending = "\r\n" if lines and lines[0].endswith("\r\n") else "\n"
    kept = [l for l in lines if not l.startswith(DECLINED)]
    if kept and not kept[-1].endswith(("\n", "\r")):
        kept[-1] += ending
    kept.append(line + ending)
    with open(path, "w", encoding="utf-8", newline="") as handle:
        handle.writelines(kept)
    return 0


def merge_box(project):
    """0 when the project's own settings ask before a merge, 1 when not."""
    try:
        data = json.loads(load(os.path.join(project, SETTINGS)))
    except (OSError, ValueError):
        return 1
    return 0 if MERGE in lists(data)["ask"] else 1


def listing(project):
    try:
        _, _, offers = read(project)
    except OSError:
        return 0
    except ValueError as error:
        print("left\t%s\t%s" % (SETTINGS, error))
        return 0
    if not offers:
        return 0
    declined = declined_rules(project)
    if declined is not None and all(rule in declined for _, rule in offers):
        for key, rule in offers:
            print("declined\t%s\t%s" % (key, rule))
        return 0
    for key, rule in offers:
        print("%s\t%s" % (key, rule))
    return 1


def main(argv):
    flags = [a for a in argv if a.startswith("--")]
    rest = [a for a in argv if not a.startswith("--")]
    if len(flags) > 1 or set(flags) - {"--apply", "--decline", "--merge-box"} or len(rest) > 1:
        print("usage: settings-rules.py [--apply | --decline | --merge-box] [PROJECT]", file=sys.stderr)
        return 2
    project = rest[0] if rest else "."
    if not os.path.isdir(project):
        print("settings-rules.py: no such project folder: %s" % project, file=sys.stderr)
        return 2
    if flags == ["--apply"]:
        return apply(project)
    if flags == ["--decline"]:
        return decline(project)
    if flags == ["--merge-box"]:
        return merge_box(project)
    return listing(project)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
