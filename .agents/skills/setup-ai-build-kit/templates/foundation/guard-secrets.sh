#!/usr/bin/env sh
# Run the Python implementation with the hook input left on standard input.
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec python3 "$script_dir/guard-secrets.py" "$@"
