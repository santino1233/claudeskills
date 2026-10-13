# M. Cyrus asset catalog v2 (owner report, 2026-10-10)

Branch `feature/cyrus-r14-catalog` (worktree `/tank/dev-worktrees/cyrus-r14`, merged with the latest `feature/cyrus-r2`). Code `lib/cyrus/library/v2/`, docs "Cyrus asset catalog (v2)". Nothing deployed, no migration run, no flag, no paid model call.

## What each asset now carries (CatalogEntry v1)
Content-hash id (`cat:<sha256>` everywhere), kind (model, PBR set, texture, sprite, HDRI, decal, sound, music), title, description (<=140 chars), controlled tags + up to 8 free tags, one primary + up to 3 secondary categories (the existing sound and texture taxonomies are reused inside it), **situations** ("gunshot sound", "sci-fi crate prop", "stone wall floor texture": 66 of them), style, a **quality score 0-100 with every check listed** (only measured checks count; a corrupt/silent/zero-triangle file is capped at 20), **fit per game** (good/ok/no + reason + budget notes + what Cyrus must do to it, read from each game's asset profile), technical facts (triangles, size in metres, rig/animations, maps, resolution; audio length, sample rate, channels, peak, loudness, silence, loop hint), licence tier (CC0, CC-BY, Nxeon-owned, user-contributed), provenance, legal class, opaque contributor, status (pending, published, held, removed).

## Measured: how much needs no AI at all (stage A)
Read-only copy of the staged catalog (51,391 rows at copy time), plus 1,953 file names from the partial SFX upload and the 795 existing built-ins:

| Set | Fully described by stage A |
|---|---|
| 3D models (10,018) | **98.7 %** |
| HDRIs (433), decals (127) | 100 % |
| PBR texture sets (2,079) | 81 % |
| Sprites (38,056) | 41.6 % (mostly Kenney tiles named `tile_0113.png`) |
| Plain textures (678) | 18 % |
| **All staged CC0** | **54.7 % full, 23.2 % partial, 22.1 % none** |
| SFX names only (audio not yet measurable: zip still uploading) | 76.9 % |
| Built-ins (514 owner sounds, 281 Cyrus textures) | 94.5 % |

Precision: I checked 100 random "full" entries: 91 right, 2 marginal, 7 wrong category (mostly the upstream pack's own labels, e.g. toy-brick "plates" filed as kitchenware). 283 pack cover/preview images were found and removed automatically.

## Cost to tag the rest (stage B)
Measured on my own tagging of 144 queued images (9 contact sheets of 16) and 40 sound names: replies average 186 characters per asset; 74 % of images and 93 % of sound names reached usable confidence. The estimator turns the staged queue into 1,038 calls, about **1.70 M input + 0.88 M output tokens** for 22,865 assets (one cell per colour/scale variant family).

Scaled linearly to **100k assets with the same mix: about 3.3 M input + 1.7 M output tokens.** Worst case (every asset needs AI, no families): about 10.2 M input + 5.3 M output. Cost = input/1M x input price + output/1M x output price; **the price per token is an input to the estimator.** With the list prices in the Claude API reference I have (cached 2026-09-25, verify before any run):

| Tier | Typical 100k | Worst case 100k |
|---|---|---|
| cheap (Haiku 4.5, $1/$5 per MTok) | ~$12 | ~$37 |
| mid (Sonnet 5.5, $2/$10) | ~$24 | ~$73 |
| top (Opus 5.5, $4/$20) | ~$47 | ~$147 |

The Batch API halves these. Assumptions: 3.6 characters per token, image tokens = width x height / 750, ~950-token fixed prefix per call (prompt caching not assumed). None of these were re-measured with the real token counter (no key, no spend).

## Retrieval
`catalog_search` returns at most 8 compact rows, capped at ~1k tokens (measured 490-620 tokens). `catalog_get` returns the `ref` that goes into a ModSpec asset slot (`source: "library"`, new `libraryRef`). Every call applies the plan gate (sounds Saka+, visuals top plan, free/Katara nothing), the licence tiers per plan, and the proprietary-library clearance. Local index: memory (54k entries built in 1.8 s, queries 60-650 ms) or SQLite full-text (5.3 s; most queries under 0.4 s but broad ones up to 17 s: not tuned). Expected assets come first for "medieval torch", "stone wall floor texture", "ui click", "night sky", "treasure chest".

## Community library
Assets made in Cyrus enter as pending, then deterministic filters: adult terms removed; real-gun model names, trademarks (stub list), extremist and drug terms held for you; gore flagged; uploads/imports/derived work never auto-contributed.

## Owner decisions
1. Licence tiers per plan (`PLAN_TIERS`): today Saka and top plan may use CC0, CC-BY, community and (once cleared) the proprietary library.
2. Clear the proprietary SFX library per pack (licence text per pack folder) before customer builds use it; real-gun pack names (FN Five-seveN, Mini Uzi...) are flagged, not held, for your own library: keep or rename titles?
3. Which tier for stage B, and a budget cap (suggest a 500-asset dry run first, then cheap tier on sprites only).
4. Extend the trademark list (stub) and confirm "hold, owner reviews" for community assets named after real guns.
5. Asset profiles for the next games (only Minecraft declares catalog hints; every 3D asset is honestly "no" for Minecraft until a glTF converter exists).
6. Accept a 2-letter country-code table for the 457 flag sprites (free, zero tokens).

## Unverified
Token counts (estimated from characters and the published image formula, not counted); cheap/mid-tier tagging accuracy (only my own tagging was measured); audio features of the new SFX library (not extractable until the upload completes); loopable is a heuristic; no Postgres backend or UI yet.
