# DI - rc18 final assembly (2026-10-15)

Branch `release/cyrus-rc18`, worktree `/tank/dev-worktrees/cyrus-int5`. Start: 457fc212. **Head: c66c0ad0.** Nothing pushed, deployed, promoted or applied. Every commit was made with `git -c core.hooksPath=/dev/null` so the repo's post-commit hook (`git push origin main`) could not push.

## 1. Rescued uncommitted work
| Worktree / branch | What was there | Decision |
|---|---|---|
| cyrus-integration / feature/cyrus-nxeon-integration | 32 files: networking consent on every install path (`lib/modbuilder/capability-check.ts`), shared publish gate (`lib/cyrus-mods/publish-gate.ts`), duplicate-plugin recognition (`lib/mods/plugin-identity.ts` + engine/installer `duplicates`), delivery `ownedFiles`, other-creator update rules, generic auto-updater skips Cyrus mods, server-deleted cleanup (`lib/cyrus/lifecycle/server-gone.ts`), 3 tests, docs | Real work. Its new DB test had 2 failures: (a) fixture host purposes shorter than the 8-char policy minimum (test fix); (b) **real bug**: `publishBlockedReason` took an `env` argument but did not pass it to `flightBlocks`, so the Test Flight block read `process.env` (code fix). Then 219/219 on devhost (integration unit + db + capabilities, lifecycle, delivery, mod-autoupdate, mods-installers, mods, community). Committed 61ee5b5e. `test/cyrus-nxeon-integration-real.ts` (real Paper boots) was NOT run. |
| cyrus-separation3 / feature/cyrus-separation3 | 16 staged files: modules moved to lib/cyrus/mods + lib/cyrus/builder (old paths re-export), separation-report, reverse-import ratchet | Real work, no behaviour change. 51/51 (reverse-imports, community, launch-state, mod-seo, mods, studio-gate, seams). Committed 5a2a9a51. |
| cyrus-launch2 / feature/cyrus-launch-readiness-2 | 9 files: plan-table test for Saka 5 games (code already had 5) + regenerated references | Real. 6/6. Committed 767b4c41. |
| cyrus-taxonomy | `tsconfig.tax.json` (an agent's scratch narrowed tsconfig) | Junk, left in place uncommitted. |
| cyrus-studio-ux | `.studio-tokens.json` (session JWTs for screenshot accounts) | Scratch credentials, left in place uncommitted, not copied anywhere. |
| cyrus-dungeon | not touched (agent may still be working) | Only the committed branch head 89d6aa67 was merged. |

## 2. Merges (one commit each, in order)
1. 12ccfc0a feature/cyrus-nxeon-integration: DOCUMENTATION.md keep-both.
2. cdf58826 feature/cyrus-separation3: DOCUMENTATION.md keep-both (moved files untouched since rc16, no conflicts).
3. 25dfeff6 feature/cyrus-launch-readiness-2: docs keep-both; `lib/cyrus/admin/perms.ts` actions union (analytics.export + beta.list/invite); generated refs ours until regenerate; added `beta` to the tools ABOUT map; authz row `cyrus/report/route.ts` (session).
4. 25575085 feature/cyrus-library-taxonomy: `prisma/schema.prisma` keep-both (CyrusStudioPref/analytics tables + CyrusLibraryPublication, closing brace fixed); `lib/cyrus/host/types.ts` table literals union (+ cyrusLibraryPublication); authz rows for library v2 assets, assets/[id], taxonomy (delegated, with why) and publish (viewer).
5. feeaf535 feature/cyrus-marketing-v2: docs keep-both. **Semantic conflict on game slots:** launch-readiness-2 (D-68) keeps Free's 1 as a placeholder; marketing-v2 removed it from the placeholder list. Kept D-68 (Free still a placeholder: `config-pure.ts`, `placeholder-keys.json`, game-slots test); kept marketing-v2's plan-table rows (studios, install). Owner: confirm Free = 1 to drop the placeholder.
6. 5271a95a feature/cyrus-docs-complete: `features.json` / `flag-notes.json` 3-way JSON merge (theirs' state updates + ours' new entries); README page table = docs-complete's set plus 20 content + 21 analytics; 06-portals status line + marketing-v2 line combined.
7. ec08b53b feature/cyrus-split-design: add/add `scripts/cyrus/separation-report.ts` = split-design version (adds lib/cyrus-site as Cyrus-owned); baseline later regenerated.
8. 04aeca85 feature/cyrus-qa-batch: clean (scripts only).
9. ff2176ce feature/cyrus-dungeon-run (committed commits only): clean.
Then: 7ddaf801 regenerated references; 0c436d30 tsc fix; c66c0ad0 suite fixes.

Not merged: feature/cyrus-v6-game-palworld, -v6-game-rust, -v6-library (paused, per instruction).

### Other branches checked (`merge-base --is-ancestor` vs rc18)
cyrus-recipe-memory, cyrus-speed, cyrus-structure, cyrus-preflight, cyrus-eval-realism and every other feature/cyrus-* / fix/cyrus-* branch are already ancestors of rc18 (earlier rcs). The only non-ancestors were the 7 branches merged above plus the 3 paused v6 branches. Nothing else to merge.

## 3. Fixes made during verification (root causes)
- **tsc (0c436d30):** launch-readiness-2 code had never type-checked on its branch: `CyrusAdminTab` lacked `"beta"`, `CYRUS_ADMIN_ACTIONS` lacked `"learning.guard_review"` (audit name used by adminCyrusGuardReview), `CyrusDb` lacked `"cyrusGuardRefusal"`.
- **Suites (c66c0ad0):** GDPR list + cyrusLibraryPublication (delete); flag-notes for CYRUS_LIBRARY_AUTOPUBLISH, CYRUS_SITEMAP_CONTENT, CYRUS_STATE_DIR, CYRUS_USERNAME_REQUIRED, cyrus_beta_invites; doc-owners for lib/cyrus/beta, guard, identity, studio-prefs; host seam: consent.ts declares `LegalSection` structurally instead of importing components/marketing; reverse-import baseline regenerated, new edges only `app/api/track -> lib/cyrus/analytics/web, bridge/config` and `lib/legal/terms -> lib/cyrus/library/publish/consent` (accepted deliberately); status page support mailto marked `data-by-nxeon`; worker schedule test now 15 sweeps (cyrus-guard-retention); OpenAPI regenerated (catalog kinds datapack/design were missing).

## 4. Verification (final tree c66c0ad0, all on node-2 via devhost)
- `scripts/devhost tsc`: **exit 0** (NODE_OPTIONS=--max-old-space-size=10240).
- `test/modbuilder*.test.ts test/cyrus*.test.ts test/conversion-funnel.test.ts test/list-guard.test.ts test/email-rollout.test.ts`: **4640 tests, 4639 pass, 1 fail** = known `cyrus-liveassets-e2e` "cubes appear as they arrive" (fails on rc17 too).
- `docs-build.ts --check`, `mc-coverage.ts --check`, `gen-openapi.ts --check`: all current. Generated files were pulled back with `devhost pull` and confirmed by `--check` after a fresh push.
- Note: `cyrus-live-usage-e2e` failed once in the first full run (2 subtests, timing under load); passed in isolation and in the final full run. Watch it.
- No new golden plugins were added by these merges (results.json unchanged; mc-coverage check clean).

## 5. Owner-only steps (nothing here was done)
- Manual SQL, review then apply on production BEFORE promoting (the code reads these tables/columns): `prisma/manual-migrations/2026-10-15-cyrus-welcome-and-guard.sql` (username/terms columns + CyrusGuardRefusal; required), `2026-10-15-cyrus-library-publication.sql`, `2026-10-15-cyrus-studio-prefs.sql`, `2026-10-15-cyrus-analytics.sql`, and `prisma/manual-migration-cyrus-content.sql` (CyrusModViewDay) if not already applied. Verify each against prod first; I did not check prod.
- Build-service image bump: services/modbuilder code differs from main (creatures.js, creature-spec.js, prompts.js, server.js, textures.js, tools/testflight/lib.js from more-mobs, already in rc18 before this round). This round adds only eval JSON (guard-candidates, guard-fp-recorded); GUARD_PROMPT unchanged.
- Env/switches stay OFF unless the owner decides: CYRUS_LIBRARY_AUTOPUBLISH, CYRUS_SITEMAP_CONTENT, CYRUS_ANALYTICS, CYRUS_STUDIO_SKIN, CYRUS_MEGA_STAGING etc. `cyrus_mod_networking_enabled` now gates every install path (it was only on two before), so networking mods stay refused while it is off.
- Decide Free plan game slots (still a placeholder at 1).
- Optional: run `test/cyrus-nxeon-integration-real.ts` on node-2 (real Paper boots) before promote.

## 6. Promote sequence (one order)
1. Owner applies the welcome-and-guard SQL, then the library-publication, studio-prefs, analytics and content SQL (each verified against prod first); re-run the stopped backup first (DF report B2) and set `cyrus_cost_platform_daily_cap_usd`.
2. `scripts/deploy-staging.sh release/cyrus-rc18` (c66c0ad0), click through: Welcome step, Admin > Cyrus > Beta invites, Report a problem, an install with and without a networking manifest, NxLabs publish, status page.
3. Build and roll the modbuilder image bump (more-mobs service code), health check.
4. `scripts/promote-production.sh` for the portal; worker restart picks up the new sweep (cyrus-guard-retention) and the server-deleted cleanup.
5. Post-promote: launch-check, `scripts/cyrus/beta-report.mjs`, watch worker logs for `[cyrus-guard]` / `[cyrus] server ... deleted`.
