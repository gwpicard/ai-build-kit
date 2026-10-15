#!/usr/bin/env sh
# Run the Python implementation with the hook input left on standard input.
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if ! command -v python3 >/dev/null 2>&1 || [ ! -f "$script_dir/redact-secrets.py" ]; then
  input=$(cat)
  tool=${1:-$(printf '%s' "$input" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')}
  case "$tool" in
    Bash) output='{"stdout":"[output hidden: the secret check could not run]","stderr":"","interrupted":false}' ;;
    Grep) output='{"numFiles":0,"filenames":[]}' ;;
    Read) output='{"type":"text","file":{"filePath":"unknown","content":"[output hidden: the secret check could not run]","numLines":1,"startLine":1,"totalLines":1}}' ;;
    *) output='{"type":"text","file":{"filePath":"unknown","content":"[output hidden: the secret check could not run]","numLines":1,"startLine":1,"totalLines":1}}' ;;
  esac
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","updatedToolOutput":%s}}\n' "$output"
  echo "Secret result redactor could not run: python3 or its hook file is missing." >&2
  exit 2
fi
exec python3 "$script_dir/redact-secrets.py" "$@"
