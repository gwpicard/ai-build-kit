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
rs_rule "approved update recovery asks no second question" 'do not ask again for that recovery'
rs_rule "guidance is not repeated monthly" 'do not repeat a line already named, even on a monthly visit, unless its text has changed'
rs_rule "the read runs again at the end" 'run the check once more at the end of the visit'
rs_rule "an unrecognised list gets a proposal" 'when the script cannot rewrite a command list, show the old lines and a proposed replacement'
rs_rule "the proposal has the current inventory" 'name the six commands and the five background skills, eleven in all, using the installed founding template'
rs_rule "own sentences survive the proposal" 'keep the rest of the paragraph.s meaning and the person.s own sentences'
rs_rule "the agent applies a yes" 'on a yes, apply the replacement as an agent edit to those lines only, then run the check again'
rs_rule "the person never edits the list by hand" 'never ask the person to edit the command list by hand'
rs_rule "a no is recorded and named once" 'on a no, record `--decline commands`.*name the declined command-list lines once'
rs_rule "a current version does not hide the leftover" 'the update stays unfinished while a command list names a retired command, unless the person declined it, even when the installed version already matches the release'
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
        copy(fixture/'WORKFLOW.md.txt',p/'WORKFLOW.md')
        put(p/'README.md','Our club tool.\n')
        copy(fixture/'build-adapters.sh.txt',p/'.agents/tools/build-adapters.sh')
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
    assert kinds.count('commands')==3, listed
    assert kinds.count('pointer')==1 and kinds.count('helper')==1 and kinds.count('template')==1,listed
    assert kinds.count('installer') == (0 if route=='plugin' else 4), listed
    assert ('kitcopy\t.claude-plugin' in listed)==(route=='whole'), listed
    assert ('hook\t.agents/hooks/session-end-sync.sh' in listed)==(route=='whole'), listed
    assert 'mention\tmasterplan.md:' in listed and 'We run /ship before' in listed
    if route=='whole':
        for path in ('.claude-plugin','WORKFLOW.md','.agents/guard/blocked-commands.md','.agents/tools/build-adapters.sh','.ai-build-kit-version'):
            assert 'kitcopy\t'+path in listed,listed
        assert 'left\tagent-plugin\t' in listed,listed
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
        for path in ('.claude-plugin','WORKFLOW.md','.agents/guard/blocked-commands.md','.agents/tools/build-adapters.sh','.ai-build-kit-version'):
            assert not (p/path).exists(),path
        assert (p/'README.md').read_text()=='Our club tool.\n'
        assert (p/'.agents/hooks/session-end-sync.sh').read_bytes()==(source/'setup-ai-build-kit/templates/foundation/session-end-sync.sh').read_bytes()
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
# Reproduce the wrapped list from an older founding, after all other steps
# have finished. The installed version already matches the current release.
p=work/'sentence-list'; p.mkdir()
copy(source/'setup-ai-build-kit/templates/masterplan.md',p/'masterplan.md')
copy(source/'setup-ai-build-kit/templates/foundation/plan-refresh.sh',p/'.agents/tools/plan-refresh.sh')
copy(fixture/'sentence-AGENTS.md.txt',p/'AGENTS.md')
copy(fixture/'version-v0.10.0.txt',p/'.ai-build-kit-version')
put(p/'CHANGELOG.md','We once used /fix, /queue, /sync and /ship.\n')
with (p/'AGENTS.md').open('a') as handle:
    handle.write('\nProject rule: Keep our club notes private.\n'
                 'Our old commands helped us use /fix, /queue and /ship.\n')
original=(p/'AGENTS.md').read_text()

def sentence_pending(skills):
    # This fixture isolates command-list detection after helper upkeep. Its
    # recovery companion also records the running installation's location.
    apply(skills,p,'helper')
    listed=check(skills,p,1)
    commands=[line for line in listed.splitlines() if line.startswith('commands\t')]
    assert len(commands)==1 and 'AGENTS.md:3' in commands[0],listed
    assert 'nine commands' in commands[0] and 'fourteen skills' in commands[0],listed
    assert 'by hand' not in commands[0],listed
    if (p/'.ai-build-kit-version').exists():
        assert 'kitcopy\t.ai-build-kit-version' in listed,listed
        assert 'left\t.ai-build-kit-version' not in listed,listed
    assert listed.count('mention\tAGENTS.md:')==1,listed
    assert 'Our old commands helped' in listed,listed
    assert 'CHANGELOG.md' not in listed,listed
    return listed

sentence_pending(source)
apply(source,p,'commands')
assert (p/'AGENTS.md').read_text()==original
sentence_pending(source)  # A script that cannot rewrite never finishes the step.

