# AN: Minecraft reference bundle (r42, 2026-10-11)

Branch `feature/cyrus-r42-mcref` (worktree cyrus-r42), latest r2 merged. Not deployed, nothing flipped, no migration, no paid call. No Mojang file in git (a test enforces it).

## What was built
1. **Private reference index**: `/tank/cyrus-library-staging/_reference/tools/mc_index.py` writes the private sha256 manifest (23,487 files) and texture fingerprints (1,904) plus committable facts in `lib/cyrus/versions/vanilla/26.1.2/`. Loaders: `index.ts`, `reference.server.ts` (`CYRUS_VANILLA_REFERENCE_DIR`, fail closed). Diff report: `AM-vanilla-diff.md`. Every registry matches the jar and no emitter assumption is wrong for 26.1.2 (now pinned by tests); `on_shelf` and spear `swap_animation_scale` are reported.
2. **Validators**: real `vanilla_lookalike` (0 of 284 Cyrus textures match vanilla); vanilla overrides, sounds.json events with suggestions, model parent/display, legacy carriers. Wired into asset sync (`assets.vanilla`, behind `CYRUS_TESTFLIGHT_GATE`) and the Test Flight record (a note; never changes the verdict).
3. **Catalog**: about 4.8k metadata-only `v:` rows (status `reference`, game-derived, never library or servable) in `catalog_search` / `catalog_get` (`CYRUS_VANILLA_CATALOG`).
4. **BYO** (`CYRUS_BYO_GAME_ASSETS`): a **Minecraft** tab in the Texture and Sound studios. The browser reads the user's own jar or files and sends hashes only. The server re-hashes, stamps the doc game-derived (7-day retention), never contributes it, and exports delta-only.
4b. **Dev foundation** (dev only, preview/owner only, refused in production): 3 sets, node-2 copy `/tank/nxeon-build/reference/`. "Use as foundation" works in the studios. Builds get `vf:` catalog rows and a ModSpec `foundationRef`.
5. **`Minecraft Items.zip`**: 0 byte-identical vanilla files, 10 exact upscales, 613 vanilla look-alikes, 805 renders/icons, 24 large images, 18 gif/webp/jpg. Labelled provenance unknown; questions in OWNER-ACTIONS.

## Ran
- Unit: `test/cyrus-mcref.test.ts` (18) and `test/cyrus-gameassets.test.ts` (12) pass. After merging the latest r2, the full Cyrus suite passes (2,513/2,513, which includes the host seam and db-split tests), `cyrus.test.ts` passes (45/45) and tsc is clean.
- Real: `test/cyrus-foundation-real.ts` on node-2: `catalog_search` picked the stick, which became an ember-wand retexture. The unchanged copy was left out of the pack, the vanilla checks were clean, and Test Flight **passed** on Paper 26.1.2.
- Screenshots: 5 in `cyrus-designs/impl-shots/foundation-*.png` (Playwright on node-2, reviewed; a stale-search race was fixed). The Sound Studio and light-mode shots were NOT taken: `next dev` was OOM-killed twice in the full shared slice.

## Not run / not built
- Resound into a vanilla event is not wired (needs SoundSpec + JS twin).
- No BYO sweeper (expired content is refused at pack time).
- Models are reference-only.
- No real-client check; no live paid build (foundation picks tested via the TS pool path).
- `minecraft.zip` version is unidentified (newer than 26.2), so no validator uses it.
- One slip: I ran `pkill -f` on my own task id (it matched only my own shell). Nothing else was affected.

## Try it (dev host)
The devhost env for this worktree is already set and the private copy is on node-2. From `/tank/dev-worktrees/cyrus-r42`, run `devhost db reset && devhost db push`, then `devhost run -- npx tsx scripts/cyrus/studio-fixtures.ts > tokens`, then `devhost dev` and `devhost tunnel <port>`. Sign in as a fixture preview account, open Banshee Hunt -> Texture Studio -> **Minecraft** tab.
