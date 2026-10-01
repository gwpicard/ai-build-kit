#!/usr/bin/env sh
# Exercise the record boundary and review checkpoint without a model or account.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
python3 - "$ROOT" <<'PY'
import importlib.util, pathlib, subprocess, sys, tempfile
root=pathlib.Path(sys.argv[1]); helper=root/'.agents/skills/setup-ai-build-kit/templates/foundation/project-records.py'
spec=importlib.util.spec_from_file_location('records', helper); records=importlib.util.module_from_spec(spec); spec.loader.exec_module(records)
with tempfile.TemporaryDirectory() as temp:
    p=pathlib.Path(temp); (p/'docs').mkdir()
    legacy='Path: Explore privately\nGoes live: not hosted\nSecret location: external/file\n'
    (p/'masterplan.md').write_text(legacy)
    assert records.field(p,'Path')=='Explore privately'
    assert records.field(p,'Goes live')=='not hosted'
    assert (p/'masterplan.md').read_text()==legacy
    (p/'masterplan.md').write_text(records.MARKER+'\n# Team lending\nStaff borrow equipment; only the custodian may retire items.\n[Permissions](docs/permissions.md) owns who can retire items.\n')
    (p/'docs/working-rules.md').write_text('Path: Build and run it\n')
    (p/'docs/operations.md').write_text('Goes live: on every merge\nSecret location: external/file\n')
    (p/'docs/permissions.md').write_text('Only the custodian may retire an item.\n')
    (p/'docs/README.md').write_text('[Permissions](permissions.md): who may retire items.\n')
    assert records.field(p,'Path')=='Build and run it'
    assert records.field(p,'Goes live')=='on every merge'
    assert records.field(p,'Secret location')=='external/file'
    assert 'Staff borrow equipment' in (p/'masterplan.md').read_text()
    assert 'custodian' in (p/'docs/permissions.md').read_text()
    assert records.word_count('# Title\n[Permission rule](docs/permission-rule.md)')==3
    (p/'masterplan.md').write_text(records.MARKER+'\n# Title\n'+'word '*499)
    assert records.validate(p)==500
    (p/'masterplan.md').write_text((p/'masterplan.md').read_text()+' word')
    try: records.validate(p)
    except ValueError as e: assert '501' in str(e)
    else: raise AssertionError('501 words passed')
    (p/'masterplan.md').write_text(records.MARKER+'\n# Team lending\n[Permissions](docs/permissions.md)\n')
    subprocess.run(['git','init','-q','-b','main',str(p)],check=True)
    def git(*args): return subprocess.check_output(['git','-C',str(p),*args],text=True).strip()
    git('config','user.name','Rehearsal'); git('config','user.email','rehearsal@example.invalid')
    (p/'tool.py').write_text('first\n'); git('add','.'); git('commit','-qm','First saved state')
    head=git('rev-parse','HEAD')
    assert records.review_gap(p)['gap']
    try: records.save_review(p, head, complete=False)
    except ValueError: pass
    else: raise AssertionError('interrupted review was saved')
    records.save_review(p,head,complete=True)
    assert records.review_gap(p)['changes']==0
    git('add','.'); git('commit','-qm','Save reviewed state')
    assert records.review_gap(p)['changes']==0
    (p/'tool.py').write_text('second\n'); git('add','.'); git('commit','-qm','Change tool')
    assert records.review_gap(p)['changes']==1
    assert head in (p/'.ai-build-kit-maintenance').read_text()
    (p/'tool.py').write_text('unsaved\n')
    try: records.save_review(p,git('rev-parse','HEAD'),complete=True)
    except ValueError: pass
    else: raise AssertionError('dirty review passed')
    git('checkout','--','tool.py')
    (p/'.git/shallow').write_text(git('rev-parse','HEAD')+'\n')
    assert records.review_gap(p)['gap']
    (p/'.git/shallow').unlink()
    (p/'.ai-build-kit-maintenance').write_text('records-review|invalid\n')
    assert records.review_gap(p)['gap']
    (p/'docs/working-rules.md').unlink()
    try: records.field(p,'Path')
    except ValueError: pass
    else: raise AssertionError('missing owner silently fell back')
print('Project record and checkpoint rehearsals passed')
PY
