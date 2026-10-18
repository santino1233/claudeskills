#!/bin/bash
# Ship release/cyrus-rc22 end to end. OWNER / COORDINATOR RUNS THIS as root on the primary. Stops at the first failure.
#   bash /root/claudeskills/agent-notes/cyrus-research/ship-rc22.sh --plan     # read-only: what would run, and why
#   bash /root/claudeskills/agent-notes/cyrus-research/ship-rc22.sh            # asks before every production step
#   FAST=1 bash .../ship-rc22.sh                                               # fast-deploy path (see "FAST" below)
#   STOP_AFTER_STAGING=1 / SKIP_STAGING_DEPLOY=1 / TAG=modbuilder:0.N           # same meaning as ship-rc21.sh
#   YES=1 ...                                                                  # no prompts (the classifier blocks this as Blind Apply; prefer prompts)
# Order: preconditions (main == af5a1d55 = live rc21, clean) -> DB backup -> main fast-forward -> new SQL on staging (none)
#        -> staging deploy + smoke -> new SQL on production (none) -> modbuilder image 0.27 -> promote -> post-checks.
#
# rc22 = rc21 (af5a1d55) +
#   fix/cyrus-ai-outage-handling 7b0f830b   build service: weekly/monthly/quota limits fail fast + free, refuse at submit
#                                           (503 capacity aiLimit/resetAt), queued builds fail free, /health breaker.hard/resetKnown
#   feature/cyrus-efficiency f5fb7c56       service knobs MB_SESSION_FREEZE / MB_ESCALATE_KIND (+AFTER) / MB_REPAIR_CALL_USD /
#                                           MB_ESCALATE_CALL_USD / MB_EFFORT_CLASS / MB_CHANGE_HYGIENE (all OFF = byte-identical
#                                           prompts); portal CYRUS_CHANGE_COST_HISTORY, worker CYRUS_TESTFLIGHT_GATE_EVERY_S (OFF)
#   feature/cyrus-bundle-b bcf45a93         beta journey fixes, CYRUS_TOK_SETTLE_V2 (OFF), 90 s lost-grace (always on), admin
#                                           (money reasons, guard-refusal review, user search, storage, alerts), OIDC skeleton
#                                           (NXEON_OIDC_PROVIDER OFF), cyrus.my/admin-host scripts refuse nginx on the primary
#   feature/fast-deploy 29fb2453            FAST_DEPLOY machinery (OFF unless --fast / FAST_DEPLOY=1), deploy-modbuilder --check
#   docs/cyrus-status-audit c9a7f032        docs D-72..D-82
#   feature/cyrus-minecraft-seo d213a277    20 /minecraft SEO pages (CYRUS_MC_SEO, OFF) + public schematic generator
#                                           (CYRUS_PUBLIC_BUILDER, OFF; .schem/.nbt export) on the Room Studio job pipeline via an
#                                           optional `policy` hook in lib/cyrus/structures/studio/jobs.ts (absent = unchanged);
#                                           deploy/cyrus/nginx-cyrus-my.conf adds `minecraft` to the app-path regex (NOT applied here)
#   rc22 fixes 9cde15d4                     guard smoke polls the final record (pending/unavailable != fail), backup sfx check
#                                           LC_ALL=C both sides, launch-check never runs nginx on the primary, player-tracking
#                                           strips NUL from names (live worker error every minute on one server)
# Manual SQL: NONE (no file under prisma/manual-migrations, prisma/schema.prisma unchanged). Steps 3/4 still diff and would
#   apply anything new (additive only, one transaction per database).
# Image: modbuilder 0.27 = 0.26 + capacity.js/server.js (outage) + speed.js/server.js/prompts.js (efficiency knobs, all off).
#   PROMPT_VERSION stays mb-2026-10-17.1 (efficiency parts are flag-gated). New /health marker: capacity.breaker.hard.
#   The VM env already carries MB_TIER_SAKA=claude-sonnet-5-5, MB_CACHE_TTL=5m, MB_WORKSPACE_MAP=1 (applied 2026-10-18): keep it.
# FAST: the fast-deploy branch's dry-run (NX-fast-deploy-2026-10-18.md steps 3-4) could NOT run before this ship (its scripts
#   only exist in /opt/nxeon after the main fast-forward, and the dry-run reads production build inputs). So the DEFAULT here is
#   the CLASSIC path. FAST=1 = staging `deploy-staging.sh main --fast` (one build from production inputs), then a
#   `promote-production.sh --fast --dry-run` that must print "REUSING the artifact" before the real `--fast` promote is offered;
#   if it does not, the script falls back to the classic promote (one more build).
# Rollbacks: portal      scripts/rollback-release.sh --production | --staging
#            DB          the dump printed in step 1 (nothing in rc22 changes the schema)
#            modbuilder  TAG=modbuilder:0.26 bash scripts/cyrus/deploy-modbuilder.sh   (0.26 = live when this was written)
# Notes: GO-LIVE-rc22.md (waves of switches after this ship), EA (efficiency), NX-fast-deploy, EC (status), tracker 120/121.
set -euo pipefail
REL=release/cyrus-rc22
PREV_SHA=af5a1d55          # live rc21 (release 20261018T082948Z-af5a1d55)
APP=/opt/nxeon
NODE2=root@178.63.94.114
BUILDVM=root@10.20.1.253
WANT_PROMPT=mb-2026-10-17.1
PLAN=0; [ "${1:-}" = "--plan" ] && PLAN=1

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ask() { [ "${YES:-0}" = 1 ] && return 0; read -r -p "$1 [y/N] " a; [ "$a" = y ] || { echo "stopped."; exit 1; }; }
dburl() { grep -m1 '^DATABASE_URL=' "$1" | cut -d= -f2- | tr -d '"' | sed 's/?.*$//'; }   # without Prisma's ?schema=
node2_psi() { ssh -o BatchMode=yes -o ConnectTimeout=10 "$NODE2" 'head -1 /proc/pressure/memory' 2>/dev/null | sed -E 's/.*avg10=([0-9.]+).*/\1/'; }
wait_node2() { # agents run tsc/tests on node-2; a release build starved of memory stalls (DQ). Wait until avg10 <= 30.
  local p i; for i in $(seq 1 30); do
    p=$(node2_psi || echo "?"); echo "node-2 memory pressure avg10=$p"
    [ "$p" != "?" ] && awk "BEGIN{exit !($p <= 30)}" && return 0
    echo "  busy (other agents' devhost jobs?). Waiting 60 s ($i/30). See: /opt/nxeon/scripts/devhost status"; sleep 60
  done; echo "node-2 still under memory pressure after 30 min"; ask "Continue anyway?"
}
apply_sql() { # $1 = label, $2 = database URL; all new files in ONE transaction (-1), stop on the first error
  [ ${#NEWSQL[@]} -gt 0 ] || { echo "$1: no new manual SQL"; return 0; }
  local args=() f; for f in "${NEWSQL[@]}"; do echo "$1 <- $f"; args+=(-f "$APP/$f"); done
  psql "$2" -v ON_ERROR_STOP=1 -1 -q "${args[@]}"
}
health() { ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "curl -fsS http://127.0.0.1:7340/health" 2>/dev/null || echo ""; }

# ---- 0. preconditions --------------------------------------------------------
cd "$APP"
[ "$(id -u)" = 0 ] || { echo "run as root"; exit 1; }
[ "$(git branch --show-current)" = main ] || { echo "$APP is not on main"; exit 1; }
git diff --quiet HEAD -- || { echo "tracked files in $APP are modified; commit or resolve first"; git status --short | head; exit 1; }
git rev-parse -q --verify "$REL^{commit}" >/dev/null || { echo "$REL does not exist"; exit 1; }
PREV=$(git rev-parse "$PREV_SHA")
[ "$(git rev-parse main)" = "$PREV" ] || { echo "main ($(git rev-parse --short main)) is not $PREV_SHA (live rc21); something else shipped since. Re-check before shipping."; exit 1; }
git merge-base --is-ancestor main "$REL" || { echo "main is not an ancestor of $REL (diverged); stop"; exit 1; }
echo "main $(git rev-parse --short main) (= rc21, live) -> $REL $(git rev-parse --short "$REL")  ($(git rev-list --count main.."$REL") commits)"
mapfile -t NEWSQL < <(git diff --name-only --diff-filter=AM "$PREV" "$REL" -- prisma/manual-migrations 'prisma/manual-migration-*.sql' | sort)
if [ ${#NEWSQL[@]} -gt 0 ]; then
  echo "new manual SQL in $REL (NOT expected for rc22):"; printf '  %s\n' "${NEWSQL[@]}"
  for f in "${NEWSQL[@]}"; do
    if git show "$REL:$f" | sed 's/--.*$//' | grep -inE '\b(drop|truncate|delete[[:space:]]+from|update[[:space:]]+[a-z"_]+[[:space:]]+set|alter[[:space:]]+column[^;]*type|rename)\b'; then
      echo "$f contains a NON-additive statement (above). This script only applies additive, idempotent SQL; stop."; exit 1
    fi
  done
else
  echo "no new manual SQL vs rc21 (expected)"
fi
git diff --quiet "$PREV" "$REL" -- prisma/schema.prisma || echo "note: prisma/schema.prisma differs (NOT expected for rc22); promote's additive schema push applies it."
git diff --quiet "$PREV" "$REL" -- apps/cyrus-site/ || echo "note: apps/cyrus-site/ changed (not expected); this script does NOT publish the landing"
echo "deploy/ changes (scripts only, nothing applied by this ship): $(git diff --name-only "$PREV" "$REL" -- deploy/ | tr '\n' ' ')"
MB_FILES=$(git diff --name-only "$PREV" "$REL" -- services/modbuilder lib/cyrus/versions/registry.json lib/cyrus/import/deps.json | tr '\n' ' ')
echo "build service files changed: ${MB_FILES:-none}"
command -v psql >/dev/null || { echo "need psql on this box"; exit 1; }

if [ "$PLAN" = 1 ]; then
  say "PLAN (nothing is run)"
  echo "path: $([ "${FAST:-0}" = 1 ] && echo "FAST (staging --fast, promote --fast after a --dry-run shows artifact reuse)" || echo "CLASSIC (two builds; FAST=1 to opt in)")"
  echo "1. DB backup: scripts/backup-db.sh (production + staging dump; no schema change in rc22, but this is the cheap net)"
  echo "2. git merge --ff-only $REL (main -> $(git rev-parse --short "$REL"))"
  echo "3. staging: deploy-staging.sh main$([ "${FAST:-0}" = 1 ] && echo " --fast"), SQL: ${#NEWSQL[@]} file(s), smoke / + /api/cyrus/session"
  echo "4. production SQL: ${#NEWSQL[@]} file(s)"
  echo "5. modbuilder image: ${TAG:-next free tag, expected modbuilder:0.27} (files: ${MB_FILES:-none}); deploy-modbuilder.sh copies, builds, restarts,"
  echo "   checks promptVersion $WANT_PROMPT + scanner sha, runs the guard smoke (now polls the final record, up to 6 min)"
  echo "6. promote-production.sh$([ "${FAST:-0}" = 1 ] && echo " --fast (after --fast --dry-run)" || echo " (BUILD_MAX_MIN=45)")"
  echo "   (nginx minecraft path: printed at the end, NOT applied)"
  echo "7. post-checks: nxeon.cloud, cyrus.my, /api/cyrus/session, /health markers (breaker.hard), worker journal free of 0x00 errors, launch-check"
  exit 0
fi

# ---- 1. backup -----------------------------------------------------------------
say "1/7 database backup (production + staging)"
ask "Take the DB dump now (about 3 min)?"
bash scripts/backup-db.sh
LATEST=$(ls -t /tank/backup/db/nxeon-*.sql.gz | head -1)
gzip -t "$LATEST" && [ "$(stat -c %s "$LATEST")" -gt 100000 ] || { echo "backup looks wrong: $LATEST"; exit 1; }
echo "backup OK: $LATEST ($(du -h "$LATEST" | cut -f1))"

# ---- 2. main ---------------------------------------------------------------------
say "2/7 fast-forward main to $REL"
ask "Fast-forward main in $APP to $REL $(git rev-parse --short "$REL")?"
git merge --ff-only "$REL"
# no `git push` by hand: the repo's post-commit hook pushes main on commits; a fast-forward makes no commit.

# ---- 3. staging ------------------------------------------------------------------
say "3/7 staging: deploy, new SQL, smoke"
STG_URL=$(dburl /opt/nxeon-staging/.env)
[ -n "$STG_URL" ] || { echo "no staging DATABASE_URL"; exit 1; }
STG_HEAD=$(git -C /opt/nxeon-staging rev-parse --short HEAD 2>/dev/null || echo "?")
echo "staging currently runs $STG_HEAD"
if [ "${SKIP_STAGING_DEPLOY:-0}" = 1 ]; then
  echo "SKIP_STAGING_DEPLOY=1: not redeploying staging."
else
  if ! flock -n /run/lock/nxeon-deploy-staging.lock true; then
    echo "another staging deploy/rollback holds /run/lock/nxeon-deploy-staging.lock; waiting up to 30 min"
    flock -w 1800 /run/lock/nxeon-deploy-staging.lock true || { echo "staging still locked; stop (or SKIP_STAGING_DEPLOY=1)"; exit 1; }
  fi
  [ "$STG_HEAD" != "?" ] && ! git merge-base --is-ancestor "$STG_HEAD" main 2>/dev/null && \
    ask "staging runs $STG_HEAD, which is NOT in main (someone's branch build). Replace it with main?"
  wait_node2
  ask "Deploy main to STAGING now$([ "${FAST:-0}" = 1 ] && echo " with --fast (one build from production's inputs)")?"
  if [ "${FAST:-0}" = 1 ]; then bash scripts/deploy-staging.sh main --fast; else bash scripts/deploy-staging.sh main; fi
fi
apply_sql staging "$STG_URL"
curl -fsS -o /dev/null -w "staging /: %{http_code}\n" https://staging.nxeon.cloud/ || { echo "staging not healthy; stop"; exit 1; }
SS=$(curl -fsS https://staging.nxeon.cloud/api/cyrus/session || echo FAIL)
echo "staging /api/cyrus/session: $SS"; case "$SS" in *'"signedIn":false'*) ;; *) echo "unexpected; stop"; exit 1;; esac
if [ "${FAST:-0}" = 1 ]; then # the shared artifact's type check runs on node-2 after the build; production refuses a failed one
  AKEY=$(cat /tank/nxeon-deploy/staging/last-artifact.key 2>/dev/null || true)
  if [ -n "$AKEY" ]; then
    for i in $(seq 1 90); do
      V=$(ssh -o BatchMode=yes "$NODE2" "cat /tank/nxeon-deploy/artifacts/$AKEY/typecheck 2>/dev/null || echo none" 2>/dev/null || echo "?")
      case "$V" in
        ok|none) echo "type check of artifact $AKEY: $V"; break ;;
        failed) echo "TYPE CHECK FAILED on the shared artifact: production would refuse it. Stop (staging can be rolled back)."; exit 1 ;;
        *) echo "type check of artifact $AKEY still running ($V) $i/90"; sleep 10 ;;
      esac
    done
  else echo "no shared artifact key recorded (FAST_SHARED_BUILD off?); promote will build for itself"; fi
fi
echo "Look at staging now (https://staging.nxeon.cloud): Cyrus dashboard + a mod page + Studio open as before; admin /admin/cyrus"
echo "  Live tab shows the new Alerts panel; Guard refusals have a Review/Reopen; money actions ask for a reason."
[ "${STOP_AFTER_STAGING:-0}" = 1 ] && { echo "stopping after staging as requested."; exit 0; }
ask "Staging looks good. Continue to PRODUCTION?"

# ---- 4. production SQL -------------------------------------------------------------
say "4/7 production: new manual SQL (expected: none)"
PRD_URL=$(dburl "$APP/.env")
[ -n "$PRD_URL" ] || { echo "no production DATABASE_URL"; exit 1; }
if [ ${#NEWSQL[@]} -gt 0 ]; then ask "Apply ${#NEWSQL[@]} SQL file(s) to PRODUCTION in one transaction?"; fi
apply_sql production "$PRD_URL"

# ---- 5. modbuilder image ----------------------------------------------------------
say "5/7 modbuilder image (outage handling + efficiency knobs; restarts the live build service)"
if [ -z "${TAG:-}" ]; then
  MAXN=$(ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "docker images --format '{{.Tag}}' modbuilder | grep -E '^0\.[0-9]+\$' | cut -d. -f2 | sort -n | tail -1")
  [ -n "$MAXN" ] || { echo "cannot read the modbuilder tags from the build VM; set TAG=modbuilder:0.N yourself"; exit 1; }
  TAG="modbuilder:0.$((MAXN + 1))"
fi
LIVE_IMG=$(ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" "docker ps --format '{{.Image}}' | grep -m1 '^modbuilder:'" || echo "?")
echo "modbuilder: live $LIVE_IMG -> new $TAG (expected 0.26 -> 0.27)"
rc=0; bash scripts/cyrus/deploy-modbuilder.sh --check || rc=$?   # read-only hash compare (fast-deploy branch); 10 = differs
case "$rc" in 10) echo "service files differ from the VM: image needed (expected)";; 0) echo "WARN: the VM already has these files?! (an earlier manual copy) - building anyway";; *) echo "could not compare with the VM (exit $rc); building anyway";; esac
echo "Builds in flight right now (wait for running 0 if you can):"
health | head -c 400; echo
ask "Deploy $TAG now (rollback: TAG=$LIVE_IMG bash scripts/cyrus/deploy-modbuilder.sh)?"
TAG="$TAG" bash scripts/cyrus/deploy-modbuilder.sh
H=$(health)
case "$H" in *"\"promptVersion\":\"$WANT_PROMPT\""*) echo "service prompt $WANT_PROMPT: OK";; *) echo "WARN: /health does not report promptVersion $WANT_PROMPT";; esac
case "$H" in *'"breaker":{'*'"hard":'*) echo "capacity.breaker.hard present: outage handling image live";; *) echo "WARN: /health capacity.breaker has no 'hard' field (old image still running?)";; esac
case "$H" in *'"cacheTtl":"5m"'*) echo "cacheTtl 5m kept (VM env)";; *) echo "WARN: cacheTtl is not 5m: was /root/modbuilder.env changed? (EA recommends 5m)";; esac
cat /var/lib/cyrus/guard-smoke.json 2>/dev/null || true
echo "(guard smoke result above: ok = refused as expected; pending/unavailable = re-run later, NOT a guard failure)"

