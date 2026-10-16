#!/usr/bin/env sh
# recipe-nextjs-supabase-on-vercel.sh: run the Vercel recipe through the shape
# check, and every script it names through stand-ins for its tools. If this
# breaks, a recipe whose script mistypes a command, misses what it exists to
# catch, or says a check passed when it could not run reaches the menu, and the
# person meets the mistake on launch day.
# The recipe folder is recipes/nextjs-supabase-on-vercel.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/recipe-rehearsal.sh"

rr_init "Next.js and Supabase on Vercel recipe"
rr_locate "$ROOT/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel"
rr_shape

# Only the preview is left to a person, because Vercel puts a sign-in in front
# of it; the kit runs every other check itself.
rr_who=$(sed -n 's/^Who runs it: //p' "$RR_RECIPE/recipe.md" | sort | uniq -c | tr -s ' ' | sed 's/^ //')
rr_report "the preview is the one check a person looks at, and the kit runs the rest" \
  "$([ "$rr_who" = "$(printf '1 a person looking\n5 the kit')" ] && echo yes || echo no)"

# The first launch.
rr_case 0 good connect.sh rehearsal-app
rr_case 1 bad connect.sh rehearsal-app
rr_case 1 down connect.sh rehearsal-app
rr_case 2 good connect.sh

# Preview: built and Ready, then its health read only after the person's yes.
rr_case 0 good PREVIEW_ADDRESS=https://preview.example.test preview.sh
rr_case 0 good PREVIEW_ADDRESS=https://preview.example.test PREVIEW_HEALTH=yes preview.sh
rr_case 1 bad PREVIEW_ADDRESS=https://preview.example.test preview.sh
rr_case 1 good PREVIEW_ADDRESS=https://preview.example.test PREVIEW_HEALTH=yes LIVE_REF=previewref preview.sh
rr_case 2 good preview.sh
rr_case 2 down PREVIEW_ADDRESS=https://preview.example.test preview.sh

# Going live: main is live, and no table is open to the public key.
rr_case 0 good going-live.sh
rr_case 1 bad going-live.sh
rr_case 2 good LIVE_ADDRESS= going-live.sh

# Rollback: possible when an earlier build is listed, and never tried here.
rr_case 0 good rollback.sh
rr_said yes "from 2026-01-01"
rr_case 0 good RR_HELD=1 LIVE_ADDRESS=https://app.example.test/ rollback.sh
rr_said yes "from 2026-01-01"
rr_case 1 bad rollback.sh
rr_case 2 down rollback.sh
rr_main=$(git -C "$RR_TMP/fixture" rev-parse main)
rr_case 0 good roll-back-to.sh dpl_earlier "$rr_main"
rr_case 1 bad roll-back-to.sh dpl_earlier "$rr_main"
rr_case 2 good roll-back-to.sh
rr_case 0 good promote.sh dpl_live "$rr_main"
rr_case 1 bad promote.sh dpl_live "$rr_main"
rr_case 2 good promote.sh

# Secrets: every name on the host, no public secret, nothing committable.
rr_case 0 good secrets.sh
rr_case 1 bad secrets.sh
rr_case 2 down secrets.sh
printf 'a-value\n' > "$RR_TMP/value"
RR_STDIN="$RR_TMP/value"
rr_case 0 good add-secret.sh NEXT_PUBLIC_SUPABASE_URL
printf 'sb_secret_abcdef123456\n' > "$RR_TMP/value"
rr_case 0 good add-secret.sh SUPABASE_SECRET_KEY
rr_case 0 good add-secret.sh --replace SUPABASE_SECRET_KEY
rr_called "vercel env rm SUPABASE_SECRET_KEY production --yes"
printf 'supabase projects api-keys --project-ref ref\n' > "$RR_TMP/value"
rr_case 2 good add-secret.sh --replace SUPABASE_SECRET_KEY
if tail -n "+$((rr_mark + 1))" "$RR_CALLS" | grep -Eq '^vercel env (rm|add) '; then
  rr_fail "add-secret.sh changed Vercel before rejecting command text"
fi
printf 'not-a-supabase-key\n' > "$RR_TMP/value"
rr_case 2 good add-secret.sh --replace SUPABASE_SECRET_KEY
if tail -n "+$((rr_mark + 1))" "$RR_CALLS" | grep -Eq '^vercel env (rm|add) '; then
  rr_fail "add-secret.sh changed Vercel before rejecting a wrong key shape"
