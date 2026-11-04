#!/usr/bin/env python3
"""List and remove only Docker resources carrying the kit's run label."""
import argparse
import datetime as dt
import json
import os
import signal
import subprocess
import sys

LABEL = "ai-build-kit.run"
SCOPE = "ai-build-kit.scope"
KINDS = ("container", "network", "volume", "image")


def docker(*args):
    result = subprocess.run(["docker", *args], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError("Docker could not complete " + " ".join(args[:2]))
    return result.stdout


def inventory(scope=None):
    items = []
    for kind in KINDS:
        args = [kind, "ls", "--quiet", "--filter", "label=" + LABEL]
        if kind in ("container", "image"):
            args.append("--all")
        if scope:
            args += ["--filter", "label=" + SCOPE + "=" + scope]
        for identity in sorted(set(docker(*args).split())):
            data = json.loads(docker(kind, "inspect", identity))[0]
            labels = (data.get("Config", {}).get("Labels") if kind in ("container", "image")
                      else data.get("Labels")) or {}
            # Recheck the labels even when the daemon applied a filter.
            if not labels.get(LABEL) or (scope and labels.get(SCOPE) != scope):
                continue
            created = data.get("CreatedAt", data.get("Created", ""))
            try:
                born = dt.datetime.fromisoformat(created.replace("Z", "+00:00"))
                age = (dt.datetime.now(dt.timezone.utc) - born).total_seconds()
            except (ValueError, TypeError):
                age = None
            items.append({"kind": kind, "id": data.get("Id", data.get("Name", identity)),
                          "run": labels[LABEL], "scope": labels.get(SCOPE),
                          "created": created, "age": age})
    return items


def remove(items):
    failed = False
    for item in items:
        try:
            current = json.loads(docker(item["kind"], "inspect", item["id"]))[0]
            labels = (current.get("Config", {}).get("Labels") if item["kind"] in ("container", "image")
                      else current.get("Labels")) or {}
            if labels.get(LABEL) != item["run"] or labels.get(SCOPE) != item["scope"]:
                raise RuntimeError("Resource ownership changed")
            # Never remove associated anonymous volumes or prune shared caches.
            args = [item["kind"], "rm"]
            if item["kind"] == "container":
                args.append("--force")
            docker(*args, item["id"])
        except RuntimeError:
            print("Could not remove " + item["kind"] + ":" + item["id"], file=sys.stderr)
            failed = True
    return failed


def supervise(command, proxy=False):
    server = None
    if proxy:
        from docker_proxy import start_proxy
        server = start_proxy()
    child = None
    stopped = None
    def stop(signum, _frame):
        nonlocal stopped
        stopped = signum
        if child is not None:
            try:
                os.killpg(child.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, stop)
    try:
        child = subprocess.Popen(command, start_new_session=True)
        if stopped:
            stop(stopped, None)
        while True:
            try:
                status = child.wait(timeout=0.2)
                break
            except subprocess.TimeoutExpired:
                if stopped:
                    try:
                        child.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        os.killpg(child.pid, signal.SIGKILL)
                        child.wait()
                    break
        # A stopped shell can leave descendants in its process group.
        try:
            os.killpg(child.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        return 128 + stopped if stopped else (status if status >= 0 else 128 - status)
    finally:
        if server:
            server.shutdown()
            server.server_close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    sub.add_parser("clean")
    sweep = sub.add_parser("sweep")
    sweep.add_argument("--remove", nargs="+", metavar="KIND:ID")
    run = sub.add_parser("run")
    run.add_argument("--proxy", action="store_true")
    run.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.action == "run":
        command = args.command
        if command and command[0] == "--":
            command = command[1:]
        return supervise(command, args.proxy)
    if args.action == "clean":
        scope = os.environ.get("ABK_DOCKER_SCOPE")
        if not scope:
            raise RuntimeError("Cleanup requires this run's scope")
        return int(remove(inventory(scope)))
    old = [item for item in inventory() if item["age"] is not None and item["age"] > 86400]
    if args.remove:
        approved = set(args.remove)
        selected = [item for item in old if item["kind"] + ":" + item["id"] in approved]
        if len(selected) != len(approved):
            raise RuntimeError("The approved list changed or includes an unlabelled or recent resource; list it again")
        return int(remove(selected))
    for item in old:
        print(item["kind"] + ":" + item["id"], item["created"], "run=" + item["run"], sep="\t")
    print("Offer to remove these labelled leftovers with --remove and their listed identifiers."
          if old else "No labelled Docker leftovers older than a day.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, OSError, ValueError) as error:
        print("could not run: " + str(error), file=sys.stderr)
        sys.exit(2)