# ---- 6. promote ---------------------------------------------------------------------
say "6/7 promote production (portal + worker)"
wait_node2
PROMOTE_FAST=0
if [ "${FAST:-0}" = 1 ]; then
  echo "FAST: dry run first (stages + side smoke, no swap); it must reuse the staging artifact"
  DRY=$(bash scripts/promote-production.sh --fast --dry-run 2>&1 | tee /dev/stderr || true)
  if echo "$DRY" | grep -q "REUSING the artifact"; then PROMOTE_FAST=1; echo "dry run reused the artifact: fast promote available"
  else echo "dry run did NOT reuse the artifact: falling back to the classic promote (one more build)"; fi
fi
ask "Promote $(git rev-parse --short HEAD) to production now ($([ $PROMOTE_FAST = 1 ] && echo "--fast, artifact reuse" || echo "classic build, BUILD_MAX_MIN=45"))?"
if [ $PROMOTE_FAST = 1 ]; then bash scripts/promote-production.sh --fast; else BUILD_MAX_MIN=45 bash scripts/promote-production.sh; fi
curl -fsS -o /dev/null -w "nxeon.cloud: %{http_code}\n" https://nxeon.cloud/ || { echo "nxeon.cloud not 200 after promote; rollback: scripts/rollback-release.sh --production"; exit 1; }

