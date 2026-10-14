# Shared part: sign-in settings on hosted Supabase

Every recipe whose sign-in lives in a hosted Supabase project links this part.
The launch review reads these settings itself before it asks the person about
any of them.

How it works: Supabase answers a project's sign-in settings to anyone holding its public key, which the tool already sends to the browser. The script reads them with that key, the publishable or the older anon one, from the project's own `.env.local`, and nothing else: never the service role key or a secret key. It prints one plain line for each setting the review needs: whether a new account has to confirm its email address, whether new accounts can be made, and which sign-in methods are on. The list of addresses sign-in may send a person back to is not in that answer, so the kit asks the person to look at it under Authentication, then URL Configuration, and says the public key cannot read it.
How it is checked: Supabase answers 200 with the settings, sign-up matches the masterplan's `Access:` line, and the kit asks the person about none of the settings that answer holds.
Script: scripts/settings.sh
Who runs it: the kit
