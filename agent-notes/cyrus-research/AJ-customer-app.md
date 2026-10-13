# AJ - Cyrus customer app + landing motion fix (r39, 2026-10-11)
Branch `feature/cyrus-r39-customer-app` (worktree `/tank/dev-worktrees/cyrus-r39`), latest r2 `ce7d3cb83a` (r37, r38 grants, r40 notifications) merged in. NOT merged into r2, NOT deployed, no migration run, `CYRUS_CUSTOMER_APP` off.

## (0) Landing (not in git; left in `cyrus-designs/v7-landing/` for the parent to publish)
- Motion & effects card: 8 real-time three.js scenes on ONE shared WebGL renderer blitted into per-tile 2D canvases (`assets/js/motion.js`). Fire (meshgen AK: burst recoil, muzzle star + side flash, flash light, sparks, smoke, brass casings), Reload (meshgen drum LMG), Door (library `door-heavy-iron` glb + its Open/Slam_Shut clips, re-skinned planks/iron, light through the doorway, dust), Explosion, Flame, Smoke, Water (ripple shader), Arcane. 256 px procedural flipbooks with frame blending and correct additive/alpha. Reduced motion = one hero frame each; offscreen/paused tiles cost nothing; posters for no-WebGL.
- 3D card: PMREM studio environment, physical materials, soft shadows, auto-framing, slower rotate (`studio-env.js`).
- Playwright on node-2 at 1440 / reduced motion / 390: no console errors, no overflow; shots in `v7-landing/shots/`.

## (1)-(5) App (commits 1f8f16d078, 09a96a862e, a99106a512, b7f1c3c702, 9924afca54, fixes 3fe465c4e8, docs 7f6f67f171, merge 3cd0c6cb6c)
Shell, dashboard, projects + project page, new-mod flow, account. Details in docs "Cyrus customer app". Gate fails closed (switch + studio gate + preview gate on every page and action); Cyrus tables only via `cyrusDb`. Grants use r38's store (adapter in the app layer); notification prefs use r40's format and table.

## Ran
- `tsc` clean; full Cyrus suite **2577/2578**: the 1 failure is r40's `app/dashboard/cyrus/notifications/page.tsx` already on r2 (gate-pattern test), not this branch's code. Host-seam and data-split ratchets pass. New `test/cyrus-customer-app.test.ts` 14/14.
- Playwright on node-2 against `devhost dev` with fixtures (`scripts/cyrus/app-fixtures.ts`, `app-shots.mjs`): 20 shots `impl-shots/app-*.png` (dark, light, phone, tour, outsider 404). Fixed what they showed: link colours lost to CSS specificity, cost panel on the wrong side, phone tab bar and tour offset by the portal's transformed frame, long Test Flight pills.
- Real round trips in dev: API key create (shown once) and list, prefs save, data export request, grants state with `CYRUS_SERVER_GRANTS=1`.

## Not run
- `next build`, cyrus.my host mode in a browser (routing only unit-tested), a real install or rollback click (the APIs are the existing ones), real Stripe, notices actually sent.
- Personal API keys are not accepted by `/api/cyrus/v1` yet. Data requests are recorded only; staff handle them by hand.
