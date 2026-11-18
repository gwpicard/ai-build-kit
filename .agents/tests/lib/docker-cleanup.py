"""Exercise the cleanup boundary and real Docker exit paths."""
import importlib.util
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
from unittest import mock

ROOT = Path(__file__).resolve().parents[3]
TOOLS = ROOT / ".agents/skills/maintain/scripts"
spec = importlib.util.spec_from_file_location("resources", TOOLS / "docker-resources.py")
resources = importlib.util.module_from_spec(spec)
spec.loader.exec_module(resources)


def short_projects():
    common = "abk-" + "a" * 40
    names = [resources.project_name(common + suffix) for suffix in ("first", "second")]
    assert len(set(names)) == 2
    assert all(len(name) <= 40 for name in names)
    print("ok: SDK project identifiers remain unique within the length limit")


def sweep_boundary():
    # A fake daemon lets the test age resources without altering this computer's clock.
    old = "2000-01-01T00:00:00.123456789Z"
    from datetime import datetime, timezone
    recent = datetime.now(timezone.utc).isoformat()
    state = {}
    for kind in resources.KINDS:
        for name, labels, created in (("old", {resources.LABEL: "old-run"}, old),
                                      ("recent", {resources.LABEL: "new-run"}, recent),
                                      ("unlabelled", {}, old)):
            identity = kind + "-" + name
            state[identity] = {"Id": identity, "Name": identity, "Created": created,
                               "Config": {"Labels": labels}, "Labels": labels, "kind": kind}
    def daemon(kind, action, *args):
        if action == "ls":
            return "\n".join(key for key, value in state.items() if value["kind"] == kind)
        if action == "inspect":
            return json.dumps([state[args[-1]]])
        if action == "rm":
            assert state[args[-1]]["Labels"].get(resources.LABEL), "attempt to delete an unlabelled resource"
            del state[args[-1]]
            return ""
        raise AssertionError((kind, action, args))
    with mock.patch.object(resources, "docker", daemon):
        with mock.patch.object(sys, "argv", ["resources", "sweep"]):
            assert resources.main() == 0
        assert len(state) == 12, "inventory changed resources"
        for unsafe in ("container:container-unlabelled", "container:container-recent"):
            with mock.patch.object(sys, "argv", ["resources", "sweep", "--remove", unsafe]):
                try:
                    resources.main()
                    raise AssertionError("unsafe removal accepted")
                except RuntimeError:
                    pass
        approved = [kind + ":" + kind + "-old" for kind in resources.KINDS]
        with mock.patch.object(sys, "argv", ["resources", "sweep", "--remove", *approved]):
            assert resources.main() == 0
        assert len(state) == 8
        assert "container-unlabelled" in state
    print("ok: sweep preserves an unlabelled container, all unlabelled resources and recent labelled resources")


def stack_skip():
    with tempfile.TemporaryDirectory(prefix="abk-stack-skip-") as temporary:
        work = Path(temporary)
        (work / "docker").write_text('#!/bin/sh\n[ "$*" = info ] || exit 99\nexit 0\n')
        (work / "sh").write_text('#!/bin/sh\necho github-stack-route >&2\nexit 99\n')
        for name in ("docker", "sh"):
            (work / name).chmod(0o755)
        env = {**os.environ, "PATH": str(work) + os.pathsep + os.environ["PATH"],
               "ABK_RECIPE_WRAPPED": "1"}
        for github in ("false", "true"):
            result = subprocess.run(["/bin/sh", str(ROOT / ".agents/tests/recipe-ci-rehearsal.sh")],
                                    env={**env, "GITHUB_ACTIONS": github}, capture_output=True, text=True)
            if github == "false":
                assert result.returncode == 2
                assert "could not run here: heavy local stack, covered on GitHub" in result.stdout
                assert "github-stack-route" not in result.stdout
            else:
                assert result.returncode == 99
                assert "github-stack-route" in result.stderr
    print("ok: local stack skip reports could not run; GitHub still enters the stack rehearsal")


