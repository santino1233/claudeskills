# AX - Cyrus storage + secret admin host (r51, 2026-10-11)
Branch `feature/cyrus-r51-storage` (worktree `/tank/dev-worktrees/cyrus-r51`, from `release/cyrus-rc1` 22cfdfd90e). NOT merged, NOT deployed, no migration run, no flag flipped, nginx/DNS/Cloudflare untouched, no Stripe/email, no paid model call.

## Commits
1. `f9e056ce49` pricing function + quotas + settings (`lib/cyrus/storage/{pricing,config}.ts`, catalog group Storage).
2. `ea63836497` accounting + fail-closed write gate (`accounting`, `collect`, `collect-db`, `service`, `hooks`, `cleanup`), tables `CyrusStorageAccount/Charge/Snapshot` (SQL `prisma/manual-migrations/2026-10-11-cyrus-storage.sql`).
3. `79f636178e` Account > Storage (meter 80/95/100, per category/game/mod, full state, slider + price chart, cleanup) + add-on via Nxeon (`addon.ts`: wallet `cst:` reference = idemKey, prorated increase, decrease/cancel at period end, renewal sweep, refund reverses, reconcile, signed purchase-event path, entitlement `storage` field both sides, card subscription + webhook).
4. `b933d06627` admin `/admin/cyrus/storage` + CSV + `scripts/cyrus/storage-report.sh` + timer + `disk` alert rules.
5. `33d47f0748` hosted resource/data packs counted. 6. `e897393beb` secret admin host. 7. `2df073e325` docs + references.

## Pricing assumption (owner decision)
Rule `capped`: cost(n) = min(rate(n) x n, min over higher breakpoints of rate(b) x b). 20-50 GB = $15.00, 67-100 GB = $20.00; `graduated` / `literal` one setting away. Table in OWNER-ACTIONS "r51".

## Where Cyrus bytes live (found)
ModBuild jars `NXEON_MODBUILD_DIR/<id>.jar`, uploads + attachments under the same dir, Mod Packs `modbuilds/modpacks/<user>/`, hosted resource packs `/tank/cyrus-packs/p/<sha1>.zip` (via `result.assets`), project assets / revisions / drafts in Postgres, library contributions `CyrusCatalogEntry` (HMAC contributor id), library store/staging `/tank/cyrus-library-*`, SFX on node-2.

## Admin host: today vs after
Today: `/admin/cyrus` inside the Nxeon admin (Nxeon admin host). After (owner applies `deploy/cyrus/CYRUS-ADMIN-HOST.md`): `<secret>.cyrus.my` (`CYRUS_ADMIN_HOST`), only the Cyrus admin there, staff-only via the admin layouts, noindex, 404 elsewhere; `CYRUS_ADMIN_HOST_ONLY=1` removes it from the Nxeon admin.

## Ran (node-2 via devhost)
- Full `cyrus-*` + `modbuilder-*` suite **2809/2809**; host seam, db-split, docs-coverage ratchets pass.
- Storage DB tests (throwaway Postgres) **8/8**; bridge entitlement + purchase DB tests 12/12.
- `tsc` clean; `next build` passed (one later 3-line chart tick change not re-typechecked by tsc, compiled by next dev).
- alert-check `disk` rule and storage-report.sh dry-run on node-2.
- Screenshots (looked at, fixed scale-label collision, chart range, tick overlap, phone table): `cyrus-designs/impl-shots/storage-{meter-dark,meter-light,meter-phone,full-dark,slider-dark,slider-phone,cleanup-dark,admin-dark,admin-phone,adminhost-dark,adminhost-phone,adminhost-404}.png` (fixture data; admin host through a TLS front).

## Not run / not done
- Card add-on never ran against Stripe; GB change on a card add-on = cancel + rebuy.
- No production migration, report timer, alert rules, nginx, DNS, Cloudflare Access.
- Revision/asset history is never offered for cleanup (append-only); only old jars, drafts, uploads.
- Library byte totals rely on `entry.tech.bytes` (fixture rows had none).
- Findings: prod port 3000 listens on all interfaces; Nxeon staff/admin hostnames are public in CT logs (per-host LE certs).
- Throwaway DB `wt_cyrus_r51` + node-2 copy remain (`devhost rm`); `.studio-tokens.json` untracked in the worktree.
