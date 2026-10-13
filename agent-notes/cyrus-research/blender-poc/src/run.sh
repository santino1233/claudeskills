#!/bin/bash
# usage: run.sh PROP.py NAME  -> sync, run in sandbox, pull sheet
set -e
D=/root/agent-notes/cyrus-research/blender-poc; H=root@178.63.94.114; W=/tank/nxeon-build/tmp/blender-poc
scp -q $D/src/$1 $D/src/harness.py $H:$W/in/ && ssh $H "chmod 644 $W/in/*"
s=$(date +%s)
ssh $H "cd $W && ./sbx.sh harness.py -- $1 $2 2>&1 | grep -E 'STATS_JSON|Error|error|Traceback|File |line [0-9]' | head -30"
echo "wall_s=$(( $(date +%s) - s ))"
mkdir -p $D/out
# $3 = space-separated view names; files become <prop>-r<N>-<view>.png
names=(${3:-3q side back}); base=${2//_/-}
i=0; for v in "${names[@]}"; do scp -q $H:$W/work/$2_v$i.png $D/$base-$v.png || true; i=$((i+1)); done
scp -q $H:$W/work/$2_sheet.png $D/$base-sheet.png || true
scp -q $H:$W/work/$2.glb $D/out/ || true
