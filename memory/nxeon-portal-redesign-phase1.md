---
name: nxeon-portal-redesign-phase1
description: "Portal redesign Phase 1 (audit + blueprint) COMPLETE 2026-09-03, awaiting owner approval before any Phase 2 implementation"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1716c7ee-ae35-4cf5-b557-9059709e07c4
  modified: 2026-09-03T18:10:18.879Z
---

The Nxeon customer-portal redesign runs in phases from the carry file `/root/nxeon-redesign-phase1-brief.md`.

**Phase 1 finished 2026-09-03.** Deliverable is the "Portal Redesign Blueprint" artifact:
https://claude.ai/code/artifact/87ed7e7e-9ed6-4567-8769-c4e79ad59e80

Ten read-only audits back it. Their full reports are kept at `/root/nxeon-phase1-reports/`
(routes/IA, design system, assets, VPS, games+freeMC, hosting/sites/build/tools, account/billing,
funnels, states/a11y/terminology, competitor UX) plus my own direction drafts. The
domains/SSL/email/webmail audit was pre-existing at `/root/nxeon-phase1-completed-audit-domains.md`.

**Standing rules for this project (from the brief, still binding):**
- The backend NEVER changes — this is frontend/UI/UX/IA/visual-identity only, in every phase.
- Phase 2+ implementation happens ONLY in an isolated sandbox with no real backend connectivity
  (`/opt/nxeon-sandbox`, service `nxeon-sandbox-web` :3002, flow.k9x4rq7wpz2ah6t.nxeon.cloud).
- Clean-sheet identity: do NOT reuse the old redesign memories or the prior "Portal Redesign Atlas".

**Why:** the owner wants a premium infrastructure product, not a reskin, and the capability audits
are the "nothing gets lost" safety net for ~200 capabilities the screenshots never show.

**How to apply:** do not start Phase 2 until the owner approves the blueprint. When they do, the
order is design system → app shell → navigation → purchase funnel, and the purchase funnel comes
before the dashboard and every product surface.

Phase 1 also surfaced live defects that are independent of the redesign and worth fixing on their
own — see [[nxeon-portal-live-defects-2026-09]]. Related: [[nxeon-platform]],
[[nxeon-build-isolation]], [[nxeon-server-controlpanel]].
