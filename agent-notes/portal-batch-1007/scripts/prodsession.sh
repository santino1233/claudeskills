#!/bin/bash
# Runs the copied PROD build (.pb-local/prodnext) with next start on 3177 against the throwaway env.
cd /tank/nxeon-wt-portalfixes
set -a; . ./.env; set +a
mv .next .next-dev-aside 2>/dev/null
ln -sfn .pb-local/prodnext .next
NODE_ENV=production nice -n 15 ionice -c3 env NODE_OPTIONS=--max-old-space-size=3072 ./node_modules/.bin/next start -p 3177 > /tmp/claude-0/pb-prod.log 2>&1 &
P=$!
for i in $(seq 1 60); do curl -s -o /dev/null http://localhost:3177/api/health && break; sleep 2; done
"$@"; RC=$?
kill $P; wait $P 2>/dev/null
for pid in $(ss -ltnp 2>/dev/null | awk '/:3177 /' | grep -o 'pid=[0-9]*' | cut -d= -f2); do kill $pid; done
rm -f .next; mv .next-dev-aside .next 2>/dev/null
exit $RC
