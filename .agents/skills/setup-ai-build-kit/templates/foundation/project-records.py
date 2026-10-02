#!/usr/bin/env python3
"""Read project records and save only completed document-review checkpoints."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

MARKER = '<!-- ai-build-kit:records:v1 -->'
WORKING_FIELDS = {'Path', 'Why', 'Sensitive areas', 'Accepted', 'Recheck when', 'Last checked'}


def text(path):
    if path.is_symlink():
        raise ValueError('Record is a link: ' + str(path))
    try:
        return path.read_text(encoding='utf-8')
    except (OSError, UnicodeError) as error:
        raise ValueError('Cannot read record: ' + str(path)) from error


def new_format(root):
    content = text(Path(root) / 'masterplan.md')
    declarations = content.count('ai-build-kit:records')
    if declarations and (declarations != 1 or MARKER not in content.splitlines()):
        raise ValueError('Unknown, malformed or repeated project record format')
    return bool(declarations)


def owner(root, field_name):
    root = Path(root)
    if not new_format(root):
        return root / 'masterplan.md'
    if (root / 'docs').is_symlink():
        raise ValueError('Record folder is a link: ' + str(root / 'docs'))
    return root / 'docs' / ('working-rules.md' if field_name in WORKING_FIELDS else 'operations.md')


def field(root, field_name):
    content = text(owner(root, field_name))
    values = re.findall(r'^' + re.escape(field_name) + r':[^\S\n]*(.*)$', content, re.M)
    if len(values) != 1 or not values[0].strip():
        raise ValueError('Missing or repeated field: ' + field_name)
    return values[0].strip()


def word_count(content):
    # Count visible words, including all headings, labels and diagram source.
    content = re.sub(r'<!--.*?-->', '', content, flags=re.S)
    content = re.sub(r'!?\[([^\]]*)\]\([^)]*\)', r'\1', content)
    content = re.sub(r'!?\[([^\]]*)\]\[[^\]]*\]', r'\1', content)
    content = re.sub(r'^\s*\[[^]]+\]:\s*\S+.*$', '', content, flags=re.M)
    return len(re.findall(r"\w+(?:['’.-]\w+)*", content, flags=re.U))


def links(content):
    """Local Markdown destinations, including named and collapsed references."""
    definitions = {}
    for match in re.finditer(r'^\s*\[([^]]+)\]:\s*(<[^>]+>|\S+)', content, re.M):
        definitions[match[1].casefold()] = match[2].strip('<>')
    for match in re.finditer(r'\[[^]]*\]\(\s*(<[^>]+>|[^)\s]+)\s*\)', content):
        yield match[1].strip('<>')
    for match in re.finditer(r'\[([^]]+)\](?:\[([^]]*)\])?(?![(:])', content):
        key = (match[2] or match[1]).casefold()
        if key in definitions:
            yield definitions[key]


def record_path(root, base, target):
    """An owner must be a Markdown file inside docs, without redirected parents."""
    target = target.split('#', 1)[0]
    candidate = base / target
    if not target or Path(target).is_absolute() or ':' in target or '..' in Path(target).parts:
        raise ValueError('Indexed record is not a local concept: ' + target)
    relative = candidate.relative_to(root)
    if relative.parts[0] != 'docs' or candidate.suffix != '.md':
        raise ValueError('Indexed record is not a concept document: ' + target)
    for parent in (candidate, *candidate.parents):
        if parent == root:
            break
        if parent.is_symlink():
            raise ValueError('Record is a link: ' + str(parent))
    return relative.as_posix()


def record_names(root, index=None, check=True):
    root = Path(root)
    if (root / 'docs').is_symlink():
        raise ValueError('Record folder is a link: ' + str(root / 'docs'))
    names = {'masterplan.md', 'AGENTS.md', 'CHANGELOG.md', '.ai-build-kit-maintenance',
             'docs/README.md', 'docs/working-rules.md', 'docs/operations.md'}
    if index is None:
        index = text(root / 'docs/README.md')
    for target in links(index):
        name = record_path(root, root / 'docs', target)
        if check:
            text(root / name)
        names.add(name)
    return names


def is_record(name, names):
    return name in names or (Path(name).parent == Path('changes') and name.endswith('.md'))


def validate(root):
    root = Path(root)
    if not new_format(root):
        return word_count(text(root / 'masterplan.md'))
    content = text(root / 'masterplan.md')
    count = word_count(content)
    if count > 500:
        raise ValueError('Masterplan has %s words; the limit is 500. Move detail to its authoritative concept document.' % count)
    if re.search(r'^(?:Trued against|Path|Goes live):', content, re.M):
        raise ValueError('Detailed working or operational fields belong outside the masterplan')
    for name in ('working-rules.md', 'operations.md', 'README.md'):
        text(root / 'docs' / name)
    record_names(root)
    for target in links(content):
        if '://' not in target and not (root / target).is_file():
            raise ValueError('Masterplan link does not open: ' + target)
    return count


def git(root, *args, raw=False):
    result = subprocess.run(['git', '-C', str(root), *args], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        raise ValueError('Saved review history cannot be established')
    return result.stdout if raw else result.stdout.strip()


def checkpoint(root):
    record = Path(root) / '.ai-build-kit-maintenance'
    if not record.exists():
        raise ValueError('No completed document review is recorded; /sync can review the records')
    lines = [line for line in text(record).splitlines() if line.startswith('records-review|')]
    if len(lines) != 1 or not re.fullmatch(r'records-review\|[0-9a-f]{40}\|complete', lines[0]):
        raise ValueError('The last completed document review cannot be established; /sync can review the records')
    return lines[0].split('|')[1]


def history(root, commit):
    if git(root, 'rev-parse', '--is-shallow-repository') != 'false':
        raise ValueError('Review history is incomplete; /sync needs complete history')
    git(root, 'cat-file', '-e', commit + '^{commit}')
    git(root, 'merge-base', '--is-ancestor', commit, 'HEAD')
    if commit not in git(root, 'rev-list', '--first-parent', 'HEAD').splitlines():
        raise ValueError('Review checkpoint is outside the shared first-parent history')


def review_gap(root):
    try:
        if not new_format(root):
            raise ValueError('Legacy project: read its Trued against mark using the legacy route')
        commit = checkpoint(root)
        history(root, commit)
        changes = 0
        for landed in git(root, 'rev-list', '--first-parent', commit + '..HEAD').splitlines():
            names = set()
            for state in (landed + '^', landed):
                index = git(root, 'show', state + ':docs/README.md', raw=True)
                names.update(record_names(root, index, check=False))
            paths = git(root, 'diff-tree', '--no-commit-id', '--name-only', '-z', '-r', landed + '^', landed, raw=True).split('\0')
            if any(p and not is_record(p, names) for p in paths):
                changes += 1
        return {'gap': None, 'changes': changes, 'reviewed': commit}
    except ValueError as error:
        return {'gap': str(error), 'changes': None}


def save_review(root, commit, complete=False):
    root = Path(root)
    if not complete or not new_format(root):
        raise ValueError('Only a completed /sync review of new-format records may save a checkpoint')
    if commit != git(root, 'rev-parse', 'HEAD'):
        raise ValueError('The saved state changed during review; review it again')
    history(root, commit)
    validate(root)
    # NUL-separated paths preserve spaces, quoting and rename source names.
    names_allowed = record_names(root)
    names_allowed.update(record_names(root, git(root, 'show', 'HEAD:docs/README.md', raw=True), check=False))
    dirty = git(root, 'status', '--porcelain', '-z', '--untracked-files=all', raw=True).split('\0')
    index = 0
    while index < len(dirty):
        entry = dirty[index]
        index += 1
        if not entry:
            continue
        names = [entry[3:]]
        if 'R' in entry[:2] or 'C' in entry[:2]:
            if index >= len(dirty):
                raise ValueError('Uncommitted rename cannot be read')
            names.append(dirty[index])
            index += 1
        if any(not is_record(name, names_allowed) for name in names):
            raise ValueError('Uncommitted work remains; leave the review checkpoint unchanged')
    record = root / '.ai-build-kit-maintenance'
    old = text(record) if record.exists() else ''
    lines = [line for line in old.splitlines() if not line.startswith('records-review|')]
    lines.append('records-review|' + commit + '|complete')
    handle, temporary = tempfile.mkstemp(dir=root, prefix='.records-review.')
    try:
        with os.fdopen(handle, 'w') as stream:
            stream.write('\n'.join(lines) + '\n')
        if record.exists():
            os.chmod(temporary, record.stat().st_mode & 0o777)
        os.replace(temporary, record)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['field', 'owner', 'validate', 'review-gap', 'save-review'])
    parser.add_argument('value', nargs='?')
    parser.add_argument('--root', default='.')
    parser.add_argument('--complete', action='store_true')
    args = parser.parse_args()
    try:
        if args.action == 'field':
            print(field(args.root, args.value))
        elif args.action == 'owner':
            print(owner(args.root, args.value))
        elif args.action == 'validate':
            print('Masterplan: %s words' % validate(args.root))
        elif args.action == 'review-gap':
            print(json.dumps(review_gap(args.root)))
        else:
            save_review(args.root, args.value, args.complete)
    except (ValueError, TypeError) as error:
        parser.exit(1, str(error) + '\n')


if __name__ == '__main__':
    main()
