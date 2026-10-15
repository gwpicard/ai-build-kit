#!/usr/bin/env sh
# Run the Python implementation with the hook input left on standard input.
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if ! command -v python3 >/dev/null 2>&1 || [ ! -f "$script_dir/scan-secrets.py" ]; then
  echo "Secret scan could not run: python3 or its hook file is missing." >&2
  exit 2
fi
exec python3 "$script_dir/scan-secrets.py" "$@"
