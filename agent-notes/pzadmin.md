# pzadmin (2026-10-02)
Branch feature/pz-admin-password-apply, worktree /opt/nxeon-wt-pzadmin (real node_modules copy). Not merged/deployed.
Files: worker/zomboid-admin.ts (new), worker/game-config.ts (dispatch), lib/game-config.ts (REAL_APPLY_FAMILIES + LIVE_APPLY_FIELDS/fieldAppliesLive + help text), components/customer/GameSettings.tsx, test/zomboid-admin.test.ts, docs/DOCUMENTATION.md.
Gotcha: bcryptjs v3 emits $2b$; jBCrypt wants $2a$ -> prefix rewritten.
Not run live. ADMIN_USERNAME deliberately not applied live.
