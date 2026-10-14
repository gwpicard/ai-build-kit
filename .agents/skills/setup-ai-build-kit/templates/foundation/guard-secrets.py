#!/usr/bin/env python3
"""Refuse reads of recorded local secret files and environment dumps."""
import json
import os
import re
import shlex
import sys


def deny(reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }}, separators=(",", ":")))
    return 0


def env_file(path):
    name = os.path.basename(path.rstrip("/\\"))
    return (name == ".env" or name.startswith(".env.")) and name != ".env.example"


def recorded_password_paths(root):
    paths = set()
    for record in ("masterplan.md", "AGENTS.md"):
        try:
            content = open(os.path.join(root, record), encoding="utf-8").read()
        except (OSError, UnicodeError):
            continue
        # Project records put a value after *_PASSWORD_FILE=. Read only an
        # explicitly recorded path; a suggestive filename is not evidence.
        for line in content.splitlines():
            if "PASSWORD_FILE" not in line:
                continue
            match = re.search(r"(?:DB|PREVIEW_DB)_PASSWORD_FILE\s*[:=]\s*[`'\"]?([^\s`'\";,]+)", line)
            if match:
                value = match.group(1).rstrip(".)]")
                paths.add(os.path.normpath(os.path.expanduser(value)))
    return paths


def same_recorded_path(candidate, recorded, root):
    candidate = os.path.normpath(os.path.expanduser(candidate.strip("'\"")))
    if not candidate or candidate.startswith("-"):
        return False
    full = candidate if os.path.isabs(candidate) else os.path.join(root, candidate)
    full = os.path.normpath(full)
    for item in recorded:
        known = item if os.path.isabs(item) else os.path.join(root, item)
        if full == os.path.normpath(known):
            return True
    return False


def dumps_environment(command):
    # Parse simple commands so "env" at the end of "python -m venv env"
    # cannot be mistaken for an environment dump.
    segments = []
    for raw_segment in re.split(r"[|;&()]", command):
        try:
            segment = shlex.split(raw_segment)
        except ValueError:
            segment = raw_segment.split()
        if segment:
            segments.append(segment)
    for part in segments:
        if not part:
            continue
        name = os.path.basename(part[0])
        if name in ("env", "printenv") and len(part) == 1:
            return True
        if name == "export" and part[1:] == ["-p"]:
            return True
        if name == "set" and len(part) == 1:
            return True
        if name in ("declare", "typeset") and len(part) == 2 and part[1] in ("-p", "-x"):
            return True
        if name == "compgen" and part[1:] == ["-v"]:
            return True
        if name in ("sh", "bash") and len(part) >= 3 and part[1] == "-c":
            if dumps_environment(part[2]):
                return True
    return False


def bash_reads_env_file(command):
    try:
        words = shlex.split(command, comments=False, posix=True)
    except ValueError:
        words = command.split()
    if re.search(r"\bgit\s+check-ignore\b", command):
        return False
    if ".gitignore" in words and any(word in ("echo", "printf", "tee") for word in words[:3]):
        return False
    destinations = set()
    for index, word in enumerate(words):
        if word in (">", ">>", "1>", "1>>", "2>", "2>>") and index + 1 < len(words):
            destinations.add(index + 1)
    command_name = os.path.basename(words[0]) if words else ""
    if command_name in ("cp", "mv", "install", "ln") and len(words) > 2:
        destinations.add(len(words) - 1)
    if command_name in ("touch", "mkdir", "rm", "chmod", "chown"):
        destinations.update(range(1, len(words)))
    for index, word in enumerate(words):
        if index in destinations or "=" in word and not word.startswith("="):
            continue
        for part in re.split(r"[:,]", word):
            part = part.strip("(){}")
            if env_file(part):
                return True
    return False


try:
    event = json.load(sys.stdin)
    if not isinstance(event, dict) or not isinstance(event.get("tool_input"), dict):
        raise ValueError("hook input is not an object")
    tool = event.get("tool_name")
    args = event["tool_input"]
    root = os.path.abspath(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))
except (ValueError, TypeError, OSError):
    print("Secret read guard could not check this request.", file=sys.stderr)
    sys.exit(2)

try:
    if tool in ("Read", "Grep"):
        paths = [args.get("file_path")] if tool == "Read" else [args.get("path")]
        recorded = recorded_password_paths(root)
        for path in paths:
            if isinstance(path, str) and (env_file(path) or same_recorded_path(path, recorded, root)):
                sys.exit(deny("This read could expose a recorded secret file."))
    elif tool == "Bash":
        command = args.get("command", "")
        if not isinstance(command, str):
            raise ValueError("command is not text")
        if dumps_environment(command):
            sys.exit(deny("This command could print secret environment values."))
        if bash_reads_env_file(command):
            sys.exit(deny("This command reads a secret environment file."))
        recorded = recorded_password_paths(root)
        # Passing the recorded path to the kit's own reader is safe. Direct
        # file readers are blocked only when the exact recorded path is named.
        try:
            words = shlex.split(command)
        except ValueError:
            words = command.split()
        kit_reader = any(
            os.path.basename(word) == "run-recipe.sh" or
            ".agents/skills/setup-hosting/recipes/" in word
            for word in words
        )
        safe_option = False
        for index, word in enumerate(words):
            if kit_reader and (word == "--password-file" or
                               (word.startswith("--set") and "PASSWORD_FILE=" in word)):
                safe_option = True
            if kit_reader and "PASSWORD_FILE=" in word:
                safe_option = True
        for index, word in enumerate(words):
            if word == "--password-file" and index + 1 < len(words):
                continue
            candidate = word.split("=", 1)[-1] if "PASSWORD_FILE=" in word else word
            if safe_option and ("PASSWORD_FILE=" in word or (index and words[index - 1] == "--password-file")):
                continue
            if same_recorded_path(candidate, recorded, root):
                sys.exit(deny("This command reads a recorded password file."))
except (TypeError, ValueError, OSError):
    print("Secret read guard could not check this request.", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
