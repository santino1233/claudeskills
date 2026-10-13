# B-models: automatic custom creature + weapon models for Cyrus (vanilla client, Paper, server-pushed pack)
Date 2026-10-10. Read-only research, 13 pages opened. VERIFIED = opened; UNVERIFIED = memory/inference.

## 1. Blockbench and the .bbmodel format
- App licence: GPL-3.0 source; plugins/themes using the Blockbench API are exempt and may be proprietary or paid. VERIFIED (https://github.com/JannisX11/blockbench). Implication: Nxeon must not embed/redistribute the Blockbench app in its product, but it can write .bbmodel files and let customers open them in the (free) app/web app. Using the app as a headless renderer/separate process is a licence question for counsel: UNVERIFIED.
- .bbmodel is JSON ("There is no complete specification of the JSON format at this point in time"; read examples and `js/formats/bbmodel.js`). VERIFIED (https://blockbench.net/wiki/docs/bbmodel). So the format is readable but not formally specified or licensed as a standard. Risk: it changes. Format 5.0 (Blockbench 5.0, 2025-10-12) split `groups` from `outliner` and fixed inverted X position / X,Y rotation keyframe values. Cyrus must emit one pinned format_version and golden-test it against BetterModel.
- Skeleton: `format_version, name, resolution{width,height}, textures[{name,source:data:image/png;base64}], elements[{from,to,rotation,faces,uv}], groups[{uuid,name,children}], outliner[...], animations[{name,loop,length,animators[{channel position|rotation|scale, keyframes[]}]}]`. VERIFIED (same URL; skeleton from the page summary, keyframe field names beyond that UNVERIFIED, confirm from a real file).
- Java block/item model JSON: elements limited to from/to in -16..32; rotation single axis, 22.5 degree steps within -45..45, optional rescale; `display` transforms per context; since 1.21.4 block and item models are not distinguished internally. VERIFIED (https://minecraft.wiki/w/Model). Keyframe animations are NOT part of vanilla block/item models; they exist only as .bbmodel data interpreted by a server-side engine (below).
- Item models 1.21.4 -> 26.x: 1.21.4 introduced `assets/<ns>/items/<id>.json` selected by the `item_model` data component, with types model, composite, select, range_dispatch (can switch on custom_model_data, use_duration, display_context, damage, etc.). 26.1 added a `transformation` field plus special models (bell, book, end_cube); 26.2 removed bed/standing_sign/hanging_sign special types; 26.3 removed the `map_color` tint source. VERIFIED (https://minecraft.wiki/w/Items_model_definition). The pre-1.21.4 `overrides` + `CustomModelData` number path is the legacy route (UNVERIFIED detail); need pack-format-per-version builds for 1.21.1 vs 1.21.4+.

## 2. Server-side animated-model libraries
| Lib | Licence | Versions | Bundle? | Notes |
|---|---|---|---|---|
| BetterModel (toxicity188) | MIT VERIFIED | Modrinth lists 1.19.4, 1.20.x, 1.21.x, 26.1.x, 26.2, 26.3; Paper/Folia/Purpur/Spigot; updated "13 hours ago" (very active) VERIFIED (https://modrinth.com/mod/bettermodel). GitHub front page says 1.21.4-1.26.3 with Java 25+ (v3 branch); raw README on master says 1.20.5-1.21.11, Java 21. Conflicting; assume v3 needs Java 25 for 26.x. VERIFIED (https://github.com/toxicity188/BetterModel) | Both: `compileOnly io.github.toxicity188:bettermodel-bukkit-api` (Maven Central, separate plugin) or `shadowJar` shading. VERIFIED (raw README) | Built on `item-display` packets; cubes, meshes, locators; animations with Molang + IK; per-player animation; custom hitbox; player-skin models; auto resource-pack generation; merge guides for Oraxen/ItemsAdder/Nexo/CraftEngine; async, "designed for high-traffic". 1,629 commits. No published entity-count numbers found. |
| ModelEngine R4 (Ticxo, sold via MythicCraft) | Proprietary, $39.99, no redistribution terms visible; closed, "very limited API" per BetterModel author VERIFIED (https://mythiccraft.io/index.php?resources/model-engine%E2%80%94ultimate-entity-model-manager-1-19-4-1-21-11.1213/) | 1.19-1.21.11, 26.1, 26.2; updated 2026-09-26 | No; must be bought per server (licence per server/redistribution UNVERIFIED) | Industry standard, MythicMobs integration. Avoid: cost, closed, cannot pre-install for customers without a licence deal. |
| FreeMinecraftModels (MagmaGuy) | GPL-3.0-only VERIFIED (https://modrinth.com/project/free-minecraft-models) | 1.18.x-26.3, standalone, updated last week | No: GPL would taint a bundled proprietary jar; separate-process/plugin use is a legal grey area | Lua scripting, furniture, animations. Avoid as a dependency. |
| Display entities directly (vanilla) | n/a | all 1.19.4+ | built in | item_display shows any `item_model`; interpolation via `start_interpolation` + `interpolation_duration`; no hitbox/collision/sound; count toward entity count. VERIFIED (https://minecraft.wiki/w/Display). A hand-rolled engine needs Interaction/base entity for hitbox. |
| Armor-stand engines (old ModelEngine, ModelAPI) | various | legacy | - | Avoid; superseded. |

API shape (BetterModel): `BetterModel.model("id").map(r -> r.create(entity, TrackerModifier.DEFAULT))`, `tracker.animate("attack", AnimationModifier.DEFAULT_WITH_PLAY_ONCE, cb)`, DummyTracker for location-only models, per-player animations, `tracker.close()` required to remove a model. VERIFIED (https://github.com/toxicity188/BetterModel/wiki/API-example). Models are read from `plugins/BetterModel/models/*.bbmodel`. VERIFIED (raw README).

Gaps I could not determine: BetterModel per-entity bone/viewer limits and tick cost; exact pack-merge behaviour when Nxeon also pushes its own pack; whether a mixed-version jar supports 1.21.1 (Modrinth list is broad; test). Plan a benchmark: N banshees x 20 bones x 20 viewers on a 4 GB node (S).

Can Nxeon pre-install? BetterModel: yes (MIT, free), install it as a managed system plugin on every Cyrus-enabled server, version-pinned per Minecraft version, generated plugins `depend: [BetterModel]`. Shading is allowed but duplicates the engine per mod and breaks pack merging; avoid. ModelEngine: only with a commercial agreement.

## 3. Automatic generation by an LLM
- The LLM should not emit raw .bbmodel (UUIDs, UV rects, keyframe maths = error-prone). It emits a compact RigSpec (section 4); deterministic Nxeon code compiles it to .bbmodel + PNG + animations. This also gives Texture Studio hooks (re-paint without re-rigging).
- Archetype templates (each = bone tree + default dimensions + animation presets): humanoid, quadruped, flyer/bird, floating ghost (banshee), serpent, spider/multi-leg, blob, plus prop/weapon (single bone). LLM picks archetype + overrides colour/size/features (horns, wings, tail, glow).
- UV: per-cuboid box-unwrap (Minecraft-style cross layout) auto-packed on one atlas (e.g. 64x64 / 128x128). Reuse existing `lib/cyrus/textures` pixel renderer by painting per-face palette regions + noise/gradients (UNVERIFIED how it fits; internal code not read).
- Procedural animation: library of parametric clips driven by bone roles (sine bob for idle/float, leg-swing for walk, wind-up + strike for attack, flinch + red flash for hurt, tilt + sink + fade for death). Compiler samples to keyframes at 0.05 s steps with linear/catmullrom interpolation. LLM only chooses clip type/amplitude/speed per role.
- Published approaches: BlockbenchMCP lets an AI drive the desktop Blockbench (bones+cubes, procedural textures, keyframes, screenshots for self-review); one report of a full GeckoLib bear (walk/run/sleep/attack) from one prompt. VERIFIED search result only; repo https://github.com/jasonjgardner/blockbench-mcp-project is Apache-2.0 sample project needing a running Blockbench desktop app, with a headless `blockbench-new-model` skill VERIFIED. Useful as design inspiration/QA, not as a server dependency (GUI app, GPL). No published "AI to Paper animated mob" end-to-end pipeline found.
- Quality loop: render a turntable PNG server-side (own software rasteriser of the cuboids) and let a vision-capable model critique; limit to 2 passes (cost).

## 4. Candidate RigSpec (JSON)
```
{ "spec":1, "id":"banshee", "archetype":"floating_ghost", "scale":1.0,
  "texture":{"size":[64,64],"palette":{"skin":"#cfd8ff","hair":"#5a6aa0","eye":"#ff3355"},
             "regions":{"head":"skin+eyes","hair":"hair","robe":"skin+gradient_fade"}},
  "bones":[{"name":"body","parent":null,"pivot":[0,12,0],"role":"torso",
            "cubes":[{"from":[-4,12,-2],"to":[4,24,2],"region":"robe","inflate":0}]},
           {"name":"head","parent":"body","role":"head","pivot":[0,24,0],"cubes":[...]},
           {"name":"arm_l","parent":"body","role":"arm_l", ...}],
  "hitbox":{"w":0.6,"h":1.9,"base_entity":"VEX|ALLAY|ZOMBIE|ARMOR_STAND_MARKER"},
  "animations":{"idle":{"clip":"float","amp":0.1,"speed":0.5,"loop":true},
                "walk":{"clip":"glide","amp":0.15},
                "attack":{"clip":"lunge","bones":["arm_l","arm_r","head"],"length":0.6},
                "hurt":{"clip":"flinch","length":0.3},
                "death":{"clip":"fade_sink","length":1.2,"loop":false}},
  "sounds":{"ambient":"sfx:wail_01","hurt":"sfx:...","death":"sfx:...","attack":"sfx:..."},
  "behavior":{"hp":30,"speed":0.25,"flying":true,"attack_dmg":4} }
```
Weapon: `{ "kind":"item", "id":"handgun", "model":{bones/cubes as above, single bone}, "display":{"firstperson_righthand":{...},"thirdperson_righthand":{...},"gui":{...},"fixed":{...}}, "states":[{"when":"use_duration|cooldown","model":"handgun_fire"}], "sounds":{"fire":..}}` -> compiled to `assets/<ns>/models/item/handgun.json` + `assets/<ns>/items/handgun.json` (+ `item_model` component set by plugin).

## 5. Validation checklist (deterministic, pre-build)
1. Schema + unknown-key rejection; bone names unique, tree acyclic, depth <= 6, bones <= 24 (display-entity cost; benchmark to confirm), cubes/bone <= 24.
2. Cube coords within -16..32 per bone model (rescale/split otherwise); rotations only single-axis 22.5 steps for vanilla item models (BetterModel's own limits UNVERIFIED).
3. Cuboid dims >= 1 px or flagged for z-fighting; zero-volume cubes rejected.
4. Texture: PNG power-of-two <= 256x256 per entity, every face has UV inside atlas, no fully transparent faces, transparent-pixel policy.
5. Animations: required idle/walk/attack/hurt/death present for mobs; lengths 0.1-10 s; keyframe times monotonic; no rotation > 360 deg per segment; death non-looping.
6. Hitbox sane vs model bounds; base entity allowed list.
7. Pack: pack_format per target version; total pack size cap (e.g. 10 MB) and sha1 stable; asset paths lowercase `[a-z0-9_/.-]`; no overwrite of vanilla namespace.
8. Round-trip test: compile spec -> .bbmodel -> load in BetterModel on a headless Paper test server, check no load errors, spawn, play each animation (CI gate, M).
9. Policy: no NSFW/copyright names/texts in generated labels; IP-sensitive skins rejected.

## 6. Vanilla-client fidelity limits
- Animation is server-driven display-entity transform interpolation: smooth but costs bandwidth per bone per viewer (UNVERIFIED magnitude); movement caps at tick rate (20 Hz) with interpolation durations; no vertex/skeletal skinning, so no bending meshes, only rigid cuboids.
- No true custom-entity hitbox shape: a vanilla base entity (invisible) provides the hit area (box/AABB only), vanilla death/hurt animations (tilt/red flash) must be suppressed; sounds via sound events in the pack.
- Item display has no collision, no shadows by default, light level fixed to its block; names/health bars via text display.
- First-person weapon: only the static item model + display transform; no real recoil animation. Fake with `select`/`range_dispatch` on use_duration/cooldown or brief model swap (works from 1.21.4; legacy CMD path on 1.21.1), muzzle flash via particles/sound.
- Pack acceptance: players get a prompt; refusing = invisible/default items. Required packs (`required` flag) can kick refusers; make this an owner setting.
- Version split: <1.21.4 uses legacy model overrides; >=1.21.4 the items/ definitions; 26.x special-type removals matter only for special models Cyrus does not use.

## 7. MVP vs later
MVP (first release):
- RigSpec schema + 3 archetypes (humanoid, quadruped, floating ghost) + prop/weapon. Size M.
- Compiler: spec -> block model JSON, items/ definition, .bbmodel, atlas PNG. M.
- Procedural animation library (5 clips). M.
- BetterModel integration: managed pre-installed plugin on Paper 1.21.4+ and 26.x; generated plugin uses compileOnly API + spawn/animate/hurt/death events. M.
- Handgun path with no engine: static item model + display transforms + sounds/particles. S.
- Resource pack merge + push (Paper `setResourcePack`, UNVERIFIED; or `server.properties` via itzg env). M.
- Validation + headless load test + turntable preview. M.
Later: flyer/serpent/spider archetypes (S each); vision critique loop (S); Texture Studio edits in-place (M); in-browser .bbmodel viewer/editor (L); IK/Molang authoring (L); 1.21.1 legacy-override pack variant (M); player-skin models/custom armor (M); BetterModel benchmark and caps (S); own minimal display-entity runtime if BetterModel becomes unmaintained (L).

## 8. Architecture recommendation
- Depend on (MIT, pre-installed, version-pinned): BetterModel. Do not depend on ModelEngine or FMM. Do not embed Blockbench.
- Build in-house: RigSpec + validator, archetype library, UV/atlas packer, procedural animation sampler, .bbmodel/Java-model emitters, pack builder/hosting, behaviour glue template (spawn, hurt/death hooks), turntable renderer. The bbmodel is a portable intermediate, so a later engine swap is cheap.
- Plugin shape: generated mod jar carries only logic + `assets/` is NOT inside the jar; Nxeon's pack service merges mod packs per server, hosts the zip, sets `resource-pack` + sha1.
- Pin: run a monthly CI that loads the golden banshee + handgun on every supported Paper version (incl. 26.x on Java 25).

## 9. Generic (non-Minecraft) rig/asset profile (5 lines)
1. Keep RigSpec engine-neutral: bones (parent, pivot, rest transform), meshes (cuboids now, triangle meshes later), materials, clips (named tracks of TRS keyframes, loop flag, events).
2. Add engine profiles that map roles and units (Minecraft pixels vs metres) and declare caps (bone/vertex/tri counts, texture sizes).
3. Exporters per target: Java model JSON, glTF 2.0 (Unity/Unreal/Godot/Hytale-style tools), bbmodel; texture to PBR channels when the profile asks for it.
4. Skinning weights + blend shapes only when a profile supports them; Minecraft profile forbids both.
5. Per-game validator plug-ins reusing the same checklist shape (budgets, naming, pack layout, licence flags).

## Sources
https://github.com/toxicity188/BetterModel ; https://raw.githubusercontent.com/toxicity188/BetterModel/master/README.md ; https://modrinth.com/mod/bettermodel ; https://github.com/toxicity188/BetterModel/wiki/API-example ; https://modrinth.com/project/free-minecraft-models ; https://mythiccraft.io/index.php?resources/model-engine%E2%80%94ultimate-entity-model-manager-1-19-4-1-21-11.1213/ ; https://github.com/JannisX11/blockbench ; https://blockbench.net/wiki/docs/bbmodel ; https://minecraft.wiki/w/Items_model_definition ; https://minecraft.wiki/w/Model ; https://minecraft.wiki/w/Display ; https://github.com/jasonjgardner/blockbench-mcp-project ; BetterModel wiki index https://github.com/toxicity188/BetterModel/wiki
