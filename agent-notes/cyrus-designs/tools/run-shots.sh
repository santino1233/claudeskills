#!/bin/bash
# Sync the design folder to node-2 and take screenshots there (capped agents slice), then pull the PNGs back.
set -euo pipefail
D=/root/agent-notes/cyrus-designs; H=root@178.63.94.114; RD=/tank/nxeon-build/tmp/cyrus-designs
JOBS=${1:-$D/tools/jobs.json}
rsync -a --delete --exclude shots $D/ $H:$RD/
scp -q "$JOBS" $H:$RD/tools/jobs-run.json
ssh -o BatchMode=yes $H "mkdir -p $RD/shots && cd $RD/tools && systemd-run --quiet --pipe --wait --collect --slice=nxeon-build-agents.slice -p MemoryMax=2G -p CPUQuota=200% --working-directory=$RD/tools -E NODE_PATH=/tank/nxeon-build/wt/baseline-tests/node_modules -E PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright nice -n 10 timeout 300 /usr/bin/env node shot.js $RD/${SRCDIR:-src} $RD/shots $RD/tools/jobs-run.json"
rsync -a $H:$RD/shots/ $D/shots/
