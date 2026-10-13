---
name: nxeon-coldemail-leaddb
description: Cold Email Engine lead DB is populated in prod (2 real lists); + the promote-production.sh npm-install outage lesson
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-11T13:12:19.351Z
---

The Cold Email Engine lead database is LIVE with real data in prod (imported 2026-08-11), via `npx tsx scripts/import-leads.ts` (idempotent, dedup by normalized email, dead/suppressed never resurrected):
- **"US Business Leads — Cold Email Ready"** — 1,709 contacts, real emails scraped from each business's own live site (OSM+scrape / ChatGPT-verified / Google Places / web-research). Vendor-domain junk (email domain ≠ website domain and not free-mail) is filtered OUT before import — see scratchpad/leads/build_import_csv.py.
- **"Web Design Prospects — No Website (US)"** — 2,681 businesses with a listed email but NO website = "sell them a site" pitch (the user's golden-opportunity idea). Kept in a SEPARATE list so it gets a different campaign.
- All contacts UNVERIFIED, consent=LEGITIMATE_INTEREST recorded. **Sending stays OFF.** Enrichment still climbing toward 10k in the background.
- The 79,652-total no-website set (mostly email-less → phone outreach) lives in scratchpad/leads/NO_WEBSITE_PROSPECTS_full.csv, not the DB.
- HARD RULE (user): never fabricate lead data — every email is real/scraped/verified. See [[nxeon-ventures-hub]].

**Deploy lesson (fixed in fefc6e9):** `scripts/promote-production.sh` did NOT run `npm install` before `npm run build`. A commit that adds a dependency (imapflow/mailparser for the CE inbox) → build fails on stale node_modules → `set -e` aborts promote BEFORE restart, leaving the OLD in-memory build serving (new routes 404, site up). A later manual `systemctl restart nxeon-web` then crash-loops on the incomplete `.next` (route dirs but no BUILD_ID) = full outage. Fix: promote now `npm install`s first AND refuses to restart if `.next/BUILD_ID` is missing. Recovery when it happens: `cd /opt/nxeon && npm install && npm run build && chown -R nxeon:nxeon .next && systemctl restart nxeon-web nxeon-worker`. See [[nxeon-build-isolation]].
