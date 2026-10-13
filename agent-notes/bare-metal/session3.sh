#!/bin/bash
cd /tank/nxeon-wt-baremetal
NXEON_DEDICATED_OVH_MOCK=1 ./node_modules/.bin/tsx --env-file=.env .bm-seed.ts
find /root/agent-notes/bare-metal -maxdepth 1 -name "[0-3]*.png" ! -name "07-*" ! -name "08-*" -delete; rm -f /root/agent-notes/bare-metal/err-*.png
BM_COMBOS=dark-1440,light-1440 nice -n 15 node /root/agent-notes/bare-metal/shoot.mjs > /root/agent-notes/bare-metal/shoot.log 2>&1
BM_COMBOS=dark-390,light-390 nice -n 15 node /root/agent-notes/bare-metal/shoot.mjs >> /root/agent-notes/bare-metal/shoot.log 2>&1
