#!/bin/bash
# Usage: dev-run.sh <command...>   (runs INSIDE the shared build lock)
# Starts the worktree dev server on :3077, runs the command, kills the server by its own PID.
cd /tank/nxeon-wt-baremetal || exit 1
nice -n 15 ionice -c3 env NODE_OPTIONS=--max-old-space-size=3072 ./node_modules/.bin/next dev -p 3077 > /root/agent-notes/bare-metal/dev.log 2>&1 &
PID=$!
for i in $(seq 1 90); do curl -s -o /dev/null http://localhost:3077/api/health && break; sleep 1; done
"$@"; RC=$?
kill $PID 2>/dev/null; sleep 2; kill -9 $PID 2>/dev/null
# next dev forks a child server; kill any child of our PID tree still on the port
P=$(ss -ltnp 2>/dev/null | awk '/:3077 /{print $NF}' | grep -o 'pid=[0-9]*' | cut -d= -f2 | head -1); [ -n "$P" ] && kill $P 2>/dev/null
exit $RC
