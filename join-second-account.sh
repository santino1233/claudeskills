#!/bin/bash
# Run once on the primary server for the second Claude account. Then start it with:  CLAUDE_CONFIG_DIR=/root/.claude-friend claude   (log in with the friend's account)
set -e; D=${1:-/root/.claude-friend}; R=/root/claudeskills
mkdir -p $D/projects/-root; ln -sfn $R/skills $D/skills; ln -sfn $R/memory $D/projects/-root/memory
[ -f /root/.claude/settings.json ] && cp -n /root/.claude/settings.json $D/settings.json || true
echo "second account ready: CLAUDE_CONFIG_DIR=$D claude   (start it from /root so the memory path matches)"
