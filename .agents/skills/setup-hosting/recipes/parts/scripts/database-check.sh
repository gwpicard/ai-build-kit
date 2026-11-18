#!/usr/bin/env sh
# Keep the workflow's disposable database labelled until its final cleanup step.
set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# Keep these settings inside the check wrapper so development keeps its full stack.
export SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io
# Exclusions alone do not skip these services' database bootstrap jobs.
export SUPABASE_REALTIME_ENABLED=false
export SUPABASE_STORAGE_ENABLED=false
case "$1" in
  stop) exec python3 "$here/docker-resources.py" clean ;;
  start)
    project=$(python3 "$here/docker-resources.py" project)
    python3 - "$project" <<'PYTHON'
from pathlib import Path
import re, sys
p = Path("supabase/config.toml")
p.write_text(re.sub(r'^project_id = .*$', 'project_id = "' + sys.argv[1] + '"', p.read_text(), flags=re.M))
PYTHON
    # Auth stays running: without it, supabase status prints no API keys and the
    # app cannot reach the REST API. Type generation runs its own postgres-meta job.
    set -- "$@" -x realtime,storage-api,imgproxy,mailpit,postgres-meta,studio,edge-runtime,logflare,vector,supavisor
    ;;
esac
# On failure or cancellation, clean even a partly started stack.
trap 'status=$?; python3 "$here/docker-resources.py" clean || status=1; exit "$status"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
python3 "$here/docker-resources.py" run --proxy -- supabase "$@"
trap - EXIT
