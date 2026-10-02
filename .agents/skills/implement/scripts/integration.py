#!/usr/bin/env python3
"""Record checked integration and guard its final main-facing merge.

Only the coordinating session calls this helper, after the merge skill's
authorisation and independent review. It never pushes or folds documents.
"""

import argparse
import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import uuid

import recovery


def run(source, *args):
    result = subprocess.run(args, cwd=source, capture_output=True, text=True)
    if result.returncode:
        raise ValueError('The command did not finish successfully; retain its work and evidence.')
    return result.stdout.strip()


def gh(source, pr):
    return json.loads(run(source, 'gh', 'pr', 'view', str(pr), '--json',
                          'number,headRefName,baseRefName,headRefOid,state'))


def ref(source, name):
    return recovery.commit(source, 'refs/remotes/origin/' + name)


def refresh(source):
    run(source, 'git', 'fetch', '-q', 'origin')


def branch(source):
    return run(source, 'git', 'symbolic-ref', '--short', 'HEAD')


def fingerprint(value):
    return recovery.digest(json.dumps(value, sort_keys=True).encode())


def result_key(state):
    """Human review is bound to the included work and every remaining flag."""
    included = state['integration']['included']
    return fingerprint([p for p in state['pieces'] if p['number'] in included])


def clean(source, head):
    if (recovery.commit(source, 'HEAD') != head or
            recovery.git(source, 'status', '--porcelain').strip() or
            not recovery.tracked_matches(source, head)):
        raise ValueError('The checked copy changed; check it again.')


def verify(args, state, record):
    source = Path(args.source).resolve()
    head = recovery.commit(source, 'HEAD')
    clean(source, head)
    main = Path(recovery.git(source, 'worktree', 'list', '--porcelain').decode().splitlines()[0][9:])
    links = recovery.linked_inputs(source, main)
    folder = Path(args.state).parent / 'integration-checks' / uuid.uuid4().hex
    folder.mkdir(mode=0o700, parents=True)
    # Invalidate earlier green before any command can be interrupted.
    record['verification'] = {'head':head, 'source':str(source), 'passed':False,
                              'stage':'checking', 'commands':[], 'checked_at':None,
                              'evidence':str(folder / 'result.json')}
    recovery.save(args.state, state)
    evidence = record['verification']
    recovery.save(folder / 'result.json', evidence)
    for index, command in enumerate(args.check or []):
        result = subprocess.run(command, shell=True, cwd=source, capture_output=True)
        log = folder / (head + '-' + str(index) + '.log')
        log.write_bytes(result.stdout + result.stderr)
        evidence['commands'].append({'command':command, 'exit_code':result.returncode,
                                     'output':str(log)})
        recovery.save(args.state, state)
        recovery.save(folder / 'result.json', evidence)
    clean(source, head)
    evidence['stage'] = 'checked'
    evidence['passed'] = bool(evidence['commands']) and all(
        c['exit_code'] == 0 for c in evidence['commands']) and (
        links == recovery.linked_inputs(source, main))
    evidence['checked_at'] = recovery.now()
    # Checks may create ignored build outputs. Capture the finished copy, as
    # recovery does, while tracked inputs and established links stay unchanged.
    evidence['files'] = recovery.inventory(source)
    evidence['links'] = links
    recovery.save(args.state, state)
    recovery.save(folder / 'result.json', evidence)
    if not evidence['passed']:
        raise ValueError('Combined verification failed or is incomplete; use recovery before continuation.')
    return head


def fresh(record, source):
    check = record.get('verification', {})
    if check.get('passed') is not True or check.get('stage') != 'checked':
        raise ValueError('No finished passing verification covers this result.')
    head = check['head']
    clean(source, head)
    main = Path(recovery.git(source, 'worktree', 'list', '--porcelain').decode().splitlines()[0][9:])
    if check['files'] != recovery.inventory(source) or check['links'] != recovery.linked_inputs(source, main):
        raise ValueError('Verification inputs changed; check the result again.')
    return head


def green(source, pr, head):
    before = gh(source, pr)
    if before['headRefOid'] != head:
        raise ValueError('The pull request changed after verification.')
    checks = json.loads(run(source, 'gh', 'pr', 'checks', str(pr), '--json', 'name,state'))
    if not checks or any(c['state'] not in ('SUCCESS', 'PASS') for c in checks):
        raise ValueError('The pull request has no finished green check; nothing merges.')
    if gh(source, pr) != before:
        raise ValueError('The pull request changed while its checks were read.')
    return before


