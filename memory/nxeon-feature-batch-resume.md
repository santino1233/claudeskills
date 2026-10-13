---
name: nxeon-feature-batch-resume
description: DEPLOYED 2026-07-27 — the 5-feature batch (website builder + observability) shipped; follow-ups noted
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-07-27T14:25:21.670Z
---

**STATUS: DEPLOYED & VERIFIED LIVE 2026-07-27 14:22 UTC.** Integrated centrally,
squashed to main (b1d2785), pushed, wip branch deleted. tsc clean, 722 tests, next
build exit 0. All 7 tables live; /status writing HealthSample rows; /dashboard/sites,
/admin/backups, /admin/logs?tab=errors all built & gated. Lesson banked: four parallel
agents can blow the account session limit — resume with SendMessage (context intact)
after the reset, don't restart. FOLLOW-UPS: Website Builder Publish is DORMANT (editor
works; Publish throws until a shared builder host + ENABLE_REAL_PUBLISH=1 +
SITE_BUILDER_SERVER_ID/BASE_DOMAIN); plus tasks #69 (VM.Backup grant), #70 (build-with-AI
picker + claude CLI on guests), #71 (admin RAM counts ZFS ARC). The notes below are
now historical.

User asked (2026-07-27) for 5 features: (1) Website Builder — start it (plan in
docs/PLAN-WEBSITE-BUILDER.md, GrapesJS static-export MVP); (2) beef up public
/status health; (3) deeper admin health dashboard; (4) admin Backups UI; (5) admin
Error Logs. Dispatched 4 parallel agents; ALL FOUR died mid-write on the shared
account session limit (resets 2pm UTC).

**Partial work preserved on branch `wip-feature-batch-20260727` (commit dfc4313).**
`main` is CLEAN at 926c200 (= origin/main = deployed). DB has 0 new tables
(prisma db push NEVER run — do it at integration). grapesjs@0.23.3 +
grapesjs-preset-webpage@1.0.3 installed in node_modules.

**Schema I froze (in schema.prisma on wip branch, validated):** models Site,
SitePage, SiteVersion, SiteAsset, ErrorLog, HealthSample, StatusIncident; JobType
+SITE_PUBLISH +SITE_UNPUBLISH. All additive/nullable; Site.websiteId is a scalar FK
(no relation) so it never touches Website.

**Completeness at interrupt (finish these):**
- ERROR LOGS ~90%: lib/log.ts (DB persistence at the choke point, dedup by
  fingerprint), lib/actions-errors.ts, components/admin/ErrorLogViewer.tsx,
  app/admin/logs/page.tsx (Errors tab) all written. MISSING: tests. Also wire a
  logError call at worker/index.ts job-failure catch (source="job").
- HEALTH ~70%: lib/monitoring.ts (sampleHealth + readers), worker/monitor.ts,
  lib/actions-status.ts, app/status/page.tsx, app/admin/monitoring/page.tsx written.
  MISSING: components/status/* (auto-refresh, timeline, incident list) — the pages
  IMPORT these so the tree does NOT compile until they exist. Also tests. Wire
  sampleHealth() into worker/index.ts monitor loop (~line 1301 by sampleServerDisks).
- WEBSITE BUILDER ~20%: only lib/site-render.ts + lib/site-templates.ts (pure).
  MISSING: lib/actions-sites.ts, worker/site-publish.ts (atomic publish, model on
  worker/websites.ts, gate ENABLE_REAL_PUBLISH), app/dashboard/sites/**,
  components/customer/site-builder/** (GrapesJS client), customer nav entry, tests,
  worker/index.ts handler wiring (SITE_PUBLISH/SITE_UNPUBLISH).
- BACKUPS 0%: nothing written. Build app/admin/backups + lib/actions-backups-admin.ts
  (fleet-wide listAllBackups via nodeTargets/listBackupsOn, join vmid→Server, ADMIN
  restore re-validating volid) + components/admin/BackupsAdmin.tsx. Nav entry in
  lib/admin-groups.ts (fleet) + rbac HREF_AREA /admin/backups→fleet.

**Central wiring I own (agents must not touch):** worker/index.ts (handlers +
monitor loop), lib/admin-groups.ts, lib/rbac.ts, prisma/schema.prisma, package.json.

**Integration recipe (unchanged):** finish streams → tsc clean → npm test → next
build in scratch copy (NOT in-place) → user runs `npx prisma db push` (prod-gated,
classifier-blocks me) → deploy (systemctl restart nxeon-web nxeon-worker) → verify →
merge wip→main → push. Related: [[nxeon-resume-point]], [[nxeon-platform]].
