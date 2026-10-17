#!/bin/bash
# Ship release/cyrus-rc21 end to end. OWNER RUNS THIS as root on the primary. Stops at the first failure.
#   bash /root/claudeskills/agent-notes/cyrus-research/ship-rc21.sh            # asks before every production step
#   YES=1 bash .../ship-rc21.sh                                                # no prompts
#   STOP_AFTER_STAGING=1 bash .../ship-rc20.sh                                 # backup + main ff + staging only
#   SKIP_STAGING_DEPLOY=1 ...                                                  # staging already runs rc21
#   TAG=modbuilder:0.N ...                                                     # force the image tag (default: next free one)
# Order: preconditions (main == rc20, clean) -> DB backup -> main fast-forward -> new SQL on staging -> staging deploy + smoke
#        -> new SQL on production -> modbuilder image -> promote production (BUILD_MAX_MIN=45) -> post-checks.
# rc21 = rc20 + fix/cyrus-preserve-config-defaults (preserve.js keepDefaults step after the Config Studio settings round:
#        unrequested default changes in config.yml / schema / Java fallbacks go back, config-version never decreases;
#        configs.js syncStaleDefaults; prompt mb-2026-10-17.1, pv-2026-10-17.1)
#        + feature/cyrus-room-studio-image (Room Studio reference images: image guard MB_ROOM_IMAGE_GUARD, visual critique
#        MB_ROOM_CRITIQUE / MB_ROOM_CRITIQUE_MIN_USD; placeholder price cyrus_tok_room_studio_image_hold = 45).
#        Portal flag CYRUS_ROOM_STUDIO still default OFF (image input lives behind it).
# Manual SQL: rc21 adds NO file under prisma/manual-migrations and does not touch prisma/schema.prisma. Steps 3/4 still diff
#   the directory against rc20 and apply whatever is new (additive only, one transaction per database).
# Rollbacks: portal      scripts/rollback-release.sh --production | --staging
#            DB          the dump printed in step 1
#            modbuilder  TAG=modbuilder:0.25 bash scripts/cyrus/deploy-modbuilder.sh   (0.25 = live when this was written)
# Notes: DY-rc21-assembly-2026-10-17.md (this release), DX (rc20), DQ (node-2 memory). Image CLI check: rc21-image-cli-smoke.sh
set -euo pipefail
REL=release/cyrus-rc21
PREV=release/cyrus-rc20
APP=/opt/nxeon
NODE2=root@178.63.94.114
BUILDVM=root@10.20.1.253
WANT_PROMPT=mb-2026-10-17.1
WANT_PRESERVE=pv-2026-10-17.1

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ask() { [ "${YES:-0}" = 1 ] && return 0; read -r -p "$1 [y/N] " a; [ "$a" = y ] || { echo "stopped."; exit 1; }; }
dburl() { grep -m1 '^DATABASE_URL=' "$1" | cut -d= -f2- | tr -d '"' | sed 's/?.*$//'; }   # without Prisma's ?schema=
node2_psi() { ssh -o BatchMode=yes -o ConnectTimeout=10 "$NODE2" 'head -1 /proc/pressure/memory' 2>/dev/null | sed -E 's/.*avg10=([0-9.]+).*/\1/'; }
wait_node2() { # agents run tsc/tests on node-2; a promote starved of memory stalls (DQ). Wait until avg10 <= 30.
  local p; for i in $(seq 1 30); do
    p=$(node2_psi || echo "?"); echo "node-2 memory pressure avg10=$p"
    [ "$p" != "?" ] && awk "BEGIN{exit !($p <= 30)}" && return 0
    echo "  busy (other agents' devhost jobs?). Waiting 60 s ($i/30). See: ssh $NODE2 systemctl status nxeon-build-agents.slice"; sleep 60
  done; echo "node-2 still under memory pressure after 30 min"; ask "Continue anyway?"
}
apply_sql() { # $1 = label, $2 = database URL; all new files in ONE transaction (-1), stop on the first error
  [ ${#NEWSQL[@]} -gt 0 ] || { echo "$1: no new manual SQL"; return 0; }
  local args=(); for f in "${NEWSQL[@]}"; do echo "$1 <- $f"; args+=(-f "$APP/$f"); done
  psql "$2" -v ON_ERROR_STOP=1 -1 -q "${args[@]}"
}

# ---- 0. preconditions --------------------------------------------------------
cd "$APP"
[ "$(id -u)" = 0 ] || { echo "run as root"; exit 1; }
[ "$(git branch --show-current)" = main ] || { echo "$APP is not on main"; exit 1; }
git diff --quiet HEAD -- || { echo "tracked files in $APP are modified; commit or resolve first"; git status --short | head; exit 1; }
for r in "$REL" "$PREV"; do git rev-parse -q --verify "$r^{commit}" >/dev/null || { echo "$r does not exist"; exit 1; }; done
[ "$(git rev-parse main)" = "$(git rev-parse "$PREV")" ] || { echo "main ($(git rev-parse --short main)) is not $PREV ($(git rev-parse --short "$PREV")); something else shipped since. Stop and re-check."; exit 1; }
git merge-base --is-ancestor main "$REL" || { echo "main is not an ancestor of $REL (diverged); stop"; exit 1; }
echo "main $(git rev-parse --short main) (= $PREV, live) -> $REL $(git rev-parse --short "$REL")  ($(git rev-list --count main.."$REL") commits)"
# NEW SQL vs rc20: added or changed manual migrations. Refuse anything that is not additive.
mapfile -t NEWSQL < <(git diff --name-only --diff-filter=AM "$PREV" "$REL" -- prisma/manual-migrations 'prisma/manual-migration-*.sql' | sort)
if [ ${#NEWSQL[@]} -gt 0 ]; then
  echo "new manual SQL in $REL (applied on staging, then production, one transaction each):"; printf '  %s\n' "${NEWSQL[@]}"
  for f in "${NEWSQL[@]}"; do
    if git show "$REL:$f" | sed 's/--.*$//' | grep -inE '\b(drop|truncate|delete[[:space:]]+from|update[[:space:]]+[a-z"_]+[[:space:]]+set|alter[[:space:]]+column[^;]*type|rename)\b'; then
      echo "$f contains a NON-additive statement (above). This script only applies additive, idempotent SQL; stop."; exit 1
    fi
    git show "$REL:$f" | grep -qiE 'if not exists|on conflict' || echo "  note: $f has no IF NOT EXISTS / ON CONFLICT; check it is idempotent before you continue"
  done
else
  echo "no new manual SQL vs $PREV (expected for rc21)"
fi
git diff --quiet "$PREV" "$REL" -- prisma/schema.prisma || echo "note: prisma/schema.prisma differs (NOT expected for rc21); promote's additive schema push applies it. Look at: git diff $PREV $REL -- prisma/schema.prisma"
command -v psql >/dev/null || { echo "need psql on this box"; exit 1; }
# next free modbuilder tag on the build VM (live is 0.25 when this was written, so 0.26; a fixed number could be a downgrade)
if [ -z "${TAG:-}" ]; then
  MAXN=$(ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "docker images --format '{{.Tag}}' modbuilder | grep -E '^0\.[0-9]+\$' | cut -d. -f2 | sort -n | tail -1")
  [ -n "$MAXN" ] || { echo "cannot read the modbuilder tags from the build VM; set TAG=modbuilder:0.N yourself"; exit 1; }
  TAG="modbuilder:0.$((MAXN + 1))"
fi
LIVE_IMG=$(ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "docker ps --format '{{.Image}}' | grep -m1 '^modbuilder:'" || echo "?")
echo "modbuilder: live $LIVE_IMG -> new $TAG"
git diff --quiet "$PREV" "$REL" -- deploy/ apps/cyrus-site/ || echo "note: deploy/ or apps/cyrus-site/ changed vs $PREV (not expected for rc21); this script does NOT apply nginx or the landing"

# ---- 1. backup -----------------------------------------------------------------
say "1/7 database backup (production + staging)"
bash scripts/backup-db.sh
LATEST=$(ls -t /tank/backup/db/nxeon-*.sql.gz | head -1)
gzip -t "$LATEST" && [ "$(stat -c %s "$LATEST")" -gt 100000 ] || { echo "backup looks wrong: $LATEST"; exit 1; }
echo "backup OK: $LATEST ($(du -h "$LATEST" | cut -f1))"

# ---- 2. main ---------------------------------------------------------------------
say "2/7 fast-forward main to $REL"
git merge --ff-only "$REL"
# never `git push` here by hand: the repo's post-commit hook pushes main on commits; a fast-forward makes no commit.

# ---- 3. staging ------------------------------------------------------------------
say "3/7 staging: deploy, new SQL, smoke"
STG_URL=$(dburl /opt/nxeon-staging/.env)
[ -n "$STG_URL" ] || { echo "no staging DATABASE_URL"; exit 1; }
STG_HEAD=$(git -C /opt/nxeon-staging rev-parse --short HEAD 2>/dev/null || echo "?")
echo "staging currently runs $STG_HEAD"
if [ "${SKIP_STAGING_DEPLOY:-0}" = 1 ]; then
  echo "SKIP_STAGING_DEPLOY=1: not redeploying staging."
  apply_sql staging "$STG_URL"
else
  if ! flock -n /run/lock/nxeon-deploy-staging.lock true; then
    echo "another staging deploy/rollback holds /run/lock/nxeon-deploy-staging.lock; waiting up to 30 min"
    flock -w 1800 /run/lock/nxeon-deploy-staging.lock true || { echo "staging still locked; stop (or SKIP_STAGING_DEPLOY=1)"; exit 1; }
  fi
  [ "$STG_HEAD" != "?" ] && ! git merge-base --is-ancestor "$STG_HEAD" main 2>/dev/null && \
    ask "staging runs $STG_HEAD, which is NOT in main (someone's branch build). Replace it with main?"
  wait_node2
  bash scripts/deploy-staging.sh main   # its schema push creates what staging is missing; new SQL then runs on top (idempotent)
  apply_sql staging "$STG_URL"
fi
curl -fsS -o /dev/null -w "staging /: %{http_code}\n" https://staging.nxeon.cloud/ || { echo "staging not healthy; stop"; exit 1; }
SS=$(curl -fsS https://staging.nxeon.cloud/api/cyrus/session || echo FAIL)
echo "staging /api/cyrus/session: $SS"; case "$SS" in *'"signedIn":false'*) ;; *) echo "unexpected; stop"; exit 1;; esac
echo "Look at staging now (https://staging.nxeon.cloud): Cyrus dashboard and Studio pages open as before; a mod's Explain tab"
echo "  still renders (it gained a 'kept your earlier setting' line, shown only for builds made by the new image)."
echo "  CYRUS_ROOM_STUDIO is OFF unless you set it in /opt/nxeon-staging/.env: /dashboard/cyrus/<id>/studio/rooms is then a 404."
echo "  With it ON (staging only), the Room Studio shows the reference-image picker (paste / drop / file, up to 3)."
[ "${STOP_AFTER_STAGING:-0}" = 1 ] && { echo "stopping after staging as requested."; exit 0; }
ask "Staging looks good. Continue to PRODUCTION?"

# ---- 4. production SQL -------------------------------------------------------------
say "4/7 production: new manual SQL (backup from step 1 is the rollback)"
PRD_URL=$(dburl "$APP/.env")
[ -n "$PRD_URL" ] || { echo "no production DATABASE_URL"; exit 1; }
if [ ${#NEWSQL[@]} -gt 0 ]; then ask "Apply ${#NEWSQL[@]} SQL file(s) to PRODUCTION in one transaction?"; fi
apply_sql production "$PRD_URL"

# ---- 5. modbuilder image ----------------------------------------------------------
# Carries preserve.js keepDefaults + configs.js syncStaleDefaults (MB_PRESERVE as before; version pv-2026-10-17.1),
# prompts PROMPT_VERSION mb-2026-10-17.1, roomstudio.js / route.js / room-studio.js image input (MB_ROOM_IMAGE_GUARD on =
# fail closed, MB_ROOM_CRITIQUE on, MB_ROOM_CRITIQUE_MIN_USD 0.15), server.js run() stdin support, plus everything 0.25 had.
say "5/7 modbuilder image $TAG (config defaults keep + Room Studio image input; restarts the live build service)"
echo "Builds in flight right now (wait for 0 if you can):"
ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "curl -fsS http://127.0.0.1:7340/health 2>/dev/null | head -c 400; echo" || echo "(health read failed; check by hand)"
ask "Deploy $TAG now (rollback: TAG=$LIVE_IMG bash scripts/cyrus/deploy-modbuilder.sh)?"
TAG="$TAG" bash scripts/cyrus/deploy-modbuilder.sh
H=$(ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "curl -fsS http://127.0.0.1:7340/health" 2>/dev/null || echo "")
case "$H" in *"\"promptVersion\":\"$WANT_PROMPT\""*) echo "service prompt $WANT_PROMPT: OK";; *) echo "WARN: /health does not report promptVersion $WANT_PROMPT (old image still running?)";; esac
case "$H" in *"\"version\":\"$WANT_PRESERVE\""*) echo "features.preserve $WANT_PRESERVE: OK";; *) echo "WARN: /health does not report preserve version $WANT_PRESERVE (MB_PRESERVE=off, or old image)";; esac
case "$H" in *'"roomStudio":{'*) echo "features.roomStudio: present";; *) echo "WARN: features.roomStudio missing (MB_ROOM_STUDIO=0 on the VM, or old image)";; esac
case "$H" in *'"images":{"version":"roomimage-1"'*) echo "features.roomStudio.images: roomimage-1";; *) echo "WARN: features.roomStudio.images missing (old image?)";; esac
case "$H" in *'"guard":"roomimage-guard'*|*'"guard":"'*) echo "image guard: on";; *'"guard":false'*) echo "WARN: image guard is OFF (MB_ROOM_IMAGE_GUARD=0 on the VM); turn it back on before any image use";; esac
case "$H" in *'"rooms":{'*) echo "features.rooms: present";; *) echo "WARN: features.rooms missing (MB_ROOMS=0, or old image)";; esac
echo "One real check is still needed (owner, about 0.2 US cents): bash $(dirname "$(readlink -f "$0")")/rc21-image-cli-smoke.sh"

