#!/usr/bin/env sh
# upgrade-rehearsal.sh: rehearse an upgrade from the frozen last nine-command foundation on four
# install routes, with the three background skills the last eleven-skill
# release still had kept by the installer too, with the shipped upgrade-check.py and kit-leftovers.py. If
# this breaks, an update can overwrite a person's own guidance, settings or
# changelog, leave retired commands installed, or mark a blocked repair ready.
# It also covers a project from before the ready label, whose pieces
# /implement would never build, the renames said to the person, and lines
# named once rather than on every visit.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
echo "Upgrade rehearsal:"
python3 - "$ROOT" "$work" <<'PY'
import hashlib, importlib.util, json, os, pathlib, re, shutil, subprocess, sys
root, work = map(pathlib.Path, sys.argv[1:])
source = root / '.agents/skills'
fixture = root / '.agents/tests/fixtures/upgrade-v0.19.3'
kit_names = [p.name for p in source.iterdir() if p.is_dir()]
retired = ['fix', 'queue', 'sync', 'ship', 'change-triage', 'section-builder']
# The counts today's founding template gives, which a rewritten list takes.
template_text = (source/'setup-ai-build-kit/templates/foundation/AGENTS.md').read_text()
count_skills = re.search(r'lives in ([a-z-]+) installed', template_text).group(1)
count_background = re.search(r'\n([a-z-]+) run in the background', template_text).group(1)
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
        put(p/'skills-lock.json',json.dumps({'version':1,'skills':{n:{'source':'gwpicard/ai-build-kit','sourceType':'github'} for n in kit_names+retired}}))
        if route in ('shared','whole'):
            for name in kit_names+retired:
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
    # Every step the person is offered comes with the words they hear.
    said={line.split('\t')[1] for line in listed.splitlines() if line.startswith('say\t')}
    steps={'installer':'installer','commands':'commands','pointer':'pointers','settings':'settings',
           'template':'template','mention':'mention','kitcopy':'remove','hook':'remove','left':'left','secrets':'secrets',
           'access':'access'}
    assert {steps[k] for k in kinds if k in steps} <= said, listed
    assert 'kit' in said, listed
    assert {'commands','pointer','helper','settings','template','mention'} <= set(kinds), listed
    assert kinds.count('commands')==5, listed
    assert kinds.count('pointer')==5 and kinds.count('helper')==1 and kinds.count('template')==3,listed
    assert kinds.count('installer') == (0 if route=='plugin' else 6), listed
    assert ('kitcopy\t.claude-plugin' in listed)==(route=='whole'), listed
    assert ('hook\t.agents/hooks/session-end-sync.sh' in listed)==(route=='whole'), listed
    assert 'mention\tmasterplan.md:' in listed and 'We run /ship before' in listed
    assert kinds.count('secrets')==1, listed
    # A project from before Access: lines is asked which setting it wants.
    assert kinds.count('access')==1, listed
    if route=='whole':
        for path in ('.claude-plugin','WORKFLOW.md','.agents/guard/blocked-commands.md','.agents/tools/build-adapters.sh','.ai-build-kit-version'):
            assert 'kitcopy\t'+path in listed,listed
        assert 'left\tagent-plugin\t' in listed,listed
    if route!='plugin':
        run([npx,'skills','remove',*retired,'-y'],p)
        assert set(json.loads((p/'skills-lock.json').read_text())['skills'])==set(kit_names)
        assert not any((p/folder/name).exists() for folder in ('.agents/skills','.claude/skills') for name in retired)
    for step in ('helper','remove','commands','pointers','settings','template'): apply(skills,p,step)
    # A no changes nothing; a yes writes the line the person chose, once.
    if route=='plugin':
        plan_before=(p/'masterplan.md').read_bytes()
        run([sys.executable,skills/'maintain/scripts/upgrade-check.py','--decline','access',p])
        assert 'declined\taccess\taccess\t' in check(skills,p,0)
        assert (p/'masterplan.md').read_bytes()==plan_before
    run([sys.executable,skills/'maintain/scripts/upgrade-check.py','--apply','access',p],code=2)
    if route=='whole':
        apply(skills,p,'access=open-address')
        assert len(re.findall(r'\nAccess: open address, invitation only \(decided \d{4}-\d\d-\d\d\)\n',(p/'masterplan.md').read_text()))==1
    else:
        apply(skills,p,'access=private')
        assert (p/'masterplan.md').read_text().count('\nAccess: private\n')==1
    apply(skills,p,'access=public')
    assert 'Access: public' not in (p/'masterplan.md').read_text()
    after=check(skills,p,0)
    assert all(l.startswith(('mention\t','left\t','secrets\t','say\t')) for l in after.splitlines()),after
    assert (p/'CHANGELOG.md').read_bytes()==changelog
    assert 'Project rule: Keep our club notes private.' in (p/'AGENTS.md').read_text()
    assert 'We run /ship before the club night.' in (p/'masterplan.md').read_text()
    assert '/setup-hosting writes a hosting' in (p/'masterplan.md').read_text()
    agents=(p/'AGENTS.md').read_text()
    assert not any(n in agents for n in ('change-triage','section-builder')),agents
    assert "load `screen-check`" in agents,agents
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
    env=skills/'merge/scripts/env-names-added.sh'
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
    'fourteen skills',count_skills+' skills')
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

