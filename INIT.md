# INIT.md: starting a project from this pack

The recipe for the one person who stands the repository up. Everyone else only does step 5.

1. On github.com, create a new private repository. No template, no README, completely empty. Name it after the project.
2. Clone it through Cursor: open Cursor, choose Clone Git Repository, sign in to GitHub in the browser when prompted (this also sorts your push and pull credentials), and pick the new repo.
3. Copy everything in this starter pack into the cloned folder, including the hidden files: .agents (the skills), .gitignore, and .worktreeinclude.
4. Ask Codex to commit everything with the message "starter" and push. Or run it yourself: git add -A, git commit -m "starter", git push.
5. Invite the team as collaborators (repo Settings, Collaborators), everyone accepts the email, and everyone clones through Cursor the same way as step 2.

Verify on every machine: the repo is open in Cursor, and typing $ in the Codex panel lists the team skills (grill-the-plan, new-feature, and the rest).

Then the day-one sequence from WORKFLOW.md: $grill-the-plan, $split-features, copy the confidential files into data/ on each machine, $setup-project. From there it's the loop.

Two notes:

- data/ is gitignored, so its contents stay on each machine and never reach GitHub. Copy the real files in by hand on every machine. .worktreeinclude makes Codex carry the folder into any worktree it creates later.
- This pack is generic. Adapt the masterplan to whatever the project is; the skills, documents, and workflow stay the same for any internal tool.
