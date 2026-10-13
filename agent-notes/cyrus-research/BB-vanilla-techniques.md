# BB: vanilla-client technique catalogue for Cyrus (2026-10-11)

Labels: **V** = verified on the cited source 2026-10-11; **U** = unverified (memory or community practice; test before relying). Source keys at the end. Versions: A=1.21.1, B=1.21.4, C=1.21.8, D=1.21.11, E=26.x (26.1 released 2026-03-24, Java 25). Formats: RP/DP = A 34/48, D 75/94.1, 26.1 84/101.1 (V, [PF][J11][J26]); B 46/61 and C 64/81 are U. Cyrus today (from the coverage matrix, BA, r2 tree): plugin, texture, itemStates (B+), sound, designItem/Menu/Quest/Boss/Hud, motion, creature (26.x only), datapack+worldgen exist; 26.x plugin builds do not. Armor, fonts, dialogs, custom blocks, furniture, shaders, skies, cutscenes and vehicles have no verified lane.

## 1. Technique table
GM = Geyser needs a separate Bedrock pack/mapping; Java packs are not auto-converted (V [GI]).

| # | Technique | Mechanism (vanilla feature) | Pack / plugin must | Versions | Cost / budget | Bedrock (Geyser) | Caveats | Licence | Diff |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Custom blocks, state-carrier | note_block = 16 instruments x 25 notes x powered = 800 states (V [NB]); tripwire 128, mushroom blocks 64 each, chorus plant 64 (U) | blockstate JSON per state mapped to a model; plugin cancels physics, sets BlockData on place, swaps drops, replaces break/place sounds | A-E (blockstates unchanged); Paper has `disable-noteblock/tripwire/chorus-plant/mushroom-block-updates` (V [PC]) | Zero entities; client-side model cost only | Needs Geyser custom-block JSON with `enable-custom-content`; docs say "not very stable" (V [GB]) | Mining speed needs mining-fatigue/packet trick (U); pistons/water | Oraxen GPL, CraftEngine GPLv3 (V [CE]): clean-room only | M |
| 2 | Custom blocks, display-based | barrier/light block + item_display (model via item_model) + interaction hitbox | spawn display + interaction, track in PDC/chunk store, remove on break | B-E (item_model on display needs B+); display entities exist since 1.19.4 (V [DE]) | Per-block entities: budget <=200 visible per player (U); view_range tuned | Display entities only partly mapped (V [GS]) | No collision shapes; chunk-unload cleanup | n/a | M |
| 3 | Furniture/props | item_display + block_display + interaction (click/seat) with interpolation | model definitions; place/rotate/pick-up; seat via invisible rideable entity | B-E (A: armor stand with CMD, U) | As 2; text_display/block_display cheaper than armor stands (U) | Partial/none | One box hitbox; orphan entities after crash | Nexo proprietary (U) | M |
| 4 | Custom mobs/NPC rigs | item_display bones driven by packets (BetterModel: Blockbench cubes/meshes, Molang animations, IK, per-player view) (V [BM]) | RP bone models; vanilla base mob for AI/hitbox; sync bones to mob position | BM states 1.21.4-26.3.x (V [BM]); Cyrus gates creature to 26.x: verify C/D | Packets scale with bones x viewers: budget 20 rigs x <=40 bones in view (U) | None documented (V [BM]) | BM docs list no hitboxes or seats: Cyrus must add an interaction/base-mob hitbox. ModelEngine is premium (U) | BetterModel MIT (V) | L (lane exists) |
| 5 | Mount/seat, vehicles | invisible rideable (display/armor stand/marker boat) + `PlayerInputEvent` | add passenger, read input, move vehicle | PlayerInputEvent Paper API 1.21.3+ (V [PJ]) | Cheap | Works (vehicle is server entity) | Fly/"vehicle too fast" flags in anti-cheat (U) | n/a | S/M |
| 6 | Custom armor | `equippable` component with `asset_id` + `assets/<ns>/equipment/*.json` (layers humanoid, humanoid_leggings, wings, animals) (V [EQ]) | RP equipment json + layer textures; plugin/datapack sets component | 1.21.2 `models/equipment`, 1.21.4 `assets/<ns>/equipment` (V [EQ]); A has no component: leather dye/trim hack or CIT (U) | Free | Needs Bedrock attachable pack (GM) | Pack required on client (V [EQ]) | n/a | S |
| 7 | Tools/weapons/food/consumables | data components: consumable, food, tool, weapon, use_remainder, damage_resistant, glider (1.21.2/1.21.5 era, U); D adds attack_range, kinetic_weapon, piercing_weapon, swing_animation, use_effects (V [J11]) | Paper Data Component API (V [PD]) or datapack/`/give`; per-version adapters | A: attribute modifiers/NBT only; B-E full | Free | Geyser maps many components (V [GI]) | Hardcoded attack animations stay vanilla unless D+ | n/a | S |
| 8 | Enchantments | data-driven JSON in `data/<ns>/enchantment` (1.21+): effects, exclusive_set, supported_items (V [EN]) | datapack; description via text component; tags for table/loot | A-E | Free | Display only partly | Logic limited to vanilla effect components, no arbitrary code | n/a | S (emit exists) |
| 11 | Custom GUI/menus | container title = glyph from custom font + `space` provider negative advances to align over a chest/inventory (V [FT]); titles/lore styled with `font` | RP font json + bitmap; plugin opens inventory with component title | A-E; keep ascent <= height (V [FT]) | Pack only | Geyser shows raw glyphs unless remapped (U) | Shadow darkens glyphs (V [FT]); widths per GUI scale | Oraxen GPL (U) | M |
| 12 | Native dialogs | `dialog` registry: notice, confirmation, multi_action, server_links, dialog_list; inputs text/boolean/option/slider; no RP/mod needed (V [DG]) | Paper Dialog API or datapack | 1.21.6+ (V [DG]): not A/B; C, D, E yes | Free | Not documented | | n/a | S/M |
| 13 | HUD | actionbar/bossbar/title text with glyph font; sidebar via scoreboard | font + sprites; plugin pushes per tick | A-E | Updates <=2/s per player (U) | Fonts differ | Keep ASCII fallback; mod UIs (Sodium/Iris) fine for fonts | n/a | M |
| 14 | Core shaders | replace `assets/<ns>/shaders/core`; unsupported but works. A: JSON programs; 1.21.2 preprocessor flags; 1.21.5 program JSON removed, only default uniforms; 1.21.6 uniform blocks; 26.x ShaderC, `#include`, stricter syntax (V [SH]) | one shader set per version; merge conflicts with other text-shader packs (V [OX]) | Re-author per RP format band; 26.3+ replaces `transparency` with OIT (V [SH]) | GPU-cheap if small | Not applicable | Iris/OptiFine can break or ignore (V [SH]); one pack's `rendertype_text` wins | n/a | L |
| 15 | Post-processing/screen FX | `post_effect` chain exists (entity_outline, translucent, main); format changed 1.21.5/1.21.6 (V [SH]); vanilla only runs chain for outline/transparency/spectator creeper-style | override `entity_outline`; or fake overlays via full-screen glyph, pumpkin overlay, spectral | Fragile per version | Overlay glyphs cheap | No | Overlays: prefer font glyph or equippable head `camera_overlay` (U) | n/a | L/M |
| 16 | Sounds/music | `sounds.json` + OGG; `jukebox_song` registry + `jukebox_playable` (DP, U); env attribute music in D+ (V [EA]) | RP sounds, datapack song | A-E | Pack size; stream long files | OK via Bedrock pack | Subtitles; `/playsound` category volume | n/a | S (exists) |
| 17 | Custom particles | new particle types are code-registered (V [FA]); packs only re-skin existing ones (U for file-level behaviour). Fakes: item_display/text_display bursts, `item` particle with custom item, dust colours | plugin spawns | A-E | <=100 display effects/s/player (U) | Particle mapping lossy | No true custom particle without client mod | n/a | M |
| 18 | Dimensions/biomes/structures | datapack worldgen (noise settings, biomes, structure sets, templates) | datapack (lane exists) | A-E; 26.1 world clocks, DP 101.1 (V [J26]) | Worldgen CPU | Geyser ok (server-side) | Needs fresh chunks; `level.dat` for dimension types | n/a | M (exists) |
| 19 | Recipes/loot/advancements/trades | datapack; villager trades data-driven in 26.1 (V [PF]), `additional_trade_cost` (V [J26]); earlier = plugin MerchantRecipe | datapack/plugin | A-D plugin trades; E datapack | Free | OK | | n/a | S |
| 20 | Cutscenes/camera | spectator mode + spectate an entity, display `teleport_duration` interpolation, title/black overlay glyph (U) | plugin moves camera entity; restore mode/inventory | A-E | Cheap | Bedrock cannot spectate entities like this (U) | Client can exit with sneak: cancel via Paper event (U); Dialog pauses (V [DG]) | n/a | M |
| 21 | Skies/weather/fog | A-C: dimension_type `effects` + biome fog/sky colours + RP sky textures; D: environment attributes (sky/fog/cloud/sun/moon/stars, timelines), data-pack only (V [EA]); sun/moon textures need RP (V [EA]); E adds light tints (V [J26]) | datapack + RP | Split code path at D | Free | Bedrock gets server-side colours only (U) | Biome-level sky needs custom biomes | n/a | M |
| 24 | Scoreboard/tab/nametag | team prefix/suffix, tab header/footer, text_display above head (billboard), custom font in names | plugin | A-E | text_display per player: view_range 0.5 (U) | Names only | Custom font in names shows to everyone | n/a | S |
| 25 | Chat/emoji | font glyphs mapped to PUA codepoints; chat formatting | RP font + plugin replace `:emoji:` | A-E | Free | Raw codepoints on Bedrock (U) | Signed chat limits | Oraxen GPL (U) | S |

