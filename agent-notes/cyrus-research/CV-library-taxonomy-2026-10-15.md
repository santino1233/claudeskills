# CV: library taxonomy (game x type) and the Made with Cyrus shelf (2026-10-15)

Branch `feature/cyrus-library-taxonomy` (worktree /tank/dev-worktrees/cyrus-taxonomy), main (rc17) merged, NOT deployed, every switch OFF. Nothing run against production.

## Taxonomy tree `tax-1` over the 62,777 staged entries (62,444 published; offline report, `scripts/cyrus/library-taxonomy-report.ts`)
An entry is listed under every registered game whose fit is good/ok; an entry fitting no game is generic ("any").

**Minecraft: 31,655**
- Blocks 10,301 (building 970, natural and terrain 990, tiles 6,561, decorative 1,780)
- Items 675 (weapons 103, armor and wearables 6, tools 66, food 187, collectibles and loot 313)
- Mobs and creatures 934 (hostile 65, passive 147, NPCs and humanoids 722, boss 0)
- Textures 202 (block 202; item and entity appear once Cyrus-made textures exist)
- Sounds 6,082 (events 3,134, ambient 2,425, music 523)
- Particles and effects 2,094 (fire 394, smoke 87, magic 431, explosions 263, weather and water 116, other 803)
- Models 185 (vehicles 185; animated and animation clips fill from Cyrus rigs)
- GUIs and HUD 8,412 (icons 766, buttons and panels 2,023, cursors 1,069, input prompts 3,301, cards 1,253)
- Worldgen 293 (trees 49, plants 244)
- Data packs 0 (kind only enters through Made with Cyrus)
- **Unclassified 2,477**

**Any game (generic): 30,789**: 3D models 10,211, textures 3,428 (PBR 2,946, decals 127, flat 355), sprites 10,171, skies 1,430, effects 1,312, animation 717, UI 1,541, **unclassified 1,979**.

**Unclassified total 4,456**, all from three sources: sprites `sprites/general` (4,040: Kenney sprites with no category signal), models `misc/uncategorised` (192), textures `misc/uncategorised` (224). They need the stage-B/AI tagging already recommended in doc 04; the mapping is not guessing.

