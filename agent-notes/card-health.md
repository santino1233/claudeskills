# card-health (2026-10-05)
Branch feature/card-health-sweep, worktree /tank/nxeon-wt-cardhealth. Not merged, not deployed.
Files: lib/card-health.ts (pure), lib/card-health-live.ts (prisma+stripe retrieve), worker/card-health.ts, worker/index.ts (add "card-health"), prisma CardHealthFinding (additive), lib/settings.ts (card_health_sweep_mode=off, card_health_max_per_run=120), admin page + CardHealthControls + 3 server actions, test/card-health.test.ts (20), docs/DOCUMENTATION.md.
Verified: tsc 0 errors; suite 46 failures (same as main); new tests 20/20. No live Stripe calls made.
Design: enforce only for hard reasons, double-read before marking, unknown never marks, ladder idempotency reused.
