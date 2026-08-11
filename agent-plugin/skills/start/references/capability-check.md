# Capability check

Determine what the current harness and repository can actually do. Do not ask
the user to configure optional features before the project interview.

Check:

1. Repository files can be read and edited.
2. Shell commands can run.
3. Git is available and this is a repository.
4. The current project state is understood.
5. A suitable name and email label are configured for saving project versions.
6. An online repository exists, if the selected route will require sharing.
7. The current user has access to that online repository, when required.
8. Online authentication works, when uploads, pull requests, or online checks
   are required.
9. The project can be started or its runtime can be installed.
10. The test or smoke-check command can be discovered or created.
11. A browser or preview can be reached, when behaviour needs visual checking.
12. An independent-review route exists: subagent, separate session, or a
    user-opened clean chat.
13. Hooks and mechanical command blocks are recorded as optional enhancements,
    never assumed. Record whether the harness runs anything when a session
    opens. When it does not, the check-up reminder reaches the person through
    `/what-now` instead.

A remote address is never treated as proof that the current person has an
account or access to it. A previous commit's author is never treated as the
current person's identity.

Write the result into AGENTS.md under Capability profile.

For every missing capability, choose one:

- continue with a safe fallback;
- create a setup task;
- reduce automation;
- stop because the current build path requires it.

Never claim "works in this harness" merely because an adapter folder exists.
