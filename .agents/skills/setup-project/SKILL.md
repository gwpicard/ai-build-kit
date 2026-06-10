---
name: setup-project
description: Stand the project foundation up once, after the masterplan exists: complete AGENTS.md, create the test harness with one passing test, commit and push. Trigger exactly once per project, on day one. Never run it again; if AGENTS.md's stack section is already filled in, setup has already happened.
---

# Set up the project

You stand up the foundation, once. If the Stack section of AGENTS.md is already filled in, stop and say setup has already run; nothing here repeats.

## The routine

1. Read masterplan.md.
2. Choose a common, well-supported stack that fits the tool, and prefer boring choices over clever ones. You will explain the choice in one plain-language sentence.
3. Complete AGENTS.md: fill in the one-line project identity at the top and the Stack section at the bottom (the stack and why, the command that runs the tool, the command that runs the tests). Touch nothing else in the file.
4. Stand up a test harness with one simple passing test, plus formatting or type checks where the stack makes that cheap.
5. Add a dated CHANGELOG.md entry recording the setup.
6. Commit everything with the message "setup", push, and remind the team to pull.
7. Tell the user, in plain steps, how to run the tool and how to run the tests, and confirm the test passes on this machine.

Hard rules: nothing in any gitignored folder is ever staged, committed, or printed. No features get built in this skill; building starts with $new-feature.
