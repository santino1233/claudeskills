---
name: nxeon-retention-winback-emailtrack
description: "2026-08-24 — account-retention admin view, dormant-account win-back email automation (gated off), and email open/click tracking across all sends + admin Email log. Live + staging synced."
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-24T21:00:27.594Z
---

Shipped in 3 commits (dd7f41f, 5d83cbc, 634d156), merged + deployed, live + staging synced.

**Trigger:** user asked me to check whether people who create accounts return to the platform. I found only ~5% do (see [[nxeon-visitor-device-analytics]]-adjacent investigation — not its own memory, was inline in that session). User then asked for: (1) a permanent retention view, (2) "a way to get people back", (3) mid-turn: email open/click tracking on the Email log page, (4) mid-turn: make sure the new win-back doesn't conflict with the existing deploy-wizard win-back.

**1. `/admin/retention` (`lib/retention.ts`):** No `lastLoginAt` on `User`, so `signupRetentionRows()` unions `_max(createdAt)` grouped by userId across Visit + WalletTransaction + Server + Ticket + Project + Invoice + HostingAccount + AuditLog, scoped to `REVENUE_USER_WHERE` (excludeFromRevenue: false) + non-admin — the same "real customer" filter already used for revenue/MRR (`lib/admin-metrics.ts`). Page shows day-1/7/30 return-rate StatCards, weekly signup cohorts, and a full per-account table.

**CORRECTION (2026-08-24, found while investigating deploy-page dwell time):** the claim above that "`VisitTracker` only mounts in the marketing layout, not the portal" was WRONG — I'd only grepped `app/` for the string `VisitTracker`. It's actually also mounted in `components/portal/Shell.tsx` (`<VisitTracker kind="portal" />`, line ~474) — a directory outside `app/` my grep didn't cover — so `Visit` rows with `kind="portal"` DO exist for every `/dashboard/*` page, including real per-page `durationMs`. The broader activity-union approach above is still the right design (it's strictly more complete than Visit alone regardless), but don't repeat "the portal isn't visit-tracked" as a fact — it is. Confirmed via `SELECT count(*) FROM "Visit" WHERE path LIKE '/dashboard/%'` returning real rows with real `durationMs` values.

**2. Dormant-account win-back (`worker/dormant-winback.ts`):** Gated off by default (`dormant_winback_enabled`, admin panel at Settings → Dormant win-back). Targets accounts with zero activity since signup at all — broader than the pre-existing `worker/deploy-winback.ts`, which only targets wizard abandoners. **Critical fix from user follow-up:** the two sweeps could otherwise double-target the same person (someone who started the deploy wizard generates `DeployFunnelEvent` rows, which are NOT part of the retention activity union, so they'd look "dormant" too) — fixed by excluding anyone with ANY `DeployFunnelEvent` row from the dormant sweep's candidates, making the two audiences disjoint by construction. Coupon `WEMISSYOU30` (30% off) — must be created in the Coupons engine before enabling, same pattern as the existing `COMEBACK50`.

**3. Email open/click tracking (`lib/mailer.ts` `injectEmailTracking`):** Every `sendMail()` call now mints an `EmailLog` id up front (`randomUUID()`), rewrites every non-secret `<a href>` to `/api/track/email/[id]/click/[idx]` (positional index into a new `EmailLog.links` JSON array — NEVER a client-supplied URL, so it can't be an open-redirect), and appends a 1×1 pixel at `/api/track/email/[id]/open`. Shown as badges + rate cards on `/admin/logs?tab=email`.

**Security-critical design decision:** `lib/email-render.ts` already redacts bearer-secret query params (`token`, `code`, `key`, `secret`, `otp`, `invite`, `auth`, `sig`, `password`, `pw`) from the STORED `html` — a prior hardening fix so a leaked/browsed EmailLog row could never hand out a working password-reset link. Naively storing the raw destination in a new `links` array would have silently reopened that exact hole via a plain unauthenticated GET route. Fixed by exporting `containsSecretQueryParam()` (stateless — the shared regex is `/g`-flagged and `.test()` on it carries `lastIndex` across calls) and skipping rewrite/storage entirely for any such anchor; it's left untouched in the sent email and still gets redacted in the stored html as before.

**Also had to guard the admin preview:** the stored html now carries a live tracking pixel, so opening the Preview modal in `EmailLogViewer` would fire a real "open" event for every admin click. Fixed with `stripTrackingPixel()` before setting `srcDoc` — click links are left as-is since the iframe's `sandbox=""` already blocks navigation.

**Deploy-tooling gotcha (recurring, same as [[nxeon-visitor-device-analytics]]):** after `git merge --ff-only` into `/opt/nxeon` main, `npx prisma generate` must be re-run directly in that tree (not just the worktree) before `promote-production.sh` — its `npm install` step leaves the shared `node_modules/@prisma/client` stale relative to a schema change made only in a sibling worktree, even though `node_modules` is symlinked. Did this proactively this time and the first deploy attempt succeeded.

Verified end-to-end against live prod: sent a real test email via `sendMail()`, confirmed the secret-bearing link was left unrewritten (and still redacted) while the plain link was rewritten to a working click-redirect, hit the live open pixel and click endpoints, confirmed `EmailLog.openedAt/clickedAt` updated, confirmed a bogus click index falls back safely to the homepage instead of erroring, confirmed the dormant-winback sweep is inert with the setting unset, confirmed the worker restarted clean with no import-chain crash. Cleaned up all test EmailLog rows afterward.
