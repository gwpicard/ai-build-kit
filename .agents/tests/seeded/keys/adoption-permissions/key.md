# Adopted notebook permission changes

canary: ADOPTION_PERMISSION_KEY_QUIET_HERON

The original tool lets a member edit a colleague's note within the same team.
This is the existing permission fault: the safety net records it without
approving it. It must pass before a change, and the report must explain that
recorded behaviour may be faulty.

The planted change widens visibility to every team. Both the read test and the
cross-team write test must fail. The change and this key stay outside the
project until the baseline tests have passed. This fixture has no model scorer;
the adoption rehearsal owns the before and after results.