# ---- 7. post-checks -----------------------------------------------------------------------
say "7/7 post-checks"
curl -fsS -o /dev/null -w "nxeon.cloud:   %{http_code}\n" https://nxeon.cloud/
curl -fsS -o /dev/null -w "cyrus.my:      %{http_code}\n" https://cyrus.my/
SESS=$(curl -fsS https://cyrus.my/api/cyrus/session || echo FAIL)
echo "/api/cyrus/session: $SESS"; case "$SESS" in *'"signedIn":false'*) ;; *) echo "WARN: expected {\"signedIn\":false} without a cookie";; esac
r=$(curl -s -o /dev/null -w '%{http_code}' https://nxeon.cloud/.well-known/openid-configuration || echo 000)
echo "OIDC discovery: $r (expect 404: NXEON_OIDC_PROVIDER is off)"
r=$(curl -s -o /dev/null -w '%{http_code}' https://nxeon.cloud/minecraft || echo 000); echo "/minecraft on nxeon.cloud: $r (expect 404: CYRUS_MC_SEO is off)"
r=$(curl -s -o /dev/null -w '%{http_code}' -X POST https://nxeon.cloud/api/cyrus/public/v1/builds || echo 000); echo "public builder API: $r (expect 404: CYRUS_PUBLIC_BUILDER is off)"
systemctl is-active nxeon-web nxeon-worker
sleep 120   # two player-tracking sweeps
n=$(journalctl -u nxeon-worker --since "2 min ago" --no-pager 2>/dev/null | grep -c 'invalid byte sequence for encoding "UTF8": 0x00' || true)
echo "worker 0x00 errors in the last 2 min: $n (expect 0; was one per minute on rc21)"
bash scripts/cyrus/launch-check.sh || echo "launch-check reported items; read them above (nginx-syntax is now INFO 'skipped' on the primary by design)"

cat <<'EOF'

NGINX (not run by this script; only needed before CYRUS_MC_SEO / CYRUS_PUBLIC_BUILDER serve on cyrus.my):
  deploy/cyrus/nginx-cyrus-my.conf now proxies /minecraft to the app. Until it is applied, cyrus.my/minecraft is the vhost's 404
  and launch-check's nginx-paths row may WARN. Never run the nginx binary by hand on the primary (D-82). Steps:
   1. bash deploy/cyrus/cyrus-my-apply.sh status            # read-only diff live vhost vs template (expect only the minecraft change)
   2. syntax check off the primary: node-2 has NO nginx installed (checked 2026-10-18), so either install nginx on node-2 and run
      /opt/nxeon/scripts/devhost run -- bash scripts/cyrus/nginx-cyrus-my-check.sh --syntax, or review the one-line diff by eye
   3. owner decision: I_CHECKED_ON_NODE2=1 bash deploy/cyrus/cyrus-my-apply.sh nginx   # backs up, installs, runs `nginx -t` on the
      LIVE config (which has `user www-data;`) + systemctl reload, auto-restores on failure. This is the one sanctioned nginx run.
   4. bash deploy/cyrus/cyrus-my-apply.sh verify

DONE. rc22 is live with every new switch OFF. Next: GO-LIVE-rc22.md (same folder), wave 1.
Watch: journalctl -u nxeon-worker -f ; on the build VM: docker logs -f modbuilder
OWNER-ONLY items this script does NOT do: every switch in GO-LIVE-rc22.md (waves 1-3), the catalogue index install,
CYRUS_VANILLA_REFERENCE_DIR, bundle B decisions B-1..B-11 (docs/cyrus/31), the API key for the build service.
EOF
