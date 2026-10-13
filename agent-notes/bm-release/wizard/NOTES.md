# bm-wizard notes (2026-10-08)
Branch feature/bm-wizard, worktree /tank/dev-worktrees/bm-wizard. Not merged, not deployed.
Screens: /root/agent-notes/bm-release/wizard/shots/ (01-05 wizard, 10-track-{queued,installing,delayed,delivered}, 20-services, 30-pay-{promo,rich}, 32-after-wallet-pay; dark+light, 1440+390).
Seed (throwaway node-2 DB wt_bm_wizard, catalogue from test fixtures, no network): .bmw/seed.ts (untracked, never commit);
  devhost env set NXEON_DEDICATED_OVH_MOCK=1; devhost run -- env NODE_OPTIONS=--conditions=react-server npx tsx .bmw/seed.ts
  then sed -n 's/^JSON//p' > .bmw/seed.json; devhost dev; devhost run -- env BASE=http://127.0.0.1:4477 node .bmw/shoot.mjs
Contract for bm-ops: payDedicatedOrder payload carries acceptedNoRefund: true + expectedTotalCents; wallet split via
lib/dedicated/wallet-view.ts dedicatedWallet() {balanceCents, spendableCents, promoCents} (interim; swap in bm-ops' helper);
tracker facts: lib/dedicated/tracking.ts TrackingFacts (fill supplierPhase in tracking-load.ts factsFor).
