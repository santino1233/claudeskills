# Cyrus v6 community: notes for the merge + owner

Branch `feature/cyrus-v6-community` (worktree /tank/dev-worktrees/cyrus-v6-community). Full write-up:
docs/DOCUMENTATION.md "Cyrus community (v6)".

## Migration
Additive only. `npx prisma db push` creates 10 new tables (CyrusModListing, CyrusModMedia, CyrusRemix,
CyrusModStar, CyrusModRating, CyrusLibraryItem, CyrusCreator, CyrusCollection, CyrusCollectionItem,
CyrusCommunityReport). No existing table/column changes, no relations, no data-loss prompt expected.
Images are stored under MODBUILD_DIR/nxlabs-media (same disk as the jars).

## Merge points (shared files, all small + additive)
- lib/cyrus/types.ts: `Mod.library?`
- lib/cyrus/store.ts: `libraryMods` + `setLibraryMods`; useAllMods/findMod/useMod include them
- lib/cyrus/forge.ts: refuse prompting a library node ("Remix it first")
- components/cyrus/cosmos/graph.ts + Network.tsx + app/dashboard/cyrus/studio.css: `is-library` pill
- components/cyrus/preview/PreviewPanel.tsx: library branch + NxLabs button in the mod header
- components/cyrus/CyrusApp.tsx: `<CyrusLibrarySync />`
- lib/cyrus-mods/registry.ts loadCyrusJar: others' servers may take PUBLISHED mods (mayInstallChain)
- lib/actions-cyrus-mods.ts forkCyrusMod -> delegates to remixCyrusMod (no unscanned fork path left)
- prisma/schema.prisma: block at the end
- Duplicates to reconcile: `components/cyrus-mods/BuiltWithCyrusBadge.tsx` + public/cyrus/community/badge-*.webp
  (studio-ui owns components/cyrus/brand/); `ModListingInput` in lib/cyrus-mods/listing.ts (routing owns
  lib/cyrus/listing.ts: re-export this superset); categories come from lib/cyrus/data CATEGORIES today,
  swap to routing's universal list (saveModListing + edit page + library.ts).
- lifecycle agent: `switchCyrusVersion` (lib/actions-cyrus-installed.ts) still checks `b.userId !== server.userId`;
  for community installs it should use `mayInstallChain` too, otherwise switching versions of an installed
  community mod says "Not found".

## Owner decisions
1. Default remix setting = OPEN (code is open source anyway). OK?
2. Installing someone else's PUBLISHED Cyrus mod on your own server is now offered (was "not offered").
3. Community-tested thresholds: 5 other accounts, 3 ratings avg >= 4.0, no open bugs on current version,
   newest MC, safety pass, 7 days out. Tune?
4. Ratings only from installers (anti-spam). Stars from anyone signed in.
