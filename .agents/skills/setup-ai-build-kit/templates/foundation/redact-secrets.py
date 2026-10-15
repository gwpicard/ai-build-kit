#!/usr/bin/env python3
"""Blank known local secret values from Claude Code tool results."""
import importlib.util
import json
import os
import re
import sys

HIDDEN_LINE = "[tool result hidden because it could not be checked]"
spec = importlib.util.spec_from_file_location("scan_secrets", os.path.join(os.path.dirname(__file__), "scan-secrets.py"))
rules = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rules)
SKIP_DIRS = rules.SKIP_DIRS


def dotenv_values(path):
    values = []
    try:
        with open(path, encoding="utf-8") as handle:
            lines = handle.read().splitlines()
    except (OSError, UnicodeError):
        raise RuntimeError("local secret files could not be read")
    index = 0
    while index < len(lines):
        line = lines[index].strip()
        index += 1
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:].lstrip()
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$", line)
        if not match:
            continue
        name, raw = match.groups()
        raw = raw.lstrip()
        if raw[:1] in ("'", '"'):
            quote = raw[0]
            body = raw[1:]
            while quote not in body and index < len(lines):
                body += "\n" + lines[index]
                index += 1
            if quote in body:
                body = body[:body.find(quote)]
            value = body
        else:
            value = re.split(r"\s+#", raw, maxsplit=1)[0].strip()
        if len(value) >= 8 and rules.secret_value(name, value):
            values.append((name, value))
    return values


def secret_values(root):
    found = []
    for current, dirs, files in os.walk(root):
        dirs[:] = [name for name in dirs if name not in SKIP_DIRS]
        for name in files:
            if name == ".env.example" or not (name == ".env" or name.startswith(".env.")):
                continue
            found.extend(dotenv_values(os.path.join(current, name)))
    for path in rules.recorded_password_paths(root):
        try:
            with open(path, encoding="utf-8") as handle:
                value = handle.read().strip()
        except (OSError, UnicodeError):
            raise RuntimeError("a recorded password file could not be read")
        if len(value) >= 8 and value != "=":
            found.append(("DB_PASSWORD", value))
    unique = {}
    for name, value in found:
        if value and value != "=":
            unique.setdefault(value, name)
    return sorted(((value, name) for value, name in unique.items()), key=lambda item: len(item[0]), reverse=True)


def replace_text(text, known):
    for value, name in known:
        text = text.replace(value, "[" + name + " hidden]")
    return text


def hide_strings(value):
    if isinstance(value, str):
        return HIDDEN_LINE
    if isinstance(value, list):
        return [hide_strings(item) for item in value]
    if isinstance(value, dict):
        return {key: hide_strings(item) for key, item in value.items()}
    return value


def hide_strings_keep_schema(value, key=None):
    if isinstance(value, str):
        return value if key in ("type", "mode", "base64", "mediaType") else HIDDEN_LINE
    if isinstance(value, list):
        return [hide_strings_keep_schema(item) for item in value]
    if isinstance(value, dict):
        return {name: hide_strings_keep_schema(item, name) for name, item in value.items()}
    return value


def redact_shape(tool, result, known):
    if tool == "Read" and isinstance(result, dict) and result.get("type") in ("image", "image_url"):
        return result
    if isinstance(result, str):
        return replace_text(result, known)
    if isinstance(result, list):
        return [redact_shape(tool, item, known) for item in result]
    if isinstance(result, dict):
        # Claude Code's schemas are documented by the installed SDK types.
        # Unknown shapes are hidden in place; image payloads stay byte-for-byte.
        if tool == "Read" and result.get("type") in ("image", "image_url"):
            return result
        if tool == "Bash" and result.get("isImage") is True:
            return result
        return {key: (item if key == "base64" else redact_shape(tool, item, known))
                for key, item in result.items()}
    return result


def known_tool_shape(tool, result):
    if not isinstance(result, dict):
        return False
    if tool == "Bash":
        return (isinstance(result.get("stdout"), str) and isinstance(result.get("stderr"), str)
                and isinstance(result.get("interrupted"), bool))
    if tool == "Read":
        if result.get("type") in ("image", "image_url"):
            return True
        file = result.get("file")
        if not isinstance(file, dict):
            return False
        kind = result.get("type")
        if kind == "text":
            return (isinstance(file.get("filePath"), str) and isinstance(file.get("content"), str)
                    and all(isinstance(file.get(key), int) for key in ("numLines", "startLine", "totalLines")))
        if kind == "notebook":
            return isinstance(file.get("filePath"), str) and isinstance(file.get("cells"), list)
        if kind == "pdf":
            return (isinstance(file.get("filePath"), str) and isinstance(file.get("base64"), str)
                    and isinstance(file.get("originalSize"), int))
        if kind == "parts":
            return (isinstance(file.get("filePath"), str) and isinstance(file.get("originalSize"), int)
                    and isinstance(file.get("count"), int) and isinstance(file.get("outputDir"), str))
        if kind == "file_unchanged":
            return isinstance(file.get("filePath"), str)
        return False
    if tool == "Grep":
        return (isinstance(result.get("numFiles"), int) and isinstance(result.get("filenames"), list)
                and all(isinstance(name, str) for name in result["filenames"]))
    return False


def failure_shape(tool, result):
    if isinstance(result, dict):
        if tool == "Read" and result.get("type") in ("image", "image_url"):
            return result
        if tool == "Bash" and result.get("isImage") is True:
            return result
        known_shape = (
            tool == "Bash" and isinstance(result.get("stdout"), str)
            and isinstance(result.get("stderr"), str) and isinstance(result.get("interrupted"), bool)
        ) or (tool == "Read" and known_tool_shape(tool, result)) or (
            tool == "Grep" and isinstance(result.get("numFiles"), int)
            and isinstance(result.get("filenames"), list)
        )
        if not known_shape:
            return hide_strings_keep_schema(result)
        def hide_known(value, key=None):
            if isinstance(value, str):
                if key in ("type", "mode", "base64", "mediaType"):
                    return value
                return HIDDEN_LINE
            if isinstance(value, list):
                return [hide_known(item) for item in value]
            if isinstance(value, dict):
                return {name: hide_known(item, name) for name, item in value.items()}
            return value
        return hide_known(result)
    if isinstance(result, list):
        return hide_strings(result)
    if tool == "Bash":
        return {"stdout": HIDDEN_LINE, "stderr": "", "interrupted": False, "isImage": False}
    if tool == "Read":
        return {"type": "text", "file": {"filePath": "unknown", "content": HIDDEN_LINE,
                "numLines": 1, "startLine": 1, "totalLines": 1}}
    if tool == "Grep":
        return {"numFiles": 0, "filenames": [], "content": HIDDEN_LINE}
    return HIDDEN_LINE


def emit(result):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "updatedToolOutput": result,
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
        raise ValueError("tool_response is missing")
    known = secret_values(os.path.abspath(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())))
    rewritten = redact_shape(tool, response, known) if known_tool_shape(tool, response) else hide_strings_keep_schema(response)
    if rewritten != response:
        emit(rewritten)
except (ValueError, TypeError, AttributeError, OSError, RuntimeError, UnicodeError, json.JSONDecodeError):
    response = locals().get("response")
    tool = locals().get("tool", locals().get("tool_hint"))
    emit(failure_shape(tool, response))
    print("Tool result hidden because its result or local secret files could not be checked.", file=sys.stderr)
