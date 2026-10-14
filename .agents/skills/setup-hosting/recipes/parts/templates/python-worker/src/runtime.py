"""Read one pgmq job, extract its PDF text and write under the user's RLS."""

from __future__ import annotations

import io
import json
import os
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import quote

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
    return "\n".join(page.extract_text() or "" for page in PdfReader(io.BytesIO(data)).pages)


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


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path != "/health":
            self.send_error(404)
            return
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")


def poll() -> None:
    while True:
        try:
            if not consume_one():
                time.sleep(2)
        except Exception:
            # Do not print document text, tokens, connection strings or provider replies.
            time.sleep(5)


threading.Thread(target=poll, daemon=True).start()
HTTPServer(("0.0.0.0", 8000), HealthHandler).serve_forever()
