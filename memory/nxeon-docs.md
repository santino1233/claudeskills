---
name: nxeon-docs
description: "Keep Nxeon's system documentation current with every change; how the public /docs page is built"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-15T23:51:22.805Z
---

The user wants `docs/DOCUMENTATION.md` in [[nxeon-platform]] updated with **every** change, fix, or
addition — treat a behaviour change without a doc update as incomplete.

**Why:** The user explicitly asked to "update the documentation as we continue to make changes/fixes/
additions," and uses the doc (via an AI scan) to decide what to add/change next, so it must reflect
reality.

**How to apply:**
- Edit `docs/DOCUMENTATION.md` in the SAME commit as the change: add a dated bullet to §15 (Change
  history) and update any affected section. Keep `ROADMAP.md` in sync too. This rule is codified in
  `/opt/nxeon/CLAUDE.md` → "Documentation — keep it current," which the 4-hourly [[nxeon-improve-agent]] reads.
- The doc is mirrored to a **public** page at `https://revsports.ca/docs` (no auth, `noindex`).
  Regenerate it after editing with `node /opt/nxeon/scripts/publish-docs.mjs` (zero-dep markdown→
  styled-HTML renderer → `/var/www/nxeon-docs/index.html`). The nginx `/docs` location is baked into
  `scripts/configure-domains.sh` so it survives vhost regeneration.
- **UPDATE 2026-08-15:** the OLD public `/docs` (this internal-architecture DOCUMENTATION.md mirror) was
  retired — that content now lives ADMIN-ONLY at `/admin/docs`. The route `app/(marketing)/docs/page.tsx`
  was later REPURPOSED into a clean, SAFE public **API reference** (`/api/v1`, bearer tokens — no internal
  architecture, no admin subdomain), linked from `/developers`. A STALE nginx `location = /docs {return 404}`
  block in `sites-available/nxeon-cloud` was still 404ing it; removed 2026-08-15 + re-allowed in robots.
  **Public `/docs` = the API reference and SHOULD stay live. Do NOT re-add the nginx 404 block.**
- There is also a claude.ai artifact version (curated, hand-styled) at
  `https://claude.ai/code/artifact/9b0c97f5-4c34-4f89-bee9-b5a80eb23892` — only updatable from an
  interactive session, best-effort; the repo doc + `/docs` page are authoritative.
- The user prefers **more descriptive / more detailed** documentation (define terms, worked examples,
  how-it-works prose) over terse reference.
