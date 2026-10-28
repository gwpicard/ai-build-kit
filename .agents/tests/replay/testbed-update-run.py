#!/usr/bin/env python3
"""Run the explicit update case and keep a report beside each retained run."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def read(path):
    return path.read_text() if path.is_file() else ''


def load(path):
    try:
        return json.loads(read(path))
    except ValueError:
        return {}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--list', action='store_true', help='print the projects without calling a model')
    parser.add_argument('--input', type=Path, default=Path.home() / 'PROJECTS/abk-testbeds')
    parser.add_argument('testbeds', nargs='*', help='folder names under --input; default: every tb-* folder')
    args = parser.parse_args()
    source = args.input.resolve()
    if not source.is_dir():
        parser.error('input folder does not exist: ' + str(source))
    names = args.testbeds or sorted(p.name for p in source.glob('tb-*') if p.is_dir())
    if not names:
        parser.error('no test beds found in ' + str(source))
    if len(names) != len(set(names)):
        parser.error('duplicate test bed')
    kit_source = Path(os.environ.get('KIT_SRC', ROOT)).resolve()
    version = os.environ.get('VERSION') or read(kit_source / '.agents/skills/maintain/VERSION').strip()
    if not re.fullmatch(r'v\d+\.\d+\.\d+', version):
        parser.error('VERSION must be a stable numbered version, newer than the founding tags')
    beds = []
    for name in names:
        if Path(name).name != name or not name.startswith('tb-'):
            parser.error('name a tb-* folder under --input: ' + name)
        project = source / name
        founding = read(source / (name + '.founding.md'))
        fields = dict(re.findall(r'^(Tag|Recipe): (.+)$', founding, re.M))
        if not (project / '.git').is_dir() or not (source / (name + '.gh.json')).is_file() or len(fields) != 2:
            parser.error('test bed lacks Git history, saved issues or founding metadata: ' + name)
        numbers = lambda v: tuple(map(int, v.lstrip('v').split('.')))
        if not re.fullmatch(r'v\d+\.\d+\.\d+', fields['Tag']) or numbers(version) <= numbers(fields['Tag']):
            parser.error('VERSION must be newer than ' + fields['Tag'])
        beds.append((name, project, fields))
    if args.list:
        for name, project, fields in beds:
            print(f"{name} | tag {fields['Tag']} | recipe {fields['Recipe']} | kit {version} | case 85 | {project}")
        return 0
    base = Path(os.environ.get('REPLAY_RESULTS', Path(os.environ.get('XDG_STATE_HOME', Path.home() / '.local/state')) / 'abk-replay/testbed-updates')).resolve()
    work_base = Path(os.environ.get('REPLAY_WORK', base)).resolve()
    for location in (base, work_base):
        if location == ROOT or ROOT in location.parents or location == source or source in location.parents:
            parser.error('run output must be outside the repository and input folder')
        location.mkdir(parents=True, exist_ok=True)
    failed = False
    for name, project, fields in beds:
        run = Path(tempfile.mkdtemp(prefix=name + '.', dir=base))
        work = run / 'work' if work_base == base else Path(tempfile.mkdtemp(prefix=name + '.', dir=work_base))
        env = dict(os.environ, KIT_SRC=str(kit_source), VERSION=version, REPEATS='1',
                   REPLAY_WORK=str(work), REPLAY_RESULTS=str(run / 'results'),
                   REPLAY_TESTBED_SOURCE=str(project), REPLAY_TESTBED_VERSION=version)
        print(f'Updating {name}; run log: {run / "run.log"}', flush=True)
        with (run / 'run.log').open('w') as log:
            status = subprocess.run(['sh', str(HERE / 'run.sh'), '85'], env=env, stdout=log, stderr=subprocess.STDOUT).returncode
        result = load(run / 'results/s85-r1.json')
        replay_project = work / 's85-r1'
        transcript = run / 'results/s85-r1.transcript'
        text = read(transcript)
        second = '/maintain Make a second visit'
        marker = text.find(second)
        # Keep every statement, so the offer is quoted as made rather than
        # reconstructed by a keyword filter that could lose its qualification.
        first_text = text[:text.rfind('### user turn', 0, marker)] if marker >= 0 else text
        second_text = text[text.rfind('### user turn', 0, marker):] if marker >= 0 else ''
        report = [f'# {name} update', '', f"Tag: {fields['Tag']}", f"Recipe: {fields['Recipe']}",
                  f'Installed kit: {version}', f'Run exit: {status}', f"Held: {result.get('held', 'unavailable')}",
                  f"State check: {result.get('state_held', 'unavailable')}", f'Transcript: {transcript}',
                  f'Project: {replay_project}', f'Date: {datetime.now(timezone.utc).isoformat()}', '',
                  'Graded verdicts (including repeated offers and live evidence):', '```json',
                  json.dumps(result, indent=2), '```']
        snapshots = []
        for phase in ('after-install', 'first-visit', 'second-visit'):
            data = load(Path(str(replay_project) + '.' + phase + '.json'))
            snapshots.append(data)
            report += ['', phase + ':', '```json', json.dumps(data or {'error': 'could not run'}, indent=2), '```']
        report += ['', 'Update offer and first visit statements, as recorded:', first_text or 'could not run',
                   '', 'Second visit statements, as recorded:', second_text or 'could not run']
        reads = result.get('verdicts', {})
        required = ('Read update offer', 'Read second visit', 'Read live evidence')
        read_held = all(reads.get(name, {}).get('verdict') == 'hit' for name in required)
        report += ['', 'Visit checks held: ' + str(read_held)]
        ok = (read_held and status == 0 and result.get('held') is True and result.get('state_held') is True
              and all(snapshots) and bool(second_text) and not result.get('error'))
        report.insert(2, 'Result: completed; inspect the graded evidence.' if ok else 'Result: FAILED or could not run; inspect the log and verdicts.')
        (run / (name + '.update.md')).write_text('\n'.join(report) + '\n')
        print(('Finished' if ok else 'FAILED or could not run') + f': {name}; report: {run / (name + ".update.md")}', flush=True)
        failed |= not ok
    return 2 if failed else 0


if __name__ == '__main__':
    raise SystemExit(main())
