---
name: nxeon-server-controlpanel
description: cPanel-style control panel + lift-and-shift migration — BUILT & deployed; remaining deferrals + real-execution flag status
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-07-25T13:55:02.060Z
---

**Status as of 2026-07-25: BUILT, deployed to prod+staging, and the control panel is VERIFIED (a real MySQL DB was provisioned on a live VPS end-to-end).**

Nxeon server-management now has a cPanel/Plesk-style **Control panel** tab (`components/customer/cpanel/*`, Nxeon-themed) over a shared injection-safe SSH helper `lib/ssh-exec.ts`. Four bundles: Websites & PHP (nginx vhost/PHP/certbot/subdomains), Databases (MySQL/Postgres+users), One-click apps, Cron & Services (+live process monitor). Models `Website`/`VpsDatabase`/`AppInstall`/`CronJob`. Sandbox-simulated; real execution gated by `ENABLE_REAL_CPANEL=1`.

**Migration** is now a full lift-and-shift (`worker/migrate-real.ts`): passwordless DB dump/import (root socket/peer), prerequisite install (Docker/compose, DB engines, nginx, runtimes), Docker/compose + named-volume replication + bring-up + verify; broadened detection (Docker/ports/processes/`/opt`,`/srv`,`/app`); storage guardrail (size vs free disk → block + resize upsell + worker pre-flight) and OS/arch compatibility warnings + "reinstall to matching OS" recommendation. Marketing: `/migrate` page + homepage animated section.

**Real-execution flags (prod `.env`):** `ENABLE_REAL_MIGRATION=1` and `ENABLE_REAL_CPANEL=1` are SET (the user ran the one-liner — the auto-mode classifier blocks Claude from editing prod `.env`). If the box is ever rebuilt, re-run that one-liner. Staging stays sandbox-simulated regardless.

**Known deferrals (honest, flagged to user):**
- Mail **auto-reply & forwarding are store-only** — Mailcow's API has no reliable vacation/forwarding endpoint; would need a SOGo-side (sieve) mechanism to actually send/forward.
- **One-click apps**: WordPress installs end-to-end; Ghost/Nextcloud/Joomla/Matomo only provision vhost+DB+landing page (runtime finish left to user).
- **Email deliverability**: earlier test mail hit spam / was slow — needs sending-IP warm-up + DKIM/DMARC alignment (DNS/ops).
- **Real full migration never verified end-to-end** — scan + cPanel real-exec verified, but no complete real migration run has been done (needs a source server + creds).
- Server-side always-on AI auto-implement — parked (needs an Anthropic API key). Nightly heuristic scanner exists. See [[nxeon-improve-agent]], [[nxeon-platform]].
