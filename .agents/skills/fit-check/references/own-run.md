# Optional automatic work

Keep autonomy off unless the person asks.

For merge, explain: “If you turn this on, a finished piece can go live before
you try it. The check and a separate review still hold it. But nobody looks at
the screen before your users do. A piece that touches <areas>, changes the
database or needs a new setting still waits for you. Say ‘stop merging on your
own’ at any time.”

For parallel work, explain: “Two pieces are built at once. Each waits for you
as usual. Before the second one merges, it is checked again against the first
one.” Explain queue and loop briefly. Record the person's words and date on
`Runs on its own:`. No extra Claude permission rule is needed for `--auto`:
the project settings ask before `--approved` merges, while the automatic route
is limited by its recorded setting and the merge script's checks. When
autonomy is turned off, update the line on the next records save.

The automatic merge route reads this line from `main`. For `merge` it must sit
on one line, start with `Runs on its own:`, name `merge`, give `decided`
and a date as `YYYY-MM-DD`, and then give the person's words in double
quotes, in that order. For example:

    Runs on its own: merge, decided 2026-10-20, "merge on your own once checks pass"
