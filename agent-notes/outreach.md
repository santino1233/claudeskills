# Agent C (outreach) progress note — branch feature/partner-outreach-overhaul, worktree /opt/nxeon-wt-outreach2

## Done (committed)
- Schema (additive): OutreachCampaign, OutreachTemplate, OutreachSuppression, OutreachEvent, PartnerGrant; OutreachQueueItem +7 nullable cols.
- lib/outreach/{render,service,campaign-core,pacing,state,csv,inbound,inbox-scan,unsubscribe}.ts; lib/csv-parse.ts
- One renderer for preview/test/send; worker tick campaign-aware (worker/index.ts hooks: tick 10s, inbox scan 10m, grant sweep 1h)
- Admin UI: /admin/partners?tab=outreach, /admin/partners/outreach/[id], /admin/partners/outreach/templates/[id]; template column + template-aware Preview on invites table
- Unsubscribe route /api/outreach/unsubscribe; partner grants (lib/partner-grants.ts, actions, admin form on /admin/partners/[id], partner dashboard card)
- Docs: docs/DOCUMENTATION.md section "2026-10-01 — Outreach overhaul"
- tsc --noEmit was CLEAN (run on the tree before the final test fix).

## NOT verified
- Unit tests: first run 26/27 passed; the 1 failure (test assertion too strict) is fixed + committed but NOT re-run.
- scripts/outreach-engine-selftest.ts (throwaway-DB integration test) never ran: heavy.sh lock queue was ~30 deep.
- No dev server / Playwright render of any new UI (disk-pressure order). UI is typechecked only.
- Partner grant flow never exercised against placeGameOrder (needs a sandbox with node/plan rows).

## Re-verify (when lock is free)
  S=/tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad
  $S/heavy.sh bash -c "cd /opt/nxeon-wt-outreach2 && npx tsc --noEmit -p ."
  $S/heavy.sh $S/run-outreach-tests.sh   # unit tests + selftest; result also at $S/outreach-test-result.txt
  Throwaway DB nxeon_agt_outreach (+ role agt_outreach) still exists: `sudo -u postgres dropdb nxeon_agt_outreach; sudo -u postgres dropdb ...; psql -c "drop role agt_outreach"` when done. /opt/nxeon-wt-outreach2/.env is gitignored (delete before merging).

## Deploy notes
prisma db push (additive) then restart web + worker; the legacy 97-row queue is auto-adopted into a default campaign on first tick (or opening Outreach tab). Deleted: lib/creator-outreach-send-core.ts, lib/actions-outreach-queue.ts, components/admin/OutreachQueueUpload.tsx.
Edits outside my area: lib/mailer.ts (export injectEmailTracking + skip unsubscribe link), worker/index.ts, components/nx/PartnerView.tsx + app/dashboard/partner/page.tsx (grants card), lib/partner-invite-core.ts (csv parser moved to lib/csv-parse.ts).
