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
    return fingerprint({'included':included, 'pieces':[
        p for p in state['pieces'] if p['number'] in included]})


def clean(source, head):
    if (recovery.commit(source, 'HEAD') != head or
            recovery.git(source, 'status', '--porcelain').strip() or
            not recovery.tracked_matches(source, head)):
        raise ValueError('The checked copy changed; check it again.')


def same_inputs(check, files):
    """Only witnessed regular ignored outputs may have different bytes."""
    expected = check['files']
    current = files.copy()
    for name, shape in check.get('generated_outputs', {}).items():
        item = current.get(name, {})
        if ({k:v for k,v in item.items() if k != 'sha256'} != shape or
                shape.get('kind') != 'file' or name not in expected):
            return False
        current[name] = expected[name]
    return current == expected


def generated_outputs(source, before, after):
    """Observe check writes; unchanged ignored files remain actual inputs."""
    outputs = {}
    for name, item in after.items():
        old = before.get(name)
        if (item == old or item['kind'] != 'file' or
                old is not None and (old['kind'] != 'file' or old['mode'] != item['mode'])):
            continue
        if subprocess.run(['git','-C',str(source),'check-ignore','-q','--',name],
                          capture_output=True).returncode == 0:
            outputs[name] = {k:v for k,v in item.items() if k != 'sha256'}
    return outputs


