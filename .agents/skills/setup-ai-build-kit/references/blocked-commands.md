# Blocked commands

Never run these. They can destroy work or cross a boundary the people on this
project cannot see coming or recover from alone.

This instruction holds in every harness. Where the harness supports a command
deny list, mirror these entries there as mechanical enforcement:

- `git reset --hard`
- a force push, in the spellings listed under "A force push and a forced
  delete" below
- a direct push to `main`, in the spellings listed under "A direct push to
  `main`" below
- `git clean -f` and `git clean -fd`
- a forced delete of a folder, such as `rm -rf`, in the spellings listed under
  "A force push and a forced delete" below

The following restrictions do not reduce to one reliable command pattern and
still apply:

- `git checkout .` and `git restore .` are allowed only inside the repair's
  announced reset step, in the `section-builder` skill's
  `references/repair.md`;
- never drop or empty a database table;
- never migrate a production database without a backup and a rehearsal on a
  copy;
- never delete or bulk-update production data without explicit approval for
  that exact action;
- never print, commit, or otherwise expose a secret;
- never disable authentication or access control to make a check pass;
- never bypass a red project check to ship or merge;
- never push a change directly to `main`; every change to `main` goes through a
  pull request, so shared work reaches it by merge rather than by a direct push.
  The one exception is the project's first upload: after the person's yes,
  and only when the remote lists no branch, `main` is created through the
  GitHub API at the commit the piece's branch was cut from, as
  section-builder's "The first upload" describes. It is never written by a
  `git push`;
- never force or automate a merge over a required review, and never merge a
  pull request the person has not said yes to; where the harness can ask
  before a merge, it does, as "A merge" below says;
- never activate flagged work before its recorded condition is met or the
  person has accepted the risk on the record;
- never withdraw, soften, or redefine a risk notice you have already given, and
  never offer your own reading of your own work as the independent review a
  build path names.

Save a checkpoint before sweeping work. If one of these actions appears
necessary, stop, explain why, and let the person decide with the reason in
front of them.

## A direct push to `main`

The Claude Code settings the kit installs refuse a push that names `main` as
the branch, with any options before or after it, in any order. A deny rule
there reads the words of the command as written. So it catches the spellings
below, and it misses a push where `main` is not written out, or where git is
not called as `git push`. It can also read a chained line as one command, so
a push of another branch with anything naming `main` later in the same line
is refused too. Run such a push on its own.

These spellings are refused:

- `git push origin main`
- `git push -u origin main`
- `git push -q origin main`
- `git push --quiet --set-upstream origin main`
- `git push --force origin main`
- `git push -f origin main`
- `git push origin main --force`
- `git push origin HEAD:main`
- `git push origin +HEAD:main`
- `git push origin HEAD:refs/heads/main`
- `git push origin +main`
- `git push origin refs/heads/main`
- `git push origin --delete main`

A branch whose name only starts with `main`, such as `main-fix`, still
pushes. The rules may also refuse a push where `main` is the value of an
option, such as `git push -o main origin feature`. That push is rare, and the
person can run it themselves.

These spellings are not refused, and the rule above still forbids them:

- `git push` or `git push origin` while `main` is checked out, since git
  chooses the branch and the command never names it
- `git push origin HEAD` while `main` is checked out
- `git push origin "main"` or `git push origin 'main'`, with quotes
- `git push origin $BRANCH`, with the branch in a variable
- `git push origin heads/main`, a shortened name
- `git push --all origin` and `git push --mirror origin`, which push every
  branch
- `git -C . push origin main` and `git -c push.default=current push origin
  main`, with an option between `git` and `push`
- `/usr/bin/git push origin main`, with git called by its full path
- `sh -c 'git push origin main'`, with the push inside another shell

## A force push and a forced delete

A force push replaces what the remote holds, so another person's work on that
branch is lost. A forced delete removes a folder with no undo. The Claude Code
settings the kit installs refuse both wherever the option sits in the command.

These force pushes and deletes are refused:

- `git push --force origin feature`
- `git push --force-with-lease origin feature`
- `git push origin feature --force`
- `git push origin feature --force-with-lease`
- `git push -f origin feature`
- `git push origin feature -f`
- `git push origin -f feature`
- `git push -fu origin feature`
- `git push origin +feature`
- `rm -rf build`, `rm -fr build`, `rm -Rf build` and `rm -fR build`
- `rm -r -f build`, `rm -f -r build`, `rm -R -f build` and `rm -f -R build`
- `rm --recursive --force build` and `rm --force --recursive build`

These are not refused, and the rule above still forbids them:

- `git push -uf origin feature`, with the force letter after another one
- `sh -c 'git push --force origin feature'`, with the push inside another
  shell
- `rm -r build`, which deletes the folder without `-f` when none of its files
  is write-protected, and `find build -delete`
- a delete from another language, such as Python's `shutil.rmtree`

When a branch needs the newest `main` after a merge conflict, merge `main` into
the branch and push it. That needs no force.

## A merge

A person decides whether to merge, always. The Claude Code settings the kit
installs ask before every merge the agent runs: `gh pr merge`, and the same
merge through `gh api`. Claude Code then shows a box, and the merge runs only
when the person clicks yes. Say in one line what the merge does just before the
box appears. A merge the person makes on GitHub's own site is not affected.

Other coding agents have no such box, so there the written rule is the only
guard.

