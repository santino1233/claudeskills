# Agent H (tours) — progress note, 2026-10-01

Branch feature/guided-first-run-tours, worktree /opt/nxeon-wt-tours, commit e913fcdd00 (pushed by hook).

## Done (committed)
- Schema: UserTourProgress (additive; back-relation User.tourProgress, cascade). Pushed only to throwaway DB nxeon_agt_tours.
- lib/tours/{types,trigger,actions,server,game,vps,hosting,domain}.ts
- components/nx/tour/{TourLauncher,TourOverlay,dom,placement,ServerTour,HostingTour,DomainTour}.tsx/ts
- data-tour attrs (attr-only edits) in GamePanelShell, GameSettingsShell, GameHero, GameSettings, GamePlayers,
  VpsPanelShell, vpspanel/v2/ui.tsx, VpsHero, VpsPowerControls, VpsOverviewPanel, HostingPanelShell,
  HostingOverviewPanel, DomainDetailShell (+aria-current on its tabs).
- Mounts in app/dashboard/servers/[id]/page.tsx (game + VPS branch), hosting/[id]/page.tsx, domains/[id]/page.tsx.
- docs/TOURS.md, docs/DOCUMENTATION.md (§ data model row + change-history entry), test/tours-trigger.test.ts (18 pass).

## Verified
- tsc clean on an earlier run (before the domain tour was added). A re-run was queued behind the heavy lock;
  output lands in scratchpad/tours-tsc.txt.
- Unit tests: 18/18 passed (run once outside the lock, before the domain tour was added).

## NOT done
1. (DONE: tsc exit 0, 18/18 tests pass on the final tree, commit e913fcdd00.) Command for later re-checks:
   heavy.sh bash -c "cd /opt/nxeon-wt-tours && npx tsc --noEmit -p . && npx tsx --test test/tours-trigger.test.ts"
2. Playwright E2E. Never run: first disk was at 2 GB free, then the lock queue was too long. Ready to run:
   heavy.sh /opt/nxeon-wt-tours/.tour-e2e/run.sh   (dev server on :3115 + seed + e2e.mjs; it kills dev on exit)
   Afterwards: rm -rf /opt/nxeon-wt-tours/.next, then look at the screenshots in scratchpad/tours-shots.
   Covers: auto-start once, persist, replay, skip/Esc, 2nd MC server no retrigger, Valheim own tour,
   impersonation no-write, mobile sheet, keyboard + focus trap, reduced motion, missing-target skip/fallback,
   hydration errors.
3. Cleanup when done: sudo -u postgres dropdb nxeon_agt_tours; rm /opt/nxeon-wt-tours/.env; rm -rf .tour-e2e
   (it is untracked, never commit it).
4. No email tour yet. The "email" key is reserved.
