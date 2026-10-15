# Cut the plan

Cut pieces sized for one sitting, in the order they unblock each other, each a
vertical slice through the whole tool: what the person can do or see when it is
done, its evidence, and its real dependencies. Never split one capability into
"database", "API" and "UI" pieces.

Before the first issue, run `sh scripts/found-issues.sh check` from the project
root. Exit 0 means GitHub returned the repository and its visibility. Exit 5
means the repository could not be read or `origin` is not a GitHub repository;
founding stops without changing GitHub. Exit 6 means `origin` is still the
kit's own repository: change nothing there, say so in one line, and ask for the
person's own. With one, point `origin` at it and check again. With none, save
everything else and say the pieces are created once the project has its own
repository. Exit 2 means the command could not run or its arguments were
invalid; founding stops.

Say in one line what founding is about to do on GitHub: open the pieces as
issues, replace GitHub's labels with the kit's own, and remove a pull request's
branch once it merges. Name the repository as `owner/name` and whether it is
public or private, from the `repository` and `visibility` lines, or `unknown`.
On a public repository add that the plan will be public, and that they can ask
for a private one at any point. Carry on in the same reply either way. Where
they ask to stop, open no more issues, say the ones opened stay readable, and
save everything else.

Each piece becomes an issue in the shape the `records` skill's `references/pieces.md` describes. Where
the GitHub tool is not ready, guide it now by `manual-setup.md` beside this file; there
is no file-based substitute, and a private repository works as well. Run
`sh scripts/found-issues.sh prepare` to create the kit's labels,
delete the labels GitHub made by itself (`bug`, `documentation`, `duplicate`,
`enhancement`, `good first issue`, `help wanted`, `invalid`, `question`,
`wontfix`) while no issue exists, set `delete_branch_on_merge` and turn off
squash and rebase merges, and copy the issue template. Say which ones went,
from its `removed` and `kept` lines, and that merged branches are now removed.
A label it could not remove stays and founding carries on. For `prepare`,
exit 0 means protection is set, deferred because `main` does not exist, or
unavailable under the account plan; in the plan case the output says the kit
will hold its own merges, and founding carries on. Exit 2 means protection
could not be confirmed for another reason, such as missing admin rights,
rejected settings or a network failure. Founding stops after preparation,
which may already have created labels, settings and the issue template. Exit 5
means GitHub could not be read or `origin` is not a GitHub repository; exit 6
means `origin` is the kit's own repository. In either case founding stops
without changing GitHub. Exit 2 also means the command could not run or its
arguments were invalid. If `main` does not exist yet, protection is deferred
until the first upload creates it.

Open one issue per piece, label each shaped piece `ready` or with the `needs-`
label for its open question, and link real dependencies with GitHub's
blocked-by relationship. An idea left out becomes a closed issue labelled
`parked`, with the reason. Then run `sh scripts/found-issues.sh refresh` once.

Then load the `records` skill's `references/coverage-read.md` and run the coverage read.

Where the GitHub setup cannot be finished in this session, save everything
else, and name signing in the GitHub command line tool as the one remaining
step. Never invent a file in place of the issues.
