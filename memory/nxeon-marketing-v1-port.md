---
name: nxeon-marketing-v1-port
description: "New marketing site build — staging-only /nxm on branch feature/marketing-nxm; generators, real-data wiring, SEO layer, native pages; state as of 2026-09-27"
metadata:
  node_type: memory
  type: project
  originSessionId: ec6fa978-d80b-4147-9982-eea470598e2c
  modified: 2026-09-27T17:28:08.517Z
---

**LIVE IN PRODUCTION since 2026-09-27** (release/nxm-launch fast-forwarded into main at 49aa21912a, promoted by me on the owner's go). The code still lives under app/nxm; `NXM_ROOT=1` in /opt/nxeon/.env makes middleware.ts rewrite every URL in app/nxm/_data/live-routes.json (regenerate with `npx tsx scripts/nxm-live-routes.ts` after adding a page) to app/nxm and 301 /nxm/* to the real URL; `NXM_LIVE=1` = indexable. ROLLBACK: remove both flags from /opt/nxeon/.env + `systemctl restart nxeon-web` — the old app/(marketing) pages take over, untouched. Staging also has NXM_ROOT=1. New marketing work now branches from main (feature/marketing-nxm is merged). Launch also shipped: custom-server builder, wizard popularity tracking (/admin/popularity), VPS system logs, a 72-hour money-back guarantee (lib/refund-policy.ts — Terms/card/comparisons/support KB all read it). NOT applied: the 4-tier game prices (prisma/seed-gameplans-4tier.ts, needs owner price sign-off).

(History) The new marketing site was built on branch `feature/marketing-nxm`, worktree /root/nxeon-worktrees/marketing-nxm.
- Deploy to staging with `scripts/deploy-staging.sh feature/marketing-nxm` (https://staging.nxeon.cloud/nxm). If someone deploys main to staging, /nxm disappears.
- Everything under /nxm 404s unless `NXEON_ENV=staging`, and the pages are noindex until `NXM_LIVE=1`.

How it's built (full guide in tools/nxm/README.md on the branch):
- Generators: `tools/nxm/port_home.py` builds the homepage and `tools/nxm/port_pages.py` builds every other page. The latter runs the design package's own builders, intercepting only the base64/dist-write step. Edit the scripts, never their outputs.
- Real data: wire modules (`tools/nxm/wire/<slug>.py`) put `{{nxm:key}}` slots and `__NXM` constants into the page, and loaders (`app/nxm/_data/<slug>.ts`) fill them from the system at request time.
  - The porter's audit must say `wired` or `static` with no stale prices for every page.
  - The owner requires that nothing is hardcoded.
- SEO: registry `app/nxm/_seo/registry.ts` (seeded from live) plus `meta(p)`, `nxmMetadata`, and auto Breadcrumb/FAQ JSON-LD plus loader JSON-LD.
- Native pages (not in the design package) live in `tools/nxm/native/<slug>`. Examples: about, security, affiliate, legal (legal text moved to lib/legal, shared with the live pages).

Gotchas learned:
- Never scope CSS with `:root:has()` (causes whole-page restyle storms).
- The design's `<body class/style/data-*>` must ride on the page wrapper.
- The dev server grows to 11 GB on this production box: restart it with `NODE_OPTIONS=--max-old-space-size=4096`.
- Parallel agents in one worktree: commit only explicit paths.
- Render ported markup only through `StableHtml` (app/nxm/_components). React 19 re-sets innerHTML whenever the `dangerouslySetInnerHTML` object changes identity, even for an identical string. The promo popup's server action sets a cookie on a first visit, which refreshes the route and used to wipe the page script's work on every page.
- Design class names collide with Tailwind/global utilities (`.ring`, `.container`, `.grid`, `.dot`, `.chip`…). The `:where()` resets at the end of nxm.css handle this, so check there first for any mystery border, box or size.

Related branches (the owner promotes them):
- `fix/portal-root-class`: portal CSS `:root.nx-portal`.
- `feat/deploy-wizard-tweaks`: no discount badges, real latency (Falkenstein needs a ping endpoint on node-2), "Use a different card", standard deploy button.
- Both are merged into the marketing branch for staging.

**Regions (owner, 2026-09-27): "we plan on adding all of these regions, so stop removing them."** Keep every region/location the design or live pages show (globe, maps, counts, location pages). Only deploy/checkout links are limited to enabled nodes. A region change must never make a page throw — warn and keep rendering.

Open owner decisions (asked 2026-09-27):
- Renewal promise vs intro prices.
- Terms jurisdiction placeholder.
- Duplicate-IP server clean-up sign-off.
- "Daily backups" claims.
- Typical-host illustration.

Answered: keep homepage claims (Shield vendors, CLI/API, Samsung NVMe, Modrinth/mod.io); mention the Creator Partner Program on /affiliate as a limited-time launch offer.

**Why:** the owner wants the site exactly as designed, plus their identity picks, wired to the real system. See [[nxeon-redesign-generic-drift]] and [[nxeon-marketing-redesign-2026-09]].
