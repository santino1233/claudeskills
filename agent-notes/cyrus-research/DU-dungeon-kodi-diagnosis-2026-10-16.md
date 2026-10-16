# DU: Infinite Dungeon on kodi, diagnosis of the owner's 5 complaints (2026-10-16)

Server cmuzuj8wl00xshlv49mfv4a1p (kodi.playnxeon.com, container `mc`, Paper 1.21.11-132). Everything here was read-only: SSH helper reads, docker logs, unzip -p, cat. Source came from the build service's own `svcSourceZip` (read-only GET). Nothing was written, restarted or chowned.
Scripts and outputs: /tmp/claude-0/-/4400f828-d7f0-408f-8666-b0db1ce3383f/scratchpad/du/ (kodi1.ts/kodi1.out, kodi2.ts, x/<buildId>/ extracted sources).

## What is actually installed
- `plugins/InfiniteDungeon-1.27.1.jar`, 137,356 B, Oct 16 05:18, sha256 75203f3f...e887. That is the same hash as /var/lib/nxeon/modbuilds/mb51322a365e1e9476d7be.jar (v1.27.1, the "config fix" build). The DB lastInstall says `replaced: ["InfiniteDungeon 1.6.0"]`, restarted true, at 05:18:30Z.
- plugin.yml in the jar has **no `depend: [BetterModel]`**. The 1.27.1 source has **0** BetterModel references (1.26.0 has 11 in MonsterManager, 5 in BossManager and 1 in DungeonManager, plus the depend).
- BetterModel 2.2.0 is installed and enabled. `plugins/BetterModel/config.yml` is minecraft:minecraft 644 (the Nxeon-managed template). models/ holds all 24 `nx_oqyxirj4_*.bbmodel` files, and build.zip (190,295 B) was regenerated Oct 16 05:18.
- Pack delivery **works**. server.properties resource-pack is empty, which is expected because NxeonPackLoader hands out the packs. `plugins/NxeonPackLoader/packs.json` has 2 packs: main nx_oqyxirj4 (sha1 8e931ebc...) and bettermodel (sha1 bb716b19...). It reloaded with 2 packs at 05:19:03. telemetry.json shows the bettermodel pack was sent once and came back ACCEPTED, DOWNLOADED and SUCCESSFULLY_LOADED once. The main pack has 4/4/4/4. So the rc19 pack hand-off is already effective on kodi.
- **Stale runtime config.** `plugins/InfiniteDungeon/config.yml` is 7,268 B and dated Oct 15 12:56. It is byte-identical to the v1.6.0 default (test/fixtures/preserve-dungeon/1.6.0-.../config.yml). The plugin calls `saveDefaultConfig()` (InfiniteDungeonPlugin.java:15), which never overwrites an existing file, so the 1.27.1 defaults were never applied. Runtime values: `dungeon.max-floors: 100` and `boss.floor-interval: 10`. The owner ran `/dungeon admin setfloor papiguapo 99` and it was accepted. Every key added after 1.6.0 (room-min/max-height, pit-chance, secret-room-chance, hidden-chest-*, themes.*, boss-arena.*) is missing from the file. The code falls back to its hard-coded `getInt(path, default)` values, which equal the jar defaults, so room generation itself is unaffected.

## Last session log (05:18:31 restart, papiguapo 05:20-05:30)
- No ERROR or exception from InfiniteDungeon or BetterModel. BetterModel loaded normally.
- Mobs are logged as plain vanilla entities: `Vex['Elite Ember Imp']`, `Spider['Giant Cave Spider']`, `Zombie['Thorn Stalker']`, `Skeleton['Bone Archer']`, `IronGolem['Frost Colossus']`. There is also mob infighting, for example "Ember Imp was slain by Magma Brute" and "Giant Cave Spider was slain by Moss Sentinel".
- At 05:25:10-15, 3 Bone Archers and 1 Grave Shambler "fell out of the world" (y=-273). That points to the pit defect below.