# ---- 6. promote ---------------------------------------------------------------------
say "6/7 promote production (portal + worker; BUILD_MAX_MIN=45)"
wait_node2
ask "Promote $(git rev-parse --short HEAD) to production now?"
BUILD_MAX_MIN=45 bash scripts/promote-production.sh
curl -fsS -o /dev/null -w "nxeon.cloud: %{http_code}\n" https://nxeon.cloud/ || { echo "nxeon.cloud not 200 after promote; rollback: scripts/rollback-release.sh --production"; exit 1; }

# ---- 7. post-checks -----------------------------------------------------------------------
say "7/7 post-checks"
curl -fsS -o /dev/null -w "nxeon.cloud:   %{http_code}\n" https://nxeon.cloud/
curl -fsS -o /dev/null -w "cyrus.my:      %{http_code}\n" https://cyrus.my/
SESS=$(curl -fsS https://cyrus.my/api/cyrus/session || echo FAIL)
echo "/api/cyrus/session: $SESS"; case "$SESS" in *'"signedIn":false'*) ;; *) echo "WARN: expected {\"signedIn\":false} without a cookie";; esac
r=$(curl -s -o /dev/null -w '%{http_code}' https://nxeon.cloud/api/cyrus/assets/v1/rooms/x || echo 000)
echo "rooms API anonymous: $r (expect 404: viewer-only, and the flag is off)"
H=$(ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "curl -fsS http://127.0.0.1:7340/health" 2>/dev/null || echo "")
case "$H" in *"\"promptVersion\":\"$WANT_PROMPT\""*) echo "service prompt $WANT_PROMPT: OK";; *) echo "WARN: service promptVersion is not $WANT_PROMPT";; esac
ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "docker ps --format '{{.Image}} {{.Status}}' | grep modbuilder" || true
bash scripts/cyrus/launch-check.sh || echo "launch-check reported items; read them above (cyrus_tok_room_studio_hold and cyrus_tok_room_studio_image_hold are PLACEHOLDERS)"
systemctl is-active nxeon-web nxeon-worker

