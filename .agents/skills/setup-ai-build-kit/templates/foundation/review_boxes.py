# Shared by check-review.sh and merge.py so both hold on the same boxes.

import re


def open_review_box(body):
    level = None
    fenced = False
    settled_indent = None
    for line in body.splitlines():
        if re.match(r"^\s{0,3}(?:```|~~~)", line):
            fenced = not fenced
            continue
        if fenced:
            continue
        heading = re.match(r"^\s{0,3}(#{1,6})\s+(.+?)\s*#*\s*$", line)
        bold = re.match(r"^\s{0,3}\*\*(.+?)\*\*\s*$", line)
        if heading:
            next_level = len(heading.group(1))
            title = heading.group(2).strip().rstrip(":").strip()
            if level is not None and next_level <= level:
                level = None
            if title.casefold() == "worth stopping for":
                level = next_level
            continue
        if bold:
            title = bold.group(1).strip().rstrip(":").strip()
            if title.casefold() == "worth stopping for":
                level = 7
                settled_indent = None
            elif level is not None:
                level = None
            continue
        if level is None:
            continue
        if re.match(r"^\s*(?:[-+*]\s+)?(?:None\.?|Nothing worth stopping for)\s*$", line, re.I):
            continue
        indent = len(line) - len(line.lstrip())
        if settled_indent is not None and indent > settled_indent:
            continue
        item = re.match(r"^\s*(?:[-+*]|\d+[.)])\s+(.+?)\s*$", line)
        if item and (settled_indent is None or indent <= settled_indent):
            settled_indent = None
        if item:
            content = item.group(1)
            checkbox = re.match(r"^\[([ xX])\]\s*", content)
            if checkbox:
                if checkbox.group(1).lower() != "x":
                    return True
                settled_indent = indent
            elif re.match(r"^(?:[-+*]|\d+[.)])\s+", content):
                continue
            else:
                return True
        elif line.strip():
            return True
    return False
