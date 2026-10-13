# I1 nxlabs — progress note (2026-10-01)

Branch `feature/nxlabs-portal-and-preloader`, worktree `/opt/nxeon-wt-nxlabs`. All work committed + auto-pushed:
- b01fd987d5 Portal preloader: the marketing animated NX logo, looped
- 00dc9e2435 NX Labs portal overhaul in the marketing aesthetic
- 77a4e19c62 NX Labs: category filters pass member ids as one ANY(array) param

## Done
- Preloader: components/nx/Preloader.tsx + app/globals.css (.nx-pre*, keyframes nx-pre-in/draw/fill/sweep/glow in @layer components).
- NX Labs: app/dashboard/nxlabs/{page.tsx, games/[family]/page.tsx, [family]/[slug]/page.tsx, installed/page.tsx (new), labs.css, _lib/labs.ts, _lib/cards.tsx}, components/nx/labs/*.
- Shared layer (additive): lib/mods-catalog.ts (loader/gameVersion opts, "updated" sort, ModSummary.banner/loaders, listLoaderCounts, listGameVersionCounts); app/nxm/_data/mods-lib.ts (export CARD_ILL only).
- public/nxlabs/hero-collage.webp (95KB, replaces 2.5MB PNG as hero).
- docs/DOCUMENTATION.md (2026-10-01 entry) + ROADMAP.md.
- tsc clean (as of commit 00dc9e2435; 77a4e19c62 touched labs.ts/mods-catalog.ts after — RE-RUN tsc).

## NOT done (in order)
1. Re-run tsc: heavy.sh bash -c "cd /opt/nxeon-wt-nxlabs && npx tsc --noEmit -p ."
2. Visual verification never succeeded. First run used a .next symlink to /tmp, which broke module
   resolution (every page 500 "Cannot find module react/jsx-runtime") — not a code bug. Fixed script uses a
   real .next and deletes it after: heavy.sh bash /tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/nxlabs/devrun.sh
   (runs phases.sh: before = main versions of the 5 files, after = HEAD; desktop+mobile, light+dark; reduced-motion preloader;
   temp route app/dashboard/zz-preloader-demo is created+deleted by the script — make sure it's gone). Needs >=2.5GB free on /.
   Then look at every screenshot and fix what's broken; check console-errors.txt.
3. Perf note for preloader/LCP not yet measured.
4. git merge main near the end.

## Sandbox
- DB nxeon_agt_nxlabs (owner nxeon) seeded with 3,490 synthetic mods (incl. null/broken icons+gallery, no descriptions),
  user labs@sandbox.test (id cmup491a102p8hlexrygnd08v), 3 servers + ServerMod rows. Seed: scratchpad/nxlabs/seed.ts.
  Drop when done: sudo -u postgres dropdb nxeon_agt_nxlabs
- Worktree .env (gitignored) holds sandbox DATABASE_URL/AUTH_SECRET — delete before handing off.
- node_modules/@prisma and .prisma are symlinks to prod's (schema unchanged) to save disk.

## Blocked
- Copying a real GameMod sample from prod for realistic seeding was denied by the classifier (Production Reads) — used synthetic data.
