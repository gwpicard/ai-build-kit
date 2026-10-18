#!/usr/bin/env sh
# risk-move-rehearsal.sh: move projects from an old path record to the risk record, in throwaway
# projects built from real older records. If this breaks, an update can drop a risk area, an
# acceptance, a date or the person's words, turn an acceptance into a finished caution, write on a
# no, or leave a project whose area check reads nothing.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
echo "Risk record move rehearsal:"
python3 - "$ROOT" "$work" <<'PY'
import hashlib, json, os, pathlib, re, shutil, subprocess, sys
root, work = map(pathlib.Path, sys.argv[1:])
skills = root / '.agents/skills'
move = skills / 'maintain/scripts/risk_move.py'
upgrade = skills / 'maintain/scripts/upgrade-check.py'
area_check = skills / 'setup-ai-build-kit/templates/foundation/check-sensitive-areas.sh'
records = root / '.agents/tests/fixtures/upgrade-records'
today = subprocess.run(['date', '+%Y-%m-%d'], capture_output=True, text=True).stdout.strip()

def run(args, cwd=None, code=0, env=None):
    result = subprocess.run(list(map(str, args)), cwd=cwd, capture_output=True, text=True, env=env)
    assert result.returncode == code, (args, result.returncode, result.stdout, result.stderr)
    return result.stdout

def tree(p):
    out = {}
    for f in sorted(p.rglob('*')):
        if '.git' in f.parts or f.is_dir():
            continue
        out[str(f.relative_to(p))] = hashlib.sha256(f.read_bytes()).hexdigest()
    return out

def words(text):
    return set(re.findall(r"[A-Za-z0-9][A-Za-z0-9'-]*", text))

# GitHub, standing in. Open pieces live in a file; an edit rewrites the body from standard input.
bin_dir = work / 'bin'
bin_dir.mkdir()
fake = bin_dir / 'gh'
fake.write_text('''#!/usr/bin/env python3
import json, os, sys
if os.environ.get('GH_DOWN'):
    sys.exit(1)
path = os.environ['GH_STATE']
state = json.load(open(path))
a = sys.argv[1:]
if a[:2] == ['issue', 'list']:
    print(json.dumps(state['issues']))
elif a[:2] == ['issue', 'edit'] and a[3:] == ['--body-file', '-']:
    for issue in state['issues']:
        if issue['number'] == int(a[2]):
            issue['body'] = sys.stdin.read()
    json.dump(state, open(path, 'w'))
else:
    sys.exit(1)
''')
fake.chmod(0o755)
os.environ['PATH'] = str(bin_dir) + os.pathsep + os.environ['PATH']
state_file = work / 'gh-state.json'
os.environ['GH_STATE'] = str(state_file)

def pieces(*issues):
    state_file.write_text(json.dumps({'issues': [
        {'number': n, 'body': body, 'labels': []} for n, body in issues]}))

def piece(reaches, extra=''):
    return ('## Problem\nSlow.\n\n## Done when\nIt works.\n\n%s\n<details><summary>Under the hood</summary>\n\n'
            'Reaches: %s\n</details>\n' % (extra, reaches))

made = []

def project(name, fixture, crlf=False):
    made.append(name)
    p = work / ('%02d-%s' % (len(made), name))
    p.mkdir()
    text = (records / (fixture + '.masterplan.md.txt')).read_text()
    if crlf:
        text = text.replace('\n', '\r\n')
    with (p / 'masterplan.md').open('w', newline='') as f:
        f.write(text)
    (p / 'CHANGELOG.md').write_text('# Changelog\n\nNewest first.\n\n## 2026-09-30\n\n- Built: the first screen.\n')
    run(['git', 'init', '-q', '-b', 'main'], p)
    run(['git', 'config', 'user.name', 'Test'], p)
    run(['git', 'config', 'user.email', 'test@example.invalid'], p)
    return p

def listed(p, *args):
    result = subprocess.run([sys.executable, upgrade, *map(str, args), str(p)], capture_output=True, text=True)
    assert result.returncode in (0, 1), (result.returncode, result.stdout, result.stderr)
    return result.stdout

def section(text):
    m = re.search(r'^## (Build path|Risk record)\n.*?(?=^## |\Z)', text, re.S | re.M)
    return m.group(0)

