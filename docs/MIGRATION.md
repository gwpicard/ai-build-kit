# Migrating to a clean repository

A runbook for replacing the public repository with one whose history carries no
AI attribution, while keeping the issues, the releases, the numbering and the
web address.

Written 10 September 2026, after the history rewrite of the same day. Every step
below was rehearsed against real GitHub repositories before this was written.
Nothing here is theory except the two steps marked as unrehearsable, and those
were rehearsed on stand-ins that behaved the same way.

Read the whole document before starting. The middle of a migration is a bad
place to meet a surprise.

Not to be confused with `docs/MIGRATION-READINESS.md`, which is a record of a
different and finished move: retiring the private maintainer repository in
August 2026. It has nothing to do with this.

## Why this exists

A coding agent appended two lines to every commit message and pull request
description it wrote: a co-author trailer naming the model, and a
`Claude-Session:` trailer carrying a personal link to the session the work came
out of. Nobody noticed until the repository was already public.

The session link is the part that matters. It is a personal address on the agent
vendor's site, it opens for anyone who reads it, and a commit message has no use
for it.

## What has already been done

Do not repeat these. They are finished.

- The 33 commits on `main` were rewritten and force-pushed. Nineteen of them
  carried attribution. The file contents did not change at all: the tree of the
  rewritten `main` is identical to the tree it replaced.
- The four tags that moved with them, v0.11.0 through v0.13.0, were force-pushed.
  The twelve older tags never carried attribution and were untouched.
- Thirteen pull request descriptions were cleaned through the REST API.
- Issues, comments and all seventeen release notes were checked and were already
  clean.
- A hook and a validator rule now stop the lines coming back. See the
  Attribution section of the root `AGENTS.md`.

## What is left, and why a migration is the only way to reach it

GitHub creates a permanent reference for every pull request ever opened, and
those references still point at the original branch commits. Because later
branches were cut from the old `main`, that chain drags most of the old history
along with it.

**Thirty-five commits still carry attribution** and are still served. They are
reachable from each merged pull request's Commits tab, and by their address.

Those references cannot be rewritten. Git refuses a push to them and there is no
route through the API. They are deliberately immutable, so that a merged pull
request's record cannot be changed underneath a reviewer.

That single fact is why there is no smaller fix. The two ways out are asking
GitHub Support to purge them, which depends on somebody else's tooling and
judgement, or replacing the repository, which is this document.

## What the migration achieves, and what it costs

It keeps the web address, so every existing link, badge and install command
keeps working. It keeps the issues with their numbers, the labels, the releases,
the release downloads and the settings. The old repository survives, renamed and
private, so nothing is destroyed.

It costs the following, and there is no way to avoid any of them.

- **Three stars.** The new repository starts at zero. The archive keeps them but
  nobody can see a private repository's stars.
- **The repository's age.** The created date resets from 7 August 2026 to
  whenever you run this.
- **Every issue and comment timestamp.** They all show the day you run it. The
  real date is written into the text of each one instead.
- **Release dates.** The API gives no way to backdate a release. Tag dates
  survive, because those come from the commits.
- **Pull requests as pull requests.** Seventeen of them become closed issues
  holding their title, description and comments. The prose survives and stays
  searchable. The diffs and the review threads do not.
- **Traffic and insight history.**

## What happens to people who installed the kit

This is the part that matters most, so it was checked rather than assumed.

Claude Code records a marketplace by its path, not by any internal identity of
the repository. The local record reads `"source": "github"` with
`"repo": "gwpicard/ai-build-kit"`. The migration keeps that path, so the record
stays correct and nobody has to edit anything on their machine.

The marketplace is kept as an ordinary git clone whose origin is the same web
address, and an install records the commit it came from. The new repository is
pushed from the same local clone the rewrite happened in, so its commits are the
same commits with the same addresses. Nothing about the git side changes.

The install and update commands in `README.md` keep working, unchanged:

```
claude plugin marketplace add gwpicard/ai-build-kit
claude plugin install ai-build-kit@ai-build-kit --scope local
```

and `claude plugin marketplace update ai-build-kit` still finds its source.

Release downloads are addressed by tag and file name rather than by an internal
number, so those links survive as well.

