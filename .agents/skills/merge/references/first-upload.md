# The first upload

Founding told the person nothing would be uploaded, so the first push of the
project's code waits for their yes. Where `origin` is the kit's own
repository, `gwpicard/ai-build-kit`, push nothing: say the project still
points at the kit's repository, and ask for their own.

Run `python3` with this skill's `scripts/first-upload.py` from the project
root. Its `state` line and exit code give the answer:

- Exit 2: the repository has no branch. Nothing is online yet, and this push
  is the first upload.
- Exit 0 with a remote branch sharing history with local `main` (after `git
  fetch origin`, `git merge-base` finds a shared commit): the code is already
  online. Push without asking. The question is asked once per project.
- Branches, but none sharing history with `main`: push nothing. Name
  `owner/name`, say it holds something else, and ask what to do.
- State `no-main`, exit 9: an earlier first upload pushed a branch but did not
  create `main`. Ask for a yes to create it, then run the script with
  `--approved`. It creates `main` and pushes nothing.
- Any other exit: the listing could not be read (no `origin`, GitHub
  unreachable, or not signed in). Keep the work local with a one-line note.
  Never treat it as an empty repository.

Before asking, run the installed `setup-ai-build-kit` skill's
`scripts/workflow-upload-check.py` with python3, adding `--codex` in Codex.
Exit 1 gives the exact line to say: the person runs `gh auth refresh -h
github.com -s workflow` in their own terminal, which opens the browser once.
Save locally and leave the upload waiting for that step. Exit 0 finds no
missing permission; an SSH push or unreadable permissions stay unknown. Where
a push is refused for the `workflow` permission, run the helper with
`--refused`, give its line, and keep the work local. Never ask them to update
the credential, refresh the login for them, or retry in a Codex session
holding the old login. Their yes still stands when they
return.

Build and check the piece first; only the push waits. In the reply that
reports the piece, ask for a yes that names the upload: the repository as
`owner/name` and whether it is public or private, from the script's
`repository` and `visibility` lines, or `unknown` where it says so. Close to:
"This is the first time your project's code goes online. It goes to
owner/name, which is private. Shall I upload it?"

On a yes, run the script with `--approved` from the piece's branch. It pushes
the branch, creates `main` on GitHub at the commit the branch was cut from,
and makes it the default branch. Run the push as a command of its own, with
nothing chained to it: the project's settings refuse a chained command that
names `main`. Where a command is refused that way, run its parts one at a
time; the yes still stands. Open the pull request, and say in one clause that
GitHub now starts from their project's main copy. On a no, keep the piece on
its branch on this computer with a one-line note; the next push asks again.
In an unattended run never upload: keep the work local and note it on the
piece.
