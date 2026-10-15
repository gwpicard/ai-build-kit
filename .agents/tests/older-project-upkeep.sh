#!/usr/bin/env sh
# older-project-upkeep.sh: run the shipped old-skill-pointers.py and the
# upgrade check against older projects. If this breaks, a monthly visit can
# rewrite a project's own skill pointer, break a command or link the person
# wrote, leave pointers that open nothing on a Claude-Code-only or plugin
# install, or stop offering to move a leftover plan.md whose pieces nothing
# reads.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/maintain/scripts/old-skill-pointers.py"
TEMPLATES="$ROOT/.agents/skills/setup-ai-build-kit/templates"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
passed=0
report() {
  if [ "$2" = yes ]; then
    echo "  ok: $1"; passed=$((passed + 1))
  else
    echo "FAIL: $1" >&2; exit 1
  fi
}

echo "Older-project pointer rewrite:"
for f in "$SCRIPT" "$TEMPLATES/foundation/AGENTS.md" "$TEMPLATES/masterplan.md"; do
  [ -f "$f" ] || { echo "FAIL: missing $f" >&2; exit 1; }
done

# --- the script, run --------------------------------------------------------

WORK="$work/projects"
mkdir -p "$WORK/old" "$WORK/current" "$WORK/own"

# An old project, in the form the templates once wrote.
cat > "$WORK/old/AGENTS.md" <<'EOF'
When a skill says to run another skill, load that installed skill and follow
it. If native discovery is unavailable, open `.agents/skills/<name>/SKILL.md`
directly. Skills live in `.agents/skills/`.
The remaining work lives in this project's issues, one per piece, in the shape
`.agents/skills/setup-ai-build-kit/references/pieces.md` describes.
Our own deploy notes are in `.agents/skills/deploy-notes/SKILL.md`.
EOF
cat > "$WORK/old/masterplan.md" <<'EOF'
<!-- Rewritten only by re-running the fit check, which lives at
.agents/skills/setup-ai-build-kit/references/fit-check.md. The agent reads this section
first, every session. -->
EOF
cp "$WORK/old/AGENTS.md" "$WORK/old/AGENTS.before"

found=$(python3 "$SCRIPT" "$WORK/old")
report "an old project's two pointers are both found" \
  "$([ "$(printf '%s\n' "$found" | grep -c .)" = 2 ] && echo yes || echo no)"
