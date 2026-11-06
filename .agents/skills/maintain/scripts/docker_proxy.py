"""A private Docker socket that labels resources created by SDK clients."""
import http.server
import json
import os
import re
import select
import socket
import socketserver
import subprocess
import tempfile
import threading
import urllib.parse
import uuid


def start_proxy():
    backend_env = os.environ.copy()
    def docker(*args):
        result = subprocess.run(["docker", *args], env=backend_env, capture_output=True, text=True)
        if result.returncode:
            raise RuntimeError("Docker resource preparation failed")
        return result.stdout
    endpoint = None if backend_env.get("DOCKER_CONTEXT") else backend_env.get("DOCKER_HOST")
    if not endpoint:
        endpoint = docker("context", "inspect", "--format", "{{.Endpoints.docker.Host}}").strip()
    if not endpoint.startswith("unix://"):
        raise RuntimeError(
            "Backup, restore and container checks require a local Docker engine reached "
            "through a Unix socket; TCP and SSH connections are not supported. "
            "Select a local Docker context for these checks, or run them on another "
            "computer with a local engine. No check was started."
        )
    labels = {"ai-build-kit.run": os.environ["CODEX_RUN_ID"],
              "ai-build-kit.scope": os.environ["ABK_DOCKER_SCOPE"]}

    def volume(name=None):
        name = name or "abk-" + uuid.uuid4().hex
        found = subprocess.run(["docker", "volume", "inspect", name], env=backend_env,
                               capture_output=True, text=True)
        if found.returncode == 0:
            held = json.loads(found.stdout)[0].get("Labels") or {}
            if any(held.get(key) != value for key, value in labels.items()):
                raise RuntimeError("A volume belongs to another run")
        else:
            docker("volume", "create", "--label", "ai-build-kit.run=" + labels["ai-build-kit.run"],
                   "--label", "ai-build-kit.scope=" + labels["ai-build-kit.scope"], name)
        return name

    class Handler(http.server.BaseHTTPRequestHandler):
        rbufsize = 0
        def log_message(self, *_args):
            pass  # Docker bodies and URLs can contain credentials.

        def forward(self):
            target = urllib.parse.urlsplit(self.path)
            route = re.sub(r"^/v[0-9.]+", "", target.path)
            body = None
            try:
                if self.command == "POST" and route in ("/containers/create", "/volumes/create", "/networks/create"):
                    if self.headers.get("Transfer-Encoding"):
                        raise RuntimeError("Chunked resource definitions are unsupported")
                    remaining = int(self.headers.get("Content-Length", 0))
                    chunks = []
                    while remaining:
                        chunk = self.rfile.read(remaining)
                        if not chunk:
                            raise RuntimeError("Incomplete resource definition")
                        chunks.append(chunk)
                        remaining -= len(chunk)
                    body = b"".join(chunks)
                    data = json.loads(body)
                    data["Labels"] = {**(data.get("Labels") or {}), **labels}
                    if route == "/containers/create":
                        host = data.setdefault("HostConfig", {})
                        mounted = set((host.get("Tmpfs") or {}).keys())
                        binds = []
                        for bind in host.get("Binds") or []:
                            parts = bind.split(":")
                            if len(parts) == 1:
                                parts = [volume(), parts[0]]
                            elif not parts[0].startswith("/"):
                                volume(parts[0])
                            mounted.add(parts[1])
                            binds.append(":".join(parts))
                        mounts = host.get("Mounts") or []
                        for mount in mounts:
                            mounted.add(mount["Target"])
                            if mount.get("Type") == "volume":
                                mount["Source"] = volume(mount.get("Source"))
                        image = json.loads(docker("image", "inspect", data["Image"]))[0]
                        targets = set((image.get("Config", {}).get("Volumes") or {}).keys())
                        targets.update((data.get("Volumes") or {}).keys())
                        for path in targets - mounted:
                            binds.append(volume() + ":" + path)
                        host["Binds"] = binds
                    body = json.dumps(data).encode()
                with socket.socket(socket.AF_UNIX) as upstream:
                    upstream.connect(endpoint.removeprefix("unix://"))
                    headers = [(key, value) for key, value in self.headers.items()
                               if key.lower() not in ("connection",) and not (body is not None and key.lower() == "content-length")]
                    upgrade = self.headers.get("Upgrade")
                    headers.append(("Connection", "Upgrade" if upgrade else "close"))
                    if body is not None:
                        headers.append(("Content-Length", str(len(body))))
                    request = f"{self.command} {self.path} HTTP/1.1\r\n"
                    request += "".join(f"{key}: {value}\r\n" for key, value in headers) + "\r\n"
                    upstream.sendall(request.encode())
                    if body is not None:
                        upstream.sendall(body)
                    # Streaming pulls, exec and hijacked attach connections remain byte streams.
                    peers = [self.connection, upstream]
                    while peers:
                        ready, _, _ = select.select(peers, [], [])
                        for source in ready:
                            payload = source.recv(65536)
                            destination = upstream if source is self.connection else self.connection
                            if not payload:
                                peers.remove(source)
                                destination.shutdown(socket.SHUT_WR)
                            else:
                                destination.sendall(payload)
            except (OSError, ValueError, RuntimeError, KeyError):
                # Do not print daemon responses, which can hold credentials.
                self.close_connection = True
            self.close_connection = True

        do_GET = do_POST = do_DELETE = do_PUT = do_HEAD = forward

    class Server(socketserver.ThreadingMixIn, socketserver.UnixStreamServer):
        daemon_threads = True
        def server_close(self):
            super().server_close()
            self.scratch.cleanup()

    scratch = tempfile.TemporaryDirectory(prefix="abk-docker-", dir="/tmp")
    server = Server(scratch.name + "/engine.sock", Handler)
    server.scratch = scratch
    os.chmod(scratch.name + "/engine.sock", 0o600)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    os.environ["DOCKER_HOST"] = "unix://" + scratch.name + "/engine.sock"
    os.environ.pop("DOCKER_CONTEXT", None)
    return server
