# K1 modinstall — progress note (2026-10-01)

Branch feature/one-click-mod-installers, worktree /opt/nxeon-wt-modinstall. Commits f1823272c2, d98333994c, 05f11be5dd (all pushed by hook).

## Done
- Audit + coverage table for all 52 families: docs/MODS-COVERAGE.md
- Engine: lib/mods/{engine,safe-fetch,archive,paths,mirror,guest-fs,queue,facts,types}.ts
- Installers: lib/mods/installers/{minecraft,valheim,rust,cs2,factorio,index}.ts
- Worker: worker/game-mods.ts routes engine families; worker/mods-guest-ssh.ts (key first, then password)
- Actions: lib/actions-mod-installs.ts (new); lib/actions-mods.ts install/uninstall go through lib/mods/queue.ts
- UI: components/customer/gamepanel/v2/ModsPanel.tsx rewritten
- Docs: DOCUMENTATION.md game-servers subsection + change-history entry
- Verified: tsc clean (TSC_EXIT=0); 41/41 tests (test/mods-installers.test.ts, terraria-plugins, game-mods-coverage);
  scripts/verify-mod-installers.ts installs 7 real public mods into a temp fake guest then uninstalls them (all pass);
  sandbox worker run on throwaway DB: install/disable/enable/update/fail paths all correct, audit rows written.

## Not done
1. UI screenshots: Playwright was blocked by the "How did you hear about us?" onboarding modal; no usable screenshots.
   Re-run: dismiss the modal (click "Skip") in the script, then screenshot desktop and mobile.
2. Not tested on any live game server (read-only SSH probe was denied by the classifier).
3. Cleanup done (throwaway DB + role dropped, fake guests removed).

## Re-verify
cd /opt/nxeon-wt-modinstall && npx tsc --noEmit -p . && npx tsx --test test/mods-installers.test.ts test/terraria-plugins.test.ts test/game-mods-coverage.test.ts && npx tsx scripts/verify-mod-installers.ts