def init(args, state):
    if 'integration' in state:
        raise ValueError('This run already has an integration target; reconcile and reuse it.')
    source = Path(args.source).resolve()
    target = branch(source)
    expected = 'integration/' + state['run']
    if target != expected or len(expected) > 100:
        raise ValueError('Use the unique bounded integration/<run> branch named in the approved plan.')
    refresh(source)
    head = recovery.commit(source, 'HEAD')
    if ref(source, target) != head or ref(source, 'main') != head:
        raise ValueError('The new integration target must start at the current main baseline.')
    state['integration'] = {'target':target, 'source':str(source), 'checked_commit':None,
                            'included':[], 'pull_request':None, 'pending':None,
                            'human_review':None, 'final_verification':None}
    checked = verify(args, state, state['integration'])
    state['integration']['checked_commit'] = checked


def check(args, state):
    record = state['integration'] if args.piece is None else next(
        p for p in state['pieces'] if p['number'] == args.piece)
    source = Path(args.source).resolve()
    refresh(source)
    target = state['integration']['target']
    expected = ref(source, target)
    head = recovery.commit(source, 'HEAD')
    if args.piece is None:
        if branch(source) != target or head != expected:
            raise ValueError('Check the current integration branch, never an old or different copy.')
    elif subprocess.run(['git','-C',str(source),'merge-base','--is-ancestor',expected,head],
                        capture_output=True).returncode:
        raise ValueError('The feature does not contain the current integration target.')
    checked = verify(args, state, record)
    record['verification']['base'] = expected
    if args.piece is None:
        record['checked_commit'] = checked
        record['human_review'] = None
        record['final_verification'] = {'head':checked, 'main':ref(source,'main'),
                                        'result':result_key(state)}


def include(state, pending, source):
    integration = state['integration']
    pr = gh(source, pending['pr'])
    if (pr['state'] != 'MERGED' or pr['baseRefName'] != integration['target'] or
            pr['headRefOid'] != pending['head']):
        raise ValueError('The pending feature merge is not confirmed on its integration target.')
    current = ref(source, integration['target'])
    if subprocess.run(['git','-C',str(source),'merge-base','--is-ancestor',pending['head'],current],
                      capture_output=True).returncode:
        raise ValueError('Integration does not retain the checked feature history.')
    # A merge commit retains the exact checked tree only with an unchanged target.
    if recovery.git(source,'rev-parse',current+'^{tree}') != recovery.git(source,'rev-parse',pending['head']+'^{tree}'):
        integration['verification'] = {'passed':False, 'stage':'checking'}
        raise ValueError('The combined tree differs from the checked candidate; preserve it and run recovery.')
    piece = next(p for p in state['pieces'] if p['number'] == pending['piece'])
    if pending['piece'] not in integration['included']:
        integration['included'].append(pending['piece'])
    piece['state'] = 'merged'
    piece['checked_commit'] = pending['head']
    piece['integrated_commit'] = current
    integration['checked_commit'] = current
    integration['baseline_evidence'] = piece['verification']['evidence']
    integration['pending'] = None
    integration['human_review'] = None
    integration['final_verification'] = None


def merge_feature(args, state):
    integration = state['integration']
    if integration['pending']:
        raise ValueError('Reconcile the pending merge before another integration write.')
    source = Path(args.source).resolve()
    piece = next(p for p in state['pieces'] if p['number'] == args.piece)
    if piece.get('recovery') or piece['state'] != 'to check':
        raise ValueError('This piece has not completed its checked build.')
    head = fresh(piece, source)
    refresh(source)
    base = ref(source, integration['target'])
    if (integration.get('verification', {}).get('passed') is not True or
            base != integration['checked_commit'] or piece['verification']['base'] != base):
        raise ValueError('Integration moved or its shared baseline is unchecked; recheck before merging.')
    pr = green(source,args.pr,head)
    if pr['baseRefName'] != integration['target'] or pr['headRefName'] != branch(source):
        raise ValueError('Every feature integration must target the recorded integration branch.')
    pending = {'piece':args.piece,'pr':args.pr,'head':head,'base':base}
    integration['pending'] = pending
    recovery.save(args.state,state)
    run(source,'gh','pr','merge',str(args.pr),'--merge','--match-head-commit',head)
    refresh(source)
    include(state,pending,source)


