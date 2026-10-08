#!/usr/bin/env sh
# Rehearse an upgrade from the frozen last nine-command foundation on four routes.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"
rs_init "Upgrade rehearsal"
MAINTAIN="$ROOT/.agents/skills/maintain/SKILL.md"
rs_rule "every visit reaches the upgrade" 'finish a kit update, as "finishing a kit update" below says. this runs on every visit'
rs_rule "the read uses the shipped check" 'skill>/scripts/upgrade-check\.py`, with `--monthly` added'
rs_rule "a full offer is first and monthly only" 'make the full offer only on the first visit that finds a leftover and on monthly visits'
rs_rule "other visits give one line" 'on other visits with the same version, say only:'
rs_rule "the offer is recorded" 'after showing the offers, record that line, keeping the other lines'
rs_rule "a helper follows the saved checkpoint" 'on the clean checkpoint the truing.s save leaves, run the check with `--apply helper`'
rs_rule "the settings step is reached" '`settings` lines: `--apply settings`'
rs_rule "the pointer step is reached" 'and `--apply pointers`, each shown old and new'
rs_rule "own guidance is never changed" 'name each one once, in the reply that makes the offers, as the person.s to change, and never rewrite one'
rs_rule "the read runs again at the end" 'run the check once more at the end of the visit'
rs_guard "$MAINTAIN" "the upgrade visit"
rs_reset
rs_rule "the release brings the person back" 'after updating, start a new session \(or /reload-plugins\) and type /maintain again'
rs_guard "$ROOT/docs/release-notes/v0.20.0.md" "the release notes"
rs_reset
rs_rule "implement reads before building" 'scripts/upgrade-check\.py`, and keep only its exit code'
rs_rule "implement gives only one line" 'where it exits 1, say one line: "the kit update is not finished. /maintain finishes it." then carry on'
rs_guard "$ROOT/.agents/skills/implement/SKILL.md" "implement's upgrade read"
rs_reset
rs_rule "what-now reads without changing" 'scripts/upgrade-check\.py`, and keep only its exit code. it reads and changes nothing'
rs_rule "what-now gives only one line" 'where the update check exited 1, say one line before the recap'
rs_guard "$ROOT/.agents/skills/what-now/SKILL.md" "what-now's upgrade read"
if [ -z "${RS_LIST:-}" ]; then
python3 - "$ROOT" "$rs_dir" <<'PY'
import hashlib, importlib.util, json, os, pathlib, shutil, subprocess, sys
root, work = map(pathlib.Path, sys.argv[1:])
source = root / '.agents/skills'
fixture = root / '.agents/tests/fixtures/upgrade-v0.19.3'
eleven = [p.name for p in source.iterdir() if p.is_dir()]
retired = ['fix', 'queue', 'sync', 'ship']
known = json.loads((source/'maintain/scripts/kit-retired-skills.json').read_text())['skills']

def run(args, cwd=None, code=0):
    result = subprocess.run(list(map(str,args)), cwd=cwd, capture_output=True, text=True)
    assert result.returncode == code, (args, result.returncode, result.stdout, result.stderr)
    return result.stdout

def put(p, data):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(data)

def copy(a,b):
    b.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(a,b)

def check(skills,p,code):
    return run([sys.executable,skills/'maintain/scripts/upgrade-check.py',p],code=code)

def apply(skills,p,step):
    run([sys.executable,skills/'maintain/scripts/upgrade-check.py','--apply',step,p])

