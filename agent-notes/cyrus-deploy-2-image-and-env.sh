#!/bin/bash
# Cyrus owner-test deploy, PART 2: build-service image on VM 88001 + env + restarts (docs/CYRUS-TEST-DEPLOY.md steps 4-5).
# Run AFTER part 1 is healthy. Public switches stay OFF; only preview accounts (nicholas.sj.albanese@gmail.com) reach Cyrus.
set -euo pipefail
cd /opt/nxeon
say() { printf '\n== %s\n' "$*"; }

say "preflight"
curl -s -o /dev/null -w 'nxeon.cloud -> %{http_code}\n' https://nxeon.cloud/
bash scripts/cyrus/smoke-readonly.sh migrations || { echo "part 1 not clean: STOP"; exit 1; }
ls /tank/cyrus-managed/nxeon-pack-loader/NxeonPackLoader-0.1.0.jar >/dev/null
ss -ltn | grep -q ':47380 ' && { echo "port 47380 is in use: STOP"; exit 1; } || true
read -r -p "Rebuild the build service image on VM 88001 (it refuses if a build is running, rolls itself back on failure) and set env + restart worker and web? Type yes: " A; [ "$A" = yes ] || exit 1

say "4. build-service image on VM 88001"
bash scripts/cyrus/deploy-modbuilder.sh --list | tail -3
TAG=modbuilder:0.6 bash scripts/cyrus/deploy-modbuilder.sh
bash scripts/cyrus/smoke-readonly.sh service

say "5. environment (secrets generated now, never committed)"
TOK=$(openssl rand -hex 24)
cp /opt/nxeon/.env /root/nxeon.env.bak-$(date +%s)
cat >> /opt/nxeon/.env <<EOF2
# --- Cyrus owner test (docs/CYRUS-TEST-DEPLOY.md) ---
CYRUS_PACK_STORE=local
CYRUS_PACK_LOCAL_DIR=/tank/cyrus-packs
CYRUS_PACK_PUBLIC_BASE=https://cyrus.my/packs
CYRUS_MANAGED_PLUGIN_DIR=/tank/cyrus-managed
CYRUS_SOUND_RENDER=relay
CYRUS_SOUND_RELAY_URL=http://127.0.0.1:47380
CYRUS_SOUND_RELAY_TOKEN=$TOK
CYRUS_DESIGNER=1
CYRUS_ITEM_STATES=1
CYRUS_TESTFLIGHT_GATE=1
CYRUS_TESTFLIGHT_BLOCK_ON_FAIL=1
CYRUS_MANAGED_PLUGINS_REAL=1
CYRUS_DELIVERY=1
EOF2
install -d -m 755 /etc/nxeon /etc/systemd/system/nxeon-worker.service.d
install -m 600 /dev/null /etc/nxeon/cyrus-worker.env
printf 'CYRUS_SOUND_RENDER=ssh\nCYRUS_SOUND_RELAY_PORT=47380\nCYRUS_SOUND_RELAY_TOKEN=%s\n' "$TOK" > /etc/nxeon/cyrus-worker.env
printf '[Service]\nEnvironmentFile=-/etc/nxeon/cyrus-worker.env\n' > /etc/systemd/system/nxeon-worker.service.d/cyrus-worker-env.conf
systemctl daemon-reload
systemctl restart nxeon-worker      # 120 s graceful stop; builds continue on the VM
systemctl restart nxeon-web         # a few seconds of 502
unset TOK

say "smoke"
sleep 15
bash scripts/cyrus/smoke-readonly.sh flags worker packs owner || true
bash scripts/cyrus/smoke-readonly.sh all || true
curl -s -o /dev/null -w 'nxeon.cloud -> %{http_code}\n' https://nxeon.cloud/
cat <<'EOF'

DONE part 2. Rollback: cp the newest /root/nxeon.env.bak-* back to /opt/nxeon/.env;
  rm /etc/systemd/system/nxeon-worker.service.d/cyrus-worker-env.conf /etc/nxeon/cyrus-worker.env;
  systemctl daemon-reload; systemctl restart nxeon-worker nxeon-web.
  Image: the deploy script printed the previous tag + exact rollback line.
Next (supervised test, you at the keyboard): take a backup of minecraft-f3izjh in the panel, then docs/CYRUS-TEST-DEPLOY.md section 6.
EOF
