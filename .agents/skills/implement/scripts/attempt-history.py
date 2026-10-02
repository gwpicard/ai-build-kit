#!/usr/bin/env python3
"""Keep reviewed attempt summaries pending until the original issue verifies them.

Only the coordinating session publishes. This helper records locations supplied
by recovery; it never preserves, resets or checks failed work itself.
"""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

START = '<!-- attempt-history -->'
END = '<!-- /attempt-history -->'
MARK = re.compile(r'<!-- attempt:([A-Za-z0-9_-]+) -->$')


def read_json(path):
    return json.loads(path.read_text())


def save(path, value):
    temporary = path.with_suffix('.pending')
    with temporary.open('w') as stream:
        json.dump(value, stream, indent=2)
        stream.write('\n')
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


def sha(line):
    return hashlib.sha256(line.encode()).hexdigest()


def safe_text(value):
    if (not isinstance(value, str) or not value.strip() or len(value) > 500
            or any(ord(c) < 32 or c in '<>`' for c in value)):
        raise ValueError('Use concise plain text without secrets, markup or transcripts.')
    return value


def section(body):
    if not body.count(START) and not body.count(END):
        return []
    if body.count(START) != 1 or body.count(END) != 1 or body.index(END) < body.index(START):
        raise ValueError('The issue has an ambiguous attempt section; keep publication pending.')
    content = body.split(START,1)[1].split(END,1)[0]
    lines = [line for line in content.splitlines() if line.strip()]
    if not lines or lines[0] != '## Attempt history':
        raise ValueError('The attempt section cannot be read; keep publication pending.')
    result = lines[1:]
    if any(not MARK.search(line) or not line.startswith('- ') for line in result):
        raise ValueError('An attempt has no stable identity; keep publication pending.')
    combine([], result)
    return result


def combine(old, new):
    lines = list(old)
    known = {}
    for line in old + new:
        identity = MARK.search(line).group(1)
        if identity in known and known[identity] != line:
            raise ValueError('An attempt identity has conflicting text; keep publication pending.')
        known[identity] = line
    for line in new:
        if line not in lines:
            lines.append(line)
    return lines


def render(body, lines):
    block = START + '\n## Attempt history\n\n' + '\n'.join(lines) + '\n' + END
    if START in body:
        before, rest = body.split(START,1)
        return before + block + rest.split(END,1)[1]
    return body + ('\n' if body.endswith('\n') else '\n\n') + block + '\n'


def remote(issue, project):
    result = subprocess.run(['gh','issue','view',issue,'--json','body,url'],
                            cwd=project,capture_output=True,text=True,timeout=60)
    if result.returncode:
        raise ValueError('The issue could not be read; local publication remains pending.')
    value = json.loads(result.stdout)
    if value['url'] != issue or not isinstance(value['body'],str):
        raise ValueError('GitHub identified another issue; stop publication.')
    section(value['body'])
    return value['body']


def pending(folder):
    paths = list(folder.glob('*.json'))
    if any(path.is_symlink() for path in paths):
        raise ValueError('An attempt record must not be a link.')
    records = [(path, read_json(path)) for path in paths]
    return sorted(records,key=lambda item:(item[1]['order'],item[0].name))


def incomplete(folder):
    return sorted(path for path in folder.glob('*.pending')
                  if not path.with_suffix('.json').exists())


def check_receipts(records, lines):
    digests = {sha(line) for line in lines}
    if any(rec['status'] == 'saved' and rec['digest'] not in digests for path,rec in records):
        raise ValueError('A previously saved attempt is missing or changed; reconcile the issue history first.')


def point(args, records):
    if not args.state:
        return
    path = Path(args.state).resolve()
    if not path.is_relative_to(args.project / '.agents/runs'):
        raise ValueError('Run state must stay in the main project runs folder.')
    state = read_json(path)
    piece = next(p for p in state['pieces'] if p['number'] == args.number)
    piece['attempt_history'] = {'issue':args.issue + '#attempt-history',
        'pending':([str(path) for path,rec in records if rec['status'] == 'pending'] +
                   [str(path) for path in incomplete(args.folder)])}
    save(path,state)


def stage(args, folder):
    if not args.reviewed:
        raise ValueError('Review the summary and locations for secrets before staging.')
    rec = read_json(Path(args.record))
    identity = rec['id']
    if not isinstance(identity,str) or not re.fullmatch(r'[A-Za-z0-9_-]+',identity):
        raise ValueError('Use the same safe run-and-attempt identity on every retry.')
    approach, result, branch, location = [safe_text(rec[key]) for key in
                                        ('approach','result','branch','location')]
    line = f'- {approach}; {result}; kept on `{branch}` at `{location}`. <!-- attempt:{identity} -->'
    path = folder / (identity + '.json')
    if path.exists():
        old = read_json(path)
        if old['digest'] != sha(line):
            raise ValueError('This identity already records a different attempt; keep both inputs.')
        return
    save(path, {'issue':args.issue,'status':'pending','line':line,
                'digest':sha(line),'order':time.time_ns(),'observed':[]})


