# Billing fallback

Use this only through `merge.py --approved`. If GitHub did not start
`project-check` because of a billing limit and no other check is blocked, tell
the person before approval that the workflow's commands will run on this
computer against a clean copy of the exact commit, with this computer's tools
standing in for setup actions, and say so again after the run. The local run
must pass. If it fails or cannot run, leave the pull request open. Any other
failed, pending or missing check blocks the merge.