## Verdict per complaint
1. **Vanilla mobs: WRONG BUILD INSTALLED.** v1.27.1 lost all BetterModel wiring. This regression was already recorded in the CK note, round 4. The pack is not the problem: both packs loaded on the client. v1.26.0 (mbe94b7e5992e0a1c0df8d) is the last build with wiring, and installing it should show models. Note: the 10 rotating BossManager bosses and anything not in MODELED_IDS stay vanilla even in 1.26.0.
2. **Floors look basic: DESIGN LIMITATION.** `buildRoomStructure` (DungeonManager.java:864-928 in 1.27.1, identical in 1.26.0) fills the whole floor with one block, `theme.floor()`. Walls and ceiling also use one block each. Decoration in normal rooms (`decorateTheme`, :1082-1142) is only 2-4 blocks per theme (wall fixtures every 4 blocks, 1 banner, 2 mushrooms, 2 icicles, cobwebs, vines). There are no floor patterns, rubble, carpets or variation. Reinstalling would not change this.
3. **Empty chests: REAL CODE DEFECT, present in EVERY build** (1.6.0, 1.14.1, 1.26.0, 1.27.1). `placeChest` (:1500-1513) and `placeHiddenChests` (:1031-1046) do `block.setType(CHEST); if (block.getState() instanceof Chest chest) { chest.getInventory().clear(); ...getInventory().addItem(...); chest.update(); }`. On a placed block, `getInventory()` is the live world inventory. `update()` then writes the BlockState snapshot back, and that snapshot was captured while the chest was still empty, so the items are wiped (Paper CraftBlockEntityState.update → applyTo loads the snapshot NBT). The loot pool is not empty: treasure.loot has 6 entries in both the runtime and jar config, and `rollWeightedItem` returns items. Fix: use `chest.getSnapshotInventory()` and keep `update()`, or drop the `update()` call. Confidence is high from the API semantics, but I have not reproduced it in game. Also by design, a chest only exists on "treasure" floors (50% of normal floors, `rng.nextBoolean()` at :704) or at hidden spots (pit bottom, catwalk, secret room; max 2).
4. **No obstacles: DESIGN LIMITATION.** Normal rooms get only an optional pit (45%), a catwalk when height ≥ 7, and a secret side room (30%). There are no pillars, cover or obstacle pass. Pillars exist only in boss arenas (`decorateBossArena`). There is also a **real defect** in `carvePit` (:930-964): the pit has no side walls below floor level, and the floor is a 1-block slab over the void. Mobs in the pit walk sideways under the floor and fall into the void, as in the log at 05:25.
5. **Rooms still small: DESIGN LIMITATION / the "bigger rooms" refine only partly delivered.** `ROOM_WIDTH = 10`, `ROOM_LENGTH = 14` are hard-coded constants (:65-66), giving a 9x13 interior. v1.6.0 was 8x8 with a 7x7 interior. Only the height became configurable (6-9). Boss arenas add +8/+6 (18x20, height 12). There is no config key for width or length, and 1.14.1 and 1.26.0 are identical. The 32-block slot would allow up to about 24 wide.

## Would reinstalling change anything?
| Build | BetterModel wiring | jar max-floors / interval | room W×L | chest bug |
|---|---|---|---|---|
| 1.14.1 mb6c1ca6 | yes (5 creatures) | 100 / 10 | 10×14 | yes |
| 1.26.0 mbe94b7e | yes (24 specs) | 100 / 10 | 10×14 (roomgen byte-identical to 1.27.1) | yes |
| 1.27.1 mb51322a (installed) | **no** | 11 / 3 | 10×14 | yes |
Reinstalling 1.26.0 fixes only complaint 1. Floors, chests, obstacles and room size stay the same. Also, kodi's stale 1.6.0 config.yml overrides max-floors and interval whichever jar is installed.

## Shortest path to a good result
1. Make one new build on base 1.26.0 source with these changes. Check it afterwards for regressions (plugin.yml depend + BetterModel.model count + config max-floors and interval):
   (a) In both chest methods, use `getSnapshotInventory()`.
   (b) In `carvePit`, give the pit solid side walls down to the pit floor.
   (c) Set max-floors 11 / floor-interval 3.
   (d) Make the room width and length config keys with larger defaults, for example 18×22.
   (e) Add a pillar/cover obstacle pass and a mixed-block floor pattern to `decorateTheme`.
   The items are small enough to hand-patch if the refine keeps regressing.
2. On kodi (owner action), remove or replace the stale `plugins/InfiniteDungeon/config.yml` so the new defaults are written, then restart. No pack work is needed; rc19 delivery is already working.
