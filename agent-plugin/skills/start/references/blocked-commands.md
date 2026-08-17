# Blocked commands

Never run these. They can destroy work or cross a boundary the people on this
project cannot see coming or recover from alone.

This instruction holds in every harness. Where the harness supports a command
deny list, mirror these entries there as mechanical enforcement:

- `git reset --hard`
- `git push --force` and `git push -f`
- `git clean -f` and `git clean -fd`
- `rm -rf`

The following restrictions do not reduce to one reliable command pattern and
still apply:

- `git checkout .` and `git restore .` are allowed only inside the fix skill's
  announced reset step;
- never drop or empty a database table;
- never migrate a production database without a backup and a rehearsal on a
  copy;
- never delete or bulk-update production data without explicit approval for
  that exact action;
- never print, commit, or otherwise expose a secret;
- never disable authentication or access control to make a check pass;
- never bypass a red project check to ship or merge;
- never force or automate a merge over a required review;
- never activate flagged work before its recorded condition is met or the
  person has accepted the risk on the record;
- never withdraw, soften, or redefine a risk notice you have already given, and
  never offer your own reading of your own work as the independent review a
  build path names.

Save a checkpoint before sweeping work. If one of these actions appears
necessary, stop, explain why, and let the person decide with the reason in
front of them.
