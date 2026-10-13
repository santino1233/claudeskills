#!/bin/bash
# OWNER RUNS THIS ON THE PRIMARY (agents are blocked from these by the classifier). No secrets in this file.
#   bash owner-batch-rc3-prep.sh gate       # rc3 schema push (throwaway DB on node-2) + next build, on node-2
#   bash owner-batch-rc3-prep.sh settings   # token economy: refused builds free, 10 free failures (DB Settings, effective at once)
#   bash owner-batch-rc3-prep.sh budgets    # build-service per-build / per-call spend caps (VM env, restart when idle)
#   bash owner-batch-rc3-prep.sh portalenv  # CYRUS_PERF_WATCH_ACTION=notify + CYRUS_DESIGNER_BUILDS=1 in /opt/nxeon/.env (NO restart: do it with the rc3 promote)
set -euo pipefail
J=root@178.63.94.114; V=root@10.20.1.253
case "${1:-}" in
gate)
  cd /tank/dev-worktrees/cyrus-rc3
  /opt/nxeon/scripts/devhost db push
  /opt/nxeon/scripts/devhost build
  ;;
settings)
  URL="$(grep '^DATABASE_URL=' /opt/nxeon/.env | head -1 | cut -d= -f2- | tr -d '"')"
  for kv in "cyrus_tok_charge_refused=false" "cyrus_tok_free_failures=10"; do
    k=${kv%%=*}; v=${kv#*=}
    psql "$URL" -v ON_ERROR_STOP=1 -q -c "insert into \"Setting\"(key, value) values ('$k', '$v') on conflict (key) do update set value = excluded.value"
    psql "$URL" -At -F ' = ' -c "select key, value from \"Setting\" where key = '$k'"
  done
  ;;
budgets)
  ssh -o BatchMode=yes -J $J $V 'curl -s 127.0.0.1:7340/health | grep -q "\"running\":0" || { echo "A BUILD IS RUNNING: wait"; exit 1; }
    cp -a /root/modbuilder.env /root/modbuilder.env.bak-$(date +%Y%m%d-%H%M%S)
    sed -i "/^MB_BUILD_BUDGET_USD=/d;/^MB_CALL_BUDGET_USD=/d" /root/modbuilder.env
    printf "MB_BUILD_BUDGET_USD=1.5\nMB_CALL_BUDGET_USD=1.0\n" >> /root/modbuilder.env
    IMG=$(docker inspect -f "{{.Config.Image}}" modbuilder); cd /opt/modbuilder && ./run.sh "$IMG" >/dev/null
    sleep 6; curl -s 127.0.0.1:7340/health | grep -o "\"auth\":\"[a-z_]*\""; docker exec modbuilder printenv MB_BUILD_BUDGET_USD MB_CALL_BUDGET_USD'
  ;;
portalenv)
  cp -a /opt/nxeon/.env /opt/nxeon/.env.bak-$(date +%Y%m%d-%H%M%S)
  sed -i '/^CYRUS_PERF_WATCH_ACTION=/d;/^CYRUS_DESIGNER_BUILDS=/d' /opt/nxeon/.env
  printf 'CYRUS_PERF_WATCH_ACTION=notify\nCYRUS_DESIGNER_BUILDS=1\n' >> /opt/nxeon/.env
  grep -E '^CYRUS_(PERF_WATCH_ACTION|DESIGNER_BUILDS)=' /opt/nxeon/.env
  echo "written; takes effect at the next web+worker restart (the rc3 promote)"
  ;;
*) sed -n 2,7p "$0"; exit 2 ;;
esac