## What shipped
1. **Taxonomy** `lib/cyrus/library/taxonomy/`: ordered rule table (Minecraft complete, generic for the rest), version field, `unclassified` bucket with counts, `registerGameTaxonomy` extension point (validated; Valheim, Terraria etc. are one call). Counts are one grouped SQL query, cached 5 min, dropped on publish/unpublish.
2. **API + UI**: `GET /api/cyrus/library/v2/taxonomy`, `/assets` (game, type, category, kind, tier, fit, author, made, q, limit <= 100, offset), `/assets/<id>`. Customer `/dashboard/cyrus/app/library/browse` + `/library/a/<id>` (use in my project, report, licence, author, used-in mods); public `/mods/cyrus/a` + `/a/<id>` behind the existing public gate. Plan gate decides `usable` (sounds Saka+, visuals All models, proprietary SFX hidden unless cleared); browsing is metadata-public.
3. **Made with Cyrus** `lib/cyrus/library/publish/` (flag `CYRUS_LIBRARY_AUTOPUBLISH`, default off, needs backend + store + URL secret): public mods only (page PUBLIC, not hidden, revision passed). texture -> texture PNG rendered from its spec; sound set -> a WAV per event (synth-only); rig spec -> animated-model; designer item / item model -> design; datapack -> datapack (two new catalogue kinds: `datapack`, `design`). Goes through `contributeAsset` so eligibility, exact + near dedupe, strict filters, quality and the hold queue all apply. Idempotent (source hash + content hash). Provenance `via mod:<project>@<revision>`; opaque contributor. Unpublish/takedown/report reuse the existing moderation; admin page `/admin/cyrus/library/made`.
4. **Never published** (unit-tested one by one): origin imported / upload / library; legal class game-derived / third-party; `base`, `gameBase`, `foundationRef`, `vanilla`, `byo`, `retention`, `libraryRef`, `derivedFrom`; an edit whose basedOn chain is refused or unknown; sound sets with a `lib:` layer (proprietary SFX); config / ui / pack.
5. **Opt-out**: default publish; per account (Setting `cyrus_library_optout:<user>`) and per mod (`cyrus_library_optout_mod:<project>`) through `POST /api/cyrus/library/v2/publish`, which unpublishes immediately (entries removed with reason `opt-out:`, entries another creator also published are never touched) and reinstates on opt-in; the sweep script reconciles every few minutes. Controls: project page card and library page; consent text single-sourced in `publish/consent.ts`, shown as a Terms section only while the flag is on.
6. **Author**: one helper `publish/author.ts`: the Cyrus username (read from `CyrusCreator.username` when the community branch's schema lands, validated, rejects emails) else "Cyrus creator"; never the account name. Seam: replace `creatorLookup` in `publish/server.ts` with `host.users` display fields if the community branch moves it there.
7. **Backfill**: `scripts/cyrus/library-publish-sweep.ts`, dry-run by default; `--apply --confirm-database <name>`.

## Schema (additive, listed)
`CyrusLibraryPublication` (model in prisma/schema.prisma + `prisma/manual-migrations/2026-10-15-cyrus-library-publication.sql`, NOT applied, `cyrusLibraryPublication` added to the CyrusDb pick list). No change to CyrusCatalogEntry.

## Decisions and risks
- **Pack name must not carry the game id**: a pack `cyrus-mod-minecraft` tripped the trademark filter and held every asset (found by test). Game membership lives in `games.<id>.fit`.
- **Published bytes are specs for rigs, designs, datapacks** (JSON), not renders: they have no thumbnail until a renderer exists; textures and sounds are real PNG/WAV.
- **UGC licence**: entries are tier `user-contributed`, described as CC0 in the consent text and Terms section; a lawyer must review the grant before the flag is flipped (also open item from doc 04). CC0 grants cannot be withdrawn; opt-out only stops further distribution.
- **Moderation load**: filters are text-only (known gap O-8); datapack `function` command strings and rig names are not pixel/audio/command classified. Expect held items; the hold queue is the capacity limit.
- **Author labels for pre-existing studio contributions** read "Cyrus creator" (no publication row maps their HMAC to an account).
- Public library shows metadata only; previews use signed URLs that need a signed-in viewer.
- Counts above are from the staged file and include near-duplicates; the live query excludes `duplicateOf`.
- `test/cyrus-library-prod.test.ts` "import guards" fails on main too (pre-existing, unrelated).
- Community branch overlap: its `app/dashboard/cyrus/app/library/page.tsx` + LibraryExplorer are untouched; my pages are new files under `library/browse` and `library/a`. Integrator should link the nav entry to browse (or embed `CatalogueBrowser`). `host/types.ts` pick list and `projects/[rootId]/page.tsx` carry one-line additions that may need a trivial conflict resolution.

## Verification
`test/cyrus-library-taxonomy.test.ts`: 33 pass (mapping table, counts, listing + page cap, SQL assembly, never-publish rules, idempotency, opt-out incl. shared + reinstate, author, flag, Terms); existing library tests pass. tsc: see end of file.

## Owner commands (nothing applied)
1. Review + apply the table: `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f prisma/manual-migrations/2026-10-15-cyrus-library-publication.sql`.
2. Dry run: `npx tsx scripts/cyrus/library-publish-sweep.ts` (with CYRUS_LIBRARY_AUTOPUBLISH=1 and the backend env).
3. Lawyer review of `lib/cyrus/library/publish/consent.ts`; then set `CYRUS_LIBRARY_AUTOPUBLISH=1` and run the sweep with `--apply --confirm-database nxeon` from a 5-minute timer.