cat <<'EOF'

DONE. Watch: journalctl -u nxeon-worker -f ; on the build VM: docker logs -f modbuilder (look for "kept" / keepDefaults lines on refines)
The next refine of a mod with a Config Studio settings round (e.g. the owner's Infinite Dungeon) should keep max-floors /
boss.floor-interval / config-version; the Explain tab says "Kept your earlier setting X = Y". That is the real test.

OWNER-ONLY decisions / steps this script does NOT do:
 1. Image CLI check (one real call, about 0.2 US cents): bash /root/claudeskills/agent-notes/cyrus-research/rc21-image-cli-smoke.sh
    It pipes one 16x16 red PNG as a base64 stream-json message into `claude -p --input-format stream-json` inside the
    modbuilder container (Haiku, --max-budget-usd 0.05). PASS = a clean result naming "red". The image path has had NO real
    model call yet (tests use recorded replies); until this passes, do not use image input even on staging.
 2. Token price cyrus_tok_room_studio_image_hold (Setting, PLACEHOLDER 45 at Saka, the EXTRA hold for a generation with
    reference images, on top of cyrus_tok_room_studio_hold 60; settles at measured cost). Decide both in Admin > Cyrus
    settings before item 3; launch-check lists both as placeholders.
 3. CYRUS_ROOM_STUDIO (portal env, default OFF; restart nxeon-web after a change): turns on the Room Studio incl. image input.
    Try on staging first (/opt/nxeon-staging/.env), 2-3 generations with and without images, look at cost and quality.
 4. Build-service image flags (VM env of the modbuilder container; defaults are the intended ones): MB_ROOM_IMAGE_GUARD (on,
    fail closed: keep it on), MB_ROOM_CRITIQUE (on; =0 saves one call per image job), MB_ROOM_CRITIQUE_MIN_USD (0.15).
 5. Privacy note: reference images are never stored or logged (job keeps the count only); confirm the wording of the
    studio's privacy line is acceptable to you before turning item 3 on in production.
 Carried from rc20 (still open unless done): upload store in production (uploads / rooms save answer 503), 
 CYRUS_ROOM_STUDIO_KEEP_PROMPTS (default OFF), Litematica real-client load test, never CYRUS_ROOM_STUDIO_BACKEND=fake in
 production. From rc19: cyrus.my mail DNS (DM), admin secret host (DK), rotate CYRUS_GOOGLE_CLIENT_SECRET, node-2 slice
 memory (DQ), public switches cyrus_content_public_enabled / cyrus_mods_public_enabled, guard false_positive marks (DS),
 staging mod-page fixture cleanup (DP), /var/lib/nginx temp dir ownership (DN).
EOF
