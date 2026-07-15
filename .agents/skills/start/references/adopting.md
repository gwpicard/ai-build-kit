# Adopting a project that already exists

Most people who pick up this kit already built something: an app in an
all-in-one builder, a tool inside ChatGPT, a vibe-coded project that works
until you look closely. This route brings that project under the kit
instead of replacing it. The risk is inverted from a fresh start: the
danger isn't building the wrong thing, it's changing something whose
behaviour nobody ever wrote down.

## The route, step by step

1. Read before anything. Go through the existing code, and say back in
   plain language what the tool appears to do, who appears to use it, and
   what data it appears to hold. Guesses attached, like the interview:
   correcting a wrong guess is how the real picture surfaces.

2. Interview against reality. The grilling runs as normal, with one twist:
   the questions are about what the tool is supposed to do, asked next to
   what it actually does. Every gap between the two gets written down as
   either a piece for the plan (it should do X and doesn't) or a wart to
   record (it does Y and that's wrong, but people rely on it for now).

3. The fit check runs as normal. An adopted project answers the same six
   questions; a tool that already has outside users or real data arrives
   with its flags already raised, and the stakes section says so.

4. Write the masterplan for the present that exists, warts included.
   "Uploads over 10MB fail silently" belongs in the masterplan if that is
   what the tool does today, because the masterplan describes the present,
   and the present was not built by this kit.

5. Pin down before changing. Any part of the code that is going to change
   gets pin-down tests first: tests that record what the tool does today,
   right or wrong, so tomorrow's changes cannot silently break behaviour
   someone depends on. Write them only where change is planned; the rest
   of the old code stays untouched and untested, on purpose.

6. Cut the plan from the gaps found in step 2, then stand up whatever is
   missing around the code: the documents, the branch flow, the hosting
   split if there is hosting. From here, everything runs normally: new
   work through /build, breakage through /fix, and the old parts nobody
   touches stay exactly as they were.

## The one hard rule

Never rewrite or tidy old code that has no tests on it, however messy it
looks. Messy code that works is carrying knowledge nobody wrote down.
Pin it down first, or leave it alone.

## What to tell the person

Their earlier build was the right first step, and it did its job: it
proved the idea and taught them what the tool should be. Adopting it is
what graduating looks like, and nothing from here requires starting over.
