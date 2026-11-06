#!/usr/bin/env sh
# docker-proxy.sh: prove remote contexts refuse before starting checks and local context selection matches Docker.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
python3 - "$ROOT" <<'PY'
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
from unittest import mock

path = Path(sys.argv[1]) / '.agents/skills/maintain/scripts/docker_proxy.py'
spec = importlib.util.spec_from_file_location('docker_proxy', path)
proxy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(proxy)
base = {'CODEX_RUN_ID': 'proxy-test', 'ABK_DOCKER_SCOPE': 'scope'}
for endpoint in ('tcp://example.invalid:2376', 'ssh://example.invalid'):
    for selection in ({'DOCKER_HOST': endpoint}, {'DOCKER_CONTEXT': 'remote'},
                      {'DOCKER_CONTEXT': 'remote', 'DOCKER_HOST': 'unix:///ignored.sock'}):
        with mock.patch.dict(os.environ, {**base, **selection}, clear=True), \
             mock.patch.object(proxy.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, endpoint)) as run, \
             mock.patch.object(proxy.tempfile, 'TemporaryDirectory') as scratch:
            try:
                proxy.start_proxy()
                raise AssertionError('remote connection accepted')
            except RuntimeError as error:
                message = str(error)
                assert 'Backup, restore and container checks' in message
                assert 'local Docker context' in message
                assert 'No check was started' in message
                assert endpoint not in message, 'endpoint details leaked'
            scratch.assert_not_called()
            if selection.get('DOCKER_CONTEXT'):
                assert run.call_args.args[0] == ['docker', 'context', 'inspect', '--format', '{{.Endpoints.docker.Host}}']
            else:
                run.assert_not_called()

for selection in ({'DOCKER_HOST': 'unix:///test.sock'}, {'DOCKER_CONTEXT': 'local'},
                  {'DOCKER_CONTEXT': 'local', 'DOCKER_HOST': 'tcp://ignored.invalid:2376'}):
    with mock.patch.dict(os.environ, {**base, **selection}, clear=True), \
         mock.patch.object(proxy.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, 'unix:///test.sock')):
        server = proxy.start_proxy()
        try:
            assert os.environ['DOCKER_HOST'].startswith('unix:///tmp/abk-docker-')
            assert 'DOCKER_CONTEXT' not in os.environ
        finally:
            server.shutdown()
            server.server_close()
print('PASS: TCP and SSH refusal, context precedence and local Unix socket setup')
PY
