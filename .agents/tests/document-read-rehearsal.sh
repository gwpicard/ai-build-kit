#!/usr/bin/env sh
# document-read-rehearsal.sh: run the shipped document-claims script against a
# throwaway project whose documents name things that are gone, and things that
# are not.
#
# Each of the four kinds of stale name has to be found at its line: a file, a
# link, a command and an environment variable. Just as much, nothing true may be
# flagged: a file that exists, a command the project has, a setting the code
# reads, a file git ignores on purpose, and a document that simply says less
# than the project does. A document AGENTS.md never points at is not read at
# all. A clean project produces no output, and the script writes nothing.
#
# A visit names three findings, the cap, and records those as offered. The
# next visit leaves those three out, even once their lines move, and brings
# back the three that did not fit.
#
# The false-positive half is the one that matters most. A read that flags true
# things gets ignored, and then the stale name it also found is ignored with it.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/maintain/scripts/document-claims.py"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[ -x "$SCRIPT" ] || fail "the document-claims script is missing or not runnable"
command -v python3 >/dev/null 2>&1 || fail "python3 is needed to run this rehearsal"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PROJECT="$WORK/project"
mkdir -p "$PROJECT/src" "$PROJECT/docs"
cd "$PROJECT"

commit() {
  git -c user.name=Rehearsal -c user.email=rehearsal@example.invalid \
    commit -q -m "$1"
}

git init -q
printf '%s\n' '{"name":"shop","scripts":{"dev":"node src/index.js","test":"node --test"}}' > package.json
printf '%s\n' 'const key = process.env.SHOP_API_KEY;' > src/index.js
printf '%s\n' '.env' > .gitignore
printf '%s\n' '# Agents' '' 'Setup is in `docs/setup.md`. Read [the workflow](WORKFLOW.md) too.' > AGENTS.md
printf '%s\n' '# How this project runs' '' 'It names `gone/by/design.js`, and is the kit'"'"'s, not the project'"'"'s.' > WORKFLOW.md
printf '%s\n' '# Unlisted notes' '' 'Nothing points here, so `missing/unlisted.js` is never read.' > docs/unlisted.md
cat > docs/setup.md <<'EOF'
# Setup

Copy `.env` and set `SHOP_API_KEY`.
EOF
cat > README.md <<'EOF'
# Shop

It sells things.
EOF
git add -A
commit "A project whose documents are true"

# --- a clean project --------------------------------------------------------

status=0
out=$(python3 "$SCRIPT") || status=$?
[ -z "$out" ] || fail "a clean project should produce nothing, got: $out"
[ "$status" = 0 ] || fail "a clean project should exit 0, got $status"
echo "  ok: documents that name only real things produce nothing and exit 0"
[ -z "$(git status --porcelain)" ] || fail "the script wrote into the project"
echo "  ok: the script writes nothing"

# --- stale names, beside true ones ------------------------------------------

cat > README.md <<'EOF'
# Shop

Start it with `npm run dev`, then `npm run serve` for the preview.

Set `SHOP_API_KEY` and `PAYMENT_SECRET_KEY` before the first run.

The entry point is `src/index.js`. Deployment lives in `scripts/deploy.sh`.
See [the setup guide](docs/setup.md) and [the old notes](docs/old.md).

```sh
npm run test
```

Type `/implement` to build. The code is at `owner/shop` and `github.com/owner/shop`, the entry file is `index.js`, and releases use `release.sh`.
EOF
git add -A
commit "The README drifts"

status=0
out=$(python3 "$SCRIPT") || status=$?
printf '%s\n' "$out" | sed 's/^/    /'
[ "$status" = 1 ] || fail "findings should exit 1, got $status"

expect() {
  printf '%s\n' "$out" | grep -qF "$(printf '%s\t%s\t%s' "$1" "$2" "$3")" ||
    fail "expected $2 '$3' at $1"
  echo "  ok: the stale $2 '$3' is named at $1"
}
expect README.md:3 command 'npm run serve'
expect README.md:5 'environment variable' PAYMENT_SECRET_KEY
expect README.md:7 file scripts/deploy.sh
expect README.md:8 link docs/old.md

expect README.md:14 file release.sh

[ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = 5 ] ||
  fail "expected exactly five findings, got: $out"
echo "  ok: nothing true is flagged: a real file, command, link and setting, and an ignored .env"
echo "  ok: a slash command, a repository name and a web address are not taken for files"
echo "  ok: a bare file name kept in a folder is found there"

printf '%s\n' "$out" | grep -q 'unlisted' && fail "a document AGENTS.md never points at was read"
printf '%s\n' "$out" | grep -q 'gone/by/design' && fail "the kit's own WORKFLOW.md was read"
echo "  ok: only the README and the documents AGENTS.md points at are read"