FIXTURES = ['explore', 'build-and-run', 'build-with-care', 'four-paths', 'four-paths-expert']

# Each record is found by the upgrade check, the three path values and the four-path fields alike.
for name in FIXTURES:
    p = project('find-' + name, name)
    out = listed(p)
    assert any(l.startswith('fitcheck\tmasterplan.md:') for l in out.splitlines()), (name, out)
print('  ok: each older record is found, one per path value and the four-path fields')

# A current record and a never-filled template are not found.
p = project('current', 'explore')
run([sys.executable, move, '--apply', p])
assert 'fitcheck\t' not in listed(p)
(p / 'masterplan.md').write_text('# Masterplan\n\n## Build path\n\nPath:\nWhy:\nSensitive areas:\nAccepted:\n')
assert 'fitcheck\t' not in listed(p)
print('  ok: a moved record and an unfilled template are left alone')

# Showing the move writes nothing, anywhere.
for name in FIXTURES:
    p = project('show-' + name, name)
    pieces((1, piece('src/a.ts')))
    before = tree(p)
    out = run([sys.executable, move, p])
    assert '--- before ---' in out and '--- after ---' in out and 'Risk areas' in out, out
    assert tree(p) == before, name
print('  ok: showing the move changes no file')

# A no changes nothing in the project's records. The one line it adds is the kit's own note
# that the offer was declined, in the maintenance record.
for name in FIXTURES:
    p = project('no-' + name, name)
    (p / '.ai-build-kit-maintenance').write_text('last-light-pass|2026-09-01\n')
    before = tree(p)
    run([sys.executable, upgrade, '--decline', 'fitcheck', p])
    after = tree(p)
    changed = [f for f in after if before.get(f) != after[f]]
    assert changed == ['.ai-build-kit-maintenance'], (name, changed)
    note = (p / '.ai-build-kit-maintenance').read_text().splitlines()
    assert note[0] == 'last-light-pass|2026-09-01' and len(note) == 2 and note[1].startswith('upgrade-declined|'), note
    assert 'declined\tfitcheck' in listed(p)
print('  ok: a no leaves every project record as it was and is remembered')

# The yes. Each fixture moves, and no acceptance, date or word is lost.
def moved(name, issues=(), crlf=False):
    p = project('yes-' + name, name, crlf)
    pieces(*issues)
    old_text = (p / 'masterplan.md').read_bytes().decode()
    out = run([sys.executable, upgrade, '--apply', 'fitcheck', p])
    new_text = (p / 'masterplan.md').read_bytes().decode()
    return p, old_text, new_text, out

def kept(old_text, new_text, p):
    old, new = section(old_text.replace('\r', '')), section(new_text.replace('\r', ''))
    log = (p / 'CHANGELOG.md').read_text()
    labels = r'^(Path|Why|Required controls|Outside help|Access|Sensitive areas|Accepted|Runs on its own|Recheck when|Last checked):'
    old_body = re.sub(r'<!--.*?-->', '', re.sub(labels, '', old.split('\n', 1)[1], flags=re.M), flags=re.S)
    missing = words(old_body) - words(new) - words(log)
    assert not missing, missing
    assert set(re.findall(r'\d{4}-\d{2}-\d{2}', old)) <= set(re.findall(r'\d{4}-\d{2}-\d{2}', new)), 'a date was lost'
    for line in old.splitlines():
        if line.startswith('Accepted:') or re.match(r'^\s+Accepted:', line):
            assert line in new.splitlines(), ('an acceptance changed', line)
    return new

for name in FIXTURES:
    p, old_text, new_text, out = moved(name)
    new = kept(old_text, new_text, p)
    assert new.startswith('## Risk record\n') and 'Path:' not in new and 'Sensitive areas:' not in new, new
    for field in ('Exposed:', 'Data:', 'Wrong answer:', 'Recovery:'):
        assert field + ' not yet answered' in new, (field, new)
    assert re.search(r'^Earlier path: .* \(until %s\)$' % today, new, re.M), new
    assert 'Earlier why:' in new
    assert re.search(r'^## %s\n\n- Moved the masterplan' % today, (p / 'CHANGELOG.md').read_text(), re.M), (p / 'CHANGELOG.md').read_text()
    assert 'Built: the first screen.' in (p / 'CHANGELOG.md').read_text()
    # Everything outside the section is byte for byte as it was.
    head_old, tail_old = old_text.split('## Build path', 1)[0], re.split(r'^## ', old_text.split('## Build path', 1)[1], 1, flags=re.M)[1]
    assert new_text.startswith(head_old) and new_text.endswith(tail_old), name
    assert 'fitcheck\t' not in listed(p)
    run([sys.executable, move, '--apply', p], code=1)
    assert (p / 'masterplan.md').read_text() == new_text
