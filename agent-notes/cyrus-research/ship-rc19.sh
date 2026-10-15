#!/bin/bash
# Ship release/cyrus-rc19 end to end. OWNER RUNS THIS as root on the primary. Stops at the first failure.
#   bash /root/claudeskills/agent-notes/cyrus-research/ship-rc19.sh            # asks before every production step
#   YES=1 bash .../ship-rc19.sh                                                # no prompts
#   STOP_AFTER_STAGING=1 bash .../ship-rc19.sh                                 # backup + main ff + staging only
#   SKIP_STAGING_DEPLOY=1 ...                                                  # staging already runs rc19
#   SMOKE_COOKIE='__Host-cyrus_session=...' ...                                # optional: a signed-in cyrus.my session for the
#                                                                              # same-origin POST smoke (step 9); creates NO data
# Order: preconditions -> DB backup -> main fast-forward -> staging deploy + smoke -> modbuilder image -> promote production
#        (BUILD_MAX_MIN=45) -> cyrus.my nginx vhost -> cyrus.my landing publish -> post-checks.
# No manual SQL this time: rc19 adds no file under prisma/manual-migrations and no schema change (rc18's SQL is already applied).
# Rollbacks: portal  scripts/rollback-release.sh --production | --staging
#            DB      the dump printed in step 1
#            modbuilder  TAG=modbuilder:0.23 bash scripts/cyrus/deploy-modbuilder.sh   (0.23 = live when this was written)
#            nginx   the backup path printed in step 7 (restored automatically if nginx -t or the reload fails)
#            landing apps/cyrus-site/publish.sh rollback --go
# modbuilder image: the new tag carries guard-2026-10-15.1 (prompt-guard false-positive fix) AND the refine regression guard
#   (services/modbuilder/preserve.js, MB_PRESERVE: preservation invariants BASE vs NEW on a refine).
# Notes: DT-rc19-assembly-2026-10-15.md (this release), DR (web hotfix), DS (guard), DP (BetterModel hand-off), DK, DM, DQ, DN, DO.
set -euo pipefail
REL=release/cyrus-rc19
APP=/opt/nxeon
NODE2=root@178.63.94.114
BUILDVM=root@10.20.1.253
VHOST_LIVE=/etc/nginx/sites-enabled/cyrus-my
VHOST_REPO=deploy/cyrus/nginx-cyrus-my.conf
BK_DIR=/root/nginx-backups            # NOT under sites-enabled (nginx would load a backup there as a second vhost)

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ask() { [ "${YES:-0}" = 1 ] && return 0; read -r -p "$1 [y/N] " a; [ "$a" = y ] || { echo "stopped."; exit 1; }; }
node2_psi() { ssh -o BatchMode=yes -o ConnectTimeout=10 "$NODE2" 'head -1 /proc/pressure/memory' 2>/dev/null | sed -E 's/.*avg10=([0-9.]+).*/\1/'; }
wait_node2() { # agents run tsc/tests on node-2; a promote starved of memory stalls (DQ). Wait until avg10 <= 30.
  local p; for i in $(seq 1 30); do
    p=$(node2_psi || echo "?"); echo "node-2 memory pressure avg10=$p"
    [ "$p" != "?" ] && awk "BEGIN{exit !($p <= 30)}" && return 0
    echo "  busy (other agents' devhost jobs?). Waiting 60 s ($i/30). See: ssh $NODE2 systemctl status nxeon-build-agents.slice"; sleep 60
  done; echo "node-2 still under memory pressure after 30 min"; ask "Continue anyway?"
}

# ---- 0. preconditions --------------------------------------------------------
cd "$APP"
[ "$(id -u)" = 0 ] || { echo "run as root"; exit 1; }
[ "$(git branch --show-current)" = main ] || { echo "$APP is not on main"; exit 1; }
git diff --quiet HEAD -- || { echo "tracked files in $APP are modified; commit or resolve first"; git status --short | head; exit 1; }
git rev-parse -q --verify "$REL^{commit}" >/dev/null || { echo "$REL does not exist"; exit 1; }
git merge-base --is-ancestor main "$REL" || { echo "main is not an ancestor of $REL (diverged); stop"; exit 1; }
echo "main $(git rev-parse --short main) -> $REL $(git rev-parse --short "$REL")  ($(git rev-list --count main.."$REL") commits)"
NEWSQL=$(git diff --name-only --diff-filter=A main "$REL" -- prisma/manual-migrations prisma/manual-migration-*.sql || true)
[ -z "$NEWSQL" ] || { echo "UNEXPECTED new manual SQL in $REL (this script assumed none): $NEWSQL"; exit 1; }
git diff --quiet main "$REL" -- prisma/schema.prisma || echo "note: prisma/schema.prisma differs; promote's additive schema push will apply it"
command -v nginx >/dev/null && command -v psql >/dev/null || { echo "need nginx + psql on this box"; exit 1; }
# next free modbuilder tag on the build VM (live is 0.23 when this was written; a fixed number could be a downgrade)
if [ -z "${TAG:-}" ]; then
  MAXN=$(ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "docker images --format '{{.Tag}}' modbuilder | grep -E '^0\.[0-9]+\$' | cut -d. -f2 | sort -n | tail -1")
  [ -n "$MAXN" ] || { echo "cannot read the modbuilder tags from the build VM; set TAG=modbuilder:0.N yourself"; exit 1; }
  TAG="modbuilder:0.$((MAXN + 1))"