# Each behavioural assertion must catch the copied script without its fix.
mutations={
    'sentence detection': ('kit-leftovers.py',
        '    blocks = command_blocks(lines)', '    blocks = []'),
    'unfinished status': ('upgrade-check.py',
        '    if kind == "commands" and finding[-1].startswith("left as written:"):',
        '    if kind == "commands":\n        return True\n    if kind == "commands" and finding[-1].startswith("left as written:"):'),
    'plain version marker': ('kit-leftovers.py',
        '    if path == MARKER:', '    if False:'),
}
for name,(script,old,new) in mutations.items():
    skills=work/('without-'+name.replace(' ','-'))/'skills'
    shutil.copytree(source,skills)
    target=skills/'maintain/scripts'/script
    text=target.read_text(); assert old in text
    target.write_text(text.replace(old,new,1))
    if name == 'unfinished status':
        (p/'.ai-build-kit-version').unlink()
        sentence_pending(source)
    try:
        sentence_pending(skills)
    except AssertionError:
        pass
    else:
        raise AssertionError('removing '+name+' was not caught')
    if name == 'unfinished status':
        copy(fixture/'version-v0.10.0.txt',p/'.ai-build-kit-version')
    print('  ok: removing '+name+' is caught')

# A no is retained, offered monthly, and never duplicated as a mention.
apply(source,p,'helper')
run([sys.executable,source/'maintain/scripts/upgrade-check.py','--decline','commands',p])
apply(source,p,'remove')
declined=check(source,p,0)
assert declined.count('declined\tcommands\tcommands\t')==1,declined
assert declined.count('mention\tAGENTS.md:')==1,declined
monthly=run([sys.executable,source/'maintain/scripts/upgrade-check.py','--monthly',p],code=1)
assert 'commands\tAGENTS.md:3' in monthly and 'declined\tcommands' not in monthly,monthly
# Stand in for the approved agent edit, keeping all the other sentences.
replacement=original.replace('nine commands','six commands').replace(
    '`setup-ai-build-kit`, `shape`, `implement`, `queue`, `fix`, `ship`, `sync`,',
    '`setup-ai-build-kit`, `shape`, `implement`, `setup-hosting`,').replace(
    'fourteen skills','eleven skills')
put(p/'AGENTS.md',replacement)
finished=check(source,p,0)
assert 'commands\t' not in finished and 'declined\tcommands' not in finished,finished
assert 'Project rule: Keep our club notes private.' in (p/'AGENTS.md').read_text()
assert (p/'CHANGELOG.md').read_text()=='We once used /fix, /queue, /sync and /ship.\n'
# Explicit short lists still count; prose using several commands does not.
for wording in ('Commands: `/fix`, `/shape`.',
                'Our commands are `ship` and `implement`.',
                '- Commands: `shape`, `fix`. Keep our club notes private.'):
    put(p/'AGENTS.md',wording+'\n')
    listed=run([sys.executable,source/'maintain/scripts/upgrade-check.py','--monthly',p],code=1)
    assert listed.count('commands\tAGENTS.md:')==1,listed
    assert 'mention\t' not in listed,listed
put(p/'AGENTS.md',replacement)
# Extra text, a preview version and a link never qualify as a plain marker.
for content in ('v0.10.0\nOur notes.\n','v0.10.0-preview.1\n'):
    put(p/'.ai-build-kit-version',content)
    listed=check(source,p,0)
    assert 'left\t.ai-build-kit-version' in listed,listed
    apply(source,p,'remove')
    assert (p/'.ai-build-kit-version').read_text()==content
(p/'.ai-build-kit-version').unlink()
outside_marker=work/'outside-version'; put(outside_marker,'v0.10.0\n')
(p/'.ai-build-kit-version').symlink_to(outside_marker)
assert 'left\t.ai-build-kit-version\tit is a link' in check(source,p,0)
apply(source,p,'remove')
assert (p/'.ai-build-kit-version').is_symlink() and outside_marker.read_text()=='v0.10.0\n'
print('  ok: sentence list stays unfinished until an agent edit or a recorded no')

# The record rewrite tools must not follow linked project documents.
p=work/'linked-records'; p.mkdir(); outside=work/'outside-records'; outside.mkdir()
for name in ('AGENTS.md','masterplan.md'):
    copy(fixture/(name+'.txt'),outside/name)
    (p/name).symlink_to(outside/name)
before={name:(outside/name).read_bytes() for name in ('AGENTS.md','masterplan.md')}
for step in ('commands','pointers','template'):
    apply(source,p,step)
assert before=={name:(outside/name).read_bytes() for name in before}
listed=check(source,p,1)  # The helper is still missing; links are informational.
assert not any(line.startswith('template\t') for line in listed.splitlines()),listed
assert 'left as written: it is a link' in listed
print('  ok: linked records and their external targets stay untouched')

PY
fi
rs_done
