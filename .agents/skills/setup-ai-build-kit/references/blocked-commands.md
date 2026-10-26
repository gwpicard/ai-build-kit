# Blocked commands

Follow the project's installed command guard. Do not run commands it blocks.
Other harnesses must honour the same rules. Never use `git reset --hard`, a
forced push or delete. Also, never push a change directly to `main`, skip the
project's check, or disable its Git hook. Never discard unsaved work or
read a stored login. The installed settings hold the command spellings.

The exact blocked spellings include `git checkout .`, `git restore .`,
`git clean -f`, `git reset --hard`, `git stash drop`, `rm -rf`, and shell-wrapped
forms of these; Python `shutil.rmtree`, `find -delete`, `gh auth token`,
`git credential`, and `security find-*` also protect unsaved work or stored
logins. Do not vary their spelling to get around a guard.

These boundaries need judgement and always apply:

- Never drop or empty a database table, migrate production data without a
  backup and rehearsal, or delete or bulk-update production data without
  approval for that action.
- Never expose a secret, disable access control to pass a check, or bypass a
  failing project check to ship or merge.
- Never merge without the person's approval, except through the automatic merge
  option they recorded, or force a merge past a required review.
  The `merge` skill handles approval and merge checks. A check GitHub did not
  start is not a failed check; follow that skill's recovery step.
- Never start flagged work before its recorded condition is met or the person
  accepts its risk. Do not soften a risk notice or treat your own review as
  independent.
- Never change a live service without the person's approval for that change.
  Before its confirmation box, say what will change, whether it can be undone,
  and what the person will notice.

Save a checkpoint before sweeping work. If a blocked action seems necessary,
stop and explain why so the person can decide.
