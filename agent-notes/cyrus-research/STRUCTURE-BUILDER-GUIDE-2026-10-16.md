# How to build a dungeon room for Cyrus (owner guide, 2026-10-16)

This guide is for building the big, decorated rooms that Cyrus mods paste into dungeons. You build a room in Minecraft, mark a few spots with coloured blocks, save it to a file and upload it. Cyrus checks the file, and the mod places the room for you, turned and mirrored so runs look different.

Code: branch `feature/cyrus-structures` (stage 1). Background: `DV-room-generation-options-2026-10-16.md`. Until the production upload store exists, uploads only work on dev/staging hosts (`CYRUS_UPLOAD_STORE=local`); in production the Rooms card says "uploads off".

## 1. Set up a building world (once)

1. Use the **same Minecraft version as the server, or older**. Cyrus needs 1.21.1 or newer and refuses a room saved on a newer version than the mod's server. 1.21.11 is a good default.
2. Create a **Creative, Superflat** world, with cheats on. Turn off mob spawning: `/gamerule doMobSpawning false`.
3. Choose a tool:

| Tool | Setup | Best for | How you save |
|---|---|---|---|
| **Vanilla structure block** (recommended) | nothing: `/give @s structure_block` | any room up to 48 x 48 x 48 | structure block in SAVE mode, gives a `.nbt` |
| **WorldEdit** (Paper/Spigot plugin, or the Fabric mod) | install WorldEdit 7.3+ in your building world | fast walls, `//replace`, `//smooth`, brushes, rooms up to 64 wide | `//schem save <name>`, gives a `.schem` |
| Axiom (Fabric client mod + server plugin) | Fabric client; free for non-commercial use | sculpting and painting | export as `.schem`, or save the area with a structure block |

Litematica `.litematic` files are not read yet. In Litematica, use "save as vanilla structure", or save the area with a structure block.

## 2. Size and layout rules

| Rule | Value |
|---|---|
| Standard footprint | 40 x 40 (also fine: 24 x 24, 32 x 32; boss arenas up to 48 x 48 or 64 x 64 with WorldEdit) |
| Hard limits | each side 64 or less, height 48 or less, total volume 64 x 32 x 64 (131,072 cells), 60,000 blocks, 2 MB file |
| Origin | the **north-west bottom corner** (lowest x, lowest y, lowest z) is the room's corner. The save starts there |
| Doorways | 3 wide and 4 high. Entry in the middle of the **south** wall, exit in the middle of the **north** wall. A standard doorway lets Cyrus join rooms later |
| Floor | solid floor under every place a player walks. Keep 2 blocks of headroom on paths |
| Walking path | there must be a way **on foot** from the entry to the exit: steps of 1 block, drops of up to 3, ladders, vines and scaffolding are fine. Cyrus refuses a room whose exit cannot be reached |
| Light | keep light level 8 or more on the main path (lanterns, torches, shroomlight). Cyrus warns below 50% of the floor; dark corners on purpose are fine |
| Gravity and fluids | avoid sand or gravel over air; contain lava and water |

## 3. Marker blocks: tell the mod where things go

Put markers **where the thing's feet go** (one block above the floor). Cyrus removes them from the room and tells the mod where they were. Do not use glazed terracotta as decoration in these rooms (or ask for "data-only" markers, see the end of this section).

| Block | Meaning | How many |
|---|---|---|
| `light_blue_glazed_terracotta` | **Player entry**. Place it while standing where the player arrives and **looking the way the player should look** (the block faces you; Cyrus takes the opposite of its facing) | exactly 1 |
| `magenta_glazed_terracotta` | **Exit door**: bottom-centre of the exit doorway. The mod can seal it with bars until the room is cleared | 1 (or more); none only in treasure / shrine / secret rooms |
| `lime_glazed_terracotta` | Normal **mob** spawn | any |
| `red_glazed_terracotta` | **Elite** mob; in a **boss** room it is the **boss spot** | boss rooms need exactly 1 |
| `orange_glazed_terracotta` | **Trap** trigger | any |
| `yellow_glazed_terracotta` | **Objective** (shrine altar, lever puzzle) | any |
| `purple_glazed_terracotta` | **Connector**: centre-bottom of a 3 x 4 opening, for joining rooms later | any |
| a real `chest`, `barrel` or `trapped_chest` | **Loot** spot (stays a chest; anything inside is removed, the mod fills it). A trapped chest is a mimic or trapped loot | 16 or fewer is sensible |

