#!/usr/bin/env python3
"""Run maintainer briefs with isolated Docker labels and a shared two-run limit."""
import argparse
import fcntl
import importlib.util
import json
import math
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
WRAPPER = ROOT / '.agents/skills/maintain/scripts/docker-run.sh'
KINDS = ('container', 'image', 'volume', 'network')
LABEL = 'ai-build-kit.run'
children = []
stopping = None


def command(*args):
    result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    if result.returncode:
        raise RuntimeError('could not run ' + ' '.join(args[:2]))
    return result.stdout


def reachable():
    return subprocess.run(['docker', 'info'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def inventory():
    found = {}
    for kind in KINDS:
        args = ['docker', kind, 'ls', '--quiet']
        if kind in ('container', 'image'):
            args.append('--all')
        for identity in set(command(*args).split()):
            data = json.loads(command('docker', kind, 'inspect', identity))[0]
            labels = (data.get('Config', {}).get('Labels') if kind in ('container', 'image') else data.get('Labels')) or {}
            found[(kind, identity)] = labels
    return found


def bytes_size(value):
    match = re.fullmatch(r'\s*([0-9]+(?:\.[0-9]+)?)\s*([KMGTPE]?i?B)\s*', value, re.I)
    if not match:
        raise RuntimeError('Docker returned an unrecognised disk size: ' + value)
    unit = match.group(2).upper()
    power = 'BKMGTPE'.index(unit[0])
    return float(match.group(1)) * (1024 if 'I' in unit else 1000) ** power


def storage(limit):
    raw = command('docker', 'system', 'df', '--format', '{{json .}}')
    print('Docker disk use:', flush=True)
    used = 0
    for line in raw.splitlines():
        row = json.loads(line)
        print('  ' + row['Type'] + ': ' + row['Size'], flush=True)
        used += bytes_size(row['Size'])
    if not raw.strip():
        raise RuntimeError('Docker returned no disk usage; no brief started')
    free = shutil.disk_usage(Path.home()).free
    print('Computer free space: %.2f GiB' % (free / 1024**3), flush=True)
    print('Docker reported total: %.2f GiB (limit %.2f GiB)' % (used / 1024**3, limit), flush=True)
    if used > limit * 1024**3:
        raise RuntimeError('Docker storage is above the limit; no brief started')


def processes():
    # Capture only for counting. Never write process arguments to the log.
    lines = command('ps', '-axww', '-o', 'pid=,ppid=,comm=,args=').splitlines()
    parents, agents = {}, set()
    for line in lines:
        fields = line.strip().split(None, 3)
        if len(fields) < 4:
            continue
        try:
            pid, parent = int(fields[0]), int(fields[1])
            args = fields[3].split()
        except (ValueError, IndexError):
            continue
        parents[pid] = parent
        executable = os.path.basename(fields[2])
        if executable == 'node' and any(os.path.basename(a) == 'codex' for a in args[1:]):
            index = next(i for i, a in enumerate(args[1:], 1) if os.path.basename(a) == 'codex')
            if 'exec' in args[index + 1:]:
                agents.add(pid)
        elif executable == 'codex' and 'exec' in args[1:]:
            agents.add(pid)
    return parents, agents


def alive(pid, parents):
    return pid in parents or pid == os.getpid()


def managed(pid, owners, parents):
    seen = set()
    while pid in parents and pid not in seen:
        if pid in owners:
            return True
        seen.add(pid)
        pid = parents[pid]
    return pid in owners


def stop(signum, _frame):
    global stopping
    stopping = signum
    for child in children:
        if child.poll() is None:
            child.send_signal(signal.SIGTERM)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--limit-gib', type=float, default=50)
    parser.add_argument('--wait-seconds', type=float, default=60)
    parser.add_argument('--poll-seconds', type=float, default=5)
    parser.add_argument('--agent', default='codex', help='agent executable; receives the brief on stdin')
    parser.add_argument('--agent-arg', action='append', default=[], help='argument for a non-default agent, repeatable')
    parser.add_argument('--model', default=os.environ.get('CODEX_MODEL'))
    parser.add_argument('--effort', default=os.environ.get('CODEX_EFFORT'))
    parser.add_argument('brief', type=Path)
    parser.add_argument('folder', type=Path)
    args = parser.parse_args()
    if not all(math.isfinite(x) and x > 0 for x in (args.limit_gib, args.wait_seconds, args.poll_seconds)):
        parser.error('limits and intervals must be positive')
    brief = args.brief.resolve(strict=True)
    folder = args.folder.resolve(strict=True)
    if not brief.is_file() or not folder.is_dir():
        parser.error('supply a brief file and a working folder')
    if not reachable():
        raise RuntimeError('Docker is not reachable at the start; nothing removed and no brief started')
    storage(args.limit_gib)
    run = 'maintainer-' + uuid.uuid4().hex
    env = os.environ.copy()
    env['CODEX_RUN_ID'] = run
    prompt = ('Docker rules for this run: label every container, image, volume and network with '
              'ai-build-kit.run=$CODEX_RUN_ID and ai-build-kit.scope=$ABK_DOCKER_SCOPE. '
              'Use the supplied COMPOSE_PROJECT_NAME. Use BuildKit with labels for every build. '
              'If BuildKit or credentials are unavailable, stop and report the failure. '
              'Never fall back to an unlabelled or legacy build. Never prune shared build cache.\n\n') + brief.read_text()
    if args.agent == 'codex':
        agent = [args.agent, 'exec']
        if args.model:
            agent += ['-m', args.model]
        if args.effort:
            agent += ['-c', 'model_reasoning_effort=' + args.effort]
        agent += ['-s', 'workspace-write', '-c', 'sandbox_workspace_write.network_access=true']
        for plugin in ('computer-use', 'unified-computer-use', 'chrome', 'browser'):
            agent += ['-c', 'plugins."' + plugin + '@openai-bundled".enabled=false']
        agent += ['-c', 'mcp_servers.node_repl.enabled=false', '-C', str(folder), '-']
    else:
        agent = [args.agent, *args.agent_arg]
    # A lock serialises admission between separate maintainer sessions. Reservations
    # cover the time before an agent process appears in ps.
    lockpath = Path(os.environ.get('ABK_AGENT_QUEUE_DIR', '/tmp')) / ('abk-agent-runs-' + str(os.getuid()))
    started = time.monotonic()
    next_notice = started + args.wait_seconds
    child = None
    with lockpath.open('a+') as lock:
        while not stopping:
            fcntl.flock(lock, fcntl.LOCK_EX)
            try:
                lock.seek(0)
                try:
                    reservations = json.loads(lock.read() or '[]')
                except (ValueError, TypeError):
                    raise RuntimeError('run reservation file is invalid; no brief started')
                parents, agents = processes()
                reservations = [p for p in reservations if isinstance(p, int) and alive(p, parents)]
                external = sum(not managed(pid, set(reservations), parents) for pid in agents)
                if len(reservations) + external < 2:
                    if not reachable():
                        raise RuntimeError('Docker is not reachable before launch; nothing removed and no brief started')
                    storage(args.limit_gib)
                    if stopping:
                        break
                    before = inventory()
                    reservations.append(os.getpid())
                    lock.seek(0); lock.truncate(); json.dump(reservations, lock); lock.flush()
                    launch = ('import os, shutil, sys; '
                              'program = shutil.which(sys.argv[3]); '
                              'program or sys.exit(127); '
                              'print("Started " + sys.argv[1] + " (run " + sys.argv[2] + ")", flush=True); '
                              'os.execv(program, sys.argv[3:])')
                    child = subprocess.Popen([str(WRAPPER), '--proxy', '--', sys.executable, '-c', launch,
                                              str(brief), run, *agent], cwd=folder,
                                             env=env, stdin=subprocess.PIPE, text=True)
                    children.append(child)
                    break
            finally:
                fcntl.flock(lock, fcntl.LOCK_UN)
            if time.monotonic() >= next_notice:
                print('Still waiting: ' + str(brief), flush=True)
                next_notice = time.monotonic() + args.wait_seconds
            time.sleep(args.poll_seconds)
        if child is None:
            return 128 + stopping
        try:
            child.communicate(prompt)
            status = child.returncode
        finally:
            fcntl.flock(lock, fcntl.LOCK_EX)
            try:
                lock.seek(0)
                reservations = json.loads(lock.read() or '[]')
                lock.seek(0); lock.truncate(); json.dump([p for p in reservations if p != os.getpid()], lock); lock.flush()
            finally:
                fcntl.flock(lock, fcntl.LOCK_UN)
    if not reachable():
        print('Docker is not reachable at the end; nothing removed by the final report. Check labelled leftovers later.', file=sys.stderr)
        return 1
    try:
        resource_file = ROOT / '.agents/skills/maintain/scripts/docker-resources.py'
        spec = importlib.util.spec_from_file_location('docker_resources', resource_file)
        resources = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(resources)
        if resources.remove([item for item in resources.inventory() if item['run'] == run]):
            print('Could not remove every resource labelled for ' + run, file=sys.stderr)
            status = 1
        after = inventory()
        print('New unlabelled resources observed during ' + run + ' (may include other concurrent work):')
        for kind, identity in sorted(after.keys() - before.keys()):
            if not after[(kind, identity)].get(LABEL):
                print('  ' + kind + ':' + identity)
    except (RuntimeError, ValueError, KeyError) as error:
        print('Could not complete the unlabelled resource report: ' + str(error), file=sys.stderr)
        return 1
    return (128 + stopping) if stopping else status


if __name__ == '__main__':
    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, stop)
    try:
        sys.exit(main())
    except (RuntimeError, OSError, ValueError, KeyError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
