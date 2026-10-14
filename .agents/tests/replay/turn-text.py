#!/usr/bin/env python3
"""Write everything the kit said in one turn, not only its last message.

Usage:

    turn-text.py claude <raw-json> <session-jsonl or ""> <reply-out> [message]
    turn-text.py codex <raw-jsonl> <reply-out>

A coding agent answers a turn in several messages when it works between them:
some text, a tool call, more text. The headless result keeps only the last
message, so a notice given earlier in the same turn never reached the
transcript, and the grader judged a turn the person had read in full. This
joins every text block the agent wrote in the turn, in order, with a blank
line between them.

Claude Code: the session file records the turn. It starts at the person's
message, the one passed in, and runs to the end of the file; a note the agent
adds itself, such as a background task finishing, does not start a new turn.
Messages from a subagent are left out, since the person never saw them. Where
the session file cannot be read, the turn's final result is kept, as before.
Codex: every agent message in the turn's JSONL events, or the last message
where there are none.

Exits 0 when it wrote a reply, 1 when the raw output could not be read.
"""

import json
import sys


def claude(raw, session, out, message=""):
    try:
        result = json.load(open(raw)).get("result") or ""
    except (OSError, ValueError):
        return 1
    texts = []
    try:
        entries = [json.loads(line) for line in open(session) if line.strip()]
    except (OSError, ValueError):
        entries = []
    # The turn starts at the person's message. A note the coding agent adds as
    # a message of its own, such as a background task finishing, is part of
    # the turn, not the start of a new one.
    start = None
    fallback = None
    head = " ".join((message or "").split())[:80]
    for index, entry in enumerate(entries):
        if entry.get("type") != "user" or entry.get("isSidechain"):
            continue
        content = (entry.get("message") or {}).get("content")
        if isinstance(content, str):
            text = content
        elif isinstance(content, list) and not any(
                isinstance(b, dict) and b.get("type") == "tool_result" for b in content):
            text = " ".join(b.get("text", "") for b in content if isinstance(b, dict))
        else:
            continue
        flat = " ".join(text.split())
        if head and head in flat:
            start = index
        elif not flat.startswith(("<task-notification>", "<system-reminder>")):
            fallback = index
    if start is None:
        start = fallback
    if start is not None:
        for entry in entries[start + 1:]:
            if entry.get("type") != "assistant" or entry.get("isSidechain"):
                continue
            for block in (entry.get("message") or {}).get("content") or []:
                if isinstance(block, dict) and block.get("type") == "text" and block.get("text", "").strip():
                    texts.append(block["text"].strip())
    if not texts:
        texts = [result] if result else []
    elif result.strip() and texts[-1] != result.strip():
        texts.append(result.strip())
    with open(out, "w") as handle:
        handle.write("\n\n".join(texts))
    return 0


def codex(raw, out):
    texts = []
    try:
        for line in open(raw):
            try:
                event = json.loads(line)
            except ValueError:
                continue
            item = event.get("item") or {}
            if event.get("type") == "item.completed" and item.get("type") == "agent_message":
                text = (item.get("text") or "").strip()
                if text:
                    texts.append(text)
    except OSError:
        return 1
    if texts:
        with open(out, "w") as handle:
            handle.write("\n\n".join(texts))
    return 0


def main(argv):
    if argv[:1] == ["claude"] and len(argv) in (4, 5):
        return claude(*argv[1:])
    if argv[:1] == ["codex"] and len(argv) == 3:
        return codex(argv[1], argv[2])
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
