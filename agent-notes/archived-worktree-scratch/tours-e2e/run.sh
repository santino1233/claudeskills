#!/bin/bash
# Runs under heavy.sh: dev server + seed + Playwright, then stops the dev server.
cd /opt/nxeon-wt-tours || exit 1
set -a; . ./.env; set +a
export NEXT_TELEMETRY_DISABLED=1
LOG=/tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/tours-dev.log
npx next dev -p 3115 > "$LOG" 2>&1 &
DEV=$!
trap 'kill $DEV 2>/dev/null; sleep 2; P=$(lsof -ti tcp:3115 2>/dev/null); [ -n "$P" ] && kill $P' EXIT
for i in $(seq 1 180); do curl -s -o /dev/null http://localhost:3115/login && break; sleep 2; done
SEED=$(npx tsx .tour-e2e/seed.ts | tail -1)
echo "SEED=$SEED"
SEED="$SEED" node .tour-e2e/e2e.mjs
