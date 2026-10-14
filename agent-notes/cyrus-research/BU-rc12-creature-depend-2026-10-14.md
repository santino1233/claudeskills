# BU rc12: creature mods declare BetterModel, honest Test Flight failure (2026-10-14)

Branch `release/cyrus-rc12` (worktree /tank/dev-worktrees/cyrus-rc12, from main bf93b4bd which already contains rc10 + rc11), head 664076ac, 1 commit, NOT promoted, NOT deployed.

## Root cause
Owner's goblin mod (mb7714738f123ea861d24a): custom/GoblinManager.java imports kr.toxicity.model.api.*, plugin.yml has no depend. The only check was a soft creature warning ("one repair, then warnings"), so the build shipped; Paper then refused to enable it (Test Flight plugins_enabled failed) while the portal said succeeded.

## Changes (services/modbuilder, image 0.19)
- autofix.js `fixPluginDepends(yml, java, parse, force)`: text-level edit (comments and other keys untouched), handles no key, inline list, scalar, block list, empty key; BetterModel is always `depend` (moved out of `softdepend`, an emptied softdepend is removed). Result must parse and declare the plugin, else null (soft check stays as backstop). Never touches `load`.
- Other managed plugins (table from lib/cyrus/import/deps.json packages): PlaceholderAPI me.clip.placeholderapi, Vault net.milkbowl.vault, LuckPerms net.luckperms.api, ProtocolLib com.comphenix.protocol become `softdepend` when imported and not declared in either list (never depend: whether the main class would fail without them is not knowable from the sheets). Imported (rec.imported) plugins are skipped.
- server.js: runs in the autofix block before assetRound (so the creature check already sees it), forces BetterModel when the build has creature specs, event "Autofix: added depend: [BetterModel] to plugin.yml (...; no model round)", recorded in rec.autofixes / usage.autofix.
- creatures.js: result carries `dependMissing`; assetRound throws a clear compile failure ("plugin.yml does not declare BetterModel ...") after the asset repairs are used up instead of shipping the warning (no extra model loop).

## Portal
- lib/cyrus/app/failure.ts `flightFailureOf(build)`: only a DONE flight with verdict failed on a succeeded build. Project page (app/dashboard/cyrus/app/projects/[rootId]/page.tsx) shows a role=alert card "This mod did not load in our test server: <check detail>", failed checks, "We are not charging for the repair. Use Refine to fix it...", and a Refine button to the studio.
- lib/cyrus-mods/featured.ts loadFeaturedCards drops pages whose current version flight failed (marketing + cyrus.my feed); admin adminCyrusFeatureListing refuses to feature one. Existing CYRUS_TESTFLIGHT_BLOCK_ON_FAIL publish gate unchanged.

## Billing (report only, NOT changed)
Build status stays succeeded; tokens are settled at build settle (lib/cyrus/tokens/builds.ts settleBuildTokens) before the async gate worker flies it. The only refund mechanism is for status failed (reservation release). The banner says "not charging for the repair" which matches the existing rule that Refine of a failed boot is a change build. Options if the owner wants a refund: (a) in the gate worker, on verdict failed, call a new ledger credit for that build's settled charge (needs a new reason code + idempotency key); (b) make the fix-up Refine free via a waiver flag on the child build. Decision needed; not implemented.

## Tests
test/modbuilder-rc12-depend.test.ts (goblin fixture test/fixtures/cyrus-rc12/*, shapes, move, idempotent, other plugins, parse refusal, creature backstop), test/cyrus-flight-failure.test.ts. tsc 0. modbuilder*/cyrus* suites: 3778 tests, 3775 pass; 3 fail: docs refs (regenerated, now passes) and 2 pre-existing and unrelated (email templates link /cyrus; authorization matrix route inventory), no file of mine involved.

## Owner commands
Portal: `cd /opt/nxeon && git merge --ff-only release/cyrus-rc12 && bash scripts/promote-production.sh --skip-staging-check`
Image (service idle): `cd /tank/dev-worktrees/cyrus-rc12 && TAG=modbuilder:0.19 bash scripts/cyrus/deploy-modbuilder.sh`
The goblin mod itself is not repaired retroactively: use Refine on it after 0.19 (the autofix adds the depend in the first round).
