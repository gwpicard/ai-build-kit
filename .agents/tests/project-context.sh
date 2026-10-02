#!/usr/bin/env sh
# Exercise the shipped section reader. Guided model routing stays a separate check.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT/.agents/tests/project-context-reader.py"