**Extra details with a DATA structure block** (optional): give yourself a structure block, set it to **DATA** mode and type a text:
- placed **directly on top of** a marker or chest, the text describes that marker: `mob:ranged`, `mob:melee`, `mob:swarm:4`, `trap:arrow`, `trap:fire`, `trap:spikes`, `trap:collapse`, `chest:treasure`, `chest:hidden`, `door:secret`, `objective:shrine`, `connector:n`;
- placed **on its own**, it is a marker by its text (`mob:ranged`, `boss`, `entry`, `door:exit`, ...).
DATA blocks are removed from the room too. Other structure-block modes (SAVE, LOAD, CORNER) must not be left inside the saved area.

## 4. What is not allowed (the upload is refused, and Cyrus says where)

- Command blocks (all three), jigsaw blocks, structure blocks that are not DATA markers, nether / end portals, end gateways, test blocks.
- Signs, books or items whose text runs a command (click events), command-block items or minecarts, spawners whose mob has extra data (a plain spawner of one vanilla mob is allowed, with a warning).
- Modded blocks (only `minecraft:` blocks), blocks or block states that do not exist in that Minecraft version.
- Armour stands, item frames and paintings are not kept yet (they are removed with a note). Barriers, light blocks and TNT are allowed with a warning.

## 5. Save the room

**With a structure block (recommended, `.nbt`):**
1. `/give @s structure_block`, place it just outside the room's north-west bottom corner.
2. Right-click, set mode **SAVE**, name it `<theme>_<type>_<nn>` (for example `crypt_combat_03`).
3. Set **Relative Position** so the box starts at the room's corner (for a block placed at the corner minus one in x and z: `1, 0, 1`) and **Structure Size** to the room size (for example `40, 24, 40`). Click **Detect** if you placed corner blocks, check the outline, then **SAVE**.
4. The file is in your world folder: `saves/<world>/generated/minecraft/structures/crypt_combat_03.nbt`.

**With WorldEdit (`.schem`):**
1. `//pos1` at the north-west bottom corner, `//pos2` at the opposite top corner (or use the wand).
2. Stand anywhere, `//copy`, then `//schem save crypt_combat_03`.
3. The file is in `plugins/WorldEdit/schematics/` (server) or `config/worldedit/schematics/` (client mod).

## 6. Upload it

1. Open the mod in Cyrus, tab **Assets**, card **Rooms** (the top plan is needed to upload; uploads cost no tokens). The mod must have been built once.
2. Optionally type a **theme** (for example `crypt`); otherwise the theme is the first word of the file name.
3. Click **Upload room** and pick the `.nbt` or `.schem`. Cyrus checks it in a second or two:
   - **refused**: a red box lists what to fix (for example "no walkable path from the entry (19 4 37) to the exit (19 7 0)").
   - **added with notes**: for example unreachable mob markers, a dark floor, items removed from chests.
4. Use **Preview** to look at it (3D, top-down, or one layer at a time with the slider; colours are approximate). Click the theme tag to change it, **Remove** to take it out of the mod (builds already made keep it).
5. Ask Cyrus for the dungeon (or a change: "use my uploaded rooms for every floor"). The next build ships the rooms in the mod; the mod's code decides which mobs, loot and traps go on the markers.

Uploading the same file name again replaces that room.

## 7. Names and themes

