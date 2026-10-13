#!/bin/bash
# support-overhaul dev server (throwaway DB nxeon_agt_support), port 3913; log/pid OUTSIDE the worktree and the shared scratchpad
L=/root/agent-notes/support-overhaul/run; mkdir -p $L
cd /tank/nxeon-wt-support
export DATABASE_URL="postgresql://agt_support:$(cat .agent-scratch/agtpw)@localhost:5432/nxeon_agt_support"
export AUTH_SECRET=$(cat .agent-scratch/authsecret)
export NODE_OPTIONS=--max-old-space-size=2560
nohup nice -n 19 ./node_modules/.bin/next dev -p 3913 > $L/dev.log 2>&1 < /dev/null &
echo $! > $L/dev.pid
