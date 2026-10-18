# DZ: Minecraft as Cyrus's main SEO source (2026-10-18)

Branch `feature/cyrus-minecraft-seo`, worktree `/tank/dev-worktrees/cyrus-mc-seo`, from main `af5a1d55`. NOT merged, NOT deployed. No migration. Every new flag is OFF. Model spend: **$0** (all example builds are deterministic; the dev generator uses the recorded-fixture backend). Docs: `docs/cyrus/34-minecraft-seo.md`.

## What shipped

| # | Item | Flag | Key files |
|---|---|---|---|
| 1 | Schematic export for players: room spec -> `.schem` (Sponge v3, WorldEdit/FAWE) and `.nbt` (vanilla). A **thin adapter** over Room Studio's existing `generateRoom` + `exportRoom` (no second exporter). Markers stripped. Size limits are warnings, except the spec's crash-safe bounds. | none | `lib/cyrus/public-builder/schematic.ts`, `test/cyrus-schematic.test.ts`, `test/cyrus-schematic-real.ts` |
| 2 | Public build generator: prompt or picture -> live preview -> download | `CYRUS_PUBLIC_BUILDER` | `lib/cyrus/public-builder/*`, `app/api/cyrus/public/v1/**`, `components/cyrus/web/BuildGenerator.tsx`, `build-worker.ts`, page `app/(cyrus-web)/cyrus-web/minecraft/build-generator` |
| 3 | `/minecraft` SEO cluster (20 pages: hub, 5 tool pages, builds index, 7 build-idea themes, 4 version pages) with 15 example builds | `CYRUS_MC_SEO` | `lib/cyrus/minecraft-seo/*`, `app/(cyrus-web)/cyrus-web/minecraft/**`, `components/cyrus/web/McPage.tsx`, `public/cyrus/mc/**`, `scripts/cyrus/mc-seo-artifacts.ts` |
| 4 | Docs (34 page, flags, doc-owners, DOCUMENTATION.md, regenerated references), launch checklist, this report | - | - |

Example builds:
- 8 are Room Studio's worked examples; 7 are new specs (medieval tavern + cottage, modern living room + atrium, spawn plaza + hall, PvP arena), made with kit palette overrides.
- The new kits were NOT added (that would have changed the generator and the service bundle).
- Previews are WebP (10-67 KB). There are 18 OG JPEGs (36-64 KB).
- Downloads are compiled on request and cached.

Structured data: BreadcrumbList on every page, FAQPage, SoftwareApplication (hub and tools), HowTo (2 pages, real steps only), and ItemList of builds on the theme pages. All were seen in the rendered pages.

## Verification
- `devhost tsc`: 0 errors.
- Tests (devhost):
  - new: `cyrus-schematic` 5/5, `cyrus-public-builder` 7/7, `cyrus-mc-seo` 6/6;
  - with roomstudio, roomstudio-image, host-seam, db-split, db-seam, seo and content: 145/145;
  - docs-coverage + admin-r40: 64/64;
  - nginx-vhost (node-2).
- `devhost build`: EXIT=0. First-load JS: `/cyrus-web/minecraft*` 106 kB (route 1.04 kB). Generator 110 kB (route 5.22 kB); the preview generator is in a worker that loads on the first preview.
- **Real Paper + WorldEdit flight** on node-2: 1.21.11 + WorldEdit 7.4.2 **73/73**, and 1.21.1 + WorldEdit 7.3.9 **73/73**. 5 builds each: `/schem load`, `//paste`, `/place template` from a data pack (the 56-wide castle included), probe blocks checked with `execute if block`. Record: `mc-schematic-flights-2026-10-18.json`.
- Findings from the flight:
  - WorldEdit 7.4 console syntax: `//pos1` and `//paste`; the file name needs its `.schem` extension.
  - Gravel and sand fall when a build is pasted in mid-air (expected; the probes skip them).
