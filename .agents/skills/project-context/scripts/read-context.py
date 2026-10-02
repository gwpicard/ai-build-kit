"""Read chosen Markdown sections and their explicit local cross-references.

Selection and semantic review belong to the calling skill. This reader never
writes project records or decides a permission, contradiction or workflow state.
"""
import argparse
import json
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit


class ContextGap(ValueError):
    pass


def visible_lines(text):
    """Mask fenced examples without changing line positions."""
    result, fence = [], None
    for line in text.splitlines(keepends=True):
        marker = re.match(r"^ {0,3}(`{3,}|~{3,})", line)
        if fence:
            if marker and marker[1][0] == fence[0] and len(marker[1]) >= len(fence) and not line[marker.end():].strip():
                fence = None
            result.append("\n")
        elif marker:
            fence = marker[1]
            result.append("\n")
        else:
            result.append(line)
    return result


def slug(heading):
    heading = heading.lower().strip()
    heading = re.sub(r"[^\w\-\s]", "", heading)
    return re.sub(r"\s", "-", heading)


def select(text, anchor, source):
    lines = text.splitlines(keepends=True)
    visible = visible_lines(text)
    if not anchor:
        return text, "".join(visible)
    headings, counts = [], {}
    for i, line in enumerate(visible):
        match = re.match(r"^ {0,3}(#{1,6})\s+(.+?)\s*#*\s*$", line)
        if match:
            key = slug(match[2])
            count = counts.get(key, 0)
            counts[key] = count + 1
            headings.append((i, len(match[1]), key + ("-" + str(count) if count else "")))
    for n, (start, level, key) in enumerate(headings):
        if key == anchor:
            end = next((i for i, depth, _ in headings[n + 1:] if depth <= level), len(lines))
            return "".join(lines[start:end]), "".join(visible[start:end])
    raise ContextGap(f"missing heading {source}#{anchor}; use an ATX heading anchor or read the relevant text directly")


def references(text, selected):
    definitions = dict((m[1].strip().casefold(), m[2]) for m in re.finditer(r"(?m)^ {0,3}\[([^\]]+)\]:\s*<?([^\s>]+)>?", "".join(visible_lines(text))))
    links = re.compile(r"!?\[([^\]]+)\](?:\(\s*<?([^\s)>]+)>?(?:\s+[^)]*)?\)|\[([^\]]*)\])?")
    for match in links.finditer(selected):
        if match[2]:
            yield match[2]
        else:
            key = (match[3] or match[1]).strip().casefold()
            if key in definitions:
                yield definitions[key]
            elif match[3] is not None:
                raise ContextGap(f"undefined reference [{key}]")


def read(root, selections):
    sections, opened, leads, seen = [], [], [], set()
    pending = [(Path("."), item) for item in selections]
    while pending:
        base, target = pending.pop(0)
        url = urlsplit(target)
        if url.scheme or url.netloc:
            if target not in leads:
                leads.append(target)
            continue
        relative = base / unquote(url.path) if url.path else base
        path = root / relative
        if path.is_absolute() and not path.resolve().is_relative_to(root):
            raise ContextGap(f"outside project: {target}")
        # Even an internal redirect can silently change the intended owner.
        if any(p.is_symlink() for p in (path, *path.parents) if p != root and p.is_relative_to(root)):
            raise ContextGap(f"redirected document: {target}")
        source = path.resolve().relative_to(root).as_posix()
        if path.suffix.lower() != ".md":
            if target not in leads:
                leads.append(target)
            continue
        anchor = unquote(url.fragment)
        key = source + ("#" + anchor if anchor else "")
        if key in seen:
            continue
        seen.add(key)
        if len(seen) > 64:
            raise ContextGap("more than 64 linked sections; select a smaller scope or review directly")
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as error:
            raise ContextGap(f"cannot read {key}: {error}") from error
        if source not in opened:
            opened.append(source)
        body, visible = select(text, anchor, source)
        sections.append({"source": key, "text": body})
        for link in references(text, visible):
            pending.append((Path(source) if link.startswith("#") else Path(source).parent, link))
    return {"sections": sections, "opened": opened, "leads": leads}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("sections", nargs="+")
    args = parser.parse_args()
    try:
        result = read(args.root.resolve(), args.sections)
    except (ContextGap, ValueError) as error:
        print(f"Context gap: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
