#!/usr/bin/env python3
"""Refuse Claude Code reads that could expose local secrets."""
import json
import os
import re
import sys


def deny(reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }}))
    return 0


try:
    event = json.load(sys.stdin)
    if not isinstance(event, dict):
        raise ValueError("hook input is not an object")
    tool = event.get("tool_name")
    args = event.get("tool_input")
    if not isinstance(args, dict):
        raise ValueError("tool_input is not an object")
    text = " ".join(str(value) for value in args.values() if isinstance(value, str))
except (ValueError, TypeError, OSError):
    print("Secret read guard could not check this request.", file=sys.stderr)
    return_code = 2
    sys.exit(return_code)

if tool in ("Read", "Grep"):
    paths = re.findall(r"(?:^|[\s=])([^\s,;]+)", text)
    for item in paths:
        name = os.path.basename(item.rstrip("/\\"))
        if name == ".env.example":
            continue
        base = name.lower().split(".", 1)[0]
        if name == ".env" or name.startswith(".env.") or re.search(
            r"pass(word|wd)?|cred(ential)?|secret", base
        ):
            sys.exit(deny("This read could expose a secret file."))
elif tool == "Bash":
    command = args.get("command", "")
    if not isinstance(command, str):
        print("Secret read guard could not check this request.", file=sys.stderr)
        sys.exit(2)
    if re.search(r"(^|[;&|\s])(?:[^\s;&|]*/)?(?:env|printenv)(\s|$)|\bexport\s+-p\b|^\s*set\s*$", command):
        sys.exit(deny("This command could print secret environment values."))
    env_files = re.findall(r"(?<![\w.-])(?:[^\s'\";|]*/)?\.env(?:\.[^\s'\";|]*)?(?=$|[\s'\";|])", command)
    if env_files and any(os.path.basename(match) != ".env.example" for match in env_files):
        sys.exit(deny("This command names a secret environment file."))
    if re.search(r"\b(password|passwd|credentials|secrets)(?:\.\w+)?\b", command, re.I):
        sys.exit(deny("This command names a password or secret file."))

sys.exit(0)