- Screenshots (dev instance, flags on, fake backend): `agent-notes/cyrus-research/screens-mc-seo/` (01 hub, 02 castles, 03 schematic generator, 04 version 1.21.11, 05 builds index, 06 generator after a generation, 07 mobile).

## Touch points other agents own (merge notes)
- Room Studio core (now owned by feature/cyrus-room-studio-v2):
  - **Functions this branch depends on:** `generateRoom`, `composeRoom`, `renderComposed`, `exportRoom` / `EXPORT_MIME`, `startRoomJob` / `pollRoomJob` / `ROOM_START_MAX_BODY`, `roomStudioDeps`, `fakeRoomBackend`, `ROOM_EXAMPLES`, `KIT_IDS` / `KITS`, `REF_IMAGE_LIMITS` / `REF_IMAGE_CLIENT_SIDE`, `parsePartialJson`.
  - **The one edit in `lib/cyrus/structures/studio/`:** `jobs.ts` gets an optional `RoomStudioDeps.policy` (`gate`, `hold`, `charge`; absent = unchanged behaviour). The public builder needs it to skip the plan gate, start free generations without a reservation and charge a fixed price.
  - The RoomStudio UI is untouched. The image re-encode helper is copied to `components/cyrus/web/ref-image.ts`.
  - If v2 renames those functions, only `lib/cyrus/public-builder/{schematic,http,deps}.ts` and `lib/cyrus/minecraft-seo/render.ts` need updating.
  - The new "any build" generator should make the house and ship examples nicer; regenerate with `mc-seo-artifacts.ts`.
- Marketing shell (feature/cyrus-marketing-v2):
  - The Minecraft pages render inside the content-page layout `app/(cyrus-web)/cyrus-web/layout.tsx`, through ONE seam `components/cyrus/web/McShell.tsx` (wired in `minecraft/layout.tsx`). Swap its body for the new shell. There is no own nav or footer.
  - The only layout edits are the visibility gate (`mcOn` / `builderOn`) and the `_ctx.ts` surface `minecraft`.
- nginx: `deploy/cyrus/nginx-cyrus-my.conf` (+ `.patch`) adds `minecraft` to the app-path list. I never ran nginx on the primary; the vhost test ran only through devhost on node-2.

## Owner decisions
1. **Prices** (host settings, placeholders):
   - `cyrus_public_builder_anon_per_day` = 2;
   - `cyrus_public_builder_anon_global_per_day` = 40 (the spend guard);
   - `cyrus_public_builder_free_first` = 1;
   - `cyrus_public_builder_price` = 0. 0 means the Room Studio hold settled at measured cost; set a fixed token price if wanted.
2. **Canonical host**: default and recommended is cyrus.my (indexable there only). nxeon.cloud serves the same pages at `/cyrus-web/minecraft/**` as noindex without a canonical, so there is no duplicate content. Say if nxeon.cloud should be canonical instead.
3. Example downloads are public (no sign-in); downloads of your own generated builds need an account. Flip this if you want sign-ups gated on examples too.
4. Public generation runs real model calls: it needs the build service on an API key, not the subscription. Keep `MB_ROOM_BUDGET_USD_HOUR` low at launch.

## Launch checklist (short; full one in docs 34)
1. Merge and promote. No image change is needed.
2. Apply the nginx vhost (syntax check on node-2).
3. Turn on `CYRUS_MC_SEO=1`.
4. Turn on `CYRUS_SITEMAP_CONTENT=1` and set `cyrus_content_index_enabled=true`.
5. Submit `https://cyrus.my/sitemap.xml` in Search Console and Bing, and inspect `/minecraft` and `/minecraft/builds/castles`.
6. After the API key: turn on `CYRUS_PUBLIC_BUILDER=1` and run one anonymous and one signed-in build.

Measure:
- impressions, clicks and position per page;
- generator starts, completions and downloads (`cyrus_pub_job:*`, audit `cyrus.publicbuilder.*`);
- `signin_required` refusals vs new accounts;
- model cost per build vs the price;
- Core Web Vitals.
