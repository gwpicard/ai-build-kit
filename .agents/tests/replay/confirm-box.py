"""Answer Claude's confirmation boxes for the replay's scripted person."""

import json
import os
from pathlib import Path
import re
import shlex
import sys


def migration_command(command):
    """Recognise a migration or its recorded yes, without running the shell."""
    # Every part of a compound command must belong to the granted migration.
    if any(part in command for part in ("$(", "`", "\n")):
        return None
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()<>")
    lexer.whitespace_split = True
    lexer.commenters = ""
    try:
        words = list(lexer)
    except ValueError:
        return None
    if words[:1] == ["cd"] and len(words) > 3 and words[2] == "&&":
        words = words[3:]
    # A status report after the command grants no further action.
    if words[-3:] == [";", "echo", "exit $?"]:
        words = words[:-3]
    if any(word != "&&" and re.fullmatch(r"[;&|()<>]+", word) for word in words):
        return None
    parts = [[]]
    for word in words:
        if word == "&&":
            parts.append([])
        else:
            parts[-1].append(word)
    actions = [migration_action(part) for part in parts]
    return ", then ".join(actions) if all(actions) else None


def migration_action(words):
    while words and re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*=.*", words[0]):
        words.pop(0)
    if words[:1] in (["python3"], ["python"], ["sh"], ["bash"]):
        words = words[1:]
    if not words:
        return None
    executable = Path(words[0]).name
    if (executable == "approval.py" and len(words) == 5 and words[1] == "yes"
            and words[3] == "--words"
            and (re.fullmatch(r"migrate --apply(?: [A-Za-z0-9_-]+)?", words[2])
                 or re.match(r"apply (?:the )?migration\b", words[2], re.IGNORECASE))):
        return "record the migration yes"
    if executable == "migrate.sh" and words[1:2] == ["--apply"] and len(words) in (2, 3):
        return "apply the migration"
    if executable == "supabase" and words[1:3] == ["db", "push"]:
        return "supabase db push"
    return None


def answer(arguments, grants, turn):
    action = None
    tool_input = arguments.get("input", {})
    if arguments.get("tool_name") == "Bash" and isinstance(tool_input, dict):
        command = tool_input.get("command")
        if isinstance(command, str):
            action = migration_command(command)
    granted = False
    for line in Path(grants).read_text().splitlines():
        number, _, grant = line.partition("\t")
        if number.isdigit() and 0 < int(number) <= turn and grant == "migration":
            granted = True
    if action and granted:
        return {"behavior": "allow", "updatedInput": tool_input}, action
    return {"behavior": "deny", "message": "The scripted person has not granted this command on this turn."}, action


def serve(grants, log, turn):
    for line in sys.stdin:
        request = json.loads(line)
        if "id" not in request:
            continue
        method = request.get("method")
        if method == "initialize":
            result = {"protocolVersion": request["params"]["protocolVersion"],
                      "capabilities": {"tools": {}},
                      "serverInfo": {"name": "replay-confirm-box", "version": "1"}}
        elif method == "tools/list":
            result = {"tools": [{"name": "answer", "description": "Answer a replay confirmation box.",
                                 "inputSchema": {"type": "object", "properties": {
                                     "tool_name": {"type": "string"}, "input": {"type": "object"},
                                     "tool_use_id": {"type": "string"}},
                                     "required": ["tool_name", "input"]}}]}
        elif method == "tools/call" and request["params"]["name"] == "answer":
            arguments = request["params"]["arguments"]
            decision, action = answer(arguments, grants, turn)
            # Commands can contain passwords. Log the recognised action and id,
            # without copying command text or tool input into the transcript.
            with open(log, "a") as handle:
                handle.write("Confirmation box: %s; answer: %s; turn: %s; tool use: %s\n" % (
                    action or "ungranted tool or command", decision["behavior"], turn,
                    json.dumps(arguments.get("tool_use_id", ""))))
            result = {"content": [{"type": "text", "text": json.dumps(decision)}]}
        elif method == "ping":
            result = {}
        else:
            print(json.dumps({"jsonrpc": "2.0", "id": request["id"],
                              "error": {"code": -32601, "message": "Unknown method"}}), flush=True)
            continue
        print(json.dumps({"jsonrpc": "2.0", "id": request["id"], "result": result}), flush=True)


if __name__ == "__main__":
    if sys.argv[1] == "--config":
        print(json.dumps({"mcpServers": {"replay_box": {
            "command": sys.executable, "args": [os.path.abspath(__file__), *sys.argv[2:]]}}}))
    else:
        serve(sys.argv[1], sys.argv[2], int(sys.argv[3]))
