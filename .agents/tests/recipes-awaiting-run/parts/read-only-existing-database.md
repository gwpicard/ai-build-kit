# Shared part: read-only connection to an existing database

Every recipe that connects to an existing database links this part. Access stays on the server, and the connection string lives in the host's settings.

How it works: The tool connects from server-side code with a database user made for reading. The user and connection string stay in the host's settings and never reach the browser. The check reads the configured user's table privileges and never attempts a write.
How it is checked: The configured user can read every table in the database and has no insert, update, delete, truncate, trigger or reference privilege on any table.
Script: scripts/read-only-database.sh
Who runs it: the kit

This part never writes to the existing database. A request to write to it waits for a yes that names each change and says whether it can be undone.

Outcome: No real run yet (added 2026-10-15).
