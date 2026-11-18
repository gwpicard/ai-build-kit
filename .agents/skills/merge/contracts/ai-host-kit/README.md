# AI Host Kit host record schema

AI Host Kit owns this schema. The copy here is unchanged, and `upstream.json`
records its public repository, branch, full commit, path, Git blob and SHA-256.
The reader supports exactly version `1.0`.

Run `python3 .agents/tools/check-host-record-vendor.py` from the source checkout.
The suite runs this check. It compares the exact bytes, including whitespace,
with both fingerprints in the pin. It does not contact upstream or establish
branch reachability. When updating the copy, confirm the full commit and blob
in the upstream repository and save the unchanged schema and pin together.

The reader reports field paths and fixed explanations without printing record
values. Unknown versions require a supporting reader update. It also refuses
obvious secret assignments, private-key headers and high-entropy strings,
following Host Kit's record reader. These checks can miss disguised secrets.
Host Kit keeps secret values in a protected `.env` file outside every repository
by default; records contain declarations and references, never those values.

Schema validity describes a declaration. It proves neither that a live copy is
safe nor that backup, restore or rollback evidence is sufficient for a release.
Null checks and empty rollback targets remain missing evidence. An accepted
gap remains accepted.
