# Adopting a project that already exists

This route brings something already built (an app from an all-in-one builder,
a tool inside a chat assistant, an earlier attempt) under the kit instead of
replacing it. The danger is changing behaviour nobody ever wrote down.

## The route

1. Read before anything. Say back in plain language what the tool appears to
   do, who uses it, and what data it holds, with guesses attached.
2. Interview against reality: what it should do, next to what it does. Each
   gap becomes a piece (it should do X and does not) or a recorded wart (it
   does Y, which is wrong, but people rely on it for now).
3. Run the full fit check. A tool with outside users or real data arrives with
   the risk areas that reflect it.
4. Write the masterplan for the present, warts included: "Uploads over 10MB
   fail silently" belongs there if that is what it does today.
5. Pin down before changing. Code that is going to change gets tests that
   record what it does today, right or wrong. Leave the rest untouched.
6. Cut the plan from the gaps, then stand up what is missing around the code:
   the documents, the branch flow, the hosting split. From here, work runs
   through /shape and /implement as normal.

## The one hard rule

Never rewrite or tidy old code that has no tests on it, however messy. Pin it
down first, or leave it alone.

## Classify existing behaviour

Each observed behaviour is one of: promised and should remain; accidental but
relied on; broken and safe to fix; unknown and needs evidence; risky and needs
the fit check again.

## The smallest trustworthy surface

Do not test the whole project. Start with the next area to change, data
boundaries, permissions, outside integrations, behaviour people rely on, and
the manual fallback.

Clean up structure only where a current change is blocked by it, repeated bugs
point at the same place, the change can be verified through existing
behaviour, and no risk area's caution forbids it.

## What to tell the person

Their earlier build proved the idea and taught them what the tool should be.
Adopting it is what graduating looks like, and nothing requires starting over.
