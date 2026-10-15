"""Read one pgmq job, extract its PDF text and write under the user's RLS."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import quote
from pathlib import Path

import httpx
import psycopg
from pydantic import BaseModel
from pypdf import PdfReader


class Job(BaseModel):
    owner_id: str
    bucket: str
    path: str
    user_access_token: str


def extract(data: bytes) -> str:
    with tempfile.TemporaryDirectory() as directory:
        source = Path(directory) / "source.pdf"
        output = Path(directory) / "ocr.pdf"
        source.write_bytes(data)
        subprocess.run(
            ["ocrmypdf", "--skip-text", str(source), str(output)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
        )
        return "\n".join(page.extract_text() or "" for page in PdfReader(output).pages)


def consume_one() -> bool:
    with psycopg.connect(os.environ["DATABASE_URL"]) as connection:
        row = connection.execute(
            "select msg_id, message from pgmq.read(%s, %s, %s)",
            ("document_jobs", 30, 1),
        ).fetchone()
        if row is None:
            return False
        message_id, message = row
        job = Job.model_validate(message if isinstance(message, dict) else json.loads(message))

        # The service key is server-only and reads Storage. The user's access
        # token is used for the result insert, so Postgres row rules still apply.
        base = os.environ["SUPABASE_URL"].rstrip("/")
        service_key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
        object_path = "/".join(quote(part, safe="") for part in job.path.split("/"))
        file_response = httpx.get(
            f"{base}/storage/v1/object/{quote(job.bucket, safe='')}/{object_path}",
            headers={"apikey": service_key, "Authorization": f"Bearer {service_key}"},
            timeout=60,
        )
        file_response.raise_for_status()
        text = extract(file_response.content)
        result_response = httpx.post(
            f"{base}/rest/v1/document_results",
            headers={
                "apikey": os.environ["SUPABASE_ANON_KEY"],
                "Authorization": f"Bearer {job.user_access_token}",
                "Content-Type": "application/json",
                "Prefer": "return=minimal",
            },
            json={"owner_id": job.owner_id, "job_id": message_id, "text_content": text},
            timeout=60,
        )
        result_response.raise_for_status()
        connection.execute("select pgmq.delete(%s, %s)", ("document_jobs", message_id))
        return True


poll_state = {"failures": 0}
POLL_FAILURE_LIMIT = 3
poll_state_lock = threading.Lock()


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path != "/health":
            self.send_error(404)
            return
        status = health_status()
        self.send_response(status)
        self.end_headers()
        self.wfile.write(b"ok" if status == 200 else b"job processing unavailable")


def health_status() -> int:
    with poll_state_lock:
        return 200 if poll_state["failures"] < POLL_FAILURE_LIMIT else 503


def poll_once() -> bool:
    try:
        worked = consume_one()
        with poll_state_lock:
            poll_state["failures"] = 0
        return worked
    except Exception as error:
        message = str(error)
        if re.search(r"(?i)\b(?:postgres(?:ql)?|postgres)://|\b(?:host|hostaddr|dbname|user|password)=\S+", message):
            message = "[database connection details hidden]"
        message = re.sub(
            r"(?i)\b(password|token|secret|api[_-]?key|authorization)\s*([=:])\s*([^\s,;]+)",
            r"\1\2[hidden]",
            message,
        )
        print(f"document worker poll failed: {type(error).__name__}: {message}", file=sys.stderr, flush=True)
        with poll_state_lock:
            poll_state["failures"] += 1
        return False


def poll() -> None:
    while True:
        if not poll_once():
            time.sleep(5 if health_status() == 503 else 2)


def run() -> None:
    threading.Thread(target=poll, daemon=True).start()
    HTTPServer(("0.0.0.0", 8000), HealthHandler).serve_forever()


if __name__ == "__main__":
    run()
