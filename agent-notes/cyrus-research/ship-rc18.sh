#!/bin/bash
# Ship release/cyrus-rc18 end to end. OWNER RUNS THIS as root on the primary. Stops at the first failure.
#   bash /root/claudeskills/agent-notes/cyrus-research/ship-rc18.sh            # asks before production steps
#   YES=1 bash .../ship-rc18.sh                                                # no prompts
#   STOP_AFTER_STAGING=1 bash .../ship-rc18.sh                                 # backup + staging only
# Order: backup -> main fast-forward -> staging SQL -> staging deploy -> production SQL -> modbuilder image -> promote -> checks.
# Every SQL file is additive + IF NOT EXISTS (no DROP/DELETE) and runs in ONE transaction (-1, ON_ERROR_STOP).
# Rollbacks: scripts/rollback-release.sh --production | --staging ; DB dump path is printed in step 1;
#            modbuilder: re-run deploy-modbuilder.sh with the previous TAG (modbuilder:0.19).
set -euo pipefail
REL=release/cyrus-rc18
APP=/opt/nxeon
# next free tag on the build VM (0.22 was running when this was written; a fixed 0.20 would be a downgrade)
if [ -z "${TAG:-}" ]; then
  MAXN=$(ssh -o BatchMode=yes -J root@178.63.94.114 root@10.20.1.253 "docker images --format '{{.Tag}}' modbuilder | grep -E '^0\.[0-9]+\$' | cut -d. -f2 | sort -n | tail -1")
  [ -n "$MAXN" ] || { echo "cannot read the modbuilder tags from the build VM; set TAG=modbuilder:0.N yourself"; exit 1; }
  TAG="modbuilder:0.$((MAXN + 1))"
fi
SQL=(
  prisma/manual-migrations/2026-10-15-cyrus-welcome-and-guard.sql
  prisma/manual-migrations/2026-10-15-cyrus-library-publication.sql
  prisma/manual-migrations/2026-10-15-cyrus-studio-prefs.sql
  prisma/manual-migrations/2026-10-15-cyrus-analytics.sql
  prisma/manual-migration-cyrus-content.sql
)
say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ask() { [ "${YES:-0}" = 1 ] && return 0; read -r -p "$1 [y/N] " a; [ "$a" = y ] || { echo "stopped."; exit 1; }; }
dburl() { # DATABASE_URL of an env file, without Prisma's ?schema=... suffix
  grep -m1 '^DATABASE_URL=' "$1" | cut -d= -f2- | tr -d '"' | sed 's/?.*$//'
}

cd "$APP"
[ "$(id -u)" = 0 ] || { echo "run as root"; exit 1; }
[ "$(git branch --show-current)" = main ] || { echo "$APP is not on main"; exit 1; }
git diff --quiet HEAD -- || { echo "tracked files in $APP are modified; commit or resolve first"; git status --short | head; exit 1; }
git merge-base --is-ancestor main "$REL" || { echo "main is not an ancestor of $REL (diverged); stop"; exit 1; }
echo "main $(git rev-parse --short main) -> $REL $(git rev-parse --short "$REL")"

say "1/7 database backup (production + staging)"
bash scripts/backup-db.sh
LATEST=$(ls -t /tank/backup/db/nxeon-*.sql.gz | head -1)
gzip -t "$LATEST" && [ "$(stat -c %s "$LATEST")" -gt 100000 ] || { echo "backup looks wrong: $LATEST"; exit 1; }
echo "backup OK: $LATEST ($(du -h "$LATEST" | cut -f1))"

say "2/7 fast-forward main to $REL"
git merge --ff-only "$REL"

say "3/7 staging: SQL then deploy"
STG_URL=$(dburl /opt/nxeon-staging/.env)
[ -n "$STG_URL" ] || { echo "no staging DATABASE_URL"; exit 1; }
bash scripts/deploy-staging.sh main   # its schema push creates the tables staging is missing; the SQL below then runs on top (idempotent)
for f in "${SQL[@]}"; do echo "staging <- $f"; psql "$STG_URL" -v ON_ERROR_STOP=1 -1 -q -f "$APP/$f"; done
curl -fsS -o /dev/null -w "staging health: %{http_code}\n" https://staging.nxeon.cloud/ || { echo "staging not healthy; stop"; exit 1; }
echo "Look at staging now: https://staging.nxeon.cloud (Welcome step, Admin > Cyrus > Beta invites, Report a problem, status page)."
[ "${STOP_AFTER_STAGING:-0}" = 1 ] && { echo "stopping after staging as requested."; exit 0; }
ask "Staging looks good. Continue to PRODUCTION?"

say "4/7 production: SQL (backup from step 1 is the rollback)"
PRD_URL=$(dburl "$APP/.env")
[ -n "$PRD_URL" ] || { echo "no production DATABASE_URL"; exit 1; }
for f in "${SQL[@]}"; do echo "production <- $f"; psql "$PRD_URL" -v ON_ERROR_STOP=1 -1 -q -f "$APP/$f"; done

say "5/7 modbuilder image $TAG (restarts the live build service; make sure no build is mid-flight)"
ask "Deploy $TAG now?"
TAG="$TAG" bash scripts/cyrus/deploy-modbuilder.sh

say "6/7 promote production"
bash scripts/promote-production.sh

say "7/7 post-promote checks"
curl -fsS -o /dev/null -w "nxeon.cloud: %{http_code}\n" https://nxeon.cloud/
curl -fsS -o /dev/null -w "cyrus.my:    %{http_code}\n" https://cyrus.my/
bash scripts/cyrus/launch-check.sh || echo "launch-check reported items; read them above"
systemctl is-active nxeon-web nxeon-worker
echo
echo "DONE. Watch: journalctl -u nxeon-worker -f   (look for [cyrus-guard] and '[cyrus] server ... deleted')"
echo "Owner decisions still open: Free plan game slots (placeholder 1), cyrus_cost_platform_daily_cap_usd, launch switches."