fi
LIVE_IMG=$(ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "docker ps --format '{{.Image}}' | grep -m1 '^modbuilder:'" || echo "?")
echo "modbuilder: live $LIVE_IMG -> new $TAG"
echo "landing live release: $(readlink /var/www/cyrus.my 2>/dev/null || echo 'real dir (first publish converts it)')"

# ---- 1. backup -----------------------------------------------------------------
say "1/9 database backup (production + staging)"
bash scripts/backup-db.sh
LATEST=$(ls -t /tank/backup/db/nxeon-*.sql.gz | head -1)
gzip -t "$LATEST" && [ "$(stat -c %s "$LATEST")" -gt 100000 ] || { echo "backup looks wrong: $LATEST"; exit 1; }
echo "backup OK: $LATEST ($(du -h "$LATEST" | cut -f1))"

# ---- 2. main ---------------------------------------------------------------------
say "2/9 fast-forward main to $REL"
git merge --ff-only "$REL"
# never `git push` here by hand: the repo's post-commit hook pushes main on commits; a fast-forward makes no commit.

# ---- 3. staging ------------------------------------------------------------------
say "3/9 staging deploy + smoke"
STG_HEAD=$(git -C /opt/nxeon-staging rev-parse --short HEAD 2>/dev/null || echo "?")
echo "staging currently runs $STG_HEAD ($(git -C "$APP" branch -a --contains "$STG_HEAD" 2>/dev/null | head -3 | tr -s ' \n' ' '))"
if [ "${SKIP_STAGING_DEPLOY:-0}" = 1 ]; then
  echo "SKIP_STAGING_DEPLOY=1: not redeploying staging."
else
  # staging lock: one staging deploy at a time (an agent may be deploying or using staging right now)
  if ! flock -n /run/lock/nxeon-deploy-staging.lock true; then
    echo "another staging deploy/rollback holds /run/lock/nxeon-deploy-staging.lock; waiting up to 30 min"
    flock -w 1800 /run/lock/nxeon-deploy-staging.lock true || { echo "staging still locked; stop (or SKIP_STAGING_DEPLOY=1)"; exit 1; }
  fi
  [ "$STG_HEAD" != "?" ] && ! git merge-base --is-ancestor "$STG_HEAD" main 2>/dev/null && \
    ask "staging runs $STG_HEAD, which is NOT in main (someone's branch build). Replace it with main?"
  wait_node2
  bash scripts/deploy-staging.sh main
fi
curl -fsS -o /dev/null -w "staging /: %{http_code}\n" https://staging.nxeon.cloud/ || { echo "staging not healthy; stop"; exit 1; }
SS=$(curl -fsS https://staging.nxeon.cloud/api/cyrus/session || echo FAIL)
echo "staging /api/cyrus/session: $SS"; case "$SS" in *'"signedIn":false'*) ;; *) echo "unexpected; stop"; exit 1;; esac
echo "Look at staging now (https://staging.nxeon.cloud): Welcome to Cyrus -> Continue (must NOT say cross-site),"
echo "  Open Cyrus header when signed in, a mod page on phone width, Admin > Cyrus > Notify 'Rendered templates',"
echo "  a ticket reply with an image, a Project Zomboid server's Server Password field."
[ "${STOP_AFTER_STAGING:-0}" = 1 ] && { echo "stopping after staging as requested."; exit 0; }
ask "Staging looks good. Continue to PRODUCTION?"

# ---- 4. modbuilder image ----------------------------------------------------------
# The image carries guard-2026-10-15.1 (route.js/server.js prompt-guard fix) and the refine regression guard
# (preserve.js, MB_PRESERVE: refuses a refine that drops what the base mod had).
say "4/9 modbuilder image $TAG (guard-2026-10-15.1 + refine regression guard MB_PRESERVE; restarts the live build service)"
echo "Builds in flight right now (wait for 0 if you can):"
ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "curl -fsS http://127.0.0.1:7340/health 2>/dev/null | head -c 400; echo" || echo "(health read failed; check by hand)"
ask "Deploy $TAG now (rollback: TAG=$LIVE_IMG bash scripts/cyrus/deploy-modbuilder.sh)?"
TAG="$TAG" bash scripts/cyrus/deploy-modbuilder.sh