def reconcile(args, state):
    integration = state['integration']
    source = Path(args.source).resolve()
    refresh(source)
    if integration.get('pull_request'):
        final_pr = gh(source, integration['pull_request'])
        consent = integration.get('final_consent', {})
        if final_pr['state'] == 'MERGED':
            if (final_pr['headRefName'] != integration['target'] or final_pr['baseRefName'] != 'main' or
                    consent.get('pr') != final_pr['number'] or consent.get('head') != final_pr['headRefOid'] or
                    consent.get('approved') is not True or not consent.get('words') or not integration.get('human_review') or
                    subprocess.run(['git','-C',str(source),'merge-base','--is-ancestor',
                                    final_pr['headRefOid'],ref(source,'main')],capture_output=True).returncode):
                raise ValueError('The final remote merge has no matching reviewed consent record; report it for review.')
            integration['final_merged'] = True
            return
    if integration['pending']:
        pending = integration['pending']
        pr = gh(source,pending['pr'])
        if pr['state'] == 'MERGED':
            include(state,pending,source)
        elif pr['state'] == 'OPEN' and ref(source,integration['target']) == pending['base']:
            integration['pending'] = None
        else:
            raise ValueError('The pending merge needs review; do not repeat an uncertain write.')
    # Reuse recorded PR and target; old green does not authorise new work.
    current = ref(source,integration['target'])
    local = recovery.commit(source,'HEAD')
    if branch(source) != integration['target']:
        raise ValueError('Resume in the recorded integration copy.')
    clean(source,local)
    run(source,'git','merge','--ff-only',current)
    check(args,state)


def final(args, state):
    integration = state['integration']
    source = integration['source']
    pr = gh(source,args.pr)
    if pr['headRefName'] != integration['target'] or pr['baseRefName'] != 'main':
        raise ValueError('The combined pull request must aim from integration to main.')
    old = integration.get('pull_request')
    if old is not None and old != args.pr:
        raise ValueError('Reuse the recorded combined pull request on resume.')
    integration['pull_request'] = args.pr


def review(args, state):
    integration = state['integration']
    fresh(integration, Path(integration['source']))
    record = recovery.read(args.record)
    verified = integration.get('final_verification')
    if (not verified or record.get('reviewed') is not True or not record.get('review_words') or
            record.get('pr') != integration['pull_request'] or record.get('head') != verified['head'] or
            record.get('base') != verified['main'] or verified['result'] != result_key(state)):
        raise ValueError('Record the person\'s review of this verified combined result and every remaining flag.')
    integration['human_review'] = {'pr':record['pr'],'head':record['head'],'base':record['base'],
                                    'words':record['review_words'],'result':verified['result']}


def merge_final(args, state):
    integration = state['integration']
    human = integration.get('human_review')
    if not human or not args.record:
        raise ValueError('Final main waits for recorded human review and a separate explicit yes.')
    consent = recovery.read(args.record)
    if (consent.get('merge_approved') is not True or not consent.get('yes_words') or consent.get('pr') != args.pr or
            consent.get('head') != human['head'] or consent.get('base') != human['base'] or
            human['pr'] != args.pr or human['result'] != result_key(state)):
        raise ValueError('Advance consent does not cover the final main merge; obtain a separate result-bound yes.')
    source = Path(integration['source'])
    head = fresh(integration,source)
    refresh(source)
    pr = green(source,args.pr,head)
    if (pr['headRefName'] != integration['target'] or pr['baseRefName'] != 'main' or
            head != human['head'] or ref(source,'main') != human['base'] or
            ref(source,integration['target']) != head or integration['pending']):
        raise ValueError('The reviewed result or main changed; verify and present it for review again.')
    if subprocess.run(['git','-C',str(source),'merge-base','--is-ancestor',human['base'],head],
                      capture_output=True).returncode:
        raise ValueError('The final result must be brought up to date with main before review.')
    integration['final_consent'] = {'pr':args.pr,'head':head,'base':human['base'],
                                    'words':consent['yes_words'],'approved':True}
    recovery.save(args.state,state)
    run(source,'gh','pr','merge',str(args.pr),'--merge','--match-head-commit',head)
    integration['final_merged'] = gh(source,args.pr)['state'] == 'MERGED'


def main():
    os.umask(0o077)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command',choices=['init','check','merge-feature','reconcile','final','review','merge-final'])
    parser.add_argument('--state',required=True)
    parser.add_argument('--source')
    parser.add_argument('--piece',type=int)
    parser.add_argument('--pr',type=int)
    parser.add_argument('--check',action='append')
    parser.add_argument('--record')
    args = parser.parse_args()
    required = {'init':['source'],'check':['source'],'merge-feature':['source','piece','pr'],
                'reconcile':['source'],'final':['pr'],'review':['record'],'merge-final':['pr']}[args.command]
    if any(getattr(args,k) is None for k in required):
        parser.error('Missing inputs for '+args.command)
    try:
        # Share recovery's lock: one coordinator owns all run-state writes.
        with Path(args.state).with_name('recovery.lock').open('a') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX)
            state = recovery.read(args.state)
            try:
                globals()[args.command.replace('-','_')](args,state)
            finally:
                recovery.save(args.state,state)
    except (ValueError,OSError,KeyError,StopIteration,RuntimeError) as error:
        print(str(error) if isinstance(error,ValueError) else
              'Integration could not confirm its records; retain work and stop affected writes.',file=sys.stderr)
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main())
