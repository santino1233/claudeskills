# CN: cyrus.my marketing v2 (2026-10-15)

Branch `feature/cyrus-marketing-v2` (worktree /tank/dev-worktrees/cyrus-marketing-v2, from main 89608a9f, main rc17 merged in). NOT published, NOT promoted, no flag or setting changed.
Screenshots: /root/cyrus-marketing-v2-shots/ (motion / ingame / plans, desktop 1440 + mobile 390; `-placeholder` = API answered with placeholder numbers, `-fail` = API failed, static fallback; the older -fail plans shots predate the hidden-badge fix).

## 1. Diagnosis (before)
**Motion & effects** (8 cards, `.loop` + `.spr` background-image sprites):
- The sheets were rendered by the headless software rasteriser (`lib/cyrus/motion/preview.ts`: flat shading, z-buffer, ground grid, no AA, no lights) at 72 to 192 px per frame, then saved as lossy VP8 WebP strips without alpha. That is why the pistol and door read as crude voxels on a checker floor.
- The CSS then stretched each frame (`background-size: n*100%`, `image-rendering:auto`) and used `mix-blend-mode: screen` on black JPEG-ish backgrounds: flames became smeared, the explosion a blurry white blob (8 mostly dark frames, 6 fps, no flash/shockwave).
- The real library flipbooks (256 px RGBA, additive, 16-32 frames) and the CC0 animated models were never used; `assets/motion/fx/*` was dead weight.

**From prompt to your hand** (3 cards):
- Items were the real 16 px templates (service pistol, hunter bow) but drawn by `lib/cyrus/studios/held.ts` (canvas polygons, "approximate") with an invented purple arm. Vanilla first person draws NO arm for a held item, so the purple blocks were wrong by construction; the item floated beside them at the pack's re-gripped angle.
- Backgrounds were a 160x132 canvas upscaled with `image-rendering: pixelated` (starfield + grass strip), items 350x298 WebP with a radial mask.
- Third card: a 64 px canvas shown at 46 % with a full 360 degree Y spin, so the flat extruded sprite went edge-on every half turn (the "thin sliver").

## 2. After
- **Pre-rendered loops** (WebM VP9 + MP4 H.264 + WebP poster, 0.08 to 0.47 MB each, 2x DPR sizes 560x560 and 800x660, `preload="none"`, play only while on screen, reduced motion = poster only, pause control kept) made by `scripts/cyrus/site-media/`:
  - `build-data.ts` (tsx): real item textures (service pistol + hunter bow templates, `render()`), every state's display transforms from `stateDisplays` (exactly what the pack writes), the `effect:explosion` preset sampled with `particlesAt`.
  - `stage.mjs` / `stage.html` / `render.mjs`: three.js in headless Chromium on node-2 (SwiftShader), deterministic per frame; flipbooks with frame blending and correct additive/normal blending, soft glow, light pools, contact shadows.
  - `encode.sh`: ffmpeg, raises CRF until each file <= 1.2 MB. `fetch-inputs.sh` + `inputs.txt`: copies the CC0 library inputs to node-2 (not committed). `shots.mjs`: screenshots.
