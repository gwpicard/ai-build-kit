#!/usr/bin/env python3
"""Blank known local secret values from successful Claude Code tool results."""
import json
import os
import re
import sys

HIDDEN = "[hidden because the tool result could not be checked]"


def secrets(root):
    values = []
    try:
        names = os.listdir(root)
    except OSError:
        raise RuntimeError("project files could not be read")
    for name in names:
        if name == ".env" or (name.startswith(".env.") and name != ".env.example"):
            path = os.path.join(root, name)
            if not os.path.isfile(path):
                continue
            with open(path, encoding="utf-8") as handle:
                for line in handle:
                    line = line.strip()
                    if not line or line.startswith("#") or "=" not in line:
                        continue
                    value = line.split("=", 1)[1].strip().strip("'\"")
                    if value:
                        values.append(value)
    return sorted(set(values), key=len, reverse=True)


def replace(value, known):
    if isinstance(value, str):
        for secret in known:
            value = value.replace(secret, "[secret hidden]")
        return value
    if isinstance(value, list):
        return [replace(item, known) for item in value]
    if isinstance(value, dict):
        return {replace(key, known): replace(item, known) for key, item in value.items()}
    return value


def hidden_shape(tool):
    if tool == "Bash":
        return {"stdout": HIDDEN, "stderr": "", "interrupted": False, "isImage": False}
    return HIDDEN


def emit(tool, output):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "updatedToolOutput": output,
    }}))


try:
    tool_hint = sys.argv[1] if len(sys.argv) == 2 and sys.argv[1] in ("Bash", "Read", "Grep") else None
    if len(sys.argv) > 2 or (len(sys.argv) == 2 and tool_hint is None):
        print("usage: redact-secrets.sh [Bash|Read|Grep]", file=sys.stderr)
        sys.exit(2)
    event = json.load(sys.stdin)
    if not isinstance(event, dict):
        raise ValueError("hook input is not an object")
    tool = event.get("tool_name") or tool_hint
    response = event.get("tool_response")
    if tool not in ("Bash", "Read", "Grep"):
        sys.exit(0)
    if not isinstance(response, (str, dict, list)):
        raise ValueError("tool_response is missing or has an unknown shape")
    known = secrets(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))
    result = replace(response, known)
    emit(tool, result)
except (ValueError, TypeError, AttributeError, OSError, RuntimeError, UnicodeError, json.JSONDecodeError):
    tool = locals().get("tool", locals().get("tool_hint"))
    emit(tool, hidden_shape(tool))
    print("Tool result hidden because its result or the local secret files could not be checked.", file=sys.stderr)
