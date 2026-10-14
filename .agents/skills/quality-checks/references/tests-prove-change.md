# Tests that prove the change

Run `quality.py tests --base <start commit> --piece <number>` once after the
build. It runs the project's recorded test command on a throwaway copy of the
start commit and on the current project. Each machine-judged Done when line
needs a test named with its D number. A person-judged line ends `(try it)`.

`fails-before D<n>` means its test failed on the start copy. `passes-before`
means the test already passed there, so it does not prove the change.
`fails-after` means the test failed on the current code. `untested` means the
read found no matching test result or the result was skipped. A behaviour piece
also needs a `Test:` commit containing its tests. A refactor marked
`Kind: refactor` needs passing tests both before and after.

The read reports changed, non-blank code lines that no test ran. One uncovered
line is a finding to review. Exit 1 for coverage only when no changed code line
ran. Missing coverage tools or reports produce `not-checked coverage` and do
not fail a successful test read. Exit 1 also means a required test failed its
before/after check, a test was skipped, or no red commit was made. Exit 2 means
the test results could not be checked.

For a screen, a Playwright spec under its configured test folder can name a D
number in a test title. The read runs only those cases with `--grep`; without
Playwright it prints one `not-checked playwright` line.
