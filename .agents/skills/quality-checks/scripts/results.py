"""The one set of results every kit check reports, and what each does to a merge.

quality.py, gate.py and merge.py keep their own exit codes and wording, and map
them onto these names where they report. A check that never started, a missing
runner or a crashed tool is NOT_RUN. It is never shown as PASS.
"""

PASS = "PASS"
FAIL = "FAIL"
NOT_RUN = "NOT_RUN"
INCONCLUSIVE = "INCONCLUSIVE"
NOT_APPLICABLE = "NOT_APPLICABLE"

RESULTS = (PASS, FAIL, NOT_RUN, INCONCLUSIVE, NOT_APPLICABLE)

# What each result does to a merge: block stops it, review asks a person to
# look before a yes, inform is reported and nothing more.
POLICY = {
    PASS: "inform",
    FAIL: "block",
    NOT_RUN: "block",
    INCONCLUSIVE: "review",
    NOT_APPLICABLE: "inform",
}


def from_exit(code):
    """The kit's exit codes: 0 passed, 1 found something, anything else did not run."""
    if code == 0:
        return PASS
    if code == 1:
        return FAIL
    return NOT_RUN


def from_github(row):
    """A row from `gh pr checks --json name,state,bucket`."""
    bucket = row.get("bucket")
    if bucket == "pass":
        return PASS
    if bucket in ("fail", "cancel"):
        return FAIL
    if bucket == "skipping":
        return NOT_APPLICABLE
    return NOT_RUN


def blocks(result):
    return POLICY.get(result, "block") == "block"
