#!/usr/bin/env python3
"""Scan pushed or recorded Git history without printing any secret value."""
import os
import re
import subprocess
import sys
import tempfile


def fail(message, code):
    print("Secret scan: " + message, file=sys.stderr)
    return code


def run_git(args):
    return subprocess.run(["git", *args], stdout=subprocess.PIPE,
                          stderr=subprocess.DEVNULL, check=False)


def exact_values():
    values = set()
    try:
        names = os.listdir(".")
        for name in names:
            if name == ".env" or (name.startswith(".env.") and name != ".env.example"):
                if not os.path.isfile(name):
                    continue
                with open(name, encoding="utf-8") as handle:
                    for line in handle:
                        line = line.strip()
                        if line and not line.startswith("#") and "=" in line:
                            value = line.split("=", 1)[1].strip().strip("'\"")
                            if len(value) >= 8 and not value.startswith("${"):
                                values.add(value)
    except (OSError, UnicodeError):
        raise RuntimeError("local secret files could not be read")
    return sorted(values, key=len, reverse=True)


PATTERNS = [
    re.compile(rb"AKIA[0-9A-Z]{16}"),
    re.compile(rb"(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})"),
    re.compile(rb"(?:sk_live_|rk_live_)[A-Za-z0-9]{16,}"),
    re.compile(rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(rb"(?i)(?:api[_-]?key|secret|password|token)\s*[:=]\s*['\"]?[A-Za-z0-9_./+=-]{20,}"),
]


def main(argv):
    if len(argv) != 1 or (argv[0] != "--all" and not argv[0].startswith("--range=")):
        return fail("could not run: expected --all or --range=<git range>", 2)
    args = ["log", "--no-ext-diff", "--format=", "-p"]
    exact = not os.environ.get("CI")
    if argv[0] == "--all":
        args.append("--all")
    else:
        git_range = argv[0].split("=", 1)[1]
        if not git_range or git_range.startswith("-"):
            return fail("could not run: invalid Git range", 2)
        args.append(git_range)

    if os.environ.get("SCAN_SECRETS_DISABLE_GITLEAKS") != "1":
        gitleaks = subprocess.run(["sh", "-c", "command -v gitleaks"],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if gitleaks.returncode == 0:
            report = None
            try:
                handle = tempfile.NamedTemporaryFile(prefix="abk-secret-scan-", suffix=".json", delete=False)
                report = handle.name
                handle.close()
                command = ["gitleaks", "git", "--no-banner", "--redact",
                           "--report-format=json", "--report-path=" + report]
                if argv[0] != "--all":
                    command.append("--log-opts=" + args[-1])
                else:
                    command.append("--log-opts=--all")
                result = subprocess.run(command, stdout=subprocess.DEVNULL,
                                        stderr=subprocess.DEVNULL)
                if result.returncode == 0:
                    return 0
                if result.returncode == 1:
                    try:
                        import json
                        with open(report, encoding="utf-8") as findings_file:
                            findings = json.load(findings_file)
                        if isinstance(findings, list) and findings:
                            return fail("a secret pattern was found in the commits being checked", 1)
                    except (OSError, ValueError):
                        pass
                return fail("could not run gitleaks", 2)
            finally:
                if report:
                    try:
                        os.unlink(report)
                    except OSError:
                        pass

    log = run_git(args)
    if log.returncode:
        return fail("could not read Git history", 2)
    data = log.stdout
    if exact:
        try:
            for value in exact_values():
                if value.encode() in data:
                    return fail("a value from a local secret file is in the commits being checked", 1)
        except RuntimeError:
            return fail("could not run: local secret files could not be read", 2)
    if any(pattern.search(data) for pattern in PATTERNS):
        return fail("a key-shaped value was found in the commits being checked", 1)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
