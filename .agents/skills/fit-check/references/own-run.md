# Optional automatic work

Keep autonomy off unless the person asks. Offer these options only on Build and
run it or Build with care. On Explore privately, keep `Runs on its own:` off.

For merge, explain: “If you turn this on, a finished piece can go live before
you try it. The check and a separate review still hold it. But nobody looks at
the screen before your users do. A piece that touches <areas>, changes the
database or needs a new setting still waits for you. Say ‘stop merging on your
own’ at any time.”

For parallel work, explain: “Two pieces are built at once. Each waits for you
as usual. Before the second one merges, it is checked again against the first
one.” Explain queue and loop briefly. Record the person's words and date on
`Runs on its own:`. They add the local Claude rule themselves:
`Bash(python3 *merge.py --auto *)`. When autonomy is turned off, update the line
on the next records save and tell them to remove the local rule.
