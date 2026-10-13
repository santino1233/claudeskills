#!/bin/bash
# Cyrus v4 work session: runs UNDER the build lock. Type-checks, starts the mock service and the
# dev server, then holds them until /root/agent-notes/cyrus-v4/.stop exists (max 4 h). Kills by PID.
W=/tank/nxeon-wt-cyrus; N=/root/agent-notes/cyrus-v4
rm -f $N/.stop $N/.ready
cd $W
nice -n 15 ionice -c3 env NODE_OPTIONS=--max-old-space-size=3072 ./node_modules/.bin/tsc --noEmit -p tsconfig.json > $N/tsc.log 2>&1
node .cyrus-local/mocksvc.js > .cyrus-local/mock.log 2>&1 & MOCK=$!
setsid nice -n 15 ionice -c3 env NODE_OPTIONS=--max-old-space-size=3072 ./node_modules/.bin/next dev -p 3149 > .cyrus-local/dev.log 2>&1 & DEV=$!
echo "$MOCK $DEV" > $N/.pids
for i in $(seq 1 120); do grep -q "Ready in" .cyrus-local/dev.log && break; sleep 1; done
(set -a; . ./.env; set +a; TOKENS_OUT=$W/.cyrus-local/tokens.json nice ./node_modules/.bin/tsx .cyrus-local/seed.ts full > $N/seed.log 2>&1)
touch $N/.ready
for i in $(seq 1 2880); do [ -e $N/.stop ] && break; kill -0 $DEV 2>/dev/null || break; sleep 5; done
kill -- -$DEV 2>/dev/null; kill $MOCK 2>/dev/null; sleep 2; kill -9 -- -$DEV 2>/dev/null
rm -f $N/.ready