printf '%s\n' "$out" | grep -qE '[0-9]+ *%|score|grade' && fail "a score reached the output"
echo "  ok: no score, grade or percentage"

[ -z "$(git status --porcelain)" ] || fail "the script wrote into the project"
echo "  ok: the script still writes nothing"

# --- the document changed longest ago comes first ---------------------------

printf '%s\n' 'Run `make release` to ship.' >> docs/setup.md
git add -A
commit "The setup guide drifts"
printf '%s\n' 'const extra = 1;' > src/extra.js
git add -A
commit "Later work"
printf '%s\n' '' 'Nothing else.' >> README.md
git add -A
commit "The README is touched again"
: > Makefile
git add -A
commit "A Makefile arrives with no release target"

first=$(python3 "$SCRIPT" | head -1)
case "$first" in
  docs/setup.md:*) echo "  ok: the document changed longest ago is listed first" ;;
  *) fail "expected docs/setup.md first, got: $first" ;;
esac
python3 "$SCRIPT" | grep -qF "$(printf 'docs/setup.md:4\tcommand\tmake release')" ||
  fail "a make target the Makefile does not have was not named"
echo "  ok: a make target the Makefile does not have is named"

# --- only what no visit has offered -------------------------------------------

# The visit names three of the six findings, the cap, and records those three.
all=$(python3 "$SCRIPT" || true)
[ "$(printf '%s\n' "$all" | wc -l | tr -d ' ')" = 6 ] || fail "expected six findings before the visit, got: $all"
printf 'last-light-pass: %s\n' "$(date +%Y-%m-%d)" > .ai-build-kit-maintenance
printf '%s\n' "$all" | head -3 > "$WORK/offered"
python3 "$SCRIPT" --record-offered < "$WORK/offered" > "$WORK/recorded" ||
  fail "recording what was offered failed"
[ "$(cat "$WORK/recorded")" = "$(printf 'recorded\t3')" ] || fail "expected three offers recorded, got: $(cat "$WORK/recorded")"
grep -q '^last-light-pass: ' .ai-build-kit-maintenance || fail "recording the offers lost the record's other lines"
[ "$(grep -c '^offered|document-claims|' .ai-build-kit-maintenance)" = 3 ] ||
  fail "the record does not hold one line for each finding offered"
git add -A
commit "Record the visit"

status=0
out=$(python3 "$SCRIPT" --skip-offered) || status=$?
[ "$status" = 1 ] || fail "the findings that did not fit should come back with exit 1, got $status"
[ "$out" = "$(printf '%s\n' "$all" | tail -3)" ] ||
  fail "expected exactly the three findings nobody was offered, got: $out"
echo "  ok: the names offered at the last visit are not raised again, and the three that did not fit come back"

# A new stale name near the top of each document moves every line below it.
for doc in README.md docs/setup.md; do
  { head -1 "$doc"; printf '\n%s\n' 'Backups run from `scripts/backup.sh`.'; tail -n +2 "$doc"; } > "$WORK/moved"
  mv "$WORK/moved" "$doc"
done
git add -A
commit "A new stale name after the visit"
out=$(python3 "$SCRIPT" --skip-offered || true)
printf '%s\n' "$out" | grep -qF "$(printf '\tfile\tscripts/backup.sh')" || fail "a new stale name was not raised: $out"
printf '%s\n' "$all" | head -3 > "$WORK/offered"
while IFS= read -r line; do
  document=${line%%:*}
  rest=$(printf '%s\n' "$line" | cut -f2-)
  if printf '%s\n' "$out" | grep "^$document:" | grep -qF "$rest"; then
    fail "a name offered at the last visit was raised again after its line moved: $line"
  fi
done < "$WORK/offered"
[ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = 5 ] ||
  fail "expected the three that did not fit and the new name in two documents, got: $out"
echo "  ok: a new stale name is raised, and one already offered stays left out when its line moves"

printf '%s\n' "$all" > "$WORK/offered"
python3 "$SCRIPT" --record-offered < "$WORK/offered" > /dev/null
python3 "$SCRIPT" --record-offered < "$WORK/offered" > "$WORK/recorded"
[ "$(cat "$WORK/recorded")" = "$(printf 'recorded\t0')" ] || fail "an offer recorded twice was written twice"
echo "  ok: an offer already recorded is not written twice"
git checkout -q -- .ai-build-kit-maintenance

status=0
(cd "$WORK" && python3 "$SCRIPT" >/dev/null 2>&1) || status=$?
[ "$status" = 2 ] || fail "outside a Git project it should exit 2, got $status"
echo "  ok: outside a project under Git it exits 2"

echo
echo "document-read-rehearsal.sh: stale names found at their lines, true ones left alone"
