# Shared part: sign-in settings on hosted Supabase

Every recipe whose sign-in lives in a hosted Supabase project links this part.
The launch review reads these settings itself before it asks the person about
any of them.

How it works: Supabase answers a project's sign-in settings to anyone holding its public key, which the tool already sends to the browser. The kit reads them with `curl -fsS -H "apikey: <public key>" https://<project ref>.supabase.co/auth/v1/settings`, and takes the public key and the project address from the project's own environment file. The answer is a small JSON object. `mailer_autoconfirm` says whether a new account has to confirm its email address: `false` means the dashboard's "Confirm email" setting is on, and `true` means it is off, so somebody can sign up with an address they do not own. `disable_signup` says whether new accounts can be made at all, and `external` lists the sign-in providers that are switched on. The kit uses the public key for this read and nothing else, never the service role key or a secret key. The list of addresses sign-in may send a person back to is not in this answer. The dashboard shows it under Authentication, then URL Configuration, so the kit asks the person to look at that list, and says that the public key cannot read it.
How it is checked: The command returns 200 with a JSON object that carries `mailer_autoconfirm`. The kit reports each value the review needs in one plain line, such as "new accounts have to confirm their email address", and asks the person about no setting this answer holds.
Who runs it: the kit
