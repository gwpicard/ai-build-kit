# Live changes and records

For secrets a check needs and any live-service change, follow `live-copy`.
Before deciding a deploy failed, read its full output or the deployment list.
Do not deploy again until the first is confirmed not live; a second deploy
replaces the rollback target.

Save records on a branch and pull request for each run using the `merge`
skill's `scripts/save-records.sh`, then its `scripts/upload-piece.py` with
`--title` naming the run and `--body-file` holding its report. Never push records to `main` or include
uncommitted work. Ask to merge the records pull request only after reporting
the run and getting a yes that names that pull request. If the host builds
every change to `main`, say the merge moves the rollback target and offer to
leave the pull request open.

When going live changes the risk record or names a risk area, record why,
its caution, and which work continues or waits.