def real_paths():
    if subprocess.run(["docker", "info"], capture_output=True).returncode:
        print("could-not-run: Docker cleanup integration requires a running Docker engine")
        return 2
    # BuildKit may cache a FROM image without adding its registry tag to Docker.
    # Pull the base explicitly so the retention assertion tests an existing image.
    if subprocess.run(["docker", "image", "inspect", "postgres:17.6-alpine"], capture_output=True).returncode:
        subprocess.run(["docker", "pull", "postgres:17.6-alpine"], check=True)
    run_id = os.environ.get("CODEX_RUN_ID", "cleanup-test-" + str(os.getpid()))
    # The same wrapper is copied to the standalone template, with drift checked here.
    template = ROOT / "templates/nextjs-postgres/scripts"
    for name in ("docker-run.sh", "docker-resources.py"):
        assert (template / name).read_bytes() == (TOOLS / name).read_bytes(), name + " drifted"
    with tempfile.TemporaryDirectory(prefix="abk-cleanup-") as temporary:
        work = Path(temporary)
        (work / "Dockerfile").write_text("FROM postgres:17.6-alpine\n")
        (work / "compose.yml").write_text("""services:
  fixture:
    image: ${COMPOSE_PROJECT_NAME}-fixture
    build:
      context: .
      labels:
        ai-build-kit.run: ${CODEX_RUN_ID}
        ai-build-kit.scope: ${ABK_DOCKER_SCOPE}
    labels:
      ai-build-kit.run: ${CODEX_RUN_ID}
      ai-build-kit.scope: ${ABK_DOCKER_SCOPE}
    entrypoint: [sleep, '300']
    tmpfs: [/var/lib/postgresql/data]
    volumes: [evidence:/evidence]
volumes:
  evidence:
    labels:
      ai-build-kit.run: ${CODEX_RUN_ID}
      ai-build-kit.scope: ${ABK_DOCKER_SCOPE}
networks:
  default:
    labels:
      ai-build-kit.run: ${CODEX_RUN_ID}
      ai-build-kit.scope: ${ABK_DOCKER_SCOPE}
""")
        (work / "case.sh").write_text("""#!/bin/sh
set -eu
printf '%s' "$ABK_DOCKER_SCOPE" > scope
# Explicit down complements the wrapper's label sweep, including partial creation.
trap 'docker compose down --volumes' EXIT
trap 'exit 143' TERM
trap 'exit 130' INT
docker compose up --build -d
printf ready > ready
case "$1" in
  fail) exit 7 ;;
  stop) sleep 300 ;;
esac
""")
        env = {**os.environ, "CODEX_RUN_ID": run_id}
        for mode, sig in (("pass", None), ("fail", None), ("stop", signal.SIGTERM), ("stop", signal.SIGINT)):
            for name in ("scope", "ready"):
                (work / name).unlink(missing_ok=True)
            with (work / "log").open("w") as log:
                child = subprocess.Popen(["sh", str(template / "docker-run.sh"), "--", "sh", "case.sh", mode],
                                         cwd=work, env=env, stdout=log, stderr=log)
                try:
                    deadline = time.monotonic() + 180
                    while not (work / "ready").exists() and child.poll() is None and time.monotonic() < deadline:
                        time.sleep(0.1)
                    assert (work / "ready").exists(), (work / "log").read_text()
                    scope = (work / "scope").read_text()
                    if sig:
                        assert {x["kind"] for x in resources.inventory(scope)} == set(resources.KINDS)
                        child.send_signal(sig)
                    status = child.wait(timeout=30)
                    assert status == (128 + sig if sig else 7 if mode == "fail" else 0), (status, (work / "log").read_text())
                    assert not resources.inventory(scope), "resources survived " + mode
                    print("ok: real Compose image, container, volume and network removed after", mode, sig or "")
                finally:
                    if child.poll() is None:
                        child.terminate()
                        child.wait(timeout=30)
                    if (work / "scope").exists():
                        resources.remove(resources.inventory((work / "scope").read_text()))
        assert subprocess.run(["docker", "image", "inspect", "postgres:17.6-alpine"], capture_output=True).returncode == 0
        # Exercise the SDK socket path, including an implicit image volume and exec streams.
        (work / "sdk.sh").write_text("""#!/bin/sh
set -eu
printf '%s' "$ABK_DOCKER_SCOPE" > scope
id=$(docker run -d postgres:17.6-alpine sleep 300)
test "$(docker inspect --format '{{index .Config.Labels "ai-build-kit.scope"}}' "$id")" = "$ABK_DOCKER_SCOPE"
volume=$(docker inspect --format '{{(index .Mounts 0).Name}}' "$id")
test "$(docker volume inspect --format '{{index .Labels "ai-build-kit.scope"}}' "$volume")" = "$ABK_DOCKER_SCOPE"
docker exec "$id" sh -c 'printf sdk-stream' | grep -q sdk-stream
docker network create "$COMPOSE_PROJECT_NAME-sdk" >/dev/null
docker volume create "$COMPOSE_PROJECT_NAME-sdk" >/dev/null
""")
        result = subprocess.run(["sh", str(TOOLS / "docker-run.sh"), "--proxy", "--", "sh", "sdk.sh"],
                                env=env, cwd=work, capture_output=True, text=True, timeout=60)
        assert result.returncode == 0, result.stderr
        assert not resources.inventory((work / "scope").read_text()), "SDK-created resources survived"
        print("ok: SDK resource labels, implicit volumes, exec streams and registry base image retention")
    return 0


short_projects()
sweep_boundary()
stack_skip()
sys.exit(real_paths())
