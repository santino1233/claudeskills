#!/bin/bash
# Deploy the Cyrus build service to VM 88001 (OWNER runs this on the primary).
# Since 2026-10-10 (r28) the real script lives IN THE REPO: scripts/cyrus/deploy-modbuilder.sh. Its file list is derived
# from services/modbuilder/Dockerfile (test-guarded), it records the running image for rollback, checks the new image's
# prompt version, scanner hash and registry, and refuses FLIP=yes unless /health auth = api_key.
# The old hand-kept version (missing 9 modules + 6 data files + template/) is kept as deploy-modbuilder.sh.old-2026-10-10.
#   bash /root/agent-notes/deploy-modbuilder.sh --list         what would be copied (touches nothing)
#   bash /root/agent-notes/deploy-modbuilder.sh                deploy from the tree in REPO (default: the integration worktree)
#   REPO=/path/to/merged/tree JDK25=yes API_KEY=sk-ant-... bash /root/agent-notes/deploy-modbuilder.sh
# Full order: docs/CYRUS-DEPLOY-RUNBOOK.md (step 3).
REPO=${REPO:-/tank/dev-worktrees/cyrus-r2}
SCRIPT="$REPO/scripts/cyrus/deploy-modbuilder.sh"
[ -f "$SCRIPT" ] || { echo "$SCRIPT not found: set REPO= to a tree that contains feature/cyrus-r28-wiring (or later)"; exit 1; }
exec bash "$SCRIPT" "$@"
