#!/bin/bash
# Run inside heavy.sh: start ONE next dev on :3109, run "$@", then kill it by PID.
cd /opt/nxeon-wt-adminmail
set -a; . ./.env; set +a
npx next dev -p 3109 > /tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/adminmail/dev.log 2>&1 &
DEV=$!
trap 'kill $DEV 2>/dev/null; sleep 1; P=$(ss -ltnp | grep ":3109 " | grep -o "pid=[0-9]*" | cut -d= -f2); [ -n "$P" ] && kill $P' EXIT
for i in $(seq 1 120); do curl -s -o /dev/null http://localhost:3109/api/health 2>/dev/null && break; sleep 1; done
"$@"
