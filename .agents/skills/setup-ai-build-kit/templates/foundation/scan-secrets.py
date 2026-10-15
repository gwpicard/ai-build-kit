#!/usr/bin/env python3
"""Scan only the commits a push or pull request is adding."""
import base64
import os
import re
import subprocess
import sys
SKIP_DIRS = {".git", ".venv", "venv", "target", "node_modules", ".next", "dist", "build", "coverage", "vendor"}
NAME_PARTS = re.compile(r"(?:KEY|SECRET|TOKEN|PASSWORD|PASSWD|PWD|PRIVATE|CREDENTIAL|AUTH|DSN|SERVICE_ROLE)", re.I)
SHAPES = [
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(r"\bsk-ant-[A-Za-z0-9_-]{20,}"),
    re.compile(r"\bsk-proj-[A-Za-z0-9_-]{20,}"),
    re.compile(r"\bAIza[0-9A-Za-z_-]{30,}"),
    re.compile(r"\bgithub_pat_[A-Za-z0-9_]{30,}"),
    re.compile(r"\bxox[abpr]-[A-Za-z0-9-]{20,}"),
    re.compile(r"\b(?:ghp_|gho_|ghs_|sbp_|sb_secret_|sk_live_|rk_live_)[A-Za-z0-9_-]{20,}"),
    re.compile(r"-----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED |PGP )?PRIVATE KEY(?: BLOCK)?-----"),
]

def secret_name(name):
    if name.upper().startswith("NEXT_PUBLIC_"):
        return False
    return bool(NAME_PARTS.search(name) or name.upper() == "DATABASE_URL")

def known_shape(value):
    return any(pattern.search(value) for pattern in SHAPES) or bool(re.search(r"https?://[^\s/:@]+:[^\s/@]+@", value, re.I))

def secret_value(name, value):
    value = value.strip()
    if name.upper().startswith("NEXT_PUBLIC_"):
        return False
    return value not in ("", "=") and (secret_name(name) or known_shape(value))

def recorded_password_paths(root):
    paths = set()
    for record in ("masterplan.md", "AGENTS.md"):
        try:
            content = open(os.path.join(root, record), encoding="utf-8").read()
        except (OSError, UnicodeError):
            continue
        for line in content.splitlines():
            match = re.match(r"\s*Password files:\s*(.*)$", line, re.I)
            if match:
                paths.update(os.path.abspath(os.path.join(root, os.path.expanduser(path.strip().strip("`'\""))))
                             for path in match.group(1).split(",") if path.strip())
    return paths


def fail(message, code):
    print("Secret scan: " + message, file=sys.stderr)
    return code


PATTERNS = [
    re.compile(rb"\bsbp_[A-Za-z0-9_-]{20,}"),
    re.compile(rb"\bsb_secret_[A-Za-z0-9_-]{20,}"),
    re.compile(rb"\b(?:sk_live_|rk_live_)[A-Za-z0-9]{16,}"),
    re.compile(rb"\b(?:ghp_|gho_|ghs_)[A-Za-z0-9]{30,}"),
    re.compile(rb"-----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED |PGP )?PRIVATE KEY(?: BLOCK)?-----"),
]
ENV_RE = re.compile(r"(?<![A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)")


def is_service_role_jwt(value):
    for token in re.findall(rb"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+", value):
        try:
            middle = token.split(b".")[1]
            middle += b"=" * (-len(middle) % 4)
            payload = base64.urlsafe_b64decode(middle)
            if re.search(rb'"role"\s*:\s*"service_role"', payload):
                return True
        except (ValueError, base64.binascii.Error):
            pass
    return False


def env_value(line):
    line = line.strip()
    if line.startswith("export "):
        line = line[7:].lstrip()
    match = ENV_RE.match(line)
    if not match:
        return None
    name, value = match.groups()
    value = value.strip()
    if value[:1] in ("'", '"'):
        quote = value[0]
        closing = value.find(quote, 1)
        if closing < 0:
            value = value[1:]
        else:
            value = value[1:closing]
    else:
        value = re.split(r"\s+#", value, maxsplit=1)[0].strip()
    return value.encode() if len(value) >= 8 and secret_value(name, value) else None


