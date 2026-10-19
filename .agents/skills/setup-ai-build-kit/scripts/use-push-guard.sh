#!/usr/bin/env sh
# Enable the project's push guard, keeping any existing shell hook in place.
# --check only checks whether Git would run the guard. Exit 1 means it would not.
# Installation waits for found-save when the folder is not a repository yet.
SCRIPT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
exec python3 - "$SCRIPT_ROOT" "$@" <<'PYTHON'
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys

skill = Path(sys.argv[1])
args = sys.argv[2:]
check = bool(args and args[0] == '--check')
if check:
    args.pop(0)
if len(args) > 1:
    sys.exit('usage: use-push-guard.sh [--check] [project-folder]')

def stop(reason=''):
    print("The push guard is not on. Run the kit's use-push-guard.sh from the project folder; "
          'if it still stops, make its hooks folder writable and keep the existing hook as a shell script.'
          + (' ' + reason if reason else ''),
          file=sys.stderr)
    sys.exit(1)

def git(*args):
    return subprocess.run(['git', *args], capture_output=True, text=True)

def shell_hook(content):
    first = content.partition('\n')[0]
    if not first.startswith('#!'):
        return True
    interpreter = shlex.split(first[2:])
    if interpreter and Path(interpreter[0]).name == 'env':
        interpreter = interpreter[1:]
    return bool(interpreter and Path(interpreter[0]).name in ('sh', 'bash', 'dash', 'zsh', 'ksh'))

# Both the guard and the person's hook receive the complete push input.
chain = '''# AI Build Kit push guard
kit_push_input=$(mktemp) || exit 1
cat > "$kit_push_input" || { rm -f "$kit_push_input"; exit 1; }
sh "$(git rev-parse --show-toplevel)/.agents/hooks/git/pre-push" "$@" < "$kit_push_input" || { rm -f "$kit_push_input"; exit 1; }
exec 0< "$kit_push_input"
rm -f "$kit_push_input"
unset kit_push_input
# End AI Build Kit push guard
'''

try:
    os.chdir(args[0] if args else '.')
    top = git('rev-parse', '--show-toplevel')
    if top.returncode:
        if check:
            stop()
        sys.exit(0)
    project = Path.cwd().resolve()
    if Path(top.stdout.strip()).resolve() != project:
        stop()
    guard = project / '.agents/hooks/git/pre-push'
    canonical = (skill / 'templates/foundation/pre-push').read_bytes()
    result = git('rev-parse', '--git-path', 'hooks/pre-push')
    if result.returncode:
        stop()
    git_hook = hook = Path(result.stdout.strip()).resolve()
    husky = hook.parent.name == '_' and (hook.parent / 'h').is_file()

    def husky_dispatches():
        dispatcher = '#!/usr/bin/env sh\n. "$(dirname "$0")/h"'
        helper = (git_hook.parent / 'h').read_text()
        return (git_hook.is_file() and os.access(git_hook, os.X_OK)
                and git_hook.read_text().strip() == dispatcher
                and all(line in helper.splitlines() for line in (
                    'n=$(basename "$0")', 's=$(dirname "$(dirname "$0")")/$n', 'sh -e "$s" "$@"')))

    if husky:
        if not husky_dispatches():
            stop('The hook tool does not provide a lasting place for the guard.')
        hook = (git_hook.parent.parent / 'pre-push').resolve()
    elif hook.parent == project / '.husky/_':
        stop('Install Husky first so its own push hook can run the guard.')
    if hook.is_file() and re.search(r'generated|do not edit|lefthook|git[ -]lfs', hook.read_text(), re.I):
        stop('A tool recreates this push hook. The guard needs a hook that survives reinstalling that tool.')

    def active():
        if husky and not husky_dispatches():
            return False
        if not hook.is_file() or not os.access(hook, os.X_OK):
            return False
        content = hook.read_text()
        if content == canonical.decode():
            return True
        if not guard.is_file() or not os.access(guard, os.X_OK) or guard.read_bytes() != canonical:
            return False
        first, sep, rest = content.partition('\n')
        return shell_hook(content) and (rest if first.startswith('#!') else content).startswith(chain)

    if check:
        if not active():
            stop()
        sys.exit(0)
    if guard.read_bytes() != canonical:
        stop()
    guard.chmod(guard.stat().st_mode | 0o111)
    if active():
        sys.exit(0)
    current = git('config', '--get', 'core.hooksPath').stdout.strip()
    own = Path(git('rev-parse', '--git-common-dir').stdout.strip()) / 'hooks'
    others = any(p.is_file() and os.access(p, os.X_OK) and not p.name.endswith('.sample')
                 for p in own.glob('*'))
    if not current and not others:
        if git('config', '--local', 'core.hooksPath', '.agents/hooks/git').returncode:
            stop()
        hook = guard
    elif hook != guard:
        # A shared or redirected folder can affect other projects. Leave it alone.
        if project not in hook.parents:
            stop()
        content = hook.read_text() if hook.exists() else '#!/bin/sh\n'
        first, sep, rest = content.partition('\n')
        if first.startswith('#!'):
            if not shell_hook(content):
                stop()
            content = first + '\n' + chain + rest
        else:
            content = '#!/bin/sh\n' + chain + content
        hook.parent.mkdir(parents=True, exist_ok=True)
        hook.write_text(content)
        hook.chmod(hook.stat().st_mode | 0o111)
    if not active():
        stop()
except (OSError, UnicodeError, ValueError):
    stop()
PYTHON