**One group is already broken, and the migration is not what broke them.** The
history rewrite gave new addresses to nineteen commits, roughly everything from
v0.11.0 onwards. An installation sitting on one of those cannot move forward,
because the commit it remembers is no longer on the branch. An installation from
v0.10.0 or earlier is unaffected: those commits were never rewritten and are
still exactly where they were.

Anyone stuck that way fixes it in two commands:

```
claude plugin marketplace remove ai-build-kit
claude plugin marketplace add gwpicard/ai-build-kit
```

Say that in the release notes next time a version goes out, whether or not the
migration ever happens.

## Before you start

Set aside about ninety minutes and do not start if you cannot finish. There is a
window of a few minutes where the web address does not resolve, and leaving it
there is worse than not starting.

You need:

- The `gh` command, signed in as the repository owner. Check with
  `gh auth status`. It needs the `repo` and `workflow` permissions, which the
  current sign-in has.
- A local clone whose `main` matches the public one, with nothing uncommitted.
- **The work you want in the new repository has to be on `main` first.** Step 3
  builds the new repository by pushing `main`, so a branch that is not merged is
  a branch that does not exist there. Two were outstanding on 10 September:
  `keep-attribution-out-of-the-record`, holding the hook and the validator rule
  that stop the trailers coming back, and `migration-plan`, holding this
  document and the scripts it runs. Merge them, or push them separately after
  step 3, or accept losing them. Check what is outstanding with
  `git branch --no-merged main`.
- The saved social preview image. There is a copy at
  `~/ai-build-kit-backups/social-preview.png`, 1280 by 640.
- The full backup of the pre-rewrite history, at
  `~/ai-build-kit-backups/`, in case anything needs reading later.

## The facts this was written against

Check these still hold before you start. If any number has moved, that is fine,
but the export in step 1 is what the migration actually uses, so trust it over
this list.

| Thing | Count on 10 September 2026 |
| --- | --- |
| Numbered items, issues and pull requests together | 37, with no gaps |
| Pull requests, all merged | 17 |
| Issues, of which 14 open | 20 |
| Comments | 41 |
| Labels | 25 |
| Releases, one of them a draft | 17 |
| Release download files | 4 |
| Sub-issue links | issue 9 is the parent of 6, 7 and 8 |
| Stars, forks | 3, 0 |
| Secrets, environments, webhooks, deploy keys, milestones | none |

Two of those items were written by somebody else. **Issue 32 and its one comment
were written by KasperHonore.** The port marks them as theirs rather than
letting them appear under your name. Tell them the migration happened, because
their contribution moves to a new record.

## The tools

All four live in `.agents/migration/` and are maintainer-only. None ships,
because none appears in `release-manifest.txt`.

| File | What it does |
| --- | --- |
| `export.sh` | Reads issues, comments, labels, releases, sub-issue links and settings out of the old repository. Read-only. Stops if it finds a gap in the numbering or any attribution text. |
| `port.py` | Recreates all of that in the new repository, in number order. Stops dead if any item lands on the wrong number. |
| `port-settings.sh` | Release download files, merge settings, description, topics, branch ruleset. |
| `verify-port.sh` | Reads the new repository back and compares it against the old one, number by number. |

## The steps

Names used below: the live repository is `gwpicard/ai-build-kit`, the archive
will be `gwpicard/ai-build-kit-archive`, and the replacement is built as
`gwpicard/ai-build-kit-next` before it takes the real name.

### 1. Export, fresh

```
cd /mnt/c/Users/GUP/Documents/ai-build-kit
bash .agents/migration/export.sh gwpicard/ai-build-kit ~/ai-build-kit-backups/export
```

**Expected:** a summary listing the counts, then `gaps : none` and `clean`.

Do not reuse an older export. An issue opened or a comment added since the
export is one that does not survive, and an issue added in the middle shifts
every number after it. The script refuses to continue if it finds a gap.

Nothing has changed on the live repository at this point, and nothing does until
step 5.

### 2. Create the replacement, private

```
gh repo create gwpicard/ai-build-kit-next --private \
  --description "$(gh api repos/gwpicard/ai-build-kit -q .description)"
```

Private, so the port happens out of sight and a half-built repository is never
public. It goes public in step 7.

### 3. Push the clean history

```
git remote add next https://github.com/gwpicard/ai-build-kit-next.git
git push next main:main
git push next --tags
```

