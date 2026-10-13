#!/bin/bash
cd /tank/nxeon-wt-baremetal
NXEON_DEDICATED_OVH_MOCK=1 ./node_modules/.bin/tsx --env-file=.env .bm-seed.ts
/root/agent-notes/bare-metal/time-routes.sh /dashboard/dedicated "/dashboard/dedicated?build=$(cat /root/agent-notes/bare-metal/.cfgid)" /dashboard/dedicated/cmuwwblpk0004hl8ibg87ndmy /dedicated-servers > /root/agent-notes/bare-metal/timings-after.txt 2>&1
BM_COMBOS=dark-1440,light-1440 nice -n 15 node /root/agent-notes/bare-metal/shoot.mjs > /root/agent-notes/bare-metal/shoot.log 2>&1
BM_COMBOS=dark-390,light-390 nice -n 15 node /root/agent-notes/bare-metal/shoot.mjs >> /root/agent-notes/bare-metal/shoot.log 2>&1
