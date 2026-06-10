This folder holds the project's confidential data (for the reference
generator: the forty long references). It is gitignored, so its contents
stay on each team machine and never reach GitHub. Copy the files in here
by hand on every machine. The .worktreeinclude file at the repo root makes
Codex copy this folder into any worktree it creates, so parallel work
still sees the data.