fi
printf 'token with spaces\n' > "$RR_TMP/value"
rr_case 2 good add-secret.sh API_TOKEN
printf '\n' > "$RR_TMP/value"
rr_case 2 good add-secret.sh API_KEY
printf 'sb_publishable_abcdef123456\n' > "$RR_TMP/value"
rr_case 0 good get-supabase-keys.sh standin "$RR_TMP/key-files"
rr_called "supabase projects api-keys --project-ref standin -o json"
rr_said yes "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: sb_publishable_abcdef"
rr_said yes "SUPABASE_SECRET_KEY: sb_secret_ghijkl"
[ "$(stat -f '%Lp' "$RR_TMP/key-files/NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY")" = 600 ] || rr_fail "the publishable key file is not mode 600"
[ "$(stat -f '%Lp' "$RR_TMP/key-files/SUPABASE_SECRET_KEY")" = 600 ] || rr_fail "the secret key file is not mode 600"
[ "$(cat "$RR_TMP/key-files/NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY")" = sb_publishable_abcdef123456 ] || rr_fail "the publishable key file has the wrong value"
if grep -q 'sb_publishable_abcdef123456\|sb_secret_ghijkl123456' "$RR_TMP/out"; then rr_fail "the key fetch printed a full key"; fi
rr_case 2 down get-supabase-keys.sh standin "$RR_TMP/key-files-down"
printf 'sb_secret_abcdef123456\n' > "$RR_TMP/value"
rr_case 1 bad add-secret.sh SUPABASE_SECRET_KEY
rr_case 2 good add-secret.sh
RR_STDIN=

# Logs, and the live check every later run and /maintain visit makes.
rr_case 0 good logs.sh
rr_case 1 bad logs.sh
rr_case 2 down logs.sh
rr_case 0 good live-check.sh
rr_case 1 bad live-check.sh
rr_case 0 good live-check.sh --only hold
rr_case 1 good RR_HELD=1 live-check.sh --only hold
rr_case 2 down live-check.sh --only migration
rr_case 2 good live-check.sh --only nothing

# Access: the fixture records private, so Vercel's sign-in covers every
# address and sign-up is closed. Each part that differs fails it. RR_GATE sets
# what the live address does apart from Vercel's setting, so the live read is
# tested on its own.
rr_case 0 good access.sh
rr_said no "bypass-stand-in-key"
rr_case 1 good RR_SSO=standard access.sh
rr_said yes "Hobby plan"
rr_case 1 good RR_SSO=standard RR_GATE=gated access.sh
rr_said yes "Hobby plan"
rr_case 1 good RR_GATE=open access.sh
rr_said yes "answers anyone who is not signed in"
rr_case 1 good RR_SIGNUP=open access.sh
rr_case 2 good RR_DISAGREE=1 access.sh
rr_case 2 down access.sh
rr_case 2 good LIVE_ADDRESS= access.sh
rr_case 0 good live-check.sh --only access
rr_case 1 good RR_SIGNUP=open live-check.sh --only access
# Behind the gate, health is read through Vercel only with a bypass key, or
# after the person's yes to make one.
rr_case 2 good RR_NO_BYPASS=1 going-live.sh
rr_case 0 good RR_NO_BYPASS=1 GATE_READ=yes going-live.sh
rr_called "vercel curl /api/health --deployment https://app.example.test --yes"
rr_case 2 good RR_NO_BYPASS=1 live-check.sh --only health
# Changing the setting: each way, refused, and nothing named.
rr_case 0 good RR_SSO=standard set-access.sh private
rr_case 0 good set-access.sh public
rr_case 1 bad set-access.sh private
rr_case 2 good set-access.sh
# Changing sign-up: only when the difference names enable_signup alone, and
# never with a tool too old to show the difference.
rr_case 0 good RR_SIGNUP=open set-signup.sh closed
rr_case 0 good set-signup.sh open
rr_case 0 good set-signup.sh closed
rr_said yes "Nothing needed changing"
rr_case 1 bad RR_SIGNUP=open set-signup.sh closed
rr_case 2 good RR_DIFF=extra set-signup.sh open
rr_said yes "site_url"
rr_case 2 good RR_OLD_CLI=1 set-signup.sh open
rr_case 2 good set-signup.sh
# Public, by the record: the gate off the live address and sign-up open.
printf '# Masterplan\n\n## Build path\n\nAccess: public (decided 2026-10-14)\n' > "$RR_TMP/fixture/masterplan.md"
rr_case 0 good RR_SSO=standard RR_SIGNUP=open access.sh
rr_case 1 good RR_SIGNUP=open access.sh
rr_case 1 good RR_SSO=standard access.sh
rr_case 1 good RR_SSO=standard RR_GATE=gated RR_SIGNUP=open access.sh
rr_said yes "asks for Vercel's sign-in"
rr_case 1 good settings.sh
# Open address, invitation only: the gate off the live address, sign-up closed.
printf '# Masterplan\n\n## Build path\n\nAccess: open address, invitation only (decided 2026-10-14)\n' > "$RR_TMP/fixture/masterplan.md"
rr_case 0 good RR_SSO=standard access.sh
rr_said yes "Open address, invitation only, as recorded"
rr_case 1 good access.sh
rr_case 1 good RR_SSO=standard RR_SIGNUP=open access.sh
rr_case 1 good RR_SSO=standard RR_GATE=gated access.sh
rr_case 0 good RR_SSO=standard settings.sh
# No access line: could not run, unless the person declined to record one.
printf '# Masterplan\n\nNo access line yet.\n' > "$RR_TMP/fixture/masterplan.md"
rr_case 2 good access.sh
rr_case 2 good signup.sh
rr_case 2 good live-check.sh --only access
printf 'upgrade-declined|2026-10-14|settings,access\n' > "$RR_TMP/fixture/.ai-build-kit-maintenance"
rr_case 0 good live-check.sh --only access
rr_said yes "Access: not recorded, by your choice."
rr_case 0 good access.sh
rm -f "$RR_TMP/fixture/.ai-build-kit-maintenance"
printf '# Masterplan\n\n## Build path\n\nPath: Build and run it\nAccess: private\n' > "$RR_TMP/fixture/masterplan.md"

