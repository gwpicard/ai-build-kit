# Blocked commands

Never run these. They can destroy work or cross a boundary the people on this
project cannot see coming or recover from alone.

This instruction holds in every harness. Where the harness supports a command
deny list, mirror these entries there as mechanical enforcement:

- `git reset --hard`
- `git push --force` and `git push -f`
- a direct push to `main`, in the spellings listed under "A direct push to
  `main`" below
- `git clean -f` and `git clean -fd`
- `rm -rf`

The following restrictions do not reduce to one reliable command pattern and
still apply:

- `git checkout .` and `git restore .` are allowed only inside the fix skill's
  announced reset step;
- never remove a worktree by force, with `git worktree remove --force` or
  `-f`, and never delete a worktree's folder by hand; one holding unsaved work
  is kept and named;
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
- never force or automate a merge over a required review;
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
not called as `git push`.

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

## A merge that goes live

Where the masterplan's `Goes live:` line says `on every merge`, each merge puts
the tool live. There the kit adds two rules to the ask list in the project's
Claude Code settings, so Claude Code shows its confirmation box before the
merge runs, whatever the session was told. Like a deny rule, an ask rule reads
the words of the command as written.

These merges are asked about:

- `gh pr merge`, which merges the pull request of the branch checked out
- `gh pr merge 12`
- `gh pr merge 12 --squash`
- `gh pr merge --merge 12`
- `gh pr merge 12 --auto`
- `gh api -X PUT repos/o/r/pulls/12/merge`

The second rule also asks before `gh api repos/o/r/pulls/12/merge` with no
method, which only reads whether the pull request has merged. Answer the box,
or read the same thing with `gh pr view 12`.

These commands are never asked about:

- `gh pr view 12`
- `gh pr list`
- `gh pr checks 12`
- `gh api repos/o/r/pulls/12`

These merges are not asked about, and a merge still needs a yes that names it:

- a merge made on GitHub's website
- a merge through another program, or with `gh` called another way, such as
  `/opt/homebrew/bin/gh pr merge 12`, `sh -c 'gh pr merge 12'`, or
  `gh api graphql` with a merge in its query
- any merge in a session in `bypassPermissions` mode, which skips every
  confirmation box
