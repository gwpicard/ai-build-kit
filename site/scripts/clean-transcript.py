#!/usr/bin/env python3
"""Turn a recorded replay transcript into a small, cleaned site data file."""

import argparse
import json
import re
import sys
from pathlib import Path


SECRET_SHAPES = [
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(r"\bsk-ant-[A-Za-z0-9_-]{20,}"),
    re.compile(r"\bsk-proj-[A-Za-z0-9_-]{20,}"),
    re.compile(r"\bAIza[0-9A-Za-z_-]{30,}"),
    re.compile(r"\bgithub_pat_[A-Za-z0-9_]{30,}"),
    re.compile(r"\bxox[abpr]-[A-Za-z0-9-]{20,}"),
    re.compile(r"\b(?:ghp_|gho_|ghs_|sbp_|sb_secret_|sk_live_|rk_live_)[A-Za-z0-9_-]{20,}"),
    re.compile(r"-----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED |PGP )?PRIVATE KEY(?: BLOCK)?-----"),
    re.compile(r"https?://[^\s/:@]+:[^\s/@]+@", re.IGNORECASE),
    re.compile(r"\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b"),
    re.compile(r"(?i)\b(?:token|secret|password|passwd|private[_ -]?key|credential)\s*[:=]\s*[^\s,;]+"),
]
SECRET_NAME = re.compile(r"(?:KEY|SECRET|TOKEN|PASSWORD|PASSWD|PWD|PRIVATE|CREDENTIAL|AUTH|DSN)", re.IGNORECASE)
ASSIGNMENT = re.compile(r"(?im)(?<![A-Za-z0-9_])(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(\"[^\"\n]*\"|'[^'\n]*'|[^\s,;]+)")

LOCAL_PATH = re.compile(
    r"(?<![A-Za-z0-9])(?:/private/var|/var/tmp|/private/tmp|/tmp|/Users/[^/\s]+|~/[^\s`'\"]+)"
    r"(?:/[^\s`'\"]*)?"
)
TEMP_NAME = re.compile(r"(?<![A-Za-z0-9])(?:abk-(?:tmp|try|preview|replay)[A-Za-z0-9._-]*|tmp-[A-Za-z0-9._-]+)", re.IGNORECASE)
NUMBERED_REFERENCE = re.compile(r"#\s*\d+")
HEADER = re.compile(r"^### (user turn|kit reply) (\d+)\s*$")


def clean_text(text: str, limit: int) -> str:
    text = LOCAL_PATH.sub("[local path]", text)
    text = TEMP_NAME.sub("[temporary folder]", text)
    text = NUMBERED_REFERENCE.sub("[number]", text)
    def redact_assignment(match: re.Match[str]) -> str:
        name, value = match.groups()
        if name.upper().startswith("NEXT_PUBLIC_"):
            return match.group(0)
        if name.upper() == "DATABASE_URL" or SECRET_NAME.search(name):
            return f"{name}=[redacted]"
        return match.group(0)
    text = ASSIGNMENT.sub(redact_assignment, text)
    for pattern in SECRET_SHAPES:
        text = pattern.sub("[redacted]", text)
    text = text.strip()
    if len(text) > limit:
        cut = text.rfind(" ", 0, limit)
        if cut < limit // 2:
            cut = text.find(" ", limit)
        if cut >= 0:
            text = text[:cut].rstrip() + "…"
    return text


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("transcript", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--max-chars", type=int, default=800)
    parser.add_argument("--stage", required=True, help="stage id from site/data/workflow.json")
    args = parser.parse_args()
    if args.max_chars < 100:
        parser.error("--max-chars must be at least 100")

    grade_path = args.transcript.with_suffix(".json")
    try:
        grade = json.loads(grade_path.read_text(encoding="utf-8"))
        raw = args.transcript.read_text(encoding="utf-8")
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        print(f"cannot read replay input: {error}", file=sys.stderr)
        return 1
    if grade.get("held") is not True:
        print("replay grade does not say held", file=sys.stderr)
        return 1
    try:
        workflow = json.loads((Path(__file__).parents[1] / "data/workflow.json").read_text(encoding="utf-8"))
        stage = next(item for item in workflow if item.get("id") == args.stage)
    except (OSError, UnicodeError, json.JSONDecodeError, StopIteration):
        print(f"workflow stage {args.stage} is not in site/data/workflow.json", file=sys.stderr)
        return 1

    turns = []
    who = None
    lines = []
    for line in raw.splitlines():
        match = HEADER.match(line)
        if match:
            if who is not None:
                text = clean_text("\n".join(lines), args.max_chars)
                if text:
                    turns.append({"who": who, "text": text})
            who = "person" if match.group(1) == "user turn" else "kit"
            lines = []
        elif who is not None:
            lines.append(line)
    if who is not None:
        text = clean_text("\n".join(lines), args.max_chars)
        if text:
            turns.append({"who": who, "text": text})
    if not turns:
        print("transcript contains no turns", file=sys.stderr)
        return 1

    verdicts = grade.get("verdicts", {}).values()
    counts = {name: sum(1 for item in verdicts if item.get("verdict") == name)
              for name in ("hit", "drift", "miss", "unobservable")}
    match = re.fullmatch(r"s(\d+)-r(\d+)\.transcript", args.transcript.name)
    if not match:
        print("transcript name must use sNN-rK.transcript", file=sys.stderr)
        return 1
    result = {
        "replayCase": f"s{match.group(1)}",
        "replayRun": f"r{match.group(2)}",
        "candidate": "1.0",
        "held": True,
        "grade": counts,
        "workflowStage": args.stage,
        "skills": stage["skills"],
        "checks": stage["checks"],
        "turns": turns,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {args.output}: {len(turns)} turns; held replay {result['replayCase']}-{result['replayRun']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
