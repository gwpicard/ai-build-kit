# The evidence run

Used by ship before anything goes live, and by build auto at the end of a run. Findings come with fresh output; no claims from memory.

1. Run the whole test suite. Everything passes, or the run stops here.
2. Walk each main journey from the masterplan as a user would, in the browser or by triggering it, and say what you saw.
3. Try to break it on purpose: the wrong password, the double click, the empty input, the enormous input, and whatever failures the stakes section's flags name.
4. Check the seams: keys out of the code and out of the browser, test data separated from real data, failures that show a message instead of a blank page.
5. Report what was tried, what held, and what did not, in plain language.
