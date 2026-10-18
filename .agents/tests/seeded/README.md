# Seeded-fault products

The kit's checks prove the kit assembles and behaves. None of them tests whether
the product the kit builds is sound. A slow import, a swallowed error or a test
that shares the builder's wrong idea passes every one of them.

This folder measures that. Each product is a small project with one real fault
planted in it. The kit is asked to build a ready piece on top of the project,
without being told about the fault. The run reports three things per product:
whether the fault was found before the merge, whether the fix works, and whether
healthy work was wrongly held.

It only measures. It adds no reviewer and no gate, and it touches no skill.

## What a product holds

Each folder in `products/` has:

- `masterplan.md`: the product intent, in the kit's own format;
- `start/`: the project as the kit finds it, a small Next.js project with tests
  that run on Node's own test runner and need nothing installed;
- `piece.md`: the ready piece, as the issue the kit builds from;
- `twin/`: the healthy twin. It is the same request on a project with no fault,
  and nothing in it should be held. It holds only the files that differ.

`products/_base/` holds the files every product shares.

## The fault keys

Each product has a folder in `keys/` with the fault, an independent reproduction,
the fixes that count, and what a wrongly held twin looks like. They were written
before any run.

The keys sit apart on purpose. The runner never copies a key into the project
the kit sees, and nothing in `products/` repeats what a key says. A key that
leaked into the project would void the measure, because the kit would be
told the answer. Each key carries a canary string, and
`../seeded-scoring.sh` fails if a canary appears anywhere the kit could read.
Only `score.py` reads a key, after the run has ended.

## Running it

```sh
./run.sh --list                  # the products
REPEATS=1 ./run.sh 03            # one quick look at one product
./run.sh                         # every product, fault and twin, three runs each
```

It reuses the replay harness: the turn gate, the provider switch for Claude Code
or Codex, the stand-in GitHub command and the stand-in host tools. It honours
`KIT_SRC`, `REPEATS`, `JOBS` and `MODEL`, and the replay settings in
`../replay/README.md`. Results go to `~/.local/state/abk-seeded/results`, outside
this repository, or to `SEEDED_RESULTS`.

A run is a short conversation. The person asks for the ready piece, says yes to
the merge, and never mentions a fault, a risk or a test. If the kit warns and
asks, the person accepts once in plain words. The run stops when the stand-in
shows the pull request merged.

A model run costs tokens and varies between runs. One run per product is weak
evidence, so use repeats and read the denominators.

## How a run is scored

The score comes from the disk and from the merge decision. The scorer reads the
GitHub stand-in's state, the remote next door and the kit's replies. It runs the
key's reproduction on the code a merge would give: the remote's main branch after
a merge, or the pull request's branch while it is still open.

For a product with the fault:

| Outcome | Meaning |
|---|---|
| fixed | The reproduction passes on what would merge. |
| held | The fault is still there and the merge did not happen. |
| flagged | The fault merged, but the kit named it first. |
| missed | The fault merged and the kit said nothing about it. |
| no pull request | The kit made none, so nothing can be scored. |
| could not run | The harness broke, or the reproduction could not run. |

Found before merge is fixed, held and flagged together. "Flagged" rests on a
pattern in the key matched against the pull request and the kit's replies up to
the one that follows the first yes. It is a wording hint, so it can move a run
only between flagged and missed. A person reads the transcript before trusting it.

For the healthy twin: ok (merged and working), wrongly held (left open after the
yes), broken (merged, but the reproduction fails), no pull request, could not run.

A run the harness breaks is reported as could not run. It is never counted as a
pass, and it is left out of the denominator. The report gives counts with
denominators, never one score, and names the later reliability pieces the results
support.

## Known limits

- The reproductions test one named function in each product. A fix made
  somewhere else is real but not credited, and a renamed function makes the
  reproduction unable to run. Both are reported, never hidden.
- The products run offline on in-memory data. They stand on the Vercel recipe's
  stack, with no live service.
- Merging without a yes is a different promise. The replay cases own it.

## Checks

`../seeded-scoring.sh` proves the scoring on hand-made outcomes, the roll-up
counts and that the keys stay out of the project. `../seeded-reproductions.sh`
proves each fault is real, each fix is recognised and each twin is left alone. It
needs Node 22.6 or newer. Neither calls a model.

## Built, and still to build

Built: 3 (a broad catch that returns an empty success), 4 (a repeated request
that applies twice) and 8 (a test that shares the builder's wrong assumption).

Still to build:

1. a list-based import that slows badly with size;
2. a cache with no limit;
5. an access check that only a mock enforces;
6. one pricing rule written two ways;
7. a dependency cycle and a rule in the wrong place;
9. a growing conditional that later changes must all touch;
10. a simple correct solution that must not be rejected.