## 2. Needs a client mod
Keybinds (only vanilla inputs reach `PlayerInputEvent`); GUI widgets beyond Dialog (V [DG]); render pipelines beyond core shaders (V [SH]); new particle types (V [FA]); new entity/block types and non-cube collision (displays have none, V [DE]); mouse capture, minimap, extra HUD layers.

**Client-mod lane.** Fabric and NeoForge both ship builds for 26.1-26.2 (Fabric API 0.154.0+26.2 seen; Mojang-named on 26.x; exact pins U [FB]). Cyrus would generate a small Fabric mod (keybind -> custom payload -> Paper plugin messaging; Java 21 for 1.21.x, Java 25 for 26.x), build it in a sandbox, and deliver an **.mrpack** (`modrinth.index.json` with `formatVersion`, `files` + `overrides/` for own jars; V [MP]) bundling Fabric loader, Fabric API, the mod and the server resource pack. Players open it in Modrinth App or Prism (U); a CurseForge `manifest.json` variant is a second export (U). Servers cannot push mods; one-click means download-and-import. Effort L (2-3 weeks MVP per version band).

## 3. Prioritised build order (value / difficulty)
1. Armor lane (6), tools/food/weapons component pass (7): S, big visible value.
2. Sounds, music, jukebox songs (16), recipes/loot/trades/advancements gaps (19).
3. GUI/HUD glyph font lane (11, 13, 25): M, unlocks "custom GUI" and chat emoji.
4. Furniture/props (3) then display-based custom blocks (2): M.
5. Dialog forms (12) for C+ (1.21.6+).
6. State-carrier custom blocks (1): M, needs Paper flags and sound override tests.
7. Enable BetterModel creature lane on 1.21.4-1.21.11 if the real flight proves it (4).
8. Mounts/vehicles/seats (5), cutscenes (20): M.
9. Skies/fog/weather (21), particle/VFX presets (17): M.
10. Core shaders and post FX (14, 15): L, ship last, one band at a time.
11. Client-mod lane + .mrpack delivery: L, only after demand is proven.

