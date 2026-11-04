"""Widen access in a throwaway notebook after its baseline run."""
from pathlib import Path
import sys

path = Path(sys.argv[1]) / 'notes.mjs'
source = path.read_text()
before = 'return notes.filter(note => note.team === user.team);'
assert source.count(before) == 1, 'the planted change no longer matches'
path.write_text(source.replace(before, 'return notes;'))