def exact_values():
    found = set()
    for current, dirs, files in os.walk("."):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in files:
            if name == ".env.example" or not (name == ".env" or name.startswith(".env.")):
                continue
            try:
                for line in open(os.path.join(current, name), encoding="utf-8"):
                    value = env_value(line)
                    if value:
                        found.add(value)
            except (OSError, UnicodeError):
                raise RuntimeError("local secret files could not be read")
    return found


def git(args):
    return subprocess.run(["git", *args], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def scan_range(spec):
    if spec == "--all":
        args = ["log", "--all", "--no-ext-diff", "--format=COMMIT:%H", "-p"]
    elif spec.startswith("--range="):
        value = spec[len("--range="):]
        if value.startswith("-") or ".." not in value:
            return None, "could not run: invalid Git range"
        left, right = value.split("..", 1)
        missing = [rev for rev in (left, right)
                   if git(["rev-parse", "--verify", rev + "^{commit}"]).returncode != 0]
        if missing:
            before = os.environ.get("PUSH_BEFORE", "") or os.environ.get("BASE_SHA", "")
            after = os.environ.get("PUSH_AFTER", "") or os.environ.get("HEAD_SHA", "")
            zero = not before or not before.strip("0")
            if after and git(["rev-parse", "--verify", after + "^{commit}"]).returncode == 0:
                if zero:
                    args = ["log", "--no-ext-diff", "--format=COMMIT:%H", "-p", after]
                elif git(["rev-parse", "--verify", before + "^{commit}"]).returncode == 0:
                    args = ["log", "--no-ext-diff", "--format=COMMIT:%H", "-p", before + ".." + after]
                else:
                    args = ["log", "--no-ext-diff", "--format=COMMIT:%H", "-p", "HEAD"]
            else:
                args = ["log", "--no-ext-diff", "--format=COMMIT:%H", "-p", "HEAD"]
        else:
            args = ["log", "--no-ext-diff", "--format=COMMIT:%H", "-p", value]
    elif spec.startswith("--new="):
        rev = spec[len("--new="):]
        if not rev or git(["rev-parse", "--verify", rev + "^{commit}"]).returncode:
            return None, "could not run: new branch commit is missing locally"
        args = ["log", "--no-ext-diff", "--format=COMMIT:%H", "-p", rev, "--not", "--remotes"]
    else:
        return None, "could not run: expected --all, --range=<base..head> or --new=<commit>"
    result = git(args)
    if result.returncode:
        return None, "could not run: Git could not read the commits being checked"
    return result.stdout, None


def main(argv):
    if len(argv) != 1:
        return fail("could not run: expected one scan range", 2)
    data, error = scan_range(argv[0])
    if error:
        return fail(error, 2)
    try:
        exact = exact_values()
    except RuntimeError as error:
        return fail("could not run: " + str(error), 2)

    commit = "unknown"
    path = "unknown"
    findings = []
    for raw in data.splitlines():
        if raw.startswith(b"COMMIT:"):
            commit = raw[7:].decode("ascii", "replace")
            continue
        if raw.startswith(b"diff --git "):
            match = re.match(rb"diff --git a/(.*?) b/", raw)
            if match:
                path = match.group(1).decode("utf-8", "replace")
            continue
        if not raw.startswith(b"+") or raw.startswith(b"+++"):
            continue
        line = raw[1:]
        decoded = line.decode("utf-8", "ignore")
        assignment = ENV_RE.search(decoded)
        public_value = bool(assignment and assignment.group(1).upper().startswith("NEXT_PUBLIC_"))
        shaped_secret = not public_value and (any(pattern.search(line) for pattern in PATTERNS)
                                               or known_shape(decoded) or is_service_role_jwt(line))
        if shaped_secret or any(value in line for value in exact):
            findings.append((commit, path))
    if findings:
        for found_commit, found_path in sorted(set(findings)):
            print("Secret scan: possible secret in commit " + found_commit + " file " + found_path, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
