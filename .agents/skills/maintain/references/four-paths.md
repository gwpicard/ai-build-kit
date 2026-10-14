# Rewriting a build-path section from four paths

Load this only for the upgrade check's `fitcheck` line. It found, in the
masterplan's build-path section, a `Required controls:` line, an `Outside
help:` line, or a `Path:` of `Build with expert help` or `Professional-led`.
Those are the fields the kit used while it had four build paths. Today the
path follows what the work touches, and each sensitive area carries one
caution, as the `fit-check` skill
describes under "Write it down".

The rewrite carries the old fields across. It runs no new fit check and
decides nothing again, so nothing the person decided is lost.

1. Work out the new section before changing anything.
   - `Explore privately` and `Build and run it` keep their name.
     `Build with expert help` and `Professional-led` become `Build with care`.
   - `Outside help: none` adds nothing.
   - `Outside help: <level>, for <scope>` becomes one line under `Sensitive
     areas:`. Name the scope as one of the areas in the `fit-check` skill's
     `SKILL.md` where it plainly is one, say what in the tool touches it, use
     the help level as its caution, and mark it `not yet done` unless the
     changelog records that it happened.
   - A `Required controls` entry that protects a place in the tool, such as a
     review of who can see what, a backup, a rehearsal on a copy or a managed
     provider, becomes a line for the area it protects. Where it protects the
     area the scope already named, it joins that line.
   - A control that names no area, such as secrets kept out of code,
     destructive actions that stop for approval, or a pull request with a
     check, is a standing rule of the kit and of the save route. It leaves
     the section. Say so in the changelog line.
   - Copy `Accepted`, `Recheck when` and `Last checked` word for word,
     including an old line that says the path moved. They are history, and
     the `fit-check` skill's `references/build-path-record.md` adds accepted
     risks and never replaces them.
2. Show the section as it is, then as it would be, one above the other, and
   ask for a yes. Change nothing else in the masterplan.
3. On a yes, write the new section as part of the visit's saved change. Where
   a control or a help line matches none of the areas, keep its words on a
   line of their own under `Sensitive areas:` and say so, rather than
   guessing. The next fit check tidies it.
4. On a no, leave the section as it is and run the check with `--decline
   fitcheck`. Say that the kit's skills now look for `Sensitive areas:`, so a
   control kept in the old fields may be missed until the section is
   rewritten, and that the next monthly visit offers it again.

Record the rewrite as a dated changelog line naming the old path, the new
one, and any control that left the section. Where an old `Accepted:` line
says the path moved, the changelog line says that acceptance came before the
rename, so a later reader does not look for a path the kit no longer has.
