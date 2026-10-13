#!/usr/bin/env bash
# Owner-run helper: show or hide whole product lines ("ranges") of the dedicated catalogue to customers.
# The customer pages already list only builds that are IN STOCK, so showing a whole range is safe: anything
# without stock simply doesn't appear. Reversible any time with `hide`.
#   usage: bash /root/agent-notes/dedicated-visibility.sh <show|hide> <range> [range...]
#          bash /root/agent-notes/dedicated-visibility.sh status
# ranges: kimsufi soyoustart rise advance game scale hgr
set -euo pipefail
URL="$(grep '^DATABASE_URL=' /opt/nxeon/.env | head -1 | cut -d= -f2- | tr -d '"')"
status() {
  psql "$URL" -At -F ' | ' -c "select range, count(*) as builds, count(*) filter (where visible) as visible from \"DedicatedCatalogItem\" where \"removedAt\" is null group by 1 order by min(\"monthlyCents\")"
}
cmd="${1:-status}"
if [ "$cmd" = "status" ]; then echo "range | builds | visible"; status; exit 0; fi
case "$cmd" in show) val=true ;; hide) val=false ;; *) echo "usage: $0 <show|hide> <range...> | status" >&2; exit 2 ;; esac
shift
[ "$#" -ge 1 ] || { echo "name at least one range" >&2; exit 2; }
list=""
for r in "$@"; do
  case "$r" in kimsufi|soyoustart|rise|advance|game|scale|hgr) list="$list'$r'," ;; *) echo "unknown range: $r" >&2; exit 2 ;; esac
done
list="${list%,}"
psql "$URL" -v ON_ERROR_STOP=1 -q -c "update \"DedicatedCatalogItem\" set visible = $val, \"updatedAt\" = now() where range in ($list) and \"removedAt\" is null"
echo "range | builds | visible"; status