report "each finding names its file, line and new form" \
  "$(printf '%s\n' "$found" | grep -qF "masterplan.md:2	.agents/skills/setup-ai-build-kit/references/fit-check.md	the \`fit-check\` skill's \`SKILL.md\`" && echo yes || echo no)"
report "listing changes nothing" \
  "$(cmp -s "$WORK/old/AGENTS.md" "$WORK/old/AGENTS.before" && echo yes || echo no)"

python3 "$SCRIPT" --apply "$WORK/old" >/dev/null
report "the rewrite gives the form the templates use now" \
  "$(grep -qF "the \`records\` skill's \`references/pieces.md\` describes." "$WORK/old/AGENTS.md" && echo yes || echo no)"
report "a placeholder, the folder and the project's own skill are left alone" \
  "$(grep -qF '`.agents/skills/<name>/SKILL.md`' "$WORK/old/AGENTS.md" \
     && grep -qF 'Skills live in `.agents/skills/`.' "$WORK/old/AGENTS.md" \
     && grep -qF '`.agents/skills/deploy-notes/SKILL.md`' "$WORK/old/AGENTS.md" && echo yes || echo no)"
report "only the pointer lines changed" \
  "$([ "$(diff "$WORK/old/AGENTS.before" "$WORK/old/AGENTS.md" | grep -c '^<')" = 1 ] && echo yes || echo no)"
report "a second run finds nothing" \
  "$([ -z "$(python3 "$SCRIPT" "$WORK/old")" ] && echo yes || echo no)"

# A project founded on the earliest releases, whose pointers name the founding
# skill by its first name. The rename migration removes that folder, so these
# open nothing on any route, and they are the ones a visit most needs to find.
mkdir -p "$WORK/first"
cat > "$WORK/first/AGENTS.md" <<'EOF'
The restrictions in `.agents/skills/start/references/blocked-commands.md` always apply.
EOF
cat > "$WORK/first/masterplan.md" <<'EOF'
<!-- Rewritten only by re-running the fit check, which lives at
.agents/skills/start/references/fit-check.md. The agent reads this section
first, every session. -->
EOF
python3 "$SCRIPT" --apply "$WORK/first" >/dev/null
report "a pointer under the founding skill's first name is rewritten to today's" \
  "$(grep -qF "The restrictions in the \`setup-ai-build-kit\` skill's \`references/blocked-commands.md\` always apply." "$WORK/first/AGENTS.md" \
     && grep -qF "the \`fit-check\` skill's \`SKILL.md\`. The agent reads this section" "$WORK/first/masterplan.md" && echo yes || echo no)"

# The fix skill was folded into shape and implement, and its rules now sit in
# implement's repair reference. A pointer to its one file follows them.
mkdir -p "$WORK/repair"
printf '%s\n' 'Repairs follow `.agents/skills/fix/SKILL.md`.' > "$WORK/repair/AGENTS.md"
python3 "$SCRIPT" --apply "$WORK/repair" >/dev/null
report "a pointer to the old fix skill is rewritten to the repair reference" \
  "$(grep -qF "Repairs follow the \`repair\` skill's \`references/fixing.md\`." "$WORK/repair/AGENTS.md" && echo yes || echo no)"

# Three background skills left in the eleven-skill releases: two were renamed
# and screen-check came back. A pointer to one of their files follows it to
# its home today, in the old folder form and in the
# named form a project founded on the eleven-skill releases carries.
mkdir -p "$WORK/eleven"
printf '%s\n' 'Facts follow `.agents/skills/change-triage/references/source-check.md`.' \
  'Screens follow `.agents/skills/screen-check/SKILL.md`.' \
  'The trim follows `.agents/skills/section-builder/references/trim.md`.' \
  "Repairs follow the \`section-builder\` skill's \`references/repair.md\`." > "$WORK/eleven/AGENTS.md"
python3 "$SCRIPT" --apply "$WORK/eleven" >/dev/null
report "pointers into the three former background skills follow them" \
  "$(grep -qF "Facts follow the \`research\` skill's \`SKILL.md\`." "$WORK/eleven/AGENTS.md" \
     && grep -qF "Screens follow the \`screen-check\` skill's \`SKILL.md\`." "$WORK/eleven/AGENTS.md" \
     && grep -qF "The trim follows the \`quality-checks\` skill's \`references/trim.md\`." "$WORK/eleven/AGENTS.md" \
     && grep -qF "Repairs follow the \`repair\` skill's \`references/fixing.md\`." "$WORK/eleven/AGENTS.md" && echo yes || echo no)"
report "and a second run finds nothing there" \
  "$([ -z "$(python3 "$SCRIPT" "$WORK/eleven")" ] && echo yes || echo no)"

# Both repair files held the shaping half and the building half. A sentence
# about shaping or reproducing a fault follows shape's repair reference; any
# other follows implement's, which points at shape's first.
mkdir -p "$WORK/halves"
printf '%s\n' 'Shaping a repair follows `.agents/skills/fix/SKILL.md`.' \
  "To reproduce a fault, read the \`section-builder\` skill's \`references/repair.md\`." \
  'Building a repair follows `.agents/skills/fix/SKILL.md`.' > "$WORK/halves/AGENTS.md"
python3 "$SCRIPT" --apply "$WORK/halves" >/dev/null
report "a pointer about shaping a repair follows shape, one about building follows implement" \
  "$(grep -qF "Shaping a repair follows the \`repair\` skill's \`references/reproduce.md\`." "$WORK/halves/AGENTS.md" \
     && grep -qF "To reproduce a fault, read the \`repair\` skill's \`references/reproduce.md\`." "$WORK/halves/AGENTS.md" \
     && grep -qF "Building a repair follows the \`repair\` skill's \`references/fixing.md\`." "$WORK/halves/AGENTS.md" && echo yes || echo no)"

# A skill of the person's own under a name the kit has retired keeps its
# pointer, whether its folder is installed or the lockfile lists it under
# another source. A folder that is the kit's released copy does not count.
mkdir -p "$WORK/mine/.agents/skills/queue" "$WORK/mine/.agents/skills/section-builder"
printf -- '---\nname: queue\ndescription: Our own list of the till jobs.\n---\n' \
  > "$WORK/mine/.agents/skills/queue/SKILL.md"
kit_description=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["skills"]["section-builder"][-1])' \
  "$ROOT/.agents/skills/maintain/scripts/kit-retired-skills.json")
printf -- '---\nname: section-builder\ndescription: %s\n---\n' "$kit_description" \
  > "$WORK/mine/.agents/skills/section-builder/SKILL.md"
printf '%s\n' '{"version":1,"skills":{"change-triage":{"source":"club/own-skills"}}}' > "$WORK/mine/skills-lock.json"
printf '%s\n' 'Jobs follow `.agents/skills/queue/SKILL.md`.' \
  'Requests follow `.agents/skills/change-triage/SKILL.md`.' \
  'The trim follows `.agents/skills/section-builder/references/trim.md`.' > "$WORK/mine/AGENTS.md"
listed=$(python3 "$SCRIPT" "$WORK/mine")
python3 "$SCRIPT" --apply "$WORK/mine" >/dev/null
report "a pointer into the person's own skill under a retired name is listed and kept" \
  "$(printf '%s\n' "$listed" | grep -qF 'AGENTS.md:1	.agents/skills/queue/SKILL.md	left as written: the project has a `queue` skill of its own' \
     && printf '%s\n' "$listed" | grep -qF 'left as written: the project has a `change-triage` skill of its own' \
     && grep -qF 'Jobs follow `.agents/skills/queue/SKILL.md`.' "$WORK/mine/AGENTS.md" \
     && grep -qF 'Requests follow `.agents/skills/change-triage/SKILL.md`.' "$WORK/mine/AGENTS.md" \
     && grep -qF "The trim follows the \`quality-checks\` skill's \`references/trim.md\`." "$WORK/mine/AGENTS.md" && echo yes || echo no)"

# The queue skill folded into implement, and the sync skill's routine became
# the maintain skill's truing reference. Pointers to either follow the rules.
mkdir -p "$WORK/folded"
printf '%s\n' 'Several pieces follow `.agents/skills/queue/SKILL.md`.' \
  'Records follow `.agents/skills/sync/SKILL.md`.' \
  'Stale names follow `.agents/skills/sync/references/document-read.md`.' > "$WORK/folded/AGENTS.md"
python3 "$SCRIPT" --apply "$WORK/folded" >/dev/null
report "a pointer to the old queue skill is rewritten to implement" \
  "$(grep -qF "Several pieces follow the \`implement\` skill's \`SKILL.md\`." "$WORK/folded/AGENTS.md" && echo yes || echo no)"
report "a pointer to the old sync skill is rewritten to the truing reference" \
  "$(grep -qF "Records follow the \`maintain\` skill's \`references/truing.md\`." "$WORK/folded/AGENTS.md" && echo yes || echo no)"
report "a pointer to the old document read follows it into maintain" \
  "$(grep -qF "Stale names follow the \`quality-checks\` skill's \`references/document-read.md\`." "$WORK/folded/AGENTS.md" && echo yes || echo no)"

# The last nine-command release founded projects whose AGENTS.md names the
# handover template by skill, as the `ship` skill's. That skill is gone and
# handovers moved to maintain, so the named pointer opens nothing until it
# follows them. The same file by its old folder goes to the same place. A named
# pointer under a current name, one in a code block, and one to a file no skill
# has are left alone.
mkdir -p "$WORK/six"
cat > "$WORK/six/AGENTS.md" <<'EOF'
by install route. A pointer such as the `ship` skill's `templates/handover.md`
names a file there. Recipes follow the `ship` skill's `templates/recipe.md`.
Hand over with `.agents/skills/ship/templates/handover.md` when you leave.
Already current: the `maintain` skill's `templates/handover.md`.
```
the `sync` skill's `SKILL.md`
```
Gone: the `queue` skill's `references/no-such-file.md` here.
EOF
sed -n '4,8p' "$WORK/six/AGENTS.md" > "$WORK/six/tail-before"
six=$(python3 "$SCRIPT" "$WORK/six")
python3 "$SCRIPT" --apply "$WORK/six" >/dev/null
report "a named pointer to the ship handover template follows it to maintain" \
  "$(grep -qF "A pointer such as the \`maintain\` skill's \`templates/handover.md\`" "$WORK/six/AGENTS.md" && echo yes || echo no)"
report "a named pointer to another ship file goes to setup-hosting" \
  "$(grep -qF "Recipes follow the \`setup-hosting\` skill's \`templates/recipe.md\`." "$WORK/six/AGENTS.md" && echo yes || echo no)"
report "the handover template by its old folder goes to maintain too" \
  "$(grep -qF "Hand over with the \`maintain\` skill's \`templates/handover.md\` when you leave." "$WORK/six/AGENTS.md" && echo yes || echo no)"
report "a current named pointer, one in a code block, and one to a missing file are left as they were" \
  "$(sed -n '4,8p' "$WORK/six/AGENTS.md" | cmp -s - "$WORK/six/tail-before" \
     && [ "$(printf '%s\n' "$six" | grep -c 'left as written: ')" = 2 ] && echo yes || echo no)"
report "a second run on that project finds nothing more to rewrite" \
  "$([ -z "$(python3 "$SCRIPT" "$WORK/six" | grep -v 'left as written: ')" ] && echo yes || echo no)"

# Lines where a rewrite would break what the person wrote. Each is listed with
# its reason and left exactly as it was, and a line with two standalone
# pointers has both rewritten.
mkdir -p "$WORK/awkward"
cat > "$WORK/awkward/AGENTS.md" <<'EOF'
Run `python3 .agents/skills/maintain/scripts/old-skill-pointers.py` monthly.
See [pieces](.agents/skills/setup-ai-build-kit/references/pieces.md) for more.
Folder `.agents/skills/setup-hosting/recipes/` holds recipes.
Anchor .agents/skills/setup-ai-build-kit/references/pieces.md#shape here.
Prefixed ./.agents/skills/setup-ai-build-kit/references/pieces.md here.
Gone `.agents/skills/setup-ai-build-kit/references/no-such-file.md` here.
Two: `.agents/skills/ship/templates/recipe.md` and `.agents/skills/start/references/pieces.md`.
EOF
head -6 "$WORK/awkward/AGENTS.md" > "$WORK/awkward/untouched"
listed_awkward=$(python3 "$SCRIPT" "$WORK/awkward")
python3 "$SCRIPT" --apply "$WORK/awkward" >/dev/null
report "a pointer inside a command, a link, a longer path, or to a missing file is listed with its reason" \
  "$([ "$(printf '%s\n' "$listed_awkward" | grep -c 'left as written: ')" = 6 ] && echo yes || echo no)"
report "and each of those lines is left exactly as it was" \
  "$(head -6 "$WORK/awkward/AGENTS.md" | cmp -s - "$WORK/awkward/untouched" && echo yes || echo no)"
report "two standalone pointers on one line are both rewritten" \
  "$(grep -qF "Two: the \`setup-hosting\` skill's \`templates/recipe.md\` and the \`records\` skill's \`references/pieces.md\`." "$WORK/awkward/AGENTS.md" && echo yes || echo no)"
report "after the rewrite, nothing is left to rewrite" \
  "$([ -z "$(python3 "$SCRIPT" "$WORK/awkward" | grep -v 'left as written: ')" ] && echo yes || echo no)"

# A second review found three more ways to break a line: a command in a fenced
# or indented code block has no backticks on its own line, a pointer between
# double backticks sat in a span the first check did not see, and a file with
# Windows line endings came back with every line changed. Each of those lines
# stays exactly as it was, and the rewrite keeps the file's line endings.
mkdir -p "$WORK/blocks"
cat > "$WORK/blocks/AGENTS.md" <<'EOF'
```sh
cat .agents/skills/setup-ai-build-kit/references/pieces.md
```
    cat .agents/skills/maintain/templates/handover.md
Double `` .agents/skills/setup-ai-build-kit/references/pieces.md `` here.
Folder .agents/skills/setup-hosting/recipes here.
Read the `.agents/skills/setup-ai-build-kit/references/fit-check.md` file.
EOF
head -6 "$WORK/blocks/AGENTS.md" > "$WORK/blocks/untouched"
blocks_listed=$(python3 "$SCRIPT" "$WORK/blocks")
python3 "$SCRIPT" --apply "$WORK/blocks" >/dev/null
report "a pointer in a code block, in double backticks, or naming a folder is listed with its reason" \
  "$(printf '%s\n' "$blocks_listed" | grep -q 'left as written: it sits inside a code block' \
     && [ "$(printf '%s\n' "$blocks_listed" | grep -c 'left as written: it sits inside a code block')" = 2 ] \
     && printf '%s\n' "$blocks_listed" | grep -q 'left as written: it sits inside a code span in double backticks' \
     && printf '%s\n' "$blocks_listed" | grep -q 'left as written: it names a folder, not a file' && echo yes || echo no)"
report "and those lines are left exactly as they were" \
  "$(head -6 "$WORK/blocks/AGENTS.md" | cmp -s - "$WORK/blocks/untouched" && echo yes || echo no)"
report "a sentence that already says the gets no second one" \
  "$(grep -qF "Read the \`fit-check\` skill's \`SKILL.md\` file." "$WORK/blocks/AGENTS.md" && echo yes || echo no)"

# A third review found a fence of four backticks closed by the first line of
# three, which is how a code block is shown inside a code block. The command
# inside was rewritten, and every line after it read the wrong way round. A
# fence closes only on a run of the same mark at least as long as its opener.
mkdir -p "$WORK/nested"
cat > "$WORK/nested/AGENTS.md" <<'EOF'
````markdown
```
cat .agents/skills/shape/SKILL.md
```
````
After `.agents/skills/setup-ai-build-kit/references/pieces.md` here.
~~~
```
cat .agents/skills/shape/SKILL.md
~~~
Then `.agents/skills/setup-ai-build-kit/references/fit-check.md` too.
EOF
nested=$(python3 "$SCRIPT" "$WORK/nested")
report "a block shown inside a longer fence stays a code block, and prose after it is read as prose" \
  "$([ "$(printf '%s\n' "$nested" | grep -c 'left as written: it sits inside a code block')" = 2 ] \
     && [ "$(printf '%s\n' "$nested" | grep -c "skill's \`")" = 2 ] && echo yes || echo no)"

