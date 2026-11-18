#!/usr/bin/env sh
# host-record.sh: check schema pins, reader diagnostics and merge behaviour on current and older projects.
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
WORK=$(mktemp -d)
trap 'rm -R "$WORK"' EXIT
node - "$ROOT" "$WORK" <<'JS'
const { readFileSync, writeFileSync } = require('node:fs');
const [root, project] = process.argv.slice(2);
const lock = JSON.parse(readFileSync(`${root}/.agents/skills/setup-hosting/recipes/parts/starters/nextjs-supabase/package-lock.json`));
const version = lock.packages['node_modules/ajv'].version;
writeFileSync(`${project}/package.json`, JSON.stringify({ private: true, dependencies: { ajv: version } }));
JS
npm install --prefix "$WORK" --cache "${npm_config_cache:-$WORK/npm-cache}" --ignore-scripts --no-audit --no-fund > "$WORK/install.log" 2>&1 || { cat "$WORK/install.log"; exit 1; }
HOST_RECORD_LEGACY_PROJECT="$WORK" node --test "$ROOT/.agents/tests/host-record.test.cjs"
