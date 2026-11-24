#!/usr/bin/env bash
# Session profile script for Verify/Revyl web sessions against the Artex UI.
#
# Revyl runs this on its hosted runner as a web session starts (never on your
# machine). It mints an Artex admin token by calling the app's own login API and
# writes it as browser storage state, so the Verify session opens already signed
# in. Revyl never shows this script's output, so secrets stay out of logs.
#
# Requires a Revyl organization secret named ARTEX_ADMIN_PASSWORD, marked
# "readable by automated runs":
#   revyl global var set ARTEX_ADMIN_PASSWORD --readable-by-automated-runs
# It must equal the Artex instance's ARTEX_ADMIN_PASSWORD (the single "ARTEX"
# admin account's password).
set -euo pipefail

[ "${REVYL_PLATFORM:-}" = "web" ] || { echo "sign-in: web sessions only" >&2; exit 1; }
origin="${REVYL_SESSION_WEB_ORIGIN:?REVYL_SESSION_WEB_ORIGIN is not set}"

pw="$(revyl global var get ARTEX_ADMIN_PASSWORD --reveal 2>/dev/null | tail -n1)"
[ -n "$pw" ] || { echo "sign-in: org secret ARTEX_ADMIN_PASSWORD is empty or unreadable" >&2; exit 1; }

token="$(curl -fsS --max-time 60 -X POST "$origin/api/auth/login" \
  -H 'content-type: application/json' \
  --data "$(jq -n --arg p "$pw" '{username:"ARTEX",password:$p}')" | jq -er .token)"
[ -n "$token" ]

host="$(printf '%s' "$origin" | sed -E 's#^https?://##; s#/.*$##; s#:.*$##')"

# Playwright-style storage state: Artex reads artex_token from localStorage and
# its Next.js middleware reads it from the cookie, so set both.
jq -n --arg o "$origin" --arg h "$host" --arg t "$token" '{
  cookies: [ { name: "artex_token", value: $t, domain: $h, path: "/", httpOnly: false, secure: true, sameSite: "Lax" } ],
  origins: [ { origin: $o, localStorage: [ { name: "artex_token", value: $t } ] } ]
}' > "$REVYL_BROWSER_STORAGE_STATE_FILE"