# A project founded while the kit had one /build command, installed through a
# plugin so no skill folder sits in the project, and with no `build` skill
# left anywhere. Its issues never had a `ready` label, so /implement would
# build none of them. The check reads that from GitHub and labels the shaped
# pieces, whatever the install route, and leaves the rest for /shape.
p=work/'before-ready'; p.mkdir()
copy(fixture/'masterplan.md.txt',p/'masterplan.md')
with (p/'masterplan.md').open('a') as f:
    f.write('\nPath: Professional-led\nOutside help: review, for client records\n')
plugin=work/'old-plugin/skills'; shutil.copytree(source,plugin)
run(['git','init','-q','-b','main'],p)
run(['git','remote','add','origin','https://github.com/club/tool.git'],p)
state=work/'gh-state.json'
def issue(number,labels,body):
    return {'number':number,'labels':[{'name':n} for n in labels],'body':body}
state.write_text(json.dumps({'labels':['visual','data'],'calls':[],'issues':[
    issue(1,['visual'],'## Problem\nSlow.\n\n## Done when\nIt loads in a second.'),
    issue(2,['needs-clarification'],'## Done when\nUnclear.'),
    issue(3,['parked'],'## Done when\nLater.'),
    issue(4,[],'Just an idea.'),
    issue(5,[],'## Done when\nThe list prints.')]}))
fakegh=work/'ready-bin/gh'
put(fakegh, '''#!/usr/bin/env python3
import json, os, sys
path=os.environ['GH_STATE']; s=json.load(open(path)); a=sys.argv[1:]
s['calls'].append(' '.join(a))
if os.environ.get('GH_DOWN'):
    json.dump(s,open(path,'w')); sys.exit(1)
if a[:2]==['label','list']:
    print(json.dumps([{'name':n} for n in s['labels']]))
elif a[:2]==['label','create']:
    s['labels'].append(a[2])
elif a[:2]==['issue','list']:
    print(json.dumps(s['issues']))
elif a[:2]==['issue','edit'] and a[3]=='--add-label':
    assert a[4] in s['labels'], 'GitHub refuses a label that does not exist'
    for i in s['issues']:
        if i['number']==int(a[2]): i['labels'].append({'name':a[4]})
else:
    sys.exit(1)
json.dump(s,open(path,'w'))
'''); fakegh.chmod(0o755)
oldpath=os.environ['PATH']
os.environ['PATH']=str(fakegh.parent)+os.pathsep+oldpath
os.environ['GH_STATE']=str(state)
listed=check(plugin,p,1)
lines=listed.splitlines()
assert lines[0]=='ready\t1,5',listed
said=[l.split('\t',2) for l in lines if l.startswith('say\t')]
assert any(k=='renamed' and '/build' in w and '/implement' in w for _,k,w in said),listed
assert any(k=='ready' and '2 pieces' in w for _,k,w in said),listed
# A step the person need not be asked about is not one they can decline.
run([sys.executable,plugin/'maintain/scripts/upgrade-check.py','--decline','ready',p],code=2)
applied=run([sys.executable,plugin/'maintain/scripts/upgrade-check.py','--apply','ready',p])
assert 'say\tready\tI have marked 2 pieces ready' in applied,applied
data=json.loads(state.read_text())
marked={i['number'] for i in data['issues'] if {'name':'ready'} in i['labels']}
assert marked=={1,5},data
assert 'ready' in data['labels'],data
again=check(plugin,p,1)  # the four-path fields are still there
assert not any(l.startswith(('ready\t','say\tready','say\trenamed')) for l in again.splitlines()),again
before=state.read_text()
run([sys.executable,plugin/'maintain/scripts/upgrade-check.py','--apply','ready',p])
assert json.loads(state.read_text())['issues']==json.loads(before)['issues']
# GitHub out of reach is not a finding and does not stop the check.
os.environ['GH_DOWN']='1'
assert not any(l.startswith('ready\t') for l in check(plugin,p,1).splitlines())
del os.environ['GH_DOWN']
# The kit's own repository is never asked.
calls=len(json.loads(state.read_text())['calls'])
run(['git','remote','set-url','origin','git@github.com:gwpicard/ai-build-kit.git'],p)
check(plugin,p,1)
assert len(json.loads(state.read_text())['calls'])==calls
os.environ['PATH']=oldpath
print('  ok: pieces shaped before the ready label are marked ready on any install route')

