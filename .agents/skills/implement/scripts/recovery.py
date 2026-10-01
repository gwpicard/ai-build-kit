#!/usr/bin/env python3
"""Keep unsuccessful work locally and check a separate base before continuation.

Only the coordinating session calls this helper. It never pushes, claims,
labels, merges or changes the failed checkout. See running-longer.md.
"""

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tarfile


def now():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def read(path):
    return json.loads(Path(path).read_text())


def save(path, value):
    path = Path(path)
    temp = path.with_name(path.name + '.pending')
    with temp.open('w') as stream:
        json.dump(value, stream, indent=2)
        stream.write('\n')
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temp, path)


def git(source, *args):
    result = subprocess.run(['git', '-C', str(source), *args], capture_output=True)
    if result.returncode:
        raise ValueError('Git could not ' + args[0] + '; work is kept.')
    return result.stdout


def commit(source, ref):
    return git(source, 'rev-parse', '--verify', ref + '^{commit}').decode().strip()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def inventory(source):
    """Include ignored work without following links or nesting other worktrees."""
    result = {}

    def unreadable(error):
        raise ValueError('A working folder could not be read; stop preservation.')

    for folder, dirs, files in os.walk(source, followlinks=False, onerror=unreadable):
        rel = Path(folder).relative_to(source)
        dirs[:] = sorted(d for d in dirs if (rel / d).as_posix() not in
                         ('.git', '.agents/runs', '.agents/worktrees', '.agents/recovery'))
        for name in sorted(files + [d for d in dirs if (Path(folder) / d).is_symlink()]):
            path = Path(folder) / name
            key = path.relative_to(source).as_posix()
            if key == '.git':
                continue
            if path.is_symlink():
                result[key] = {'kind':'link', 'target':os.readlink(path)}
            elif path.is_file():
                result[key] = {'kind':'file', 'sha256':digest(path.read_bytes()),
                               'mode':path.stat().st_mode & 0o777}
            else:
                raise ValueError('A special file cannot be preserved; stop recovery.')
    return result


def verify(source, rec):
    if commit(source, rec['retained_ref']) != rec['failed_commit']:
        raise ValueError('The retained commit does not match; stop recovery.')
    manifest = read(rec['manifest'])
    with tarfile.open(rec['archive'], 'r') as archive:
        members = {member.name:member for member in archive.getmembers()}
        if set(members) != set(manifest):
            raise ValueError('The retained files do not match their record.')
        for name, expected in manifest.items():
            member = members[name]
            if expected['kind'] == 'link':
                valid = member.issym() and member.linkname == expected['target']
            else:
                valid = (member.isfile() and member.mode == expected['mode'] and
                         digest(archive.extractfile(member).read()) == expected['sha256'])
            if not valid:
                raise ValueError('A retained file could not be verified.')
    for name in ('index_patch', 'evidence'):
        if digest(Path(rec[name]).read_bytes()) != rec[name + '_sha256']:
            raise ValueError('Retained evidence could not be verified.')


def attach(state_path, state, piece, rec):
    save(Path(rec['archive']).parent / 'recovery.json', rec)
    piece['recovery'] = rec
    # Pending recovery must still be found by older waiting/building readers.
    piece['state'] = 'building' if rec['stage'] in ('preserved', 'checking') else rec['final_state']
    if piece['state'] == 'building':
        piece['reason'] = 'Recovery unfinished; no task may use this base yet.'
    else:
        piece['reason'] = rec.get('failure_reason', 'Unsuccessful work retained for review.')
        if rec['stage'] == 'blocked':
            piece['reason'] += ' The shared baseline has not passed all checks.'
    save(state_path, state)


