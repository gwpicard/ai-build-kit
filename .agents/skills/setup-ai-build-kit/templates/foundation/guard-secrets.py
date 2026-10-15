#!/usr/bin/env python3
"""Refuse reads of recorded local secret files and environment dumps."""
import importlib.util
import json
import os
import re
import shlex
import sys

spec = importlib.util.spec_from_file_location("scan_secrets", os.path.join(os.path.dirname(__file__), "scan-secrets.py"))
scan_rules = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scan_rules)


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


def env_target(path):
    name = os.path.basename(path.rstrip("/\\"))
    return env_file(path) or (name.startswith(".env") and any(char in name for char in "*?[]") and name != ".env.example")


def recorded_password_paths(root):
    return scan_rules.recorded_password_paths(root)


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
        if name in ("env", "printenv") and (len(part) == 1 or part[1:] == ["-0"]):
            return True
        if name == "export" and part[1:] == ["-p"]:
            return True
        if name == "set" and len(part) == 1:
            return True
        if name in ("declare", "typeset") and len(part) == 2 and part[1] in ("-p", "-x"):
            return True
        if name == "compgen" and part[1:] == ["-v"]:
            return True
        if name in ("sh", "bash", "zsh") and len(part) >= 3 and part[1] == "-c":
            if dumps_environment(part[2]):
                return True
    return False


def bash_reads_env_file(command):
    try:
        words = shlex.split(command, comments=False, posix=True)
    except ValueError:
        words = command.split()
    if re.search(r"(?:`\s*env\s*`|\$\(\s*env\s*\))", command):
        return True
    if re.search(r"\bgit\s+check-ignore\b", command):
        return False
    if ".gitignore" in words and any(word in ("echo", "printf", "tee") for word in words[:3]):
        return False
    destinations = set()
    for index, word in enumerate(words):
        if word in (">", ">>", "1>", "1>>", "2>", "2>>") and index + 1 < len(words):
            destinations.add(index + 1)
    command_name = os.path.basename(words[0]) if words else ""
    if command_name in ("ls", "test") or (command_name == "[" and words[-1:] == ["]"]) or (command_name == "git" and len(words) > 2 and words[1:3] == ["rm", "--cached"]):
        return False
    if command_name == "grep" and words[-1:] == [".gitignore"]:
        return False
    if command_name in ("cp", "mv", "install", "ln") and len(words) > 2:
        destinations.add(len(words) - 1)
    if command_name in ("touch", "mkdir", "rm", "chmod", "chown"):
        destinations.update(range(1, len(words)))
    if command_name == "python3" and len(words) > 3 and words[1:3] == ["-m", "venv"]:
        destinations.update(range(3, len(words)))
    if command_name == "git" and len(words) > 2 and words[1] == "commit":
        destinations.update(i + 1 for i, word in enumerate(words[:-1]) if word in ("-m", "--message"))
    if command_name == "grep" and len(words) > 1 and words[-1] == ".gitignore":
        destinations.update(range(1, len(words) - 1))
    for index, word in enumerate(words):
        if index in destinations or "=" in word and not word.startswith("="):
            continue
        for part in re.split(r"[:,]", word):
            part = part.strip("(){}<>")
            if env_target(part):
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
        paths = [args.get("file_path")] if tool == "Read" else [args.get("path"), args.get("glob")]
        recorded = recorded_password_paths(root)
        for path in paths:
            if isinstance(path, str) and (env_target(path) or same_recorded_path(path, recorded, root)):
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
        recipe_readers = {"run-recipe.sh", "secrets.sh", "going-live.sh", "live-check.sh"}
        kit_reader = any(os.path.basename(word) in recipe_readers for word in words)
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