## 4. Top 10 risks
1. Version drift: shader format changes at 1.21.2, 1.21.5, 1.21.6 and 26.x; RP/DP minor formats from 1.21.9 (V [PF][SH]).
2. Pack merges: one shader or font file wins (V [OX]).
3. Entity-count blowups on small nodes; budgets all U.
4. Anti-cheat false positives on custom blocks, seats, vehicles (U).
5. Bedrock parity: hand-made packs, unstable custom blocks (V [GI][GB]).
6. Licence contamination: Oraxen and CraftEngine are GPL; use BetterModel (MIT) or clean-room only.
7. 250 MiB pack cap (V [SP]); declined packs.
8. 26.x needs Java 25 (V [J26]); 26.x plugins unbuildable until then.
9. State-carrier collisions with player builds; Paper flags are global.
10. Hardcoded behaviour invites impossible requests: show limits before spend.

## 5. Verify on a real client (per band A/B/C/D/E)
Armor on player and mob; note-block break sound/speed; glyph GUI at GUI scale 1-4; Dialog (C+); item_display with item_model (B+); BetterModel rig on C/D; core shader under vanilla, Sodium, Iris; env-attribute sky (D+); spectator exit; vehicle input; Geyser view of items/blocks/displays; 25-rig and 500-display load test (TPS, client FPS).

## Source keys (fetched 2026-10-11)
minecraft.wiki/w/: PF Pack_format, J11 Java_Edition_1.21.11, J26 Java_Edition_26.1, EQ Equipment, IM Items_model_definition, SH Shader, EA Environment_attribute, FT Font, DE Display, NB Note_Block, EN Enchantment_definition, DG Dialog, SP Server.properties. docs.papermc.io: PC reference/global-configuration, PD dev/data-component-api; PJ jd.papermc.io PlayerInputEvent (1.21.3 page). BM github.com/toxicity188/BetterModel; CE github.com/Xiao-MoMi/craft-engine; GI, GB geysermc.org/wiki/geyser/custom-items, custom-blocks; GS Geyser display-entity search result; OX docs.oraxen.com text effects; FA docs.fabricmc.net 1.21.4 particles; FB Modrinth search result (Fabric/NeoForge 26.x); MP docs.modrinth.com/modpacks/format (search snippet; fetch 404). Oraxen: no-copy (GPL per brief). ModelEngine docs unreachable.
