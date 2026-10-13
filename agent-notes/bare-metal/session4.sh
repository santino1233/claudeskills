#!/bin/bash
cd /tank/nxeon-wt-baremetal
NXEON_DEDICATED_OVH_MOCK=1 ./node_modules/.bin/tsx --env-file=.env .bm-seed.ts
BM_ONLY=server BM_COMBOS=dark-390,light-390 nice -n 15 node /root/agent-notes/bare-metal/shoot.mjs > /root/agent-notes/bare-metal/shoot4.log 2>&1