def verify(args, state, record, candidate=None):
    source = Path(args.source).resolve()
    head = recovery.commit(source, 'HEAD')
    clean(source, head)
    main = Path(recovery.git(source, 'worktree', 'list', '--porcelain').decode().splitlines()[0][9:])
    links = recovery.linked_inputs(source, main)
    before = recovery.inventory(source)
    previous = record.get('verification', {})
    # A repeat of the same check may leave its established report unchanged.
    outputs = (previous.get('generated_outputs', {}).copy()
               if previous.get('passed') is True and previous.get('head') == head and
               previous.get('source') == str(source) and previous.get('links') == links and
               same_inputs(previous, before) else {})
    folder = Path(args.state).parent / 'integration-checks' / uuid.uuid4().hex
    folder.mkdir(mode=0o700, parents=True)
    # Invalidate earlier green before any command can be interrupted.
    record['verification'] = {'head':head, 'source':str(source), 'passed':False,
                              'stage':'checking', 'commands':[], 'checked_at':None,
                              'evidence':str(folder / 'result.json')}
    if candidate is not None:
        candidate['verification_evidence'] = str(folder / 'result.json')
        record['integration_candidate'] = candidate
        record['verification']['base'] = candidate['base']
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
    # Keep the complete finished inventory for failure preservation. Witnessed
    # regular ignored reports may later be rewritten by another member's check.
    evidence['files'] = recovery.inventory(source)
    outputs.update(generated_outputs(source, before, evidence['files']))
    evidence['generated_outputs'] = outputs
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
    if not same_inputs(check, recovery.inventory(source)) or check['links'] != recovery.linked_inputs(source, main):
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
    candidate = None
    if args.piece is not None:
        original = recovery.commit(source, record['start_commit'])
        run(source, 'git', 'merge-base', '--is-ancestor', original, head)
        if subprocess.run(['git','-C',str(source),'merge-base','--is-ancestor',original,expected],
                          capture_output=True).returncode:
            earlier = [p for p in state['pieces'] if p['number'] != args.piece and
                       p.get('checked_commit') == original and not p.get('recovery') and
                       p.get('state') in ('to check','merged') and
                       record.get('pull_request') is not None and
                       p.get('pull_request') == record['pull_request'] and
                       p.get('branch') == record.get('branch') == branch(source)]
            if not earlier:
                raise ValueError('A later parent part needs its earlier successful same-PR checkpoint.')
        integration = state['integration']
        proof_path = integration.get('baseline_evidence') or integration['verification']['evidence']
        proof = recovery.read(proof_path)
        if (expected != integration['checked_commit'] or proof.get('passed') is not True or
                proof.get('stage') != 'checked' or not proof.get('commands') or
                any(c['exit_code'] != 0 for c in proof['commands']) or
                recovery.git(source,'rev-parse',expected+'^{tree}') !=
                recovery.git(source,'rev-parse',proof['head']+'^{tree}')):
            raise ValueError('The integration candidate has no matching checked baseline evidence.')
        run(source, 'git', 'merge-base', '--is-ancestor', proof['head'], expected)
        prior = record.get('integration_candidate', {})
        start_evidence = (proof_path if original == expected else
                          prior.get('start_evidence') or record.get('start_evidence'))
        if not start_evidence:
            raise ValueError('The original build boundary needs its saved passing check evidence.')
        start_proof = recovery.read(start_evidence)
        if (start_proof.get('passed') is not True or start_proof.get('stage') != 'checked' or
                not start_proof.get('commands') or any(c['exit_code'] != 0 for c in start_proof['commands']) or
                recovery.git(source,'rev-parse',original+'^{tree}') !=
                recovery.git(source,'rev-parse',start_proof['head']+'^{tree}')):
            raise ValueError('The original build boundary has no matching passing check evidence.')
        run(source, 'git', 'merge-base', '--is-ancestor', start_proof['head'], original)
        candidate = {'start_commit':original, 'start_evidence':start_evidence,
                     'start_evidence_sha256':recovery.digest(Path(start_evidence).read_bytes()),
                     'base':expected, 'head':head,
                     'source':str(source), 'target':target, 'recorded_at':recovery.now(),
                     'baseline_evidence':proof_path,
                     'baseline_evidence_sha256':recovery.digest(Path(proof_path).read_bytes())}
    checked = verify(args, state, record, candidate)
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
    numbers = pending.get('pieces', [pending['piece']])
    pieces = [next(p for p in state['pieces'] if p['number'] == n) for n in numbers]
    # Confirm the whole write before changing any member's saved state.
    for piece in pieces:
        check = piece.get('verification', {})
        if (piece.get('recovery') or check.get('passed') is not True or check.get('stage') != 'checked' or
                check.get('head') != pending['head'] or check.get('base') != pending['base'] or
                check.get('evidence') != pending.get('evidence', {}).get(
                    str(piece['number']), check.get('evidence'))):
            raise ValueError('The pending membership no longer has its individual checked evidence.')
    for piece in pieces:
        if piece['number'] not in integration['included']:
            integration['included'].append(piece['number'])
        piece['state'] = 'merged'
        piece['checked_commit'] = pending['head']
        piece['integrated_commit'] = current
    integration['checked_commit'] = current
    integration['baseline_evidence'] = pieces[0]['verification']['evidence']
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
    # Membership comes from the coordinator's carried-part manifest, never an
    # inference from open siblings. The ordinary one-piece route needs no list.
    recorded = [p for p in state['pieces'] if p.get('pull_request') == args.pr]
    if any(p.get('branch') != pr['headRefName'] for p in recorded):
        raise ValueError('The recorded pull-request membership identifies a different branch.')
    numbers = piece.get('integration_members', [p['number'] for p in recorded] or [args.piece])
    if (not isinstance(numbers, list) or not numbers or args.piece not in numbers or
            any(type(n) is not int for n in numbers) or len(set(numbers)) != len(numbers)):
        raise ValueError('Record the exact completed parts carried by this pull request.')
    if recorded and set(numbers) != {p['number'] for p in recorded}:
        raise ValueError('The carried-part manifest omits or adds recorded pull-request members.')
    evidence = {}
    for number in numbers:
        member = next(p for p in state['pieces'] if p['number'] == number)
        if (member.get('recovery') or member['state'] != 'to check' or
                fresh(member, source) != head or member['verification'].get('base') != base or
                Path(member['verification']['source']).resolve() != source):
            raise ValueError('Every carried part needs its own completed check on this candidate.')
        evidence[str(number)] = member['verification']['evidence']
    pending = {'piece':args.piece,'pieces':numbers.copy(),'evidence':evidence,
               'pr':args.pr,'head':head,'base':base}
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
