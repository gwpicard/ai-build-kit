#!/usr/bin/env sh
# turn-gate.sh: decide whether the next scripted turn is due yet.
#
# A replay case is a fixed conversation, and until now every line of it fired by
# its position in the file. The kit asks one question at a time, so an interview
# one question longer or shorter than the script expected put a scripted answer
# against a question nobody asked. That never produced a false pass, because the
# grader refuses to credit the kit for words the person typed. It produced
# noise, and noise is what a rate cannot tell apart from a real regression.
#
# So a turn may name a precondition: the thing the kit has to have said before
# this line makes any sense. Until the kit says it, the harness sends a neutral
# filler instead of spending the scripted turn.
#
# The gate never fails a run on its own. When a precondition has waited its
# allowance it gives up and sends the line anyway, which is exactly what the
# harness did before, and says so in the transcript. A pattern written too
# narrowly costs tokens and leaves a note; it cannot turn a good run into a bad
# one. That asymmetry is the point: the gate is allowed to be wrong, as long as
# being wrong is visible and harmless.
#
# Sourced by run.sh, and driven directly by .agents/tests/gated-turns.sh with
# replies written by hand, so the rule can be checked without a model.

# How many fillers one waiting turn may spend before it gives up and fires
# anyway. Two covers an interview that ran a question or two long, and is low
# enough that a precondition nobody's reply will ever match costs little.
FILLER_CAP=${FILLER_CAP:-2}
# What the harness says when the kit asks something the script did not expect.
# Neutral and true: it answers nothing and grants nothing, so a filler can never
# hand the kit permission it did not earn from the person.
FILLER_DEFAULT=${FILLER_DEFAULT:-I am not sure about that one.}

# case_filler <file>   the case's own filler line, or the default
case_filler() {
  cf=$(awk -F': *' '/^# filler:/ { sub(/^# filler: */, ""); print; exit }' "$1")
  [ -n "$cf" ] || cf=$FILLER_DEFAULT
  printf '%s' "$cf"
}

# split_turns <file> <directory>
# Write each turn to <directory>/turn-NN.txt. Splitting into files rather than
# reading NUL-separated records keeps this POSIX shell, as the rest of the
# suite is.
split_turns() {
  awk -v dir="$2" '
    function flush() {
      if (!started) return
      count++
      name = sprintf("%s/turn-%02d.txt", dir, count)
      printf "%s\n", buffer > name
      close(name)
      if (pending != "") {
        gate = sprintf("%s/turn-%02d.when", dir, count)
        printf "%s\n", pending > gate
        close(gate)
        pending = ""
      }
      buffer = ""
      started = 0
    }
    /^# when:/ {
      line = $0
      sub(/^# when: */, "", line)
      pending = line
      next
    }
    /^#/ { next }
    /^---$/ { flush(); next }
    {
      if (started) buffer = buffer "\n" $0
      else { buffer = $0; started = 1 }
    }
    END { flush() }
  ' "$1"
}

# gate_decision <pattern> <reply-file> <fillers-already-sent> <cap>
#   send  the precondition is met, or there is none: send the scripted turn
#   wait  not met yet: send a filler and ask again next time
#   force the allowance is used up: send the scripted turn and note it
gate_decision() {
  gate_pattern=$1
  gate_reply=$2
  gate_used=$3
  gate_cap=$4

  # No precondition means the turn fires by position, as every existing case
  # still does. The eight cases written before this keep working unchanged.
  [ -n "$gate_pattern" ] || { echo send; return 0; }

  # Nothing has been said yet, so there is nothing to wait for. A precondition
  # on the opening line has no meaning: the person speaks first.
  [ -s "$gate_reply" ] || { echo send; return 0; }

  if grep -qiE -- "$gate_pattern" "$gate_reply" 2>/dev/null; then
    echo send
    return 0
  fi

  if [ "$gate_used" -ge "$gate_cap" ]; then
    echo force
    return 0
  fi

  echo wait
}
