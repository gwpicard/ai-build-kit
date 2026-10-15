# Shared part: Python document worker on Coolify

This optional part adds one container in `worker/` to the Coolify project. It reads files from Supabase Storage, takes jobs from Supabase Queues (pgmq) with plain SQL, and writes results to tables protected by row-level security. A migration creates the queue and results table.

How it works: The worker extracts text on the team's server. pypdf reads ordinary PDFs; OCRmyPDF adds text to scanned pages that have no text layer. Add Docling only when tables or page layout require it because its image is large. Pydantic models, strict pyright, ruff and pytest cover the worker. Pin every dependency exactly. The worker does not call a model. Model processing requires the notice in [fit-check's risk notice](../../../fit-check/references/risk-notice.md).
How it is checked: The queue exists in Supabase and the worker's health route answers successfully.
Script: scripts/python-worker-check.sh
Who runs it: the kit

The container template is `templates/python-worker/`. The recipe has not had a real run with this part yet.

Outcome: No real run yet (added 2026-10-15).
