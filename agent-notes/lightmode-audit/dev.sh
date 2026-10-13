#!/bin/bash
L=/root/agent-notes/lightmode-audit/run; mkdir -p $L
cd /tank/nxeon-wt-lightmode
export DATABASE_URL="postgresql://agt_light:$(cat .agent-scratch/agtpw)@localhost:5432/nxeon_agt_light"
export AUTH_SECRET=$(cat .agent-scratch/authsecret)
export NXEON_SANDBOX=1
export NODE_OPTIONS=--max-old-space-size=3072
nohup nice -n 19 ./node_modules/.bin/next dev -p 3931 > $L/dev.log 2>&1 < /dev/null &
echo $! > $L/dev.pid
