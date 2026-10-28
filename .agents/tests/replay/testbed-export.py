#!/usr/bin/env python3
"""Export a held founding run without the harness's neighbouring files."""
import datetime
import json
from pathlib import Path
import shutil
import subprocess
import sys


def main():
    run, output, name, tag, recipe, number, status, replace = sys.argv[1:]
    run, output = Path(run), Path(output)
    result_path = run / 'results' / ('s%s-r1.json' % number)
    transcript = run / 'results' / ('s%s-r1.transcript' % number)
    project = run / 'work' / ('s%s-r1' % number)
    try:
        result = json.loads(result_path.read_text())
    except (OSError, ValueError):
        result = {'error': 'could not read the run result'}
    held, state = result.get('held'), result.get('state_held')
    report = ('# %s founding\n\nTag: %s\nRecipe: nextjs-supabase-on-%s\n'
              'Case: %s\nHeld: %s\nState check: %s\nRun exit: %s\n'
              'Transcript: %s\nResult: %s\nDate: %s\n' % (
                  name, tag, recipe, number, held, state, status, transcript,
                  result_path, datetime.datetime.now(datetime.timezone.utc).isoformat()))
    if result.get('error'):
        report += '\nCould not run: %s\n' % result['error']
    (run / 'founding.md').write_text(report)
    if status != '0' or held is not True or state is not True or result.get('error'):
        print('testbed: founding was not held; report: %s' % (run / 'founding.md'), file=sys.stderr)
        return 2
    if not (project / '.git').is_dir() or not (project / 'masterplan.md').is_file():
        print('testbed: the founded project is missing; report: %s' % (run / 'founding.md'), file=sys.stderr)
        return 2
    target = output / name
    note = output / (name + '.founding.md')
    if replace != 'yes' and any(p.exists() or p.is_symlink() for p in (target, note)):
        print('testbed: output exists; use --replace', file=sys.stderr)
        return 2
    staged = run / 'export'
    shutil.copytree(project, staged, symlinks=True)
    # The replay's remote resolves to its local stand-in. The exported copy
    # keeps its history but no remote that a later session could upload to.
    remotes = subprocess.check_output(['git', '-C', str(staged), 'remote'], text=True).splitlines()
    for remote in remotes:
        subprocess.run(['git', '-C', str(staged), 'remote', 'remove', remote], check=True)
    # Replacement preserves the previous project and note beside the new run.
    for old in (target, note):
        if old.exists() or old.is_symlink():
            old.rename(run / ('previous-' + old.name))
    staged.rename(target)
    note.write_text(report)
    print('Founded %s; report: %s' % (target, note))
    return 0


if __name__ == '__main__':
    sys.exit(main())