# The old build-path fields get the rewrite in four-paths.md, which keeps
# every accepted risk word for word, and the offer can be declined.
assert any(l.startswith('fitcheck\tmasterplan.md:') for l in again.splitlines()),again
fit=[w for _,k,w in (l.split('\t',2) for l in again.splitlines() if l.startswith('say\t')) if k=='fitcheck']
assert fit and 'word for word' in fit[0] and 'above the old one' in fit[0],again
# The rewrite's rules are in a reference the skill points at; it has to open.
assert 'references/four-paths.md' in (source/'maintain/SKILL.md').read_text()
assert (source/'maintain/references/four-paths.md').is_file()
run([sys.executable,plugin/'maintain/scripts/upgrade-check.py','--apply','fitcheck',p],code=2)
run([sys.executable,plugin/'maintain/scripts/upgrade-check.py','--decline','fitcheck',p])
assert 'declined\tfitcheck\tfitcheck\t' in check(plugin,p,1)
print('  ok: old build-path fields are offered the rewrite, which keeps accepted risks')

# The renames before the six commands are said to the person, once each,
# and a missing skill is offered with a question.
p=work/'renamed'; p.mkdir()
copy(fixture/'masterplan.md.txt',p/'masterplan.md')
put(p/'skills-lock.json',json.dumps({'version':1,'skills':{n:{'source':'gwpicard/ai-build-kit'}
    for n in [n for n in kit_names if n!='shape']+['start','build']}}))
shutil.copytree(source,p/'.agents/skills'); shutil.rmtree(p/'.agents/skills/shape')
for name in ('start','build'):
    put(p/'.agents/skills'/name/'SKILL.md','---\nname: '+name+'\n---\n')
listed=check(source,p,1)
said=[l.split('\t',2)[1:] for l in listed.splitlines() if l.startswith('say\t')]
words=' '.join(w for k,w in said if k=='renamed')
assert '/setup-ai-build-kit, not /start' in words,listed
assert 'everything /plan did' in words,listed       # shape is missing
assert '/build command has become two' in words,listed
assert sum(1 for k,_ in said if k=='renamed')==3,listed
assert any(k=='missing' and 'Shall I run it?' in w for k,w in said),listed
print('  ok: the /build, /start and /plan renames and a missing skill are said')

# A line of the person's own naming an old command, and something left as it
# is, are said once: the changelog keeps the sentence, and between monthly
# visits the recorded offer covers them.
p=work/'said-once'; p.mkdir()
copy(source/'setup-ai-build-kit/templates/masterplan.md',p/'masterplan.md')
copy(source/'setup-ai-build-kit/templates/foundation/plan-refresh.sh',p/'.agents/tools/plan-refresh.sh')
apply(source,p,'helper')
with (p/'masterplan.md').open('a') as f: f.write('\nWe run /ship before the club night.\n')
put(p/'CHANGELOG.md','Launched with /ship.\n')
(p/'.claude/skills').mkdir(parents=True)
(p/'.claude/skills/ship').symlink_to(work/'nowhere-ship')
def sayings(args):
    out=run([sys.executable,source/'maintain/scripts/upgrade-check.py',*args,p])
    return {l.split('\t',2)[1]:l.split('\t',2)[2] for l in out.splitlines() if l.startswith('say\t')}
first=sayings([])
assert {'mention','left'} <= set(first),first
assert 'We run /ship before the club night.' in first['mention'],first
version=(source/'maintain/VERSION').read_text().strip()
put(p/'.ai-build-kit-maintenance','upgrade-offered|'+version+'\n')
assert not {'mention','left'} & set(sayings([])),'repeated between monthly visits'
assert {'mention','left'} <= set(sayings(['--monthly']))
with (p/'CHANGELOG.md').open('a') as f:
    f.write('2026-10-13: '+first['mention']+' '+first['left']+'\n')
assert not {'mention','left'} & set(sayings(['--monthly'])),'repeated after the changelog named them'
print('  ok: a line already named is not named again')