# Sign-up and the sign-in settings, read with either public key Supabase
# issues: the publishable key a project made today shows, or the anon key.
# The probe names an email and no password, so it can never make an
# account: with anonymous sign-in on it still reaches sign-up's own handler.
# A captcha, or a probe and settings that disagree, means the kit cannot say.
rr_case 0 good signup.sh
rr_case 0 good RR_ANON=on signup.sh
rr_case 1 good RR_SIGNUP=open signup.sh
rr_case 1 good RR_SIGNUP=open RR_ANON=on signup.sh
rr_case 2 good RR_CAPTCHA=1 signup.sh
rr_said yes "captcha"
rr_case 2 good RR_DISAGREE=1 signup.sh
rr_case 2 good RR_SIGNUP=open RR_DISAGREE=1 signup.sh
rr_case 2 down signup.sh
rr_case 1 good RR_SIGNUP=open settings.sh
rr_case 2 good RR_SETTINGS=odd settings.sh
cp "$RR_TMP/fixture/.env.local" "$RR_TMP/env-publishable"
rr_case 0 good settings.sh
rr_called "curl -fsS -H apikey: sb_publishable_stand-in https://liveref.supabase.co/auth/v1/settings"
rr_case 0 good signup.sh
printf 'NEXT_PUBLIC_SUPABASE_URL=https://liveref.supabase.co\nNEXT_PUBLIC_SUPABASE_ANON_KEY=legacy-anon-stand-in\n' > "$RR_TMP/fixture/.env.local"
rr_case 0 good settings.sh
rr_called "curl -fsS -H apikey: legacy-anon-stand-in https://liveref.supabase.co/auth/v1/settings"
printf 'NEXT_PUBLIC_SUPABASE_URL=https://liveref.supabase.co\n' > "$RR_TMP/fixture/.env.local"
rr_case 2 good settings.sh
cp "$RR_TMP/env-publishable" "$RR_TMP/fixture/.env.local"

# The shared parts this recipe names.
rr_case 0 good migrate.sh
rr_case 1 bad migrate.sh
rr_case 2 down migrate.sh
rr_case 2 good DB_PASSWORD_FILE= migrate.sh
rr_case 1 bad RR_DRY=colour LC_ALL=C migrate.sh
rr_said yes "20260101000000_pinned.sql"
printf 'supabase db push --apply\n' > "$RR_TMP/bad-password"
rr_case 2 good DB_PASSWORD_FILE="$RR_TMP/bad-password" migrate.sh
rr_said yes "the password file does not look like a password"
if tail -n "+$((rr_mark + 1))" "$RR_CALLS" | grep -q '^supabase link '; then
  rr_fail "migrate.sh connected before checking the password file"
fi
rr_case 2 good RR_DRY=nameless migrate.sh
rr_case 0 good migrate.sh --apply liveref
rr_case 1 bad migrate.sh --apply liveref
# A preview project needs its own password, and the folder stays linked to
# the live project afterwards.
rr_case 2 good migrate.sh --apply previewref
printf 'preview-stand-in\n' > "$RR_TMP/preview-password"
rr_case 0 good PREVIEW_DB_PASSWORD_FILE="$RR_TMP/preview-password" migrate.sh --apply previewref
rr_report "migrate.sh leaves the folder linked to the live project after a preview apply" \
  "$([ "$(cat "$RR_TMP/work/supabase/.temp/project-ref")" = liveref ] && echo yes || echo no)"
rr_case 0 good rls.sh
rr_case 1 bad rls.sh
rr_case 0 bad rls.sh --on-record notices
rr_case 2 down rls.sh
rr_case 0 good keep-out-of-git.sh
rr_case 2 good GIT_DIR=/nonexistent keep-out-of-git.sh
rr_case 0 good container-check.sh
rr_called "docker rmi app-check"
rr_case 0 good RR_PORT_BUSY=1 container-check.sh
rr_case 1 bad container-check.sh
rr_called "docker rmi app-check"
rr_case 2 down container-check.sh
rr_case 0 good backup.sh
rr_case 1 bad backup.sh
rr_case 2 down backup.sh
rr_case 0 good PLAN=paid SUPABASE_ACCESS_TOKEN=stand-in backup.sh
rr_case 1 bad PLAN=paid SUPABASE_ACCESS_TOKEN=stand-in backup.sh
rr_case 2 good PLAN=paid backup.sh
rr_case 0 good restore.sh
rr_case 1 bad RR_RESTORE=1 restore.sh
rr_case 2 down restore.sh
rr_case 0 good settings.sh
rr_case 1 bad settings.sh
rr_case 2 down settings.sh

rr_scripts
echo
echo "recipe-nextjs-supabase-on-vercel.sh: all checks passed"
