---
name: nxeon-visitor-device-analytics
description: "2026-08-23 — added device type / OS / browser breakdowns to admin visitor analytics (ua-parser-js), live + staging synced, 4000+ historical visits backfilled."
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-23T23:04:41.091Z
---

Shipped commit 5b0f280, live + staging synced. User asked to track visitor device (Desktop/Mobile/Tablet), OS (iOS/Android/Windows/macOS/…), and browser.

**What shipped:** `Visit.ua` was already captured on every request — added 3 new nullable columns (`deviceType`, `os`, `browser`), parsed at ingest time in `app/api/track/route.ts` via a new `lib/ua-parse.ts` (`ua-parser-js@2.0.10`), and 3 new `topDeviceTypes`/`topOperatingSystems`/`topBrowsers` functions in `lib/analytics.ts` mirroring the existing `topCountries` groupBy pattern. Rendered as 3 new `<RankedList>` cards on `app/admin/visitors/page.tsx` (the real traffic dashboard — not `app/admin/analytics/page.tsx`, which is revenue-focused). Backfilled all 4,003 existing visits that already had a stored `ua` via `scripts/backfill-ua.ts`.

**ua-parser-js v2 API note:** callable directly as `UAParser(ua)`, not `new UAParser(ua).getResult()` (that's the v1 API). `device.type` is `undefined` for ordinary desktop browsers — the library has no positive "desktop" signal by design — so `deviceType` defaults to `"Desktop"` when unset. Correctly disambiguates iPad (tablet+iOS) from Mac (no type+macOS).

**Bug hit twice, same root cause:** `import "server-only"` in `lib/ua-parse.ts` broke any plain-`tsx` process that imports it — first the backfill script, later would have hit prod's `worker/index.ts` too if left in. Same class of bug as an earlier session's `lib/google-ads.ts`/`lib/riddle.ts` worker crash (`server-only` has no valid entry point outside a bundler). Removed the import; documented why in the file. **Lesson: any new `lib/*.ts` file must NOT have `import "server-only"` if there's any chance a plain-tsx script (backfill, worker) will import it — check call sites, not just the primary intended caller.**

**Deploy-tooling gotcha confirmed again:** `promote-production.sh`'s `npm install` step (even a no-op "up to date") can leave main's `node_modules/@prisma/client` stale relative to a `prisma generate` that was only run in a sibling worktree — even though `node_modules` is nominally shared/symlinked. Always re-run `npx prisma generate` (and `npx tsc --noEmit`) directly in `/opt/nxeon`'s own tree right before `promote-production.sh`, not just in the worktree, after any schema change.

**Also hit:** a stale `next start` scratch-verification server from an earlier, already-deleted worktree (`nxeon-wt-stripfix`) was still squatting on port 3998, silently swallowing a "verify locally" curl test and making it look like the new fields weren't being written (they were — just not by the server I thought I was hitting). Confirmed via `ss -tlnp` + `/proc/<pid>/cwd` showing `(deleted)` before killing it. **Lesson: always verify which process actually owns a scratch port before trusting a "success" from `npm start &` — a background start can silently fail with EADDRINUSE while the shell shows no error.**

Verified end-to-end on live prod: POSTed a synthetic iPhone UA to `/api/track`, confirmed the `Visit` row landed with `deviceType=Mobile, os=iOS, browser=Mobile Safari`, then deleted the test row.