# ---- 5. promote ---------------------------------------------------------------------
say "5/9 promote production (portal + worker; BUILD_MAX_MIN=45)"
wait_node2
ask "Promote $(git rev-parse --short HEAD) to production now?"
BUILD_MAX_MIN=45 bash scripts/promote-production.sh
curl -fsS -o /dev/null -w "nxeon.cloud: %{http_code}\n" https://nxeon.cloud/ || { echo "nxeon.cloud not 200 after promote; rollback: scripts/rollback-release.sh --production"; exit 1; }

# ---- 6/7. cyrus.my nginx vhost --------------------------------------------------------
say "6/9 cyrus.my nginx vhost: diff (live -> repo $VHOST_REPO from fix/cyrus-web-origin-marketing-session)"
[ -f "$VHOST_LIVE" ] || { echo "$VHOST_LIVE missing; stop"; exit 1; }
if diff -q "$VHOST_LIVE" "$VHOST_REPO" >/dev/null; then
  echo "live vhost already equals the repo file; nothing to do"
else
  diff -u "$VHOST_LIVE" "$VHOST_REPO" || true
  echo "(adds games|mods|host|blog app paths, the analytics beacon block, www -> apex 301, X-Forwarded-Host on every proxy block)"
  bash scripts/cyrus/nginx-cyrus-my-check.sh --syntax "$VHOST_REPO" || { echo "repo vhost fails nginx -t in a throwaway config; stop"; exit 1; }
  ask "Apply this vhost to $VHOST_LIVE and reload nginx?"
  say "7/9 apply vhost (automatic restore on failure)"
  mkdir -p "$BK_DIR"; chmod 700 "$BK_DIR"
  BK="$BK_DIR/cyrus-my.$(date -u +%Y%m%dT%H%M%SZ)"
  cp -a "$VHOST_LIVE" "$BK"; echo "backup: $BK"
  restore() { echo "RESTORING $BK -> $VHOST_LIVE"; cp -a "$BK" "$VHOST_LIVE"; nginx -t && systemctl reload nginx; }
  install -m 600 -o root -g root "$VHOST_REPO" "$VHOST_LIVE"
  if ! nginx -t; then echo "nginx -t failed with the new vhost"; restore; exit 1; fi
  if ! systemctl reload nginx; then echo "nginx reload failed"; restore; exit 1; fi
  sleep 2
  code=$(curl -s -o /dev/null -w '%{http_code}' https://cyrus.my/ || echo 000)
  scode=$(curl -s -o /dev/null -w '%{http_code}' https://cyrus.my/api/cyrus/session || echo 000)
  if [ "$code" != 200 ] || [ "$scode" != 200 ]; then echo "after reload: / = $code, /api/cyrus/session = $scode"; restore; exit 1; fi
  echo "vhost live: / $code, /api/cyrus/session $scode"
  bash scripts/cyrus/nginx-cyrus-my-check.sh || echo "path matrix reported rows (mods/blog/games/host 404 inside the app is expected while the public switches are off); read above"
fi

# ---- 8. landing ------------------------------------------------------------------------
say "8/9 cyrus.my landing (marketing v2 + Open Cyrus header + hidden Mods/Blog links)"
bash apps/cyrus-site/publish.sh check
bash apps/cyrus-site/publish.sh publish            # dry run: shows what would change
ask "Publish the landing to cyrus.my now (rollback: apps/cyrus-site/publish.sh rollback --go)?"
bash apps/cyrus-site/publish.sh publish --go
bash apps/cyrus-site/publish.sh list | head -3

# ---- 9. post-checks -----------------------------------------------------------------------
say "9/9 post-checks"
curl -fsS -o /dev/null -w "nxeon.cloud:   %{http_code}\n" https://nxeon.cloud/
curl -fsS -o /dev/null -w "cyrus.my:      %{http_code}\n" https://cyrus.my/
curl -s -o /dev/null -w "www.cyrus.my:  %{http_code} -> %{redirect_url}\n" https://www.cyrus.my/
SESS=$(curl -fsS -D /tmp/cyrus-session.h https://cyrus.my/api/cyrus/session || echo FAIL)
echo "/api/cyrus/session: $SESS"; grep -iE '^(cache-control|vary):' /tmp/cyrus-session.h || true
case "$SESS" in *'"signedIn":false'*) ;; *) echo "WARN: expected {\"signedIn\":false} without a cookie";; esac
curl -fsS https://cyrus.my/ | grep -q 'data-auth="in"' && echo "landing has the Open Cyrus header" || echo "WARN: landing lacks data-auth markup (publish ran?)"
# username POST same-origin smoke. Anonymous POST is 404 before the origin check, so this only proves "no 5xx".
# With SMOKE_COOKIE (a signed-in cyrus.my session) the body is invalid JSON: the route answers 400 "bad json" AFTER the
# same-origin check and BEFORE any write, so nothing is created. cross-site = 403.
u=https://cyrus.my/api/cyrus/username
a=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Origin: https://cyrus.my' -H 'content-type: application/json' --data 'x' "$u")
echo "username POST anonymous same-origin: $a (expect 404)"
if [ -n "${SMOKE_COOKIE:-}" ]; then
  s=$(curl -s -w ' %{http_code}' -X POST -H "Cookie: $SMOKE_COOKIE" -H 'Origin: https://cyrus.my' -H 'content-type: application/json' --data 'x' "$u")
  x=$(curl -s -w ' %{http_code}' -X POST -H "Cookie: $SMOKE_COOKIE" -H 'Origin: https://evil.example' -H 'content-type: application/json' --data 'x' "$u")
  echo "same-origin: $s   (expect bad json 400; 403 cross-site = the hotfix is NOT live)"
  echo "foreign origin: $x (expect 403 cross-site)"
else
  echo "(set SMOKE_COOKIE to also test a signed-in same-origin POST; or just click Continue on the Welcome screen)"
fi
ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "docker ps --format '{{.Image}} {{.Status}}' | grep modbuilder" || true
bash scripts/cyrus/launch-check.sh || echo "launch-check reported items; read them above"
systemctl is-active nxeon-web nxeon-worker

cat <<'EOF'

DONE. Then, by hand (the BetterModel fix, DP): restart the owner's server "kodi" ONCE from the panel (Manage -> Restart).
That publishes BetterModel's pack + the Pack Loader entry; players re-join and accept the pack prompt (creatures stop being magenta).
Watch: journalctl -u nxeon-worker -f   (look for [cyrus] bettermodel hand-off lines and [cyrus-guard])

OWNER-ONLY steps this script does NOT do:
 1. Cloudflare DNS for cyrus.my mail (DM): MX cyrus.my -> mail.nxeon.cloud (10); TXT SPF "v=spf1 mx a:mail.nxeon.cloud ~all";
    DKIM dkim._domainkey from Mailcow after adding the cyrus.my domain + hello@/dmarc@ mailboxes + "send as" for the SMTP user;
    _dmarc TXT. (Also stale: _dmarc.nxeon.cloud rua still points at brevo.com.)
 2. Cyrus admin secret host (DK): wildcard *.cyrus.my cert via DNS-01 (dns-cloudflare, same credentials as cyrus.my),
    deploy/cyrus/nginx-cyrus-admin.conf (+ nginx-cyrus-admin-log.conf in conf.d) with the real label, /etc/cyrus/admin-host,
    CYRUS_ADMIN_HOST / NXEON_ADMIN_HOSTS in /opt/nxeon/.env, then scripts/cyrus/nginx-cyrus-admin-check.sh; CYRUS_ADMIN_HOST_ONLY=1 later.
 3. Rotate CYRUS_GOOGLE_CLIENT_SECRET (Google console -> /opt/nxeon/.env -> restart nxeon-web): it was echoed into an agent transcript.
 4. node-2 build slice memory (DQ): ssh root@178.63.94.114
      systemctl set-property nxeon-build-prod.slice MemoryMin=9G MemoryLow=10G
      systemctl set-property nxeon-build.slice MemoryHigh=infinity
 5. Public switches (Settings; both OFF, fail closed):
      cyrus_content_public_enabled -> cyrus.my /games, /games/minecraft, /host/* hosting pages, /blog + RSS (content engine)
      cyrus_mods_public_enabled    -> cyrus.my /mods list, /mods/<slug> public mod pages, spotlight API, landing Mods/Blog nav links
      (indexing is separate: cyrus_content_index_enabled + CYRUS_SITEMAP_CONTENT=1, CYRUS_SITEMAP_MOD_PAGES=1)
 6. Admin > Cyrus > Learning: mark the 3 guard refusals (mbbee4a38..., mbed1276..., mb7c8b6bb...) as false_positive (DS);
    the boss-abilities refine can then be re-submitted.
 7. Staging cleanup of the mod-page screenshot fixtures (DP): review then run
      psql "$(grep -m1 ^DATABASE_URL= /opt/nxeon-staging/.env | cut -d= -f2- | tr -d '"' | sed 's/?.*$//')" \
        -f /root/claudeskills/agent-notes/cyrus-research/screens-mod-pages/cleanup-staging.sql
 8. nginx temp dirs owned by nobody (DN, staff ticket image replies 500): chown -R www-data:root /var/lib/nginx/{body,proxy,fastcgi,uwsgi,scgi}
    and find what ran as nobody at 18:11 on 2026-10-15. The rc19 code only shows a clearer error.
EOF
