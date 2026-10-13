#!/bin/bash
# One heavy session: next dev on :3161 -> run the given node scripts -> stop dev (by its own PID).
# Always run under: flock /root/.nxeon-build.lock nice -n 15 ionice -c3 ... (see caller)
set -u
W=/tank/nxeon-wt-cyrusmods
L=$W/.cyrusmods-local
cd $W
set -a; . ./.env; set +a
export NODE_OPTIONS=--max-old-space-size=3072
nice -n 15 ionice -c3 node node_modules/next/dist/bin/next dev -p 3161 > /tank/nxeon-cyrusmods-data/dev.log 2>&1 &
DEV=$!
echo $DEV > $L/dev.pid
cleanup() { pkill -P $DEV 2>/dev/null; kill $DEV 2>/dev/null; sleep 2; kill -9 $DEV 2>/dev/null; }
trap cleanup EXIT
for i in $(seq 1 120); do grep -q "Ready in" /tank/nxeon-cyrusmods-data/dev.log && break; sleep 2; done
echo "dev ready after ~$((i*2))s"
for s in "$@"; do
  echo "== $s"
  timeout 1500 nice -n 15 node $s 2>&1 | tail -60
done