def publish(args, folder):
    if incomplete(folder):
        raise ValueError('A local attempt record is unfinished; retry stage with its reviewed input.')
    records = pending(folder)
    todo = [(path,rec) for path,rec in records if rec['status'] == 'pending']
    if not todo:
        return
    observed = []
    for path,rec in todo:
        observed = combine(observed,rec.get('observed',[]))
    def observe(body):
        nonlocal observed
        lines = section(body)
        observed = combine(observed,lines)
        # Save every readable observation before retrying or reporting a mismatch.
        for path,rec in todo:
            rec['observed'] = observed
            save(path,rec)
        return lines

    for attempt in range(3):
        body = remote(args.issue,args.project)
        check_receipts(records,observe(body))
        lines = combine(observed,[rec['line'] for path,rec in todo])
        updated = render(body,lines)
        fresh = remote(args.issue,args.project)
        check_receipts(records,observe(fresh))
        if fresh != body:
            continue
        if updated != body:
            result = subprocess.run(['gh','issue','edit',args.issue,'--body-file','-'],
                                    cwd=args.project,input=updated,capture_output=True,text=True,timeout=60)
            if result.returncode:
                raise ValueError('The issue write is unverified; retry the same pending record.')
        verified = remote(args.issue,args.project)
        verified_lines = observe(verified)
        check_receipts(records,verified_lines)
        # Unrelated body changes are uncertain too, rather than quietly overwritten.
        if (any(line not in verified_lines for line in lines) or
                render(verified,[]) != render(body,[])):
            raise ValueError('Issue read-back did not retain the expected record; publication is pending.')
        for path,rec in todo:
            save(path,{'issue':args.issue,'status':'saved','digest':rec['digest'],'order':rec['order']})
        return
    raise ValueError('The issue kept changing; publication remains pending.')


def show(args, folder):
    failed = False
    try:
        lines = section(remote(args.issue,args.project))
        check_receipts(pending(folder),lines)
        print(args.issue + '#attempt-history')
        print('\n'.join(lines) if lines else 'No published attempts.')
    except ValueError as error:
        print(str(error))
        failed = True
    for path,rec in pending(folder):
        if rec['status'] == 'pending':
            print('Pending issue write: ' + str(path))
            print(rec['line'])
    for path in incomplete(folder):
        print('Pending local record unfinished: ' + str(path))
        failed = True
    if failed:
        raise ValueError('Read the live history before choosing another approach.')


def main():
    os.umask(0o077)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command',choices=['stage','publish','read'])
    parser.add_argument('--project',required=True,type=Path)
    parser.add_argument('--issue',required=True)
    parser.add_argument('--state')
    parser.add_argument('--record')
    parser.add_argument('--reviewed',action='store_true')
    args = parser.parse_args()
    try:
        match = re.fullmatch(r'https://github.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)/issues/([1-9][0-9]*)',args.issue)
        if not match:
            raise ValueError('Name the original GitHub issue by its full URL.')
        args.number = int(match[3])
        git = subprocess.run(['git','-C',str(args.project),'worktree','list','--porcelain'],
                             capture_output=True,text=True,check=True)
        args.project = Path(git.stdout.splitlines()[0].removeprefix('worktree ')).resolve()
        folder = args.project / '.agents/recovery/attempt-history' / ('-'.join(match.groups()))
        args.folder = folder
        for path in [folder,*list(folder.parents)[:3]]:
            if path.is_symlink():
                raise ValueError('Attempt storage must not be a link.')
        folder.mkdir(parents=True,exist_ok=True,mode=0o700)
        (folder.parents[1] / '.gitignore').write_text('*\n')
        ignored = subprocess.run(['git','-C',str(args.project),'check-ignore','-q',str(folder)])
        if ignored.returncode:
            raise ValueError('Attempt storage must be ignored by Git.')
        with (folder / 'history.lock').open('a') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX)
            try:
                if args.command == 'stage':
                    stage(args,folder)
                elif args.command == 'publish':
                    publish(args,folder)
                else:
                    show(args,folder)
            finally:
                point(args,pending(folder))
        return 0
    except (ValueError,OSError,KeyError,StopIteration,subprocess.SubprocessError) as error:
        message = str(error) if isinstance(error,ValueError) else 'Attempt history could not be verified; keep local pending files.'
        print(message,file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