**Expected:** `main` and 16 tags on the new repository. Check with
`git ls-remote next | grep -c refs/tags/`, which should print 16.

### 4. Port the content

```
python3 .agents/migration/port.py \
  --export ~/ai-build-kit-backups/export --target gwpicard/ai-build-kit-next
bash .agents/migration/port-settings.sh \
  gwpicard/ai-build-kit gwpicard/ai-build-kit-next
```

This takes roughly five minutes. It pauses a second between writes on purpose,
to stay under GitHub's limit on how fast an account may create things.

**Expected:** every number from 1 to 37 printed in order, then the sub-issue
links, then the releases, then the settings and the four downloads.

**The ruleset step will fail here**, saying the feature needs GitHub Pro or a
public repository. That is correct and expected. The repository is still
private. The ruleset is created in step 8, after it is public.

**If the port stops with `STOP: created number N where M was expected`:** delete
`gwpicard/ai-build-kit-next` entirely and start again from step 2. Do not try to
repair it. Numbers cannot be reassigned, so everything after the mistake is
wrong and there is no way back except starting over. Nothing on the live
repository has been touched, so this costs you time and nothing else.

Now verify, before anything irreversible:

```
bash .agents/migration/verify-port.sh gwpicard/ai-build-kit gwpicard/ai-build-kit-next
```

**Expected:** nine `ok` lines and `everything matched`. If any line says FAIL,
stop. Delete the new repository, work out why, and start again from step 2.

Everything up to here is free. The live repository has not changed and you can
walk away at any point by deleting `ai-build-kit-next`.

### 5. Rename the live repository aside

This is the first step that changes the live repository. From here until step 7
lands, the public web address does not resolve, so run 5, 6 and 7 back to back.

```
gh api -X PATCH repos/gwpicard/ai-build-kit -f name=ai-build-kit-archive
```

**Expected:** it prints the new full name.

**If it refuses** with `a conflicting repository operation is still in
progress`, wait about ten seconds and run it again. This happens when another
change to the repository has not settled. It is not a failure.

### 6. Take the name over

```
gh api -X PATCH repos/gwpicard/ai-build-kit-next -f name=ai-build-kit
```

Renaming into a name currently held by a redirect works, and the redirect gives
way. This was rehearsed.

**If it refuses** with `name already exists on this account`, the previous
rename has not settled. Wait ten seconds and run it again, and keep trying. The
name is free. GitHub is catching up.

### 7. Make it public

```
gh api -X PATCH repos/gwpicard/ai-build-kit -F private=false
```

**Expected:** within about ten seconds,
`https://github.com/gwpicard/ai-build-kit` serves the new repository. Check with:

```
curl -s -o /dev/null -w "%{http_code}\n" https://github.com/gwpicard/ai-build-kit
```

It should print 200. If it prints 404, wait ten seconds and try again before
worrying. GitHub serves repository pages from a cache that lags a change by up
to about ten seconds, in both directions.

The web address is working again. Nothing after this point is urgent.

### 8. Make the archive private

**This is the step that ends the exposure**, and it is the one step nobody may
skip. All 35 attributed commits and every pull request reference stop being
publicly reachable the moment it lands.

```
gh api -X PATCH repos/gwpicard/ai-build-kit-archive -F private=true
```

Check it, from a signed-out browser or with:

```
curl -s -o /dev/null -w "%{http_code}\n" https://github.com/gwpicard/ai-build-kit-archive
```

It should print 404. Allow the same ten seconds of cache lag before believing a
200.

**Archiving is not the same as making it private, and archiving alone fixes
nothing.** GitHub's archive setting makes a repository read-only. An archived
public repository is still fully public, and every one of those commits stays
readable by anyone. Private is the setting that matters. Archive it as well if
you like the label, but only after it is private.

Until this step lands, the old commits are still public under the archive name.
That window is a few minutes, and they had been public for weeks already, which
is why it is worth trading for a web address that comes back in seconds instead
of minutes.

### 9. Create the branch ruleset

The ruleset that failed during the port will work now the repository is public:

```
bash .agents/migration/port-settings.sh gwpicard/ai-build-kit gwpicard/ai-build-kit
```

Run against itself, this reapplies the settings harmlessly and creates the
ruleset. **Expected:** `ruleset created, enforcement active`.