print('  ok: each fixture moves, keeping every area, acceptance, date and word')

# Three-path areas move as written: the caution that was done stays done, the one not yet done
# stays open, and an accepted area stays accepted, never done.
p, old_text, new_text, out = moved('build-with-care')
for line in section(old_text).splitlines():
    if re.match(r'^  [^ ].*;', line) or re.match(r'^    (paths|boundary):', line) or line.startswith('  none:'):
        assert line in new_text.splitlines(), line
assert '; accepted 2026-08-12' in new_text and 'sign-in and permissions: who can see the client notes; caution: independent access review before outside use; accepted' in new_text
assert 'Runs on its own: merge (decided 2026-09-10, "merge when everything passes")' in new_text
print('  ok: areas, paths, boundaries and the automatic-work line move as written')

# The shipped area check reads the moved record: an accepted area still passes with the person's
# words on file, and an open one still holds. Before the move, it read nothing.
p = project('check', 'build-with-care')
for f in ('src/recommendations/x.ts', 'src/rules/treatment.ts', 'src/imports/maintenance/a.ts',
          'src/notes/n.ts', 'src/reporting/r.ts'):
    (p / f).parent.mkdir(parents=True, exist_ok=True)
    (p / f).write_text('export const a = 1\n')
(p / 'check-areas.sh').write_text(area_check.read_text())
run(['git', 'add', '-A'], p); run(['git', 'commit', '-qm', 'old record'], p)
def change(file, branch):
    run(['git', 'checkout', '-q', 'main'], p)
    run(['git', 'checkout', '-q', '-b', branch], p)
    (p / file).write_text('export const a = 2\n')
    run(['git', 'commit', '-qam', 'change ' + file], p)
    result = subprocess.run(['sh', 'check-areas.sh', '--change', 'main'], cwd=p, capture_output=True, text=True)
    run(['git', 'checkout', '-q', 'main'], p)
    return result
assert change('src/recommendations/x.ts', 'old-open').returncode == 0  # the old record is not read
pieces()
run([sys.executable, upgrade, '--apply', 'fitcheck', p])
run(['git', 'commit', '-qam', 'risk record'], p)
open_area = change('src/recommendations/x.ts', 'open')
assert open_area.returncode == 1 and 'regulated decisions' in open_area.stdout, (open_area.stdout, open_area.stderr)
accepted = change('src/notes/n.ts', 'accepted')
assert accepted.returncode == 0 and 'which you accepted on 12 August 2026' in accepted.stdout, (accepted.stdout, accepted.stderr)
done = change('src/imports/maintenance/a.ts', 'done')
assert done.returncode == 0 and 'caution was completed on 12 August 2026' in done.stdout, done.stdout
assert subprocess.run(['sh', 'check-areas.sh'], cwd=p, capture_output=True).returncode == 0
print('  ok: the area check holds the open area and passes the accepted one after the move')

# Open pieces: an area is named where the piece reaches it, none where it reaches no area, and a
# piece only a person can place stays as it was. Pieces that already name an area, and requests
# without a Done when, are never touched.
p = project('pieces', 'build-with-care')
requests = (6, 'Just an idea for later.')
pieces((1, piece('src/recommendations/x.ts')),
       (2, piece('src/reporting/r.ts, README.md')),
       (3, piece('new files only')),
       (4, piece('src/notes/n.ts', 'Risk areas: none')),
       requests,
       (7, piece('src/notes/n.ts, src/imports/maintenance/a.ts')))
