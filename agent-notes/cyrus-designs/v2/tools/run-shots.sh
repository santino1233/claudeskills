#!/bin/bash
# Build, sync the built v2 pages to node-2, screenshot there (capped agents slice, one browser), pull the PNGs back.
set -euo pipefail
D=/root/agent-notes/cyrus-designs/v2; H=root@178.63.94.114; RD=/tank/nxeon-build/tmp/cyrus-designs-v2
JOBS=${1:-$D/tools/jobs.json}
python3 $D/tools/build.py >/dev/null
ssh -o BatchMode=yes $H "mkdir -p $RD/pages $RD/shots $RD/tools"
rsync -a $D/*.html $H:$RD/pages/
rsync -a $D/tools/shot.js $H:$RD/tools/shot.js
scp -q "$JOBS" $H:$RD/tools/jobs-run.json
ssh -o BatchMode=yes $H "rm -f $RD/shots/*.png; systemd-run --quiet --pipe --wait --collect --slice=nxeon-build-agents.slice -p MemoryMax=2G -p CPUQuota=200% --working-directory=$RD/tools -E NODE_PATH=/tank/nxeon-build/wt/baseline-tests/node_modules -E PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright nice -n 10 timeout 300 /usr/bin/env node shot.js $RD/pages $RD/shots $RD/tools/jobs-run.json"
rsync -a $H:$RD/shots/ $D/shots/