mkdir -p "$WORK/crlf" "$WORK/unreadable"
printf 'line one\r\nSee `.agents/skills/setup-ai-build-kit/references/pieces.md`.\r\nlast\r\n' > "$WORK/crlf/AGENTS.md"
printf "line one\r\nSee the \`records\` skill's \`references/pieces.md\`.\r\nlast\r\n" > "$WORK/crlf/expected"
python3 "$SCRIPT" --apply "$WORK/crlf" >/dev/null
report "a file with Windows line endings keeps them, and only the pointer changes" \
  "$(cmp -s "$WORK/crlf/AGENTS.md" "$WORK/crlf/expected" && echo yes || echo no)"
printf 'ok\n\377\376 not text\n' > "$WORK/unreadable/AGENTS.md"
unreadable=$(python3 "$SCRIPT" "$WORK/unreadable" 2>&1) && code=0 || code=$?
report "a file that is not readable text gets one line, not a crash" \
  "$([ "$code" = 0 ] && printf '%s\n' "$unreadable" | grep -q 'left as written: it is not readable text' && echo yes || echo no)"

# A project founded today, from the shipped templates, gets nothing.
cp "$TEMPLATES/foundation/AGENTS.md" "$WORK/current/AGENTS.md"
cp "$TEMPLATES/masterplan.md" "$WORK/current/masterplan.md"
report "a project founded from today's templates gets no offer" \
  "$([ -z "$(python3 "$SCRIPT" "$WORK/current")" ] && echo yes || echo no)"

