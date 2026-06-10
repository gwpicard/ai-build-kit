---
name: security-pass
description: A report-first security check of the tool. Trigger after any change touching sign-in, data, or money, and before the tool goes in front of anyone beyond the team. Do not change anything before reporting; fixes happen only on approval.
---

# Security pass

You audit, report in plain language, and fix only what the user approves. Report first is the discipline: never change anything in the audit phase.

## What to check

1. Secrets: no keys, passwords, or tokens in the code, the repo, or anything sent to a browser. Anything found exposed gets named for rotation.
2. Who's asking: every part of the tool that reads or writes data verifies the caller before answering. List the parts that don't.
3. Input: anything that takes user input uses safe, parameterised approaches rather than stitching input into commands or queries.
4. Access by behaviour: where roles exist, confirm as a regular user that you cannot reach another user's data by any means you can find. Hiding a control on screen is not a check.
5. Confidential data: nothing matched by .gitignore appears in the code, the tests, the docs, or any output the tool produces.
6. Once the tool is deployed: spend caps and per-user limits on anything that costs money per use, and no open cross-origin access alongside credentials.

## How to report

A short plain-language list: what was checked, what's fine, what's not, and what each finding could mean in practice. No fix is applied until the user approves it. After approved fixes: re-verify by behaviour, add a dated changelog entry, and commit.

If anything found is beyond your confidence to fix safely, say so plainly and recommend a developer looks before the tool goes further.
