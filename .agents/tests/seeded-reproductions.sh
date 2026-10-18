#!/usr/bin/env sh
# seeded-reproductions.sh: each seeded fault is real, each fix is recognised, and
# each healthy twin is left alone.
#
# A seeded-fault product only measures the kit if its independent reproduction
# fails on the fault, passes on a correct fix, and passes on the healthy twin.
# Otherwise a "found" or a "wrongly held" in a real run means nothing. This builds
# every starting state without the kit, runs the product's own tests and its
# reproduction against the fault, a known fix and the twin, and requires the
# answers the key promises. It needs Node, to run the TypeScript the products
# are written in, and no model.

set -eu

TESTS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SEEDED="$TESTS_DIR/seeded"

command -v python3 >/dev/null 2>&1 || { echo "COULD NOT RUN: python3 is needed" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "COULD NOT RUN: node is needed" >&2; exit 2; }
node -e 'const [a, b] = process.versions.node.split(".").map(Number); process.exit(a > 22 || (a === 22 && b >= 6) ? 0 : 1)' \
  || { echo "COULD NOT RUN: node 22.6 or newer is needed to run the products" >&2; exit 2; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

failures=0
ok() { echo "  ok: $1"; }
bad() { echo "  FAIL: $1"; failures=$((failures + 1)); }

fake_kit="$WORK/fake-kit"
mkdir -p "$fake_kit"
cat > "$fake_kit/AGENTS.md" <<'AGENTS'
# AGENTS.md

(Filled in by the setup-ai-build-kit skill: `Recipe: <recipe folder name>` or
nothing.)

## The end
AGENTS

# build <product> <variant> <name>: a starting state without the kit.
build() {
  tree="$WORK/$3"
  mkdir -p "$tree"
  cp -R "$fake_kit/." "$tree/"
  sh "$SEEDED/seed-project.sh" "$tree" "$SEEDED/products/$1" "$2" >/dev/null
  printf '%s' "$tree"
}

# repro <product> <tree> <variant>: the reproduction's exit code.
repro() {
  set +e
  sh "$SEEDED/keys/$1/repro.sh" "$2" "$3" >/dev/null 2>&1
  code=$?
  set -e
  printf '%s' "$code"
}

expect() {
  # expect <label> <expected exit> <actual exit>
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (wanted exit $2, got $3)"; fi
}

echo "Seeded-fault reproduction checks:"

# The product's own tests pass in its starting state. They are the tests the
# builder would run, and a fault that failed them would be noticed at once.
own_tests() {
  command=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["scripts"]["test"])' "$1/package.json")
  (cd "$1" && NODE_NO_WARNINGS=1 sh -c "$command" >/dev/null 2>&1)
}

for product in 03-swallowed-error 04-repeated-action 08-shared-assumption; do
  fault=$(build "$product" fault "$product-fault")
  twin=$(build "$product" twin "$product-twin")
  if own_tests "$fault"; then ok "$product: the starting state's own tests pass"; else bad "$product: the starting state's own tests fail"; fi
  if own_tests "$twin"; then ok "$product: the twin's own tests pass"; else bad "$product: the twin's own tests fail"; fi
  expect "$product: the reproduction fails on the fault" 1 "$(repro "$product" "$fault" fault)"
done

# 03 and 04: the twin's file is the fix. The twin is clean, and so is the fault
# once the twin's file replaces it.
for product in 03-swallowed-error 04-repeated-action; do
  twin=$(build "$product" twin "$product-twin2")
  expect "$product: the reproduction passes on the healthy twin" 0 "$(repro "$product" "$twin" twin)"
  fixed=$(build "$product" fault "$product-fixed")
  cp -R "$SEEDED/products/$product/twin/files/." "$fixed/"
  expect "$product: the reproduction passes once the fault is fixed" 0 "$(repro "$product" "$fixed" fault)"
done

# 08: neither starting state has the sum built, so a reference answer is laid in.
product=08-shared-assumption
exact=$(build "$product" fault "$product-exact")
cp "$SEEDED/keys/$product/reference/exact/lib/split.ts" "$exact/lib/split.ts"
expect "$product: sharing the odd pennies passes the fault's reproduction" 0 "$(repro "$product" "$exact" fault)"
expect "$product: sharing the odd pennies passes the twin's reproduction" 0 "$(repro "$product" "$exact" twin)"
naive=$(build "$product" twin "$product-naive")
cp "$SEEDED/keys/$product/reference/naive/lib/split.ts" "$naive/lib/split.ts"
expect "$product: plain rounding fails the fault's reproduction" 1 "$(repro "$product" "$naive" fault)"
expect "$product: plain rounding passes the twin's reproduction" 0 "$(repro "$product" "$naive" twin)"

# A tree with no code to load is could not run (2), never a pass or a fail.
empty="$WORK/empty"
mkdir -p "$empty"
for product in 03-swallowed-error 04-repeated-action 08-shared-assumption; do
  expect "$product: a tree with no code is could not run" 2 "$(repro "$product" "$empty" fault)"
done

if [ "$failures" -gt 0 ]; then
  echo "FAIL: $failures check(s) failed"
  exit 1
fi
echo "All seeded-fault reproduction checks passed."
