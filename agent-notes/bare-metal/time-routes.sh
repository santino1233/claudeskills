#!/bin/bash
cd /tank/nxeon-wt-baremetal
TOK=$(./node_modules/.bin/tsx --env-file=.env .bm-token.ts cmuwwblnb0001hl8i3kskk0jt)
for u in "$@"; do
  for i in 1 2 3 4; do
    r=$(curl -s -o /dev/null -w "%{http_code} %{time_starttransfer} %{time_total} %{size_download}" -H "Cookie: nxeon_session=$TOK" "http://localhost:3077$u")
    [ $i -ge 2 ] && echo "$u run$i $r"
  done
done