The ruleset protects the default branch with four rules: no deletion, no
force-push, changes through a pull request, and two required checks named
`source-kit-validation` and `rehearsal`.

### 10. Final verification

```
bash .agents/migration/verify-port.sh gwpicard/ai-build-kit-archive gwpicard/ai-build-kit
git remote set-url origin https://github.com/gwpicard/ai-build-kit.git
git fetch origin && git status
```

Then check by hand that the old attributed commits are gone. Take any address
from the list the export wrote and open it while signed out, or in a private
browser window. It should not be found.

## What only you can do

The migration cannot finish without these, and none of them can be done from a
command line.

1. **Upload the social preview image.** Settings, then General, then Social
   preview. The file is at `~/ai-build-kit-backups/social-preview.png`. Until
   you do this, every link shared to the repository shows GitHub's generic card
   instead of yours.
2. **Tell KasperHonore.** Their issue and comment now live on a new record.
3. **Star your own repository**, if you want the count not to read zero.
4. **Check the plugin route really installs.** The web address is unchanged so
   it should, and the section above says why, but type it once and watch it
   work rather than trusting the reasoning:

   ```
   claude plugin marketplace remove ai-build-kit
   claude plugin marketplace add gwpicard/ai-build-kit
   claude plugin marketplace list
   ```

   The last command should show the marketplace pointing at
   `gwpicard/ai-build-kit`. This is the one check worth doing before you tell
   anybody the migration is finished.
5. **Tell anyone with a clone to clone again.** Their copy has the old history
   and will not merge cleanly.
6. **Decide what happens to the archive.** It can sit there privately forever at
   no cost. Do not make it public again.

## If something goes wrong

The migration is reversible up to a point, and that point is worth knowing.

| Stage | How to get back |
| --- | --- |
| Steps 1 to 4 | Delete `ai-build-kit-next`. The live repository was never touched. |
| After step 5, before step 7 | Rename the archive back to `ai-build-kit` and, if you already made it private, make it public again. You are exactly where you started. |
| After step 7 | Rename the new repository aside, rename the archive back, and make it public. The archive still holds everything. |
| After you delete the archive | Nothing. So do not delete the archive. |

The full pre-rewrite history is in a bundle at `~/ai-build-kit-backups/`. That
is the last line of defence and it does not expire.

## Risks that remain

Said plainly rather than buried, because a runbook that claims certainty is a
runbook that gets trusted at the wrong moment.

- **The export goes stale.** This is the likeliest problem and step 1 exists to
  prevent it. An issue opened between the export and the port is lost, and one
  opened in the middle of the range shifts every number after it. Export
  immediately before porting, and do not answer an issue while the migration is
  running.
- **A rate limit mid-run.** GitHub limits how fast an account creates things.
  The port pauses a second between writes, which was enough across two full
  rehearsals, but a limit hit mid-run leaves a half-built repository. The fix is
  the same as any other failure: delete it and start again.
- **GitHub changing its behaviour.** Every step here was proved against GitHub
  as it behaved on 10 September 2026. The longer this document sits unused, the
  more likely something has moved. Re-read the failure messages rather than
  assuming a step is broken.
- **Two steps could not be rehearsed against the real repository**: making the
  live repository private, and the real name takeover. Both were rehearsed on
  disposable repositories that behaved as described, including the cache lag and
  the transient rename refusal.
- **Copies outside GitHub.** Software Heritage, which mirrors public
  repositories, has not archived this one, and that was the main risk. GH
  Archive records the public event stream, including commit messages, into
  permanently public datasets. If any push happened while the repository was
  public, those messages are likely in it and nobody can remove them. It is an
  obscure corner queried by researchers rather than something a visitor meets,
  but it is beyond reach and it is honest to say so.

## Deciding not to do it

Not migrating is a reasonable choice, and it is worth writing down what you are
accepting if you take it.

The main branch, every clone, every tag and every release are already clean. A
person browsing the repository normally sees nothing. What stays is the commit
list inside each merged pull request, and any saved address of an old commit.
Someone would have to open a merged pull request's Commits tab, which is an
ordinary thing to do but not the first thing anybody does.

Weigh that against three stars, the repository's age, and seventeen pull requests
becoming issues. There is no obviously correct answer.
