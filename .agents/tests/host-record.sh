#!/usr/bin/env sh
# host-record.sh: detect schema drift and incomplete upstream pins without network access.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
python3 "$ROOT/.agents/tools/check-host-record-vendor.py"
python3 - "$ROOT" <<'PY'
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import shutil
import sys
import tempfile

root = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location('vendor', root / '.agents/tools/check-host-record-vendor.py')
vendor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vendor)
with tempfile.TemporaryDirectory() as work:
    folder = Path(work) / vendor.VENDOR
    shutil.copytree(root / vendor.VENDOR, folder)
    def check():
        with contextlib.redirect_stdout(io.StringIO()):
            return vendor.check(Path(work))
    assert check() == 0
    schema = folder / 'host-record.schema.json'
    original = schema.read_bytes()
    schema.write_bytes(original + b'\n')
    assert check() == 1, 'whitespace drift must fail'
    schema.write_bytes(original.replace(b'"boolean"', b'"string"', 1))
    assert check() == 1, 'changed merge-setting type must fail'
    schema.write_bytes(original)
    pin_file = folder / 'upstream.json'
    original_pin = json.loads(pin_file.read_text())
    for field, changed in [('sha256', '0' * 64), ('blob', '0' * 40)]:
        pin_file.write_text(json.dumps(dict(original_pin, **{field: changed})))
        assert check() == 1, 'each fingerprint must be checked independently'
    for field, changed in [('repository', 'https://example.invalid/repo.git'), ('commit', 'short'), ('ref', '../main')]:
        pin_file.write_text(json.dumps(dict(original_pin, **{field: changed})))
        assert check() == 2, 'invalid upstream metadata is not a pass'
    (folder / 'upstream.json').write_text('{}')
    assert check() == 2, 'an incomplete pin is not a pass'
print('ok: schema and pin mutations are detected')
PY
