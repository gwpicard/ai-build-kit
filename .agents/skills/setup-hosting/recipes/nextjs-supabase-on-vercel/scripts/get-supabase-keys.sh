#!/usr/bin/env sh
# get-supabase-keys.sh: save the two Supabase API keys without using a clipboard.
# Usage: get-supabase-keys.sh <project ref> <folder>
# Exit 0 when both files were written, 1 when Supabase refused, 2 when it could not run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

ref=${1:-}
folder=${2:-}
[ -n "$ref" ] && [ -n "$folder" ] || cl_cannot "Give the Supabase project reference and a folder for the key files."
cl_need supabase python3
umask 077
mkdir -p "$folder" || cl_cannot "The folder for the key files could not be made."
json=$(mktemp) || cl_cannot "A private temporary file could not be made."
trap 'rm -f "$json"' EXIT HUP INT TERM
supabase projects api-keys --project-ref "$ref" -o json >"$json" 2>/dev/null ||
  cl_cannot "Supabase could not return the API keys for project $ref."
python3 - "$json" "$folder" <<'PY'
import json, os, pathlib, re, sys, tempfile

source, folder = sys.argv[1:]
try:
    data = json.load(open(source, encoding="utf-8"))
except (OSError, ValueError):
    raise SystemExit("Supabase's answer was not readable JSON.")

found = {}
def visit(value):
    if isinstance(value, dict):
        label = " ".join(str(value.get(k, "")) for k in ("name", "type", "key_type", "keyType")).lower()
        secret = "secret" in label or "service_role" in label
        public = "publishable" in label or "anon" in label
        raw = value.get("api_key", value.get("apiKey", value.get("key")))
        if isinstance(raw, str):
            if raw.startswith("sb_secret_") or (secret and raw.startswith("eyJ")):
                found["SUPABASE_SECRET_KEY"] = raw
            if raw.startswith("sb_publishable_") or (public and raw.startswith("eyJ")):
                found["NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY"] = raw
        for item in value.values():
            visit(item)
    elif isinstance(value, list):
        for item in value:
            visit(item)
visit(data)
if len(found) != 2:
    raise SystemExit("Supabase's answer did not contain both publishable and secret keys.")

for name, value in found.items():
    target = pathlib.Path(folder) / name
    fd, temporary = tempfile.mkstemp(prefix=".supabase-key-", dir=folder)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(value + "\n")
        os.replace(temporary, target)
        os.chmod(target, 0o600)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    prefix = "sb_publishable_" if name.endswith("PUBLISHABLE_KEY") else "sb_secret_"
    if value.startswith(prefix):
        shown = prefix + value[len(prefix):len(prefix) + 6]
    else:
        shown = "eyJ" + value[3:9]
    print(f"{name}: {shown}")
PY
status=$?
[ "$status" -eq 0 ] || cl_cannot "Supabase's answer could not be saved as the two key files."
cl_pass "The Supabase publishable and secret key files were written with private permissions."
