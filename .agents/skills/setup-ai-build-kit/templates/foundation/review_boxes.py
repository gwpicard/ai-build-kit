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


# The review record. gate.py writes one line at the foot of the pull request:
#
#   Review record: reviewed=...; tried=N; open=N; head=COMMIT; verified=yes|no; seal=HASH
#
# head is the commit the review read. The seal is a hash of the record's own
# fields and the Worth stopping for section, so a hand edit of either, such as
# open=1 turned into open=0 or a finding taken out, no longer matches. A record
# from an older kit has no head and no seal, and reads as a stale review.

RECORD_FIELDS = ("reviewed", "tried", "open", "head", "verified")


def stopping_lines(body):
    match = re.search(r"(?ims)^## Worth stopping for[ \t]*\r?\n(.*?)(?=^## |\Z)", body)
    if not match:
        return []
    return [line.strip() for line in match.group(1).splitlines()
            if line.strip() and not line.strip().startswith("Review record:")]


def review_seal(fields, body):
    import hashlib
    text = "\n".join(["%s=%s" % (name, fields.get(name, "")) for name in RECORD_FIELDS]
                     + stopping_lines(body))
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:20]


def record_line(reviewed, tried, open_count, head, verified, body):
    fields = {"reviewed": reviewed, "tried": str(tried), "open": str(open_count),
              "head": head, "verified": "yes" if verified else "no"}
    return ("Review record: " + "; ".join("%s=%s" % (name, fields[name]) for name in RECORD_FIELDS)
            + "; seal=" + review_seal(fields, body))


def read_record(body):
    lines = re.findall(r"(?m)^Review record:[ \t]*(.+?)[ \t]*\r?$", body)
    if not lines:
        return None
    fields = {}
    for part in lines[-1].split(";"):
        name, _, value = part.strip().partition("=")
        if name:
            fields[name.strip()] = value.strip()
    return fields


def review_hold(body, head):
    """None when the record is whole and names this head, else a plain reason."""
    fields = read_record(body)
    if fields is None:
        return "no review recorded yet"
    if not fields.get("head") or not fields.get("seal"):
        return ("the review record names no version of the code. An older kit wrote it, "
                "so it counts as stale. Run the review again")
    if fields["seal"] != review_seal(fields, body):
        return ("the review record does not match the pull request text. The text was "
                "changed by hand after the review. Run the review again")
    if fields["head"] != head:
        return ("the review read an earlier version of this change. New work was pushed "
                "after it. Run the review again")
    return None


def review_verified(body):
    return (read_record(body) or {}).get("verified") == "yes"