# Stand in for the installer's own removal, including linked agent copies.
npx=work/'bin/npx'
put(npx, '''#!/usr/bin/env python3
import json, pathlib, shutil, sys
assert sys.argv[1:3] == ['skills','remove']
p=pathlib.Path.cwd(); lock=p/'skills-lock.json'; data=json.loads(lock.read_text())
for name in sys.argv[3:]:
    if name == '-y': continue
    assert data['skills'][name]['source'] == 'gwpicard/ai-build-kit'
    for folder in ('.claude/skills','.agents/skills'):
        target=p/folder/name
        if target.is_symlink(): target.unlink()
        elif target.is_dir(): shutil.rmtree(target)
    del data['skills'][name]
lock.write_text(json.dumps(data)+'\\n')
''')
npx.chmod(0o755)
for route in ('claude-only','shared','whole','plugin'):
    p=work/route; p.mkdir()
    if route == 'plugin':
        pack=work/'plugin-cache'; skills=pack/'.agents/skills'
        shutil.copytree(source,skills)
        copy(fixture/'claude-plugin.json',pack/'.claude-plugin/plugin.json')
    else:
        skills=p/('.claude/skills' if route=='claude-only' else '.agents/skills')
        shutil.copytree(source,skills)
    setup=skills/'setup-ai-build-kit'
    copy(fixture/'bootstrap-project.sh.txt',setup/'scripts/bootstrap-project.sh')
    for old,new in [('AGENTS.md.txt','AGENTS.md'),('claude-settings.json','claude-settings.json'),('plan-refresh.sh.txt','plan-refresh.sh')]:
        copy(fixture/old,setup/'templates/foundation'/new)
    run(['sh',setup/'scripts/bootstrap-project.sh',p],cwd=p)
    copy(fixture/'masterplan.md.txt',p/'masterplan.md')
    with (p/'AGENTS.md').open('a') as f: f.write('\nProject rule: Keep our club notes private.\n')
    with (p/'masterplan.md').open('a') as f: f.write('\nHosting request: Keep our current address.\nWe run /ship before the club night.\n')
    put(p/'CHANGELOG.md','Launched with /ship. Repaired with /fix.\n')
    changelog=(p/'CHANGELOG.md').read_bytes()
    before=json.loads((p/'.claude/settings.json').read_text())
    run(['git','init','-q','-b','main'],p)
    run(['git','add','.env.example'],p)
    run(['git','-c','user.name=upgrade rehearsal','-c','user.email=rehearsal@example.invalid','commit','-qm','Initial settings'],p)
    run(['git','checkout','-qb','piece'],p)
    with (p/'.env.example').open('a') as f: f.write('\nNEW_CLUB_SETTING=private-example\nexport SECOND_SETTING=another-value\n# IGNORED_SETTING=ignored\n')
    run(['git','add','.env.example'],p)
    run(['git','-c','user.name=upgrade rehearsal','-c','user.email=rehearsal@example.invalid','commit','-qm','Add required settings'],p)
    # Overlay updated skills, retaining the four entries the real add kept.
    shutil.rmtree(skills); shutil.copytree(source,skills)
    (skills/'maintain/VERSION').write_text('v0.20.0\n')
    if route != 'plugin':
        for name in retired:
            put(skills/name/'SKILL.md','---\nname: '+name+'\ndescription: '+known[name][-1]+'\n---\n')
        put(p/'skills-lock.json',json.dumps({'version':1,'skills':{n:{'source':'gwpicard/ai-build-kit','sourceType':'github'} for n in eleven+retired}}))
        if route in ('shared','whole'):
            for name in eleven+retired:
                target=p/'.claude/skills'/name
                target.parent.mkdir(parents=True,exist_ok=True)
                target.symlink_to('../../.agents/skills/'+name)
    if route=='whole':
        put(p/'.ai-build-kit-version','v0.19.3\n')
        copy(fixture/'agent-plugin.json',p/'agent-plugin/plugin.json')
        copy(fixture/'claude-plugin.json',p/'.claude-plugin/plugin.json')
        copy(fixture/'claude-marketplace.json',p/'.claude-plugin/marketplace.json')
        copy(fixture/'blocked-commands.md.txt',p/'.agents/guard/blocked-commands.md')
        copy(fixture/'session-end-sync.sh.txt',p/'.agents/hooks/session-end-sync.sh')
        # A changed kit folder is preserved, including extra files and links.
        put(p/'agent-plugin/notes.md','My own notes.\n')
        put(p/'.cursor/commands/ship.md','<!-- GENERATED from .agents/skills/ship/. Do not edit here; regenerate with .agents/tools/build-adapters.sh -->\n')
    listed=check(skills,p,1)
    kinds=[line.split('\t')[0] for line in listed.splitlines()]
    assert {'commands','pointer','helper','settings','template','mention'} <= set(kinds), listed
    assert kinds.count('installer') == (0 if route=='plugin' else 4), listed
    assert ('kitcopy\t.claude-plugin' in listed)==(route=='whole'), listed
    assert ('hook\t.agents/hooks/session-end-sync.sh' in listed)==(route=='whole'), listed
    assert 'mention\tmasterplan.md:' in listed and 'We run /ship before' in listed
    if route!='plugin':
        run([npx,'skills','remove',*retired,'-y'],p)
        assert set(json.loads((p/'skills-lock.json').read_text())['skills'])==set(eleven)
    for step in ('helper','remove','commands','pointers','settings','template'): apply(skills,p,step)
    after=check(skills,p,0)
    assert all(l.startswith(('mention\t','left\t')) for l in after.splitlines()),after
    assert (p/'CHANGELOG.md').read_bytes()==changelog
    assert 'Project rule: Keep our club notes private.' in (p/'AGENTS.md').read_text()
    assert 'We run /ship before the club night.' in (p/'masterplan.md').read_text()
    assert '/setup-hosting writes a hosting' in (p/'masterplan.md').read_text()
    current=json.loads((p/'.claude/settings.json').read_text())
    for key,value in before.items():
        if key!='permissions': assert current[key]==value
    for key,value in before['permissions'].items():
        if key in ('ask','deny'): assert current['permissions'][key][:len(value)]==value
        else: assert current['permissions'][key]==value
    assert (p/'.agents/tools/plan-refresh.sh').read_bytes()==(source/'setup-ai-build-kit/templates/foundation/plan-refresh.sh').read_bytes()
    if route=='whole':
        assert (p/'agent-plugin/notes.md').read_text()=='My own notes.\n'
        assert not (p/'.claude-plugin').exists()
        assert (p/'.agents/hooks/session-end-sync.sh').read_bytes()==(source/'maintain/templates/session-end-sync.sh').read_bytes()
    snapshot={str(f.relative_to(p)):f.read_bytes() for f in p.rglob('*') if f.is_file() and '.git' not in f.parts}
    assert check(skills,p,0)==after
    assert snapshot=={str(f.relative_to(p)):f.read_bytes() for f in p.rglob('*') if f.is_file() and '.git' not in f.parts}
    env=skills/'section-builder/scripts/env-names-added.sh'
    assert run(['sh',env,'piece','main'],p,1).splitlines()==['NEW_CLUB_SETTING','SECOND_SETTING']
    assert run(['sh',env,'main','main'],p)==''
    run(['sh',env,'unknown','main'],p,2)
    # A blocked repair must not be printed as ready by the new helper.
    gh=work/'bin/gh'
    put(gh, '''#!/usr/bin/env python3
import json,sys
if sys.argv[1]=='repo': print('{"nameWithOwner":"club/tool"}')
elif 'blocked_by' in sys.argv[2]: print('[{"title":"Card checkout","state":"open"}]')
else: print(json.dumps([{"number":1,"title":"Reminder emails","html_url":"https://example.invalid/piece","labels":[{"name":"broken"},{"name":"ready"}],"body":"## Done when\\nIt works.","issue_dependencies_summary":{"blocked_by":1}}]))
'''); gh.chmod(0o755)
    oldpath=os.environ['PATH']; os.environ['PATH']=str(gh.parent)+os.pathsep+oldpath
    run(['sh',p/'.agents/tools/plan-refresh.sh'],p)
    os.environ['PATH']=oldpath
    printout=(p/'plan.local.md').read_text()
    assert '(needs Card checkout)' in printout and '(ready)' not in printout,printout
    print('  ok: '+route+' preserves the person\'s work and finishes the upgrade')
PY
fi
rs_done
