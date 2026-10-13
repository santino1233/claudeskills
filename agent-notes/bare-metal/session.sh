#!/bin/bash
# One locked session: warm the routes, time them, shoot every step, kill the server.
cd /tank/nxeon-wt-baremetal
/root/agent-notes/bare-metal/time-routes.sh /dashboard/dedicated "/dashboard/dedicated?build=$(cat /root/agent-notes/bare-metal/.cfgid)" /dashboard/dedicated/cmuwwblpk0004hl8ibg87ndmy /dashboard/services /dedicated-servers /dedicated-servers/singapore > /root/agent-notes/bare-metal/timings-after.txt 2>&1
nice -n 15 node /root/agent-notes/bare-metal/shoot.mjs > /root/agent-notes/bare-metal/shoot.log 2>&1
nice -n 15 node /root/agent-notes/bare-metal/stripe-test.mjs > /root/agent-notes/bare-metal/stripe.log 2>&1