# A project whose only matching folder is its own skill gets nothing either.
printf '%s\n' 'See `.agents/skills/deploy-notes/SKILL.md`.' > "$WORK/own/AGENTS.md"
report "a project's own skill is never offered" \
  "$([ -z "$(python3 "$SCRIPT" "$WORK/own")" ] && echo yes || echo no)"

# A project's own document, or a skill of its own, naming a kit file that has
# moved is reported with the new home, and never rewritten. The kit's own skill
# folders are not read.
mkdir -p "$WORK/owndocs/docs" "$WORK/owndocs/.agents/skills/our-release" "$WORK/owndocs/.agents/skills/implement/references"
line="Pieces follow the \`setup-ai-build-kit\` skill's \`references/pieces.md\`."
printf '%s\n' "$line" > "$WORK/owndocs/docs/notes.md"
printf '%s\n' "$line" > "$WORK/owndocs/.agents/skills/our-release/SKILL.md"
printf '%s\n' "$line" > "$WORK/owndocs/.agents/skills/implement/references/old.md"
cp "$WORK/owndocs/docs/notes.md" "$WORK/owndocs-before"
owndocs=$(python3 "$SCRIPT" "$WORK/owndocs")
python3 "$SCRIPT" --apply "$WORK/owndocs" >/dev/null
report "a pointer to a moved kit file in a document of the project's own is reported with its new home, and left" \
  "$(printf '%s\n' "$owndocs" | grep -qF "docs/notes.md:1	\`setup-ai-build-kit\` skill's \`references/pieces.md\`	left as written: it is in a document of your own; the kit's file is now the \`records\` skill's \`references/pieces.md\`" \
     && printf '%s\n' "$owndocs" | grep -qF ".agents/skills/our-release/SKILL.md:1" \
     && ! printf '%s\n' "$owndocs" | grep -qF ".agents/skills/implement/" \
     && cmp -s "$WORK/owndocs/docs/notes.md" "$WORK/owndocs-before" && echo yes || echo no)"

# The script's list of the kit's skills has to be the kit's skills, or a
# renamed or added skill's pointers would be missed without a word.
listed=$(PYTHONDONTWRITEBYTECODE=1 python3 - "$SCRIPT" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("p", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
print("\n".join(sorted(module.KIT_SKILLS)))
PY
)
shipped=$(ls "$ROOT/.agents/skills" | sort)
report "the script names exactly the kit's skills" \
  "$([ "$listed" = "$shipped" ] && echo yes || echo no)"

# --- a leftover plan.md, on every monthly visit -------------------------------

# A project founded without GitHub kept its pieces in plan.md, which nothing
# reads. Every monthly visit names it until it moves, and a no is never
# recorded, so the offer comes back.
CHECK="$ROOT/.agents/skills/maintain/scripts/upgrade-check.py"
P="$work/planfile"
mkdir -p "$P"
cp "$TEMPLATES/masterplan.md" "$P/masterplan.md"
printf '%s\n' '| Piece | Done when |' '|---|---|' '| Sign-in | People can sign in |' > "$P/plan.md"
monthly=$(python3 "$CHECK" --monthly "$P") || true
report "a monthly visit names a leftover plan.md and says its pieces wait" \
  "$(printf '%s\n' "$monthly" | grep -qx 'planfile	plan.md' \
     && printf '%s\n' "$monthly" | grep '^say	planfile	' | grep -q 'not picked up until' && echo yes || echo no)"
visit=$(python3 "$CHECK" "$P") || true
report "a visit that is not monthly leaves it to the monthly part" \
  "$(printf '%s\n' "$visit" | grep -q 'planfile' && echo no || echo yes)"
python3 "$CHECK" --decline planfile "$P" >/dev/null 2>&1 && code=0 || code=$?
again=$(python3 "$CHECK" --monthly "$P") || true
report "a no is not recorded, so the next monthly visit offers it again" \
  "$([ "$code" = 2 ] && [ ! -e "$P/.ai-build-kit-maintenance" ] \
     && printf '%s\n' "$again" | grep -qx 'planfile	plan.md' && echo yes || echo no)"
rm "$P/plan.md"
moved=$(python3 "$CHECK" --monthly "$P") || true
report "once it has moved, nothing is said" \
  "$(printf '%s\n' "$moved" | grep -q 'planfile' && echo no || echo yes)"

# --- a recipe named by its old file ---------------------------------------------

# A project founded before recipes became folders names its recipe as a file,
# with .md. The kit reads that as the folder of the same name, so nothing waits
# on it, but the record should say the folder. The line changes only on a yes,
# which is the apply, and nothing else in AGENTS.md moves. The check-up
# record's menu lines are the kit's own bookkeeping, and follow along.
P="$work/old-recipe"
mkdir -p "$P"
cp "$TEMPLATES/masterplan.md" "$P/masterplan.md"
printf '# AGENTS.md\r\n\r\n## Stack\r\n\r\n- `Recipe: nextjs-supabase-on-vercel.md`\r\nRun: `npm run dev`\r\n' > "$P/AGENTS.md"
printf 'founded|2026-01-02\nfounding-menu|2026-01-02|nextjs-supabase-on-coolify.md nextjs-supabase-on-vercel.md\nrecipe-move-declined|2026-02-02|nextjs-supabase-on-vercel.md|nextjs-supabase-on-vercel.md\n' > "$P/.ai-build-kit-maintenance"
cp "$P/AGENTS.md" "$work/agents-before"
found=$(python3 "$CHECK" "$P") || true
report "an AGENTS.md naming its recipe as a file is found, with what the line would say" \
  "$(printf '%s\n' "$found" | grep -qx 'recipe	AGENTS.md:5	nextjs-supabase-on-vercel' \
     && printf '%s\n' "$found" | grep '^say	recipe	' | grep -q 'Recipe: nextjs-supabase-on-vercel\. ' && echo yes || echo no)"
report "finding it changes nothing" "$(cmp -s "$P/AGENTS.md" "$work/agents-before" && echo yes || echo no)"
python3 "$CHECK" --apply recipe "$P" >/dev/null
report "on a yes the line names the folder, and the rest of AGENTS.md is byte for byte the same" \
  "$(printf '# AGENTS.md\r\n\r\n## Stack\r\n\r\n- `Recipe: nextjs-supabase-on-vercel`\r\nRun: `npm run dev`\r\n' | cmp -s - "$P/AGENTS.md" && echo yes || echo no)"
report "the check-up record's menu lines name folders too, and its other lines are kept" \
  "$(grep -qx 'founding-menu|2026-01-02|nextjs-supabase-on-coolify,nextjs-supabase-on-vercel' "$P/.ai-build-kit-maintenance" \
     && grep -qx 'recipe-move-declined|2026-02-02|nextjs-supabase-on-vercel|nextjs-supabase-on-vercel' "$P/.ai-build-kit-maintenance" \
     && grep -qx 'founded|2026-01-02' "$P/.ai-build-kit-maintenance" && echo yes || echo no)"
again=$(python3 "$CHECK" "$P") || true
report "once it names the folder, nothing is found" \
  "$(printf '%s\n' "$again" | grep -q '^recipe	' && echo no || echo yes)"
printf '%s\n' '# AGENTS.md' '' 'Recipe: a-recipe-the-kit-never-had.md' > "$P/AGENTS.md"
gone=$(python3 "$CHECK" "$P") || true
report "a recipe file the kit has no folder for is left to the monthly offer, not rewritten" \
  "$(printf '%s\n' "$gone" | grep -q '^recipe	' && echo no || echo yes)"

# A recipe still named in AGENTS.md can use the old Build stack format even
# though its current recipe folder is installed. Offer a move once, and a no
# records the decline without changing the project instructions.
P="$work/old-recipe-format"
mkdir -p "$P"
cp "$TEMPLATES/masterplan.md" "$P/masterplan.md"
printf '# AGENTS.md\n\n## Stack\n\n- Recipe: nextjs-supabase-on-vercel\n- Build stack: Next.js with TypeScript\n' > "$P/AGENTS.md"
cp "$P/AGENTS.md" "$work/format-before"
format=$(python3 "$CHECK" "$P") || true
report "a project on the old stack format is offered the widened recipe move" \
  "$(printf '%s\n' "$format" | grep -qx 'recipe-format	AGENTS.md:5	nextjs-supabase-on-vercel' \
     && printf '%s\n' "$format" | grep '^say	recipe-format	' | grep -q 'current shared stack format' && echo yes || echo no)"
report "offering the recipe move changes no project file" \
  "$(cmp -s "$P/AGENTS.md" "$work/format-before" && [ ! -f "$P/.ai-build-kit-maintenance" ] && echo yes || echo no)"
python3 "$CHECK" --decline recipe-format "$P" >/dev/null
report "a no records the recipe move decline without editing AGENTS.md" \
  "$(grep -q '^recipe-move-declined|[0-9-]*|nextjs-supabase-on-vercel|' "$P/.ai-build-kit-maintenance" \
     && cmp -s "$P/AGENTS.md" "$work/format-before" && echo yes || echo no)"
format=$(python3 "$CHECK" --monthly "$P") || true
report "a declined recipe move is not offered again on a monthly visit" \
  "$(printf '%s\n' "$format" | grep -q '^recipe-format	' && echo no || echo yes)"

echo
echo "older-project-upkeep.sh: all $passed checks passed"
