# S: Free motion / effects assets staged for Cyrus (2026-10-10)

Staged under `/tank/cyrus-library-staging/motion/` (183 MB, no git, no root-disk use). Catalog: `motion/catalog-motion.jsonl` (1,972 rows, sha256 ids, deduped). Ledger: `motion/LICENCE-LEDGER-motion.csv` (50 rows). Rows with `ref:true` point at files already staged by the 3D ingest (not moved, not touched). Scripts: `motion/build_catalog.py`, `ogadl.py`, `glbscan.py`. OGA fetched at its 10 s crawl-delay with an identifying UA, one request at a time; KayKit via the normal itch free-download button flow.

## Per source: licence, counts, decision

| Source / pack | Licence (read on page) | Counts | Decision |
|---|---|---|---|
| KayKit Character Animations 1.1 (itch/kaylousberg.com) | CC0, License.txt quoted: "free to use in personal, educational and commercial projects" | 14 animated glb (Rig_Medium/Large), 173 clips (144 unique names), clip durations recorded | ACCEPT cc0 (free upload only; paid Source tier not used) |
| Quaternius Universal Animation Library 1+2 (already staged) | CC0 | 4 glb, 172 clip rows (86 unique; std + root-motion) | ACCEPT cc0, ref |
| 3D-ingest animated models (Quaternius, Kenney, KayKit, Khronos, Poly Haven) | CC0, plus 12 Khronos CC-BY 4.0 | 390 glb contain animation; 5,786 embedded clips (heavy duplication, same clip set per character) | ACCEPT per tier, ref |
| OpenGameArt effects (28 pages) | CC0 per asset page; 3 pages CC-BY | 127 sheets/atlases, 37 frame-sequence folders (822 frames), 238 loose sprite frames | ACCEPT; CC-BY in separate tier |
| OGA Quaternius creature FBX (animals, farm, monsters, fish, robot, animated guns) | CC0 | 30 FBX, 94 clip stacks (guns: Fire/Reload/Slide x5 weapons) | ACCEPT cc0; needs FBX to glTF conversion (no converter on this box) |
| RPicster Godot particle/VFX textures (GitHub) | CC0, LICENSE file + README quoted | 42 particle/lensflare/light textures (64/256/1024) | ACCEPT cc0 |
| Kenney Particle Pack, Smoke Particles, Splat Pack, Light Masks (already staged) | CC0 | 761 PNG (black + transparent variants of the same art) | ACCEPT cc0, ref |
| OGA Low Poly Doors Asset | CC0 | 1 gltf + 22 fbx, 0 clips (static) | Kept, not in catalog |
| Mixamo | free, no redistribution as library | none | REJECT |
| CMU mocap, Tiddybub/2d-assets, Indosaram/pixel-vfx-local, slippylabs/particle-forge | redistribution limits, or no usable licence file | none | REJECT |
| Blender Studio vault | CC-BY, membership needed | none | SKIP |
| Poly Haven | CC0 but nothing motion-related | none | N/A |
| itch.io CC0 VFX packs (Aim Studios, Stealthix, TornadoGames, GoVFX) | claimed CC0 in search snippets, not verified on page | none | DEFERRED (owner hand-pick) |

Rejected on page: OGA collection pages (Graphic FX, 2D::Animation/Effect, Effect&Shader, 05 Pixel Art) have no files of their own. Quaternius FBX copies of packs already staged as glb were downloaded then deleted as duplicates.

## Totals by kind and tier

| Kind | CC0 | CC-BY | Notes |
|---|---|---|---|
| animation-clip | 345 rows (230 unique names) | 0 | KayKit 173 + UAL 172 |
| animated-model | 408 (364 ref glb, 14 KayKit glb, 30 FBX) | 12 (Khronos, ref) | 390 glb animated, validated by parsing |
| flipbook | 118 sheets + 37 sequences (822 frames) + 238 sprite frames | 9 sheets | grid size only known from filenames (some 512 px cells in 4096 atlases); the rest need a grid-detect pass |
| particle-texture | 805 (42 RPicster, 2 OGA, 761 Kenney ref) | 0 | |
| effect-preset | 0 | 0 | none exist with a clean licence |

CC-BY attribution (recorded in catalog): "Muzzle Flash" by Aech (CC-BY 3.0); "AlotofImpacts" by JoesAlotofthings (CC-BY 4.0); "Explosion effects and more" by Soluna Software (dual CC-BY 3.0 / CC0, author says no credit needed); Khronos models per the 3D catalog.

Checks: all new glb parsed (JSON chunk, BIN bounds); all PNG/GIF opened with PIL; 0 odd files, nothing quarantined. Older 3D-ingest "Animated*" Quaternius packs (dinosaurs, guns, tanks, fish, zombie, alien, etc.) are static glb with zero animations, so only the OGA FBX copies above carry those clips.

## Gaps against the owner's list

| Effect | Free coverage |
|---|---|
| Explosion | Good as 2D flipbooks (Sinestesia 512 px atlases, more-explosions, Soluna); no 3D or volumetric |
| Fire | Good (439-frame fire/spell sets, animated fire, flame sheets) |
| Smoke | Good (Smoke Aura 91 frames, Kenney smoke, smoke sheet) |
| Muzzle flash / impacts | Good (about 270 sprites, 16 toon, hit animation) |
| Water splash / flow | Weak: one 3-frame splash and rain drops. Water flow has nothing; needs a shader plus normal map (ambientCG is staged) |
| Gun cocking | Covered by Quaternius animated guns (Reload, Slide, Fire for pistol/revolver/rifle/shotgun/P90) and UAL Pistol_Reload; needs FBX conversion |
| Creature walk/attack | Strong (cute monsters, animals, dragon/bat/slime, 397+ clip names) |
| Door / mechanism | No animation. UAL has Chest_Open/Interact for the character side only. Hinge door tracks must be authored; static door geometry is on disk |
| Car door | Nothing |

Verdict: free assets cover textures and flipbooks for fire, smoke, explosion and muzzle, plus character and creature clips. Effect presets (parameter JSON), water, doors, mechanisms and vehicle doors must be authored by us, using these flipbooks as the texture inputs.

## Owner decisions

1. CC-BY tier: accept the 9 CC-BY sheets (attribution page needed) or drop them. The Soluna pack can be treated as CC0 if you accept the dual-listing.
2. KayKit/Quaternius ask people not to resell unmodified copies. It is a courtesy request, not a licence term, but a bulk library redistribution should be modified or curated.
3. FBX to glTF: approve installing a converter (or a node FBXLoader script) in an isolated place so the 30 creature and gun FBX files become glb.
4. MIT or Apache preset repos (such as tsparticles) were not staged because only CC0/CC-BY is allowed; say if permissive licences are acceptable for effect presets.
5. itch.io CC0 VFX packs: hand-pick a few if you want more fire and explosion variety.