- **Motion cards** (honest sources shown under each label): Fire and Reload = library `low-poly-animated-guns` Pistol (Quaternius, CC0) with its Fire / Reload clips + library muzzle/smoke flipbooks; Door = Nxeon procedural-motion `door-heavy-iron-l-95` (Open/Close clips); Explosion = `effect:explosion` preset particles drawn with library fireball / shockwave / smoke flipbooks; Blue fire, Arcane flame, Orb, Pillar = library flipbooks.
- **In game**: first-person is the vanilla pose with no arm (hand origin 0.56,-0.52,-0.72, 70 degree camera, the pack's display transforms, extruded texels as flat quads so pixels stay crisp and light is smooth, MSAA, lens-offset framing so the viewing angle stays vanilla). Pistol: Aim (muzzle flash) / Reload (reloading texture) / Dropped; Bow: Idle / Drawn (pulling_0/1/2 at vanilla thresholds, hold, release). Card 3 is the live painted texture in three.js (`assets/js/held.js`, lazy, In hand / Dropped, oscillating spin so it never goes edge-on, poster fallback).
- Removed: old `assets/motion/*.webp`, `motion/fx/*`, `mods/*.webp` (the page is 9.3 MB, cap 40 MB). No layout shift: videos carry width/height + aspect-ratio.

## 3. Plans
- Owner game slots in `lib/cyrus/tokens/config-pure.ts`: katara 1, saka 5, all (Yakko) 0 = unlimited, free 1; removed from the placeholder list (+ `placeholder-keys.json`), docs D-63, 06, 11, 12, DOCUMENTATION.md, tests.
- New setting `cyrus_tok_plan_numbers_final` (default false). While false the landing labels live numbers "Launch plan, final numbers may change".
- `GET /api/cyrus/launch` now also returns `numbersFinal`, and per plan `estimate, gamesN, storageGb, studios, install, library` (same `livePlanColumns()` rows as the in-app Compare plans, so tokens/storage/games come from the same settings; prices stay "To be announced" without a real Stripe price).
- Landing: three cards each list Price / Models / Tokens / Games you can mod / Storage / Studios / Install to Nxeon servers / Asset libraries, a "What is a game slot?" line and a Free..Yakko comparison table (horizontal scroll on phones). Filled at load; static fallback keeps the owner-decided games (1 / 5 / Unlimited) and shows "Set at launch" instead of any token or storage number.
- In-app Compare plans table gains Studios and Install rows (derived from the asset gate; install is never gated).

## 4. Files
Landing: `apps/cyrus-site/src/index.html`, `assets/css/site.css`, `assets/js/main.js`, `assets/js/held.js` (new), `assets/motion/v/*`, `assets/mods/v/*`, `apps/cyrus-site/README.md`.
App: `app/api/cyrus/launch/route.ts`, `lib/cyrus/content/plan-table.ts`, `lib/cyrus/tokens/config-pure.ts`, `lib/cyrus/tokens/game-slots.ts`, `scripts/cyrus/lib/placeholder-keys.json`.
Tests: `test/cyrus-game-slots.test.ts`, `test/cyrus-plan-table.test.ts`, `test/cyrus-site-landing.test.ts`.
Tooling: `scripts/cyrus/site-media/*`.

## 5. Verification
See the end of this file (tsc / tests / docs build results).

## 6. Owner commands
The API change needs the app promoted first (an old API simply keeps the static fallback):

    cd /opt/nxeon && git merge --ff-only feature/cyrus-marketing-v2 && bash scripts/promote-production.sh --skip-staging-check
    apps/cyrus-site/publish.sh check
    CYRUS_SITE_FEATURED_JSON=https://nxeon.cloud/api/cyrus/featured apps/cyrus-site/publish.sh publish          # dry run
    CYRUS_SITE_FEATURED_JSON=https://nxeon.cloud/api/cyrus/featured apps/cyrus-site/publish.sh publish --go
    apps/cyrus-site/publish.sh rollback --go                                                                      # if needed

When the owner confirms the final plan numbers, set `cyrus_tok_plan_numbers_final` = true (Cyrus admin settings) and the badge disappears.
Re-render media: `scripts/cyrus/site-media/fetch-inputs.sh`; `scripts/devhost run -- bash -c 'npx tsx scripts/cyrus/site-media/build-data.ts && node scripts/cyrus/site-media/render.mjs --out /tank/nxeon-build/frames'`; pull the frames; `scripts/cyrus/site-media/encode.sh <frames>`.

## 7. Known limits
- The preset rigs themselves are preview proxy boxes, so Fire/Reload/Door use library models; the cards say so. No real Minecraft client was involved: held-item views are Cyrus's approximation (as the Texture Studio labels them), bow card framing scales the item 0.6 so it fits.
- Prices unknown; tokens/storage are launch defaults (labelled).
- `/api/cyrus/launch` fields were verified against a stub in the screenshots, not a live app.