def preserve(args, state, piece):
    source = Path(args.source).resolve()
    main = Path(git(source, 'worktree', 'list', '--porcelain').decode().splitlines()[0][9:])
    state_path = Path(args.state).resolve()
    if not state_path.is_relative_to(main / '.agents/runs'):
        raise ValueError('Run state must stay in the main project runs folder.')
    name = state.get('run', '')
    if not re.fullmatch(r'[A-Za-z0-9_-]+', name):
        raise ValueError('The run name is not safe for a recovery folder.')
    base = commit(source, args.base)
    if not piece.get('start_commit') or base != commit(source,piece['start_commit']):
        raise ValueError('The base is not the recorded checked task boundary; stop recovery.')
    folder = main / '.agents/recovery' / (name + '-' + str(args.piece))
    if folder.is_symlink() or folder.parent.is_symlink():
        raise ValueError('A recovery folder must not be a link.')
    folder.mkdir(parents=True, exist_ok=True, mode=0o700)
    (folder.parent / '.gitignore').write_text('*\n')
    if subprocess.run(['git','-C',str(main),'check-ignore','-q',str(folder)]).returncode:
        raise ValueError('Recovery storage is not ignored by Git.')
    record = folder / 'recovery.json'
    if record.exists():
        rec = read(record)
        if rec['source'] != str(source) or rec['requested_base'] != base:
            raise ValueError('This recovery already identifies different work; stop.')
        verify(source, rec)
        attach(state_path, state, piece, rec)
        return
    head = commit(source, 'HEAD')
    # A parent base must already be an ancestor, never guessed from main.
    git(source, 'merge-base', '--is-ancestor', base, head)
    ref = 'refs/ai-build-kit/recovery/' + name + '/' + str(args.piece)
    existing = subprocess.run(['git','-C',str(source),'rev-parse','--verify',ref],
                              capture_output=True)
    if existing.returncode == 0:
        if existing.stdout.decode().strip() != head:
            raise ValueError('A previous recovery points at other work; stop.')
    else:
        git(source, 'update-ref', ref, head, '0' * len(head))
    before = inventory(source)
    index = git(source, 'diff', '--cached', '--binary', 'HEAD')
    evidence = Path(args.evidence).read_bytes()
    if not evidence:
        raise ValueError('Failed check evidence is empty; keep the checkout and stop.')
    archive_path = folder / 'files.tar'
    temp = folder / 'files.tar.pending'
    with tarfile.open(temp, 'w', dereference=False) as archive:
        for name in before:
            archive.inodes.clear()  # Keep each hard-linked file recoverable on its own.
            archive.add(source / name, arcname=name, recursive=False)
    os.replace(temp, archive_path)
    save(folder / 'manifest.json', before)
    (folder / 'index.patch').write_bytes(index)
    (folder / 'checks-before-recovery').write_bytes(evidence)
    rec = {'piece':args.piece, 'stage':'preserved', 'source':str(source),
           'retained_ref':ref, 'failed_commit':head, 'requested_base':base,
           'archive':str(archive_path), 'manifest':str(folder / 'manifest.json'),
           'index_patch':str(folder / 'index.patch'), 'index_patch_sha256':digest(index),
           'evidence':str(folder / 'checks-before-recovery'), 'evidence_sha256':digest(evidence),
           'final_state':args.final_state, 'failure_reason':piece.get('reason') or
           'Unsuccessful work retained for review.', 'preserved_at':now(), 'checks':[], 'gaps':[]}
    verify(source, rec)
    if (inventory(source) != before or commit(source, 'HEAD') != head or
            git(source, 'diff', '--cached', '--binary', 'HEAD') != index):
        raise ValueError('The failed checkout changed during preservation; stop.')
    attach(state_path, state, piece, rec)