out = run([sys.executable, move, p])
block = out.split('--- pieces ---')[1]
assert 'piece 1: Risk areas: regulated decisions' in block and 'piece 2: Risk areas: none' in block, block
assert 'piece 7: Risk areas: irreplaceable live data, sign-in and permissions' in block, block
assert 'piece 3: stays without a line' in block and 'piece 4' not in block and 'piece 6' not in block, block
assert json.loads(state_file.read_text())['issues'][0]['body'] == piece('src/recommendations/x.ts'), 'showing edited a piece'
run([sys.executable, upgrade, '--apply', 'fitcheck', p])
bodies = {i['number']: i['body'] for i in json.loads(state_file.read_text())['issues']}
assert 'Risk areas: regulated decisions\n\n<details>' in bodies[1], bodies[1]
assert 'Risk areas: none\n\n<details>' in bodies[2] and bodies[2].count('Risk areas:') == 1
assert bodies[3] == piece('new files only') and bodies[4] == piece('src/notes/n.ts', 'Risk areas: none')
assert bodies[6] == 'Just an idea for later.'
text = (p / 'masterplan.md').read_text()
assert re.search(r'^Report-only: .*1 open piece does name none', text, re.M), text
print('  ok: open pieces get their risk areas where the reach says so, and no others change')

# Checks the moved project cannot run start report-only and say so; none are called passed.
p, old_text, new_text, out = moved('four-paths', [(1, piece('src/a.ts'))])
assert re.search(r'^Report-only: area paths for sign-in and permissions, so the project check cannot hold', new_text, re.M), new_text
assert 'report-only' in out and 'hold nothing' in out, out
p, old_text, new_text, out = moved('build-and-run')
assert 'Report-only:' not in new_text and 'report-only' not in out, (new_text, out)
os.environ['GH_DOWN'] = '1'
p, old_text, new_text, out = moved('explore')
assert re.search(r'^Report-only: piece risk areas, because the open pieces could not be read', new_text, re.M), new_text
del os.environ['GH_DOWN']
print('  ok: a check the project cannot yet run starts report-only, and says so')

# The four-path controls become area lines. A control that names no area is a standing rule: it
# leaves the record, and the changelog names it.
p, old_text, new_text, out = moved('four-paths-expert')
assert '  irreplaceable live data: from the old required controls; caution: a backup restored once before real records go in; not yet done' in new_text
assert '  personal or sensitive data: client records; caution: scoped review; not yet done' in new_text
log = (p / 'CHANGELOG.md').read_text()
assert 'secrets stay out of the code' in log and 'secrets stay out' not in section(new_text), log
p, old_text, new_text, out = moved('four-paths')
assert 'destructive actions stop for approval' in (p / 'CHANGELOG.md').read_text()
print('  ok: old controls become area lines, and standing rules are named in the changelog')

# A question the move leaves to the person: a project recorded as private only hears what the kit now expects.
p, old_text, new_text, out = moved('explore')
assert 'issues switched on' in out, out
# The access step still works on the moved record.
p, old_text, new_text, out = moved('build-and-run')
assert 'access\t' in listed(p)
run([sys.executable, upgrade, '--apply', 'access=private', p])
assert re.search(r'^Access: private$', (p / 'masterplan.md').read_text(), re.M)
print('  ok: a private-only project is told what the kit expects, and the access step reads the new record')

# Line endings and links.
p, old_text, new_text, out = moved('explore', crlf=True)
assert all(l.endswith('\r') for l in new_text.split('\n')[:-1]), 'the file mixed its line endings'
p = project('link', 'explore')
target = work / 'outside.md'
target.write_text((p / 'masterplan.md').read_text())
(p / 'masterplan.md').unlink()
(p / 'masterplan.md').symlink_to(target)
before = target.read_text()
run([sys.executable, move, '--apply', p], code=2)
assert target.read_text() == before and (p / 'masterplan.md').is_symlink()
p = project('changelog-link', 'explore')
target = work / 'outside-changelog.md'
target.write_text('outside\n')
(p / 'CHANGELOG.md').unlink(missing_ok=True)
(p / 'CHANGELOG.md').symlink_to(target)
before = tree(p)
run([sys.executable, move, '--apply', p], code=2)
assert tree(p) == before and target.read_text() == 'outside\n'
p = project('headingless', 'headingless')
before = tree(p)
run([sys.executable, move, '--apply', p], code=2)
assert tree(p) == before
print('  ok: Windows line endings stay, and a linked masterplan or changelog, or a headingless record, is never half written')
PY
echo "risk-move-rehearsal.sh: all checks passed"
