#!/usr/bin/env bash
# Owner-run helper: set ONE allow-listed platform setting in the production DB, then print the stored value.
# usage: bash /root/agent-notes/set-setting.sh <key> <value>
# Settings are read straight from the DB on every request (no cache), so the change is effective immediately.
set -euo pipefail
key="${1:-}"; val="${2:-}"
case "$key" in
  dedicated_public_enabled|dedicated_autorenew_enabled|dedicated_autopurchase_enabled|cyrus_studio_public_enabled|cyrus_tok_live|cyrus_public_enabled|cyrus_mods_public_enabled) ;;
  *) echo "refused: '$key' is not on this helper's allow-list" >&2; exit 2 ;;
esac
case "$val" in true|false) ;; *) echo "value must be true or false" >&2; exit 2 ;; esac
URL="$(grep '^DATABASE_URL=' /opt/nxeon/.env | head -1 | cut -d= -f2- | tr -d '"')"
psql "$URL" -v ON_ERROR_STOP=1 -q -c "insert into \"Setting\"(key, value) values ('$key', '$val') on conflict (key) do update set value = excluded.value"
psql "$URL" -At -F ' = ' -c "select key, value from \"Setting\" where key = '$key'"
