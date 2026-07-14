# Blocked commands

Never run these. Each one can destroy work in a way the people on this
project cannot see coming or recover from alone. Where the agent tool
supports a command deny list, add these there too, because instructions do
not prevent execution and a mechanical guard does; this file is the standing
instruction for tools without one.

- git reset --hard (throws away unsaved work)
- git checkout . and git restore . (the same thing wearing different clothes; allowed only inside fix's reset step, announced out loud first)
- git push --force (rewrites shared history under teammates' feet)
- git clean -fd (deletes files git never saved)
- rm -rf (deletes anything, recursively, with no undo)
- any command that drops or empties a database table

Commit before anything sweeping. If one of these ever looks necessary,
stop, say why, and let the human decide with the reason in front of them.
