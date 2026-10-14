#!/usr/bin/env sh
# migration-pending.after-commit.sh: merge the pinning change into main, as
# Priya did on GitHub, and write what the host and the live database hold.
#
# migration-pending.sh wrote the project. This pushes `main` to the remote next
# door, cuts the pinning change on its own branch, and merges it into `main`
# the way GitHub merges a pull request. The change adds a column to the
# notices table, in a new migration. Vercel built the merge, so the live copy
# runs the latest `main`, but nobody applied the migration, so the live
# database still has only the first one.
#
# The host's state is written beside the project, so the kit never commits it.
# It holds the builds, and the Supabase project: its reference, its password,
# the migrations it has, and the one it lacks.
#
# Usage: migration-pending.after-commit.sh <project-dir>

set -eu

project=${1:?project directory}
me=migration-pending.after-commit.sh

# Only a fresh replay project: its own repository, one commit made by the
# harness, and the remote next door. Anything else, this repository included,
# is refused before a branch is made.
top=$(git -C "$project" rev-parse --show-toplevel 2>/dev/null || true)
here=$(cd "$project" 2>/dev/null && pwd -P || true)
[ -n "$top" ] && [ "$(cd "$top" && pwd -P)" = "$here" ] || {
  echo "$me: $project is not the top of its own repository" >&2
  exit 1
}
[ "$(git -C "$project" rev-list --count --all)" = "1" ] \
  && [ "$(git -C "$project" log -1 --format=%s)" = "Project before the scenario" ] || {
  echo "$me: $project has history beyond the harness's first commit, so it is not a fresh replay project" >&2
  exit 1
}
[ "$(git -C "$project" remote get-url origin 2>/dev/null || true)" = "$project.git" ] || {
  echo "$me: $project has no remote next door" >&2
  exit 1
}
[ -f "$project.secrets/db-password" ] && [ -f "$project/lib/notices.ts" ] || {
  echo "$me: $project is not the project migration-pending.sh writes" >&2
  exit 1
}
[ ! -e "$project.host.json" ] || {
  echo "$me: $project.host.json already exists" >&2
  exit 1
}

# A bare repository keeps no log of its branches unless told to. The stand-in
# host reads that log to find each push to main.
git -C "$project.git" config core.logAllRefUpdates true
git -C "$project" branch -M main
git -C "$project" push -q origin main
first=$(git -C "$project" rev-parse main)

git -C "$project" checkout -q -b pin-notices main
python3 - "$project" <<'PY'
import os, sys

project = sys.argv[1]


def edit(name, old, new):
    path = os.path.join(project, name)
    text = open(path).read()
    if text.count(old) != 1:
        sys.exit("%s: the project changed, so this edit no longer fits" % name)
    open(path, "w").write(text.replace(old, new, 1))


def write(name, text):
    with open(os.path.join(project, name), "w") as handle:
        handle.write(text.lstrip("\n"))


write("supabase/migrations/20261005090000_pinned_notices.sql", """
alter table public.notices add column pinned boolean not null default false;
""")
edit("lib/notices.ts", '''export type Notice = { title: string; body: string; endsOn: string; author: string };

// A notice shows up to and including its end date, and never after it.
export function current(notices: Notice[], today: string): Notice[] {
  return notices.filter((notice) => notice.endsOn >= today);
}''', '''export type Notice = {
  title: string;
  body: string;
  endsOn: string;
  author: string;
  pinned?: boolean;
};

// A notice shows up to and including its end date, and never after it. A
// pinned notice shows before every other one.
export function current(notices: Notice[], today: string): Notice[] {
  const showing = notices.filter((notice) => notice.endsOn >= today);
  return [...showing.filter((n) => n.pinned), ...showing.filter((n) => !n.pinned)];
}''')
edit("lib/notices.test.ts", '''test("a notice shows on its end date", () => {''', '''test("a pinned notice shows first", () => {
  const plain = notice("2026-09-09");
  const pinned = { ...notice("2026-09-09"), title: "pinned", pinned: true };
  assert.equal(current([plain, pinned], "2026-09-02")[0].title, "pinned");
});

test("a notice shows on its end date", () => {''')
edit("app/page.tsx", '''select("title, body, ends_on, author")''', '''select("title, body, ends_on, author, pinned")''')
edit("app/page.tsx", '''author: row.author }))''', '''author: row.author, pinned: row.pinned }))''')
edit("CHANGELOG.md", "\n## 2026-09-19\n", """
## 2026-10-05

A notice can be pinned, and a pinned notice shows above the others. Priya
merged it on GitHub.

## 2026-09-19
""")
PY
git -C "$project" add -A
git -C "$project" commit -q -m "Pin a notice to the top of the board"
git -C "$project" push -q origin pin-notices
git -C "$project" checkout -q main
git -C "$project" merge -q --no-ff -m "Merge pull request #1 from pin-notices" pin-notices
git -C "$project" push -q origin main
merged=$(git -C "$project" rev-parse main)

[ -z "$(git -C "$project" status --porcelain)" ] || {
  echo "$me: the project was left with uncommitted changes" >&2
  exit 1
}

python3 - "$project" "$first" "$merged" <<'PY'
import json, subprocess, sys

project, first, merged = sys.argv[1:4]
pushes = subprocess.run(["git", "--git-dir", project + ".git", "log", "-g", "--format=%H",
                         "refs/heads/main"], capture_output=True, text=True).stdout.split()
if len(pushes) != 2:
    sys.exit("migration-pending.after-commit.sh: the remote logged %d pushes to main, not 2"
             % len(pushes))


def dep(ident, commit, state, created):
    return {"id": "dpl_" + ident,
            "url": "noticeboard-%s-office-tools.vercel.app" % ident,
            "target": "production", "branch": "main", "commit": commit, "source": "git",
            "state": state, "seen": True, "created": created, "before_run": True}


state = {
    "team": "office-tools",
    "project": "noticeboard",
    "user": "priya-office",
    "production_url": "noticeboard-office.vercel.app",
    "supabase_ref": "qwmhzkpvnbxlcrtdyefa",
    "public_key": "public-anon-key-stand-in",
    "sso": "all",
    "bypass": True,
    "signup": "closed",
    "env_names": ["NEXT_PUBLIC_SUPABASE_URL", "NEXT_PUBLIC_SUPABASE_ANON_KEY",
                  "SUPABASE_SERVICE_ROLE_KEY"],
    "remote": project + ".git",
    "pushes_built": len(pushes),
    "deployments": [
        dep("6k3lidtl1", first, "ERROR", "2026-09-19T09:41:07Z"),
        dep("6ez2xstin", first, "READY", "2026-09-19T10:05:52Z"),
        dep("9pq3tvn7h", merged, "READY", "2026-10-05T14:12:40Z"),
    ],
    "alias": "dpl_9pq3tvn7h",
    "supabase": {
        "ref": "qwmhzkpvnbxlcrtdyefa",
        "password": open(project + ".secrets/db-password").read().strip(),
        "applied": ["20260917090000"],
        "pending": ["20261005090000"],
    },
}
with open(project + ".host.json", "w") as handle:
    json.dump(state, handle, indent=1)
PY
