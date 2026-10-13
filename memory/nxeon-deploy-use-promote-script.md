---
name: nxeon-deploy-use-promote-script
description: "Deploy prod ONLY via scripts/deploy-staging.sh then scripts/promote-production.sh — a raw `npm run build && systemctl restart` took the site down twice on 2026-10-01"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-10-01T05:40:34.792Z
---

Never hand the owner a raw `npm run build` + `systemctl restart nxeon-web` for a deploy. Use `scripts/deploy-staging.sh <ref>` → verify staging → `scripts/promote-production.sh` (CLAUDE.md "Working on this codebase").

**Why:** On 2026-10-01 I gave a raw build+restart twice. The standalone output (`.next/standalone/server.js`) does NOT include `.next/static` or `public/` or geoip-lite's `.dat` files, so the site went 500 (geoip ENOENT on every request) and then loaded HTML but zero client JS (no hydration: dead buttons/animations). `promote-production.sh` already copies public/, .next/static and geoip data, runs `prisma db push`, restarts web+worker and refuses if staging is unhealthy. A `postbuild` script (scripts/postbuild-copy-geoip-data.sh) was also added on a branch as a belt-and-braces. Also `.next` ends up root-owned while the service runs as user `nxeon` (EACCES prerender cache warnings) — promote script should be checked for chown.

**How to apply:** any deploy → hand the owner `scripts/deploy-staging.sh` / `scripts/promote-production.sh` commands (or run them if the harness allows). Restarting nxeon-worker kills in-flight jobs ("Worker restarted mid-job") — prefer quiet moments. The auto-mode classifier blocks most writes under /opt/nxeon, `prisma db push`, builds and restarts even after the owner says "do it" — hand over exact commands instead of retrying. A failed `cd` in a compound command can leave the shell in /opt/nxeon and make a "test" git merge land on real main (happened once, harmless) — always verify `pwd`.


**UPDATE 2026-10-01 (seamless deploys adopted):** `scripts/promote-production.sh` / `deploy-staging.sh` were rewritten (branch feature/seamless-promote, merged): the build now happens in a git worktree under /tank/nxeon-deploy/<env>/build (NOT in /opt/nxeon), finished builds live in /tank/nxeon-deploy/<env>/releases/<id>/, and `/opt/nxeon/.next` is a SYMLINK swapped atomically then nxeon-web restarted (~20 s cold start; auto-rollback if health checks fail; `scripts/rollback-release.sh --production`). Flags: `--dry-run`, `--accept-data-loss` (prod db push is additive-only by default), `--install-units`. Run as root only (the admin board Promote button can't). Never run `npm run build` in /opt/nxeon (a prebuild guard refuses it). Promote takes ~6 min. If the build fails on next/font (Google Fonts fetch is flaky) just rerun — nothing is changed on failure. `pgrep -f promote` false-matches your own shell; use `ps -eo args | grep '^/bin/bash scripts/promote'`.
