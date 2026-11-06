#!/usr/bin/env python3
"""Check unchanged adopted code, run its safety net and report its limits.

Run from the project root. Exit 0: tests passed; 1: changed baseline or failed
test; 2: invalid inventory or a check could not run. No project code is edited.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def project_file(name):
    path = Path(name)
    if path.is_absolute() or '..' in path.parts or not path.parts:
        raise ValueError('paths must be relative files inside this project')
    if any(p.is_symlink() for p in [path, *path.parents]):
        raise ValueError('linked paths are not baseline files')
    if not path.is_file():
        raise ValueError('a recorded source or test file is missing: ' + name)
    return path


def digest(name):
    return hashlib.sha256(project_file(name).read_bytes()).hexdigest()


def strings(value):
    return (isinstance(value, list) and bool(value)
            and all(isinstance(s, str) and s.strip() for s in value))


def inventory(path):
    data = json.loads(project_file(path).read_text())
    if not isinstance(data, dict) or data.get('version') != 1:
        raise ValueError('the inventory needs version 1')
    sources = data.get('sources')
    if not isinstance(sources, dict) or not sources:
        raise ValueError('record the existing source files before writing tests')
    for name, sha in sources.items():
        project_file(name)
        if not isinstance(sha, str) or len(sha) != 64 or any(c not in '0123456789abcdef' for c in sha):
            raise ValueError('a baseline fingerprint is invalid')
    for kind in ('permissions', 'journeys'):
        suites = data.get(kind)
        if not isinstance(suites, list) or not suites:
            raise ValueError('record at least one ' + kind + ' test suite')
        for suite in suites:
            if not isinstance(suite, dict) or not isinstance(suite.get('behaviour'), str) or not suite['behaviour'].strip():
                raise ValueError('each suite needs a plain description of its behaviour')
            if not strings(suite.get('command')) or not strings(suite.get('tests')):
                raise ValueError('each suite needs a command array and test file paths')
            for name in suite['tests']:
                project_file(name)
                if name in sources:
                    raise ValueError('a new test cannot also be an existing source file')
    gaps = data.get('uncovered')
    if not isinstance(gaps, list) or any(not isinstance(s, str) or not s.strip() for s in gaps):
        raise ValueError('list uncovered behaviour, using an empty array only when none is known')
    return data


def unchanged(data):
    changed = [name for name, sha in data['sources'].items() if digest(name) != sha]
    if changed:
        print('Baseline not recorded: existing code changed: ' + ', '.join(changed))
    return not changed


def limits(data):
    print('Tests do not yet cover:')
    for gap in data['uncovered']:
        print('- ' + gap)
    if not data['uncovered']:
        print('- No further gaps recorded; this is not proof of complete coverage.')
    print('I cannot vouch for code or behaviour these tests do not cover.')
    print('Recorded behaviour is not approved behaviour. A test may be recording a fault.')


def run(data, baseline):
    print('Adoption safety net' + (' on unchanged code' if baseline else ' on current code'))
    if baseline and not unchanged(data):
        limits(data)
        return 1
    results = []
    for kind in ('permissions', 'journeys'):
        for suite in data[kind]:
            try:
                result = subprocess.run(suite['command'], stdout=sys.stderr, stderr=sys.stderr,
                                        timeout=300, check=False)
                status = 'passed' if result.returncode == 0 else 'failed'
            except (OSError, subprocess.TimeoutExpired):
                status = 'could not run'
            results.append(status)
            print(kind + ': ' + status + ': ' + suite['behaviour'])
    intact = not baseline or unchanged(data)
    limits(data)
    if not intact or 'failed' in results:
        return 1
    return 2 if 'could not run' in results else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('snapshot', 'baseline', 'check'))
    parser.add_argument('record', help='project-relative JSON inventory')
    parser.add_argument('sources', nargs='*', help='existing files, for snapshot only')
    args = parser.parse_args()
    try:
        if args.action == 'snapshot':
            if not args.sources:
                raise ValueError('snapshot needs the existing source file paths')
            # Validate the output location without creating or replacing anything.
            target = Path(args.record)
            if target.is_absolute() or '..' in target.parts or any(p.is_symlink() for p in [target, *target.parents]):
                raise ValueError('the inventory must stay inside this project')
            data = {'version': 1, 'sources': {p: digest(p) for p in args.sources},
                    'permissions': [], 'journeys': [], 'uncovered': []}
            with target.open('x') as handle:
                json.dump(data, handle, indent=2)
                handle.write('\n')
            print('Source fingerprints recorded. Add permission tests, then journey tests and coverage gaps.')
            return 0
        if args.sources:
            raise ValueError('source paths belong only to snapshot')
        return run(inventory(args.record), args.action == 'baseline')
    except (OSError, ValueError, TypeError) as error:
        print('Adoption safety net could not run: ' + str(error), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
