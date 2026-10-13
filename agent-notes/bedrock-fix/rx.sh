#!/bin/bash
cd /tank/nxeon-wt-bedrockfix; set -a; . /opt/nxeon/.env; set +a; export NXEON_DB_TARGET=nxeon
exec npx tsx /root/agent-notes/bedrock-fix/rx.ts "$@"
