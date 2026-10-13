# S2: Motion / effects assets, pass 2 (2026-10-10)

CC0 only (tier cc0, attribution null, hard-asserted by `s9_merge.py`). Zero model calls per asset: every step is a deterministic script in `/tank/cyrus-library-staging/motion/tools2/`. Catalog: `motion/catalog-motion-2.jsonl` (1,895 rows). Ledger: `motion/LICENCE-LEDGER-motion-2.csv` (145 rows). Vocabulary: `motion/vocabulary-proposal.json` (19 categories, 37 useFor rules, 4 new kinds; repo untouched). Contact sheets: `motion-sheets-procedural/` (19 PNG).

## What was added

| Kind | Rows | Where from |
|---|---|---|
| flipbook | 1,050 | 297 procedural sheets + 753 external (sheets, frame sequences, GIFs) |
| particle-texture | 363 | external OGA / itch |
| animation-clip | 396 (194 unique names) | 92 FBX + 81 FBX + 67 blend conversions, 156 authored |
| animated-model | 86 | 48 converted, 39 authored |

| Step | Result |
|---|---|
| 1. FBX to glb | 30 pass-1 FBX converted (Blender 5.2.2, sandbox recipe from I-blender-poc: no network, caps, build lock, one job). gltf-validator 0 errors (1 warning each, skinned mesh not at root). 92 clips with duration, keyframes, 30 fps frame count, tags. |
| 1b. extra conversions | 12 RPG-character FBX (81 clips) and 6 `.blend` (67 clips: dragon, mudeater, chest, sci-fi player + 2 enemies). 0 validator errors. Blender 5.2 has no Collada importer: 5 dragon `.dae` skipped (same dragon came via `.blend`). |
| 2. procedural flipbooks | 297 sheets, 14 families, 64/128/256 px, power-of-two (all checked), seed = crc32(name) in each JSON sidecar, loop seam ratio recorded, 74 MB. Re-generation of 8 sheets was byte-identical. I reviewed every family sheet and fixed fire, sparks, splash, smoke. |
| 2b. authored clips | 39 glb rigs, 156 clips with named pivot nodes and `events` in glTF extras (muzzle_flash, door_latch, mag_out...). Validator clean; 4 Blender renders confirmed the motion. |
| 3. external CC0 | OGA: 119 pages checked, 115 strict CC0 staged, 4 rejected (multi-licence pages listing CC-BY/OGA-BY beside CC0). itch.io: 20 pack pages read, 5 staged (3 with the structured "Asset license: Creative Commons Zero v1.0 Universal" field, 2 whose description states CC0). 15 rejected because the page shows no CC0 grant . Dedupe by sha256 against main catalog and pass 1. |
| 4. tagging | `motionlib.py` token rules (clip verbs, effect synonyms, category and useFor rules) drive every row; re-tagging is free. 33 clips have no useFor; 535 external images fell to generic `vfx/particles` (no keyword in the name). |

Procedural sheets by family: magic 48, fire 39, smoke+steam 31, water 27, sparks 26, explosion 23, muzzle 21, impact 18, electric 18, liquid loops 16, weather 12, dust 10, slash 8.

## Owner coverage now

| Need | Now covered by |
|---|---|
| Explosion | 23 procedural + external sets (Sinestesia, lpc-explosions, fire strike packs) |
| Fire / smoke | 39 / 31 procedural, 32-frame fire packs (morningkingdom, stealthix) |
| Water splash / flow | 27 splash+ripple sheets, 8 looping water textures + 4 water normal maps, lava loops. Flow is a texture loop only. |
| Muzzle flash | 21 sheets, front and side views, 5 colours |
| Door / mechanism / car door | 39 authored rigs: hinge, double, saloon, sliding, garage, drawbridge, chest, drawer, lever, piston, elevator, car doors/hood/trunk/wheels |
| Gun cocking | pistol, revolver, rifle, shotgun, smg clips (Fire, Cock, Reload, Slide, Pump) plus Quaternius FPS gun clips (converted) |
| Creature walk / attack | converted animals, fish, monsters, dragon, mudeater (29 clips), enemies |

## Still for the Motion core to author

Particle-emitter presets as parameter JSON (none exist under CC0; sheets are texture inputs), ability-to-effect triggers, gun/door state machines, sound-cue timing, volumetric explosions, fluid flow, character door/vehicle interaction clips.

## Caveats

- Licence is as stated on each page, not independently verified.
- Two itch packs (PVFX Foundry, "AI Assisted" disclosure; plewr rigged character) rely on a description statement, not the structured field. plewr also ships a `mixamo.fbx`, which was not ingested. Owner may drop both.
- 115 of 1,050 flipbooks have no detected grid. Third-party clip quality was not reviewed beyond parsing.

## Disk

`motion/` is 2.1 GB (pass 1 was 183 MB): procedural 74 MB, converted 11 MB, OGA 1.7 GB, itch 255 MB. Scratch `tmp-motion` 86 MB. Root `/` still 11 GB free (78%).
