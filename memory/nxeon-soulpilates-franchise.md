---
name: nxeon-soulpilates-franchise
description: "Soul Pilates multi-location / franchise framework — planning stage on the SP board (no code yet), decisions + build sequence"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-08T10:47:33.272Z
---

Soul Pilates is opening a **second location** (then many more) and wants a multi-location framework. PLANNING ONLY so far — the user said no code work yet. Mapped as a **"Franchise Framework"** stage (column `cmsk8wzj20001hlhvapj62t9r`) placed BEFORE Ideas on the Soul Pilates board (`cmsavfvil000hhla4nlpuyge6`), 16 cards, all labelled `franchise`. See [[nxeon-board]], [[nxeon-server-topology]] (SP = .200 .NET+Astro CRM).

**DECISIONS LOCKED (2026-08):**
- **Company-owned** (NOT franchised to third parties) → no franchisee data isolation, no royalty engine, no inter-owner settlement, no franchisee portals; financials fully unified; location scoping is for operational focus/accountability, not security walls.
- **"Master washout" = the EXISTING washout page, aggregated across all locations** (per-location filter + consolidated view) surfaced in the HQ portal. Base it on the current page's logic + add a Location dimension — no new financial concept.

**Requirements captured (cards):** one shared/global **client DB** (book anywhere, one login/history, optional "home location"); **location entity** (name, address, geo lat/lng for map pin, timezone, hours, per-location social handles) as the foundation everything scopes to; **staff sidebar location switcher**; **client-side location picker at booking with a Google Maps pin** (same domain — needs a Google Maps API key, external cred); **booking history shows location attended**; **master (HQ) portal** = cross-location analytics · schedule/calendar · settings · washout; **location-scoped roles** (+ regional-manager tier); **package/credit portability + per-location revenue reconciliation**; **shared-vs-per-location config matrix** (brand/templates central; schedule/pricing/address/tax/social local); **turnkey location-onboarding template** (clone schedule/pricing from an existing site); **instructors across locations**; **migration plan** (backfill existing data to "Location 1 · Da Nang", staged rollout, keep the live business safe).

**Recommended build order** (from the North Star card): Location entity + scoping → shared client DB + booking-history-by-location → staff switcher + client Maps picker → location-scoped roles → master portal (analytics/schedule/settings/washout) → location onboarding template.

Next step when the user is ready: turn this into a sequenced, live-safe build plan (SP is a LIVE business — staging-first, --env-file prod.env).