- File name = room id: `<theme>_<type>_<nn>`, lowercase letters, digits and underscores, starting with a letter (2-48 characters). Example: `crypt_combat_03`, `lava_boss_01`, `ice_treasure_02`.
- **Types** Cyrus understands: `combat`, `elite`, `boss`, `treasure`, `shrine`, `trap`, `hub`, `corridor`, `secret`, `start` (anything else is `room`). Treasure, shrine and secret rooms may be dead ends (no exit).
- **Themes** suggested: `castle`, `lava`, `swamp`, `ice`, `crypt`, `ruins`, `throne`. Per theme aim for 8-10 combat, 2 treasure, 1 shrine, 1 trap, 1 elite and 1 boss room (about 13 rooms; 64 rooms per mod at most).

## 8. Example: "Crypt of the Fallen Kings" (`crypt_combat_01`, 40 x 24 x 40)

Coordinates are relative to the room's corner (x east, y up, z south). Exit north (z = 0), entry south (z = 39).

| Part | What to build |
|---|---|
| Shell | walking floor at y3 (solid y0-2 below): `deepslate_tiles` with some `cracked_deepslate_tiles`; walls 2 thick (`deepslate_bricks` outside, `polished_deepslate` inside, `chiseled_deepslate` every 6 blocks); ceiling at y23 with upside-down `deepslate_brick_stairs` arches every 8 blocks |
| Main hall | two rows of 5 pillars (3 x 3) at x = 10 and x = 29, every 7 blocks; hanging `soul_lantern` on 4-long `chain` between pillars |
| Sunken nave | x14-25, z8-31, 3 deep: `soul_soil` floor with 4 `soul_fire` braziers; two `deepslate_brick_slab` bridges at z = 14 and z = 26 with `iron_bars` railings |
| Side crypts | 5 alcoves per side (x2-7 and x32-37), each with a sarcophagus, a `skeleton_skull`, cobwebs and candles |
| Balcony | 3-wide gallery at y10-11 with `deepslate_brick_wall` railings, spiral stairs in the north corners |
| Exit dais | x14-25, z1-6, three steps up to a king's statue; exit doorway x18-20, z0, y6-9 |
| Entry | doorway x18-20, z39, y3-6 |

| Markers | Where |
|---|---|
| `light_blue_glazed_terracotta`, placed looking north | (19, 4, 37) |
| `magenta_glazed_terracotta` | (19, 7, 0) |
| 6 x `lime` with DATA `mob:melee` on top | (6,4,8) (6,4,18) (6,4,28) (33,4,8) (33,4,18) (33,4,28) |
| 3 x `lime` with DATA `mob:ranged` on top | balcony (3,12,20) (36,12,20) (19,12,38) |
| 1 x `red` (elite) | pit centre (19, 1, 20) |
| 2 x `orange` with DATA `trap:collapse` | bridge middles (19,4,14) and (19,4,26) |
| 1 x `orange` with DATA `trap:arrow` | (19, 4, 33) |
| `chest` with DATA `chest:treasure` | behind the statue (19, 7, 2) |
| `barrel` with DATA `chest:hidden` | in the third west alcove behind a cracked-brick false wall (3, 4, 18) |

About 16-20k blocks and 28 block types: fits one structure-block save. A practised builder needs 60-90 minutes with WorldEdit.

A tiny worked example ships with Cyrus: `sample_vault_01` (9 x 6 x 9), built by `lib/cyrus/structures/sample.ts`, used by the golden plugin `mc-structure-rooms` and its Test Flight.

## 9. If something goes wrong

| Message | Fix |
|---|---|
| "no entry marker" / "N entry markers" | exactly one `light_blue_glazed_terracotta` |
| "the entry marker ... has no floor under it or no 2-block headroom" | put it where the player's feet go, on a floor, with 2 air blocks |
| "there is no walkable path from the entry to the exit" | look for a wall, a gap wider than one jump, a step higher than 1 block or a drop deeper than 3; open the Preview in Slice mode at the floor's height |
| "saved by a newer Minecraft" / "newer than this mod's ..." | save it again from a world on the server's version |
| "command blocks run server commands" (and similar) | remove that block from the saved area |
| "the structure is ... the limit is 64 x 48 x 64" | split the room, or save a smaller area |
| "uploads off" | uploads are not switched on for this host yet (production store pending) |
