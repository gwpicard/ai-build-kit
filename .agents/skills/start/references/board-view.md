# Seeing the pieces as a board

A person building with the kit can look at their pieces as a simple board on
GitHub: one card for each build step, in columns for what is still to do and
what is done. It updates itself as steps are finished. This is only a way to
look at the same list the kit already keeps. The kit does not read the board or
write to it, and nothing depends on it existing.

## Offering it

Offer it once, at the end of founding as part of the completion report, and
again from `/what-now` for somebody who skipped it. One plain sentence is
enough: the person can see their build steps as a board on GitHub, and you will
give them the steps if they want it. Somebody who says no is not asked again in
the same breath.

## The steps to give them

When the person wants it, walk them through this in plain words. You cannot make
the board for them, because GitHub only lets a person create this view, so your
part is to guide the clicks.

1. Open the project on GitHub and click the tab named "Issues". The build steps
   live there.
2. Click "Views", then "New view".
3. Name it something like "Progress".
4. Set its layout to "Board".
5. If it asks what to split the columns by, choose whether an item is open or
   done. It may call this "Status".
6. Save the view.

The board now shows two columns: the steps still to do, and the steps that are
done. Finishing a step with `/implement` closes its issue, which moves its card to
the done column by itself. There is nothing to install and nothing to keep up to
date.

## What not to do

Do not treat the board as a second to-do list. The pieces and their labels stay
the one source of truth; the board only shows them. Do not read anything back
from the board, and do not ask the person to move cards to record work. If the
board ever looks confusing, tell them it is safe to ignore, because nothing
relies on it.
