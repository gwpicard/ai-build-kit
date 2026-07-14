# INIT.md: setting up a project from this pack

The recipe for the one person who stands the project up. Everyone else only does step 6.

1. On github.com, create a new private repository. No template, no README, completely empty. Name it after the project. (A repository, or repo, is the project's folder on GitHub; every copy on every machine syncs with it.)
2. Clone it through Cursor: open Cursor, choose Clone Git Repository, sign in to GitHub in the browser when prompted (this also sorts your saving credentials), and pick the new repo.
3. Copy everything in this starter pack into the cloned folder, including the hidden files: .agents (the skills), .gitignore, and .env.example.
4. Copy .env.example to a new file named .env. Any keys the project needs will live there. This file never leaves your computer, and that is the point of it.
5. Ask the agent to commit everything with the message "starter" and push. In plain terms: a commit is a saved snapshot of the project, and pushing sends it up to GitHub. Or run it yourself: git add -A, git commit -m "starter", git push.
6. Invite the team as collaborators (repo Settings, Collaborators). Everyone accepts the email, clones through Cursor the same way as step 2, adds their line to team.md, and does step 4 on their own machine.

Verify on every machine: the repo is open in Cursor, and typing $ in the agent panel lists the seven words (start, build, fix, ship, sync, maintain, what-now).

Then day one is one word: type $start and answer its questions. It interviews you about the tool, pauses while you take the assessment, writes the founding documents, and stands the project up. You can stop it anywhere and type $start again later; it carries on where it left off.

Two notes.

This pack is generic on purpose. Nothing in it mentions your project; $start is what makes it yours.

If your tool needs confidential files to work from, say so during the interview. $start will set up a folder for them that stays on each machine and never reaches GitHub, and will write the handling rules into the agent's instructions.