def baseline(args, state, piece):
    rec = piece.get('recovery')
    if not rec:
        raise ValueError('Preserve work before checking a baseline.')
    source = Path(rec['source'])
    verify(source, rec)
    chosen = commit(source,args.base) if args.base else rec.get('baseline_commit',rec['requested_base'])
    if chosen != rec['requested_base']:
        successful = [item for item in state['pieces'] if item.get('checked_commit') == chosen
                      and item['number'] != args.piece and
                      (item.get('state') in ('to check','merged') or
                       (item.get('state') == 'building' and
                        item.get('reason') == "waiting for the parent's pull request"))]
        if not successful:
            raise ValueError('A later baseline has no successfully checked task checkpoint.')
        git(source,'merge-base','--is-ancestor',rec['requested_base'],chosen)
        if rec['failed_commit'] != rec['requested_base']:
            contains_failure = subprocess.run(['git','-C',str(source),'merge-base',
                                                '--is-ancestor',rec['failed_commit'],chosen])
            if contains_failure.returncode != 1:
                raise ValueError('A later baseline may contain the failed task; stop recovery.')
    if not args.check:
        raise ValueError('No existing project checks were supplied; the base is unchecked.')
    main = Path(git(source,'worktree','list','--porcelain').decode().splitlines()[0][9:])
    path = main / '.agents/worktrees' / ('recovery-' + state['run'] + '-' + str(args.piece))
    rec['baseline_worktree'] = str(path)
    rec['baseline_commit'] = chosen
    rec['stage'] = 'checking'
    rec['checks'] = []
    rec['gaps'] = args.gap or []
    attach(args.state,state,piece,rec)
    if path.is_symlink():
        raise ValueError('The baseline path is a link; stop recovery.')
    branch = 'recovery/' + state['run'] + '-' + str(args.piece)
    worktrees = Path(__file__).with_name('worktree.sh')
    opened = subprocess.run(['sh',str(worktrees),'open','--resume',path.name,branch,
                             chosen], cwd=main, capture_output=True)
    if opened.returncode:
        raise ValueError('The baseline worktree could not be opened; the failed work is kept.')
    if (commit(path,'HEAD') != chosen or
            git(path,'status','--porcelain').strip()):
        raise ValueError('The baseline differs from its identified commit; stop recovery.')
    for command in args.check:
        result = subprocess.run(command, shell=True, cwd=path,
                                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        rec['checks'].append({'command':command,'exit_code':result.returncode})
        attach(args.state,state,piece,rec)
    clean = commit(path,'HEAD') == chosen and not git(path,'status','--porcelain').strip()
    if not clean:
        rec['gaps'].append('The checks changed the baseline checkout.')
    rec['stage'] = 'checked' if clean and not rec['gaps'] and all(
        item['exit_code'] == 0 for item in rec['checks']) else 'blocked'
    rec['checked_at'] = now()
    # Keep the file inventory with the commit the checks actually saw.
    rec['baseline_files'] = inventory(path)
    attach(args.state,state,piece,rec)
    if rec['stage'] != 'checked':
        raise ValueError('The shared baseline is not verified; stop work that relies on it.')


def timestamp(value):
    parsed = dt.datetime.fromisoformat(value)
    if parsed.tzinfo is None:
        raise ValueError('Evidence needs an explicit observation time zone.')
    return parsed


def eligible(args, state, piece):
    rec = piece.get('recovery', {})
    if rec.get('stage') != 'checked':
        raise ValueError('Recovery has no checked baseline; do not claim the next task.')
    verify(Path(rec['source']),rec)
    path = Path(rec['baseline_worktree'])
    if (commit(path,'HEAD') != rec['baseline_commit'] or
            git(path,'status','--porcelain').strip() or inventory(path) != rec['baseline_files']):
        raise ValueError('The baseline changed after its checks; check it again before continuation.')
    issues, impact = read(args.issues), read(args.impact)
    for evidence in (issues, impact):
        observed = timestamp(evidence['observed_at'])
        if observed < timestamp(rec['checked_at']) or observed > timestamp(now()):
            raise ValueError('Refresh issue blockers and code impact after checking the baseline.')
    if impact['base_commit'] != rec['baseline_commit']:
        raise ValueError('Code impact was read against a different baseline.')
    items = {item['number']:item for item in issues['issues']}
    candidate = items[args.candidate]
    if candidate['state'] != 'open' or 'ready' not in candidate['labels']:
        raise ValueError('The next task is no longer ready and open.')
    reach = impact['tasks'].get(str(args.candidate), {})
    if reach.get('independent') is not True or not reach.get('reason'):
        raise ValueError('Current code impact does not establish safe continuation.')
    by_number = {item['number']:item for item in state['pieces']}
    seen = set()

    def visit(number):
        if number in seen:
            raise ValueError('Dependency cycle or unreadable blocker; do not continue.')
        seen.add(number)
        item = items[number]
        if number == args.piece:
            raise ValueError('This task depends on the unsuccessful task.')
        for blocker in item['blocked_by']:
            other = items[blocker]
            if other['state'] == 'closed':
                continue
            visit(blocker)
            saved = by_number.get(blocker, {})
            if saved.get('state') not in ('to check','merged') or saved.get('recovery'):
                raise ValueError('An open prerequisite has not completed its build.')
        seen.remove(number)

    visit(args.candidate)
    piece['recovery']['eligibility'] = {'candidate':args.candidate,'observed_at':now(),
                                       'issues':str(Path(args.issues).resolve()),
                                       'impact':str(Path(args.impact).resolve()),
                                       'reason':reach['reason']}
    attach(args.state,state,piece,rec)
    print('The next task may use the checked baseline; its normal readiness and claim steps still apply.')


def main():
    os.umask(0o077)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['preserve','baseline','eligible'])
    parser.add_argument('--state',required=True)
    parser.add_argument('--piece',required=True,type=int)
    parser.add_argument('--source')
    parser.add_argument('--base')
    parser.add_argument('--evidence')
    parser.add_argument('--final-state', choices=['parked','shaping'],default='parked')
    parser.add_argument('--check',action='append')
    parser.add_argument('--gap',action='append')
    parser.add_argument('--candidate',type=int)
    parser.add_argument('--issues')
    parser.add_argument('--impact')
    args = parser.parse_args()
    required = {'preserve':['source','base','evidence'], 'baseline':[],
                'eligible':['candidate','issues','impact']}[args.command]
    if any(getattr(args,key) is None for key in required):
        parser.error('Missing inputs for ' + args.command)
    try:
        state = read(args.state)
        piece = next(item for item in state['pieces'] if item['number'] == args.piece)
        globals()[args.command](args,state,piece)
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return 2
    except (OSError, KeyError, StopIteration, tarfile.TarError):
        # Paths and project command output can contain confidential material.
        print('Recovery could not establish safe continuation; keep its files and inspect the local record.',file=sys.stderr)
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main())
