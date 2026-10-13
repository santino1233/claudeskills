#!/bin/bash
# usage: pk_run.sh SPEC.json NAME(e.g. smg-r1)  -> sync, run in sandbox, pull side/3q/top + sheet + glb
set -e
D=/root/agent-notes/cyrus-research/blender-poc/partkit; H=root@178.63.94.114; W=/tank/nxeon-build/tmp/blender-poc
scp -q $D/src/pk_*.py $D/src/$1 $H:$W/in/ && ssh $H "chmod 644 $W/in/*"
s=$(date +%s); b=${2//-/_}
ssh $H "cd $W && ./sbx.sh pk_harness.py -- $1 $b 2>&1 | grep -E 'STATS_JSON|Error|error|Traceback|File |line [0-9]|Exception' | head -30"
echo "wall_s=$(( $(date +%s) - s ))"
i=0; for v in side 3q top; do scp -q $H:$W/work/${b}_v$i.png $D/$2-$v.png || true; i=$((i+1)); done
scp -q $H:$W/work/${b}_sheet.png $D/$2-sheet.png || true
mkdir -p $D/out; scp -q $H:$W/work/$b.glb $D/out/$2.glb || true
