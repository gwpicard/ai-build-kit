#!/usr/bin/env python3
"""Check the vendored Host Kit schema against its recorded byte fingerprints."""
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
VENDOR = '.agents/skills/merge/contracts/ai-host-kit'


def check(root=ROOT):
    folder = root / VENDOR
    try:
        pin = json.loads((folder / 'upstream.json').read_text())
        fields = {'repository', 'ref', 'commit', 'path', 'blob', 'sha256'}
        if not isinstance(pin, dict) or set(pin) != fields:
            raise ValueError()
        if (pin['repository'] != 'https://github.com/gwpicard/ai-host-kit.git'
                or pin['ref'] != 'main' or pin['path'] != 'contracts/host-record.schema.json'
                or not all(isinstance(value, str) for value in pin.values())
                or not all(re.fullmatch('[0-9a-f]{40}', pin[key]) for key in ('commit', 'blob'))
                or not re.fullmatch('[0-9a-f]{64}', pin['sha256'])):
            raise ValueError()
    except (OSError, ValueError, TypeError):
        print('could not check: the host record upstream pin is absent or invalid')
        return 2
    try:
        data = (folder / 'host-record.schema.json').read_bytes()
    except OSError:
        print('failed: the vendored host record schema is absent')
        return 1
    blob = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
    if blob != pin['blob'] or hashlib.sha256(data).hexdigest() != pin['sha256']:
        print('failed: the vendored host record schema differs from its pin')
        return 1
    print('passed: the vendored host record schema matches its pinned Git blob and SHA-256')
    return 0


if __name__ == '__main__':
    if len(sys.argv) != 1:
        print('Use check-host-record-vendor.py without arguments')
        sys.exit(2)
    sys.exit(check())