# An AGENTS.md written before the line refusing to show a secret is told about
# it once; one that already has it, as founding writes it, is not.
p=work/'secrets'; p.mkdir()
copy(source/'setup-ai-build-kit/templates/masterplan.md',p/'masterplan.md')
copy(source/'setup-ai-build-kit/templates/foundation/plan-refresh.sh',p/'.agents/tools/plan-refresh.sh')
apply(source,p,'helper')
copy(source/'setup-ai-build-kit/templates/foundation/AGENTS.md',p/'AGENTS.md')
assert 'secrets' not in set(sayings([])) and 'secrets\t' not in check(source,p,0)
put(p/'AGENTS.md','# Agents\n\nNever print a secret.\n')
first=sayings([])
assert 'secrets' in first and 'Shall I?' in first['secrets'],first
put(p/'.ai-build-kit-maintenance','upgrade-offered|'+version+'\n')
assert 'secrets' not in sayings([]),'repeated between monthly visits'
put(p/'CHANGELOG.md','2026-10-14: '+first['secrets']+'\n')
assert 'secrets' not in sayings(['--monthly']),'repeated after the changelog named it'
print('  ok: an older AGENTS.md hears about the secret refusal once')

# A pointer left in a file that is not readable text is given that reason,
# not the one for a pointer inside a command.
p=work/'unreadable'; p.mkdir()
copy(source/'setup-ai-build-kit/templates/masterplan.md',p/'masterplan.md')
(p/'AGENTS.md').write_bytes(b'ok\n\xff\xfe not text\n')
pointers=[w for k,w in ((l.split('\t',2)[1],l.split('\t',2)[2]) for l in check(source,p,1).splitlines()
          if l.startswith('say\t')) if k=='pointers']
assert pointers and 'not readable text' in pointers[0] and 'break the line' not in pointers[0],pointers
print('  ok: a pointer left in an unreadable file says why')

# A project founded on v0.20.3 already has the six commands. Its update only
# renames two background skills and adds the new ones, so it must not hear the
# six-command news again, and its command list is said to name old background
# skills, not old commands. The records are the v0.20.3 templates, and the two
# renamed skill folders are the released copies, kept by the installer.
# screen-check came back under its own name, so the update replaced it.
p=work/'from-v0.20.3'; p.mkdir()
v203=root/'.agents/tests/fixtures/upgrade-v0.20.3'
copy(v203/'AGENTS.md.txt',p/'AGENTS.md'); copy(v203/'masterplan.md.txt',p/'masterplan.md')
folded=['change-triage','section-builder']
shutil.copytree(source,p/'.agents/skills')
for name in folded:
    for f in (v203/'retired-skills'/name).rglob('*.txt'):
        copy(f,p/'.agents/skills'/name/f.relative_to(v203/'retired-skills'/name).with_suffix(''))
put(p/'skills-lock.json',json.dumps({'version':1,'skills':{n:{'source':'gwpicard/ai-build-kit'} for n in kit_names+folded}}))
apply(source,p,'helper')
listed=check(source,p,1)
said=[l.split('\t',2)[1:] for l in listed.splitlines() if l.startswith('say\t')]
assert not any(k=='kit' for k,_ in said),listed
assert not any(re.search(r'/(fix|queue|sync|ship)\b',w) for _,w in said),listed
words=[w for k,w in said if k=='commands']
assert len(words)==1 and 'old commands' not in words[0],listed
assert all(n in words[0] for n in folded) and 'since renamed' in words[0],listed
assert any(k=='installer' and all(n in w for n in folded) for k,w in said),listed
assert sum(1 for l in listed.splitlines() if l.startswith('template\tAGENTS.md:'))==2,listed
for step in ('commands','template'): apply(source,p,step)
agents=(p/'AGENTS.md').read_text()
assert not any(n in agents for n in folded),agents
assert count_skills+' installed' in agents and count_background+' run in the background' in agents,agents
assert 'load `screen-check`' in agents,agents
print('  ok: a v0.20.3 project hears only that two background skills were renamed')

# The three screen lines are one passage. When the person edited one of them,
# the passage is theirs, so none of its lines is listed or rewritten.
p=work/'edited-neighbour'; p.mkdir()
copy(v203/'masterplan.md.txt',p/'masterplan.md')
text=(v203/'AGENTS.md.txt').read_text()
mine='never calls a screen accessible, compliant, or good, and we check on a phone too.'
text=text.replace('never calls a screen accessible, compliant, or good.',mine)
put(p/'AGENTS.md',text)
listed=check(source,p,1)
assert not any(l.startswith('template\tAGENTS.md:') and 'screen-rules' in l for l in listed.splitlines()),listed
apply(source,p,'template')
after=(p/'AGENTS.md').read_text()
for line in ('load `screen-check`','It reads this project\'s design rules first and',mine):
    assert line in after,(line,after)
assert '`/shape` chooses the route.' in after,after
print('  ok: a kit passage with one edited line is left whole')

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
echo
echo "upgrade-rehearsal.sh: all checks passed"
