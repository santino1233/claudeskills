#!/bin/bash
# usage: session.sh <cmd...>  — starts dev server on 3177, waits, runs cmd, kills server by PID
cd /tank/nxeon-wt-portalfixes
set -a; . ./.env; set +a
nice -n 15 ionice -c3 env NODE_OPTIONS=--max-old-space-size=3072 ./node_modules/.bin/next dev -p 3177 > /tmp/claude-0/pb-dev.log 2>&1 &
P=$!
for i in $(seq 1 120); do curl -s -o /dev/null http://localhost:3177/api/health && break; sleep 2; done
"$@"
RC=$?
kill $P; wait $P 2>/dev/null
# next dev spawns a child; kill any process still listening on 3177 by PID
for pid in $(ss -ltnp 2>/dev/null | awk '/:3177 /{print}' | grep -o 'pid=[0-9]*' | cut -d= -f2); do kill $pid; done
exit $RC
