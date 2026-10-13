# Mods: "disable without uninstalling" — per-game vetting (2026-10-06)

Branch `feature/mods-tab-rework` (worktree `/tank/nxeon-wt-mods`). The code form of this table is
`lib/mods/toggle-policy.ts`; the portal, the server actions and the worker all read it.

## Ground rule
A toggle is only offered where installs go through the shared engine (`lib/mods/engine.ts`), because only
that path records exactly which files Nxeon placed (`/root/.nxeon-mods/state.json` on the guest). Moving files
we can't name exactly is how a "disable" damages a server. Legacy (pre-engine) families have no such record.

Engine families today: minecraft, valheim, rust, cs2, factorio, corekeeper (`ENGINE_INSTALLERS`).

## Table

| Family / variant | Verdict | How disable works | Restart | Dependencies | Risk |
|---|---|---|---|---|---|
| Minecraft Paper / Purpur / Spigot / Folia (plugins) | **SAFE** | plugin jar moved from `plugins/` to `/root/.nxeon-mods/disabled/<key>/...`; plugin data folder untouched | restart | `depend:` in plugin.yml → a dependent fails to enable without it. Engine refuses to disable a package an enabled mod `requires`, and refuses to enable a mod whose required package is off | Plugin data stays; custom items are vanilla items + NBT, so nothing is deleted from the world |
| Minecraft Fabric / Quilt / Forge / NeoForge (mods) | **SAFE-WITH-WARNING** | mod jar moved out of `mods/`; config stays | restart | Fabric/Forge refuse to START if a required mod is missing (crash on boot) → same engine rules | Content mods: on world load, missing registry entries are dropped — blocks become air, items/entities deleted when chunks save; re-enabling does not restore them. Fabric gives no warning at all. Performance/library mods (Lithium, FerriteCore) are safe |
| Minecraft datapacks | **SAFE-WITH-WARNING** | datapack moved out of `<world>/datapacks/` | restart | — | worldgen/structure/dimension datapacks: new chunks generate differently, custom dimensions become unreachable |
| Minecraft / Valheim **modpacks** (mrpack / Thunderstore modpack) | **NOT-SUPPORTED** | — | — | a pack is a bundle + config overrides; "off" isn't meaningful | Use uninstall, or toggle individual mods |
| Valheim BepInEx (Thunderstore) | **SAFE-WITH-WARNING** | plugin folder moved out of `/opt/valheim/config/bepinex/plugins` **and** the image's synced copy under `/opt/valheim/data/bepinex/BepInEx/plugins` deleted (sha-checked) | restart (container start re-syncs) | Thunderstore declared deps; same engine rules | Mods with custom prefabs (items, building pieces, creatures) lose them from the world when areas load without the mod; ServerSync-style mods may refuse clients whose version differs |
| Rust Oxide / Carbon (uMod .cs) | **SAFE** | .cs moved out of `oxide/plugins` (or `carbon/plugins`); config + `oxide/data` stay | **hot** — Oxide's PluginWatchers unload on file removal (needs `PluginWatchers: true`, the default) | `// Requires:` enforced by Oxide; same engine rules | Plugin-spawned entities are vanilla prefabs; nothing deleted |
| CS2 CounterStrikeSharp | **SAFE** | plugin folder moved out of `addons/counterstrikesharp/plugins` | restart (CSS may also hot-unload) | rarely declared | No persistent world |
| Factorio (mod portal) | **SAFE-WITH-WARNING** | native: mod stays on disk, `mod-list.json` enabled=false (engine `nativeToggle`) | restart | info.json deps; same engine rules | On load Factorio shows "Migrated content" and REMOVES every entity/item/recipe of a disabled mod from the save — permanent once saved. Every Factorio mod is treated as content |
| Core Keeper (mod.io) | **SAFE-WITH-WARNING** | mod folder moved out of `StreamingAssets/Mods` | restart | mod.io declared deps | content mods' items/blocks lost; QoL/visual/language mods safe |
| Terraria TShock | NOT-SUPPORTED (on Nxeon) | would be: move .dll out of `/opt/terraria-plugins` + restart — mechanically SAFE (TShock plugins add no world content) | — | — | Not built: legacy install path keeps no state file |
| ARK (Workshop) | NOT-SUPPORTED | would be: remove id from GAME_MOD_IDS | — | — | **Unsafe**: ARK deletes a removed mod's structures/dinos/items on load |
| Empyrion (scenario) | NOT-SUPPORTED | — | — | — | The scenario is the save's basis; can't be "off" |
| Project Zomboid, DST, Unturned, Squad, Soulmask, TF2, L4D2, KF2, GMod, Necesse (Workshop) | NOT-SUPPORTED (on Nxeon) | would be: drop id from load list, keep files | — | — | PZ/DST/Unturned content mods lose items/map content; GMod/TF2/L4D2/KF2 are low-risk (no persistence). Not built — legacy config-write path, no per-file state |
| Vintage Story, Satisfactory, Arma Reforger | NOT-SUPPORTED (on Nxeon) | legacy installer, no state file | — | — | content mods lose blocks/buildings |
| Palworld, 7DTD, V Rising, Enshrouded, Conan, Arma 3, DayZ, etc. | NOT-SUPPORTED | no one-click mod install on Nxeon at all | — | — | — |

## Evidence
- Engine mechanics: read `lib/mods/engine.ts`, `lib/mods/installers/*.ts`, `worker/game-mods.ts`; exercised by
  `test/mods-toggle.test.ts` (12 tests: disable/enable round trip, idempotent repeat, rollback after a failure on the
  3rd rename, finishing an interrupted attempt, refusal on missing/hand-placed files, dependency rules both ways,
  Valheim synced-copy removal on disable and uninstall).
- **Valheim image (real bug found):** lloesche/valheim-server `common` `sync_bepinex_loadables()` is
  `rsync -a` WITHOUT `--delete`; pruning of files removed from `/config/bepinex/plugins` was only added upstream on
  2026-09-19 (commit e36cbfb0, PR #811, via a `.synced_from_config` manifest). On any image older than that, a
  plugin Nxeon "disabled", "uninstalled" or updated away **kept loading** from `/opt/valheim/data/bepinex/BepInEx/plugins`.
  Fixed: engine deletes that copy (only when byte-identical) on disable, uninstall and update. Copies of the fetched
  scripts: `/root/agent-notes/mods-rework/lloesche-*`. Prod has 8 INSTALLED Valheim mods (SELECT, 2026-10-06);
  earlier Valheim uninstalls/updates may have left stale DLLs on those guests — not checked (no customer VM access).
- Oxide unload on file removal: umod.org community thread "Plugins not reloading/unloading when removed"
  (https://umod.org/community/rust/7741-plugins-not-reloadingunloading-when-removed) — governed by `PluginWatchers`.
- Factorio content removal: forums.factorio.com "Migrated Content Event" (https://forums.factorio.com/viewtopic.php?p=442090).
- Fabric missing blocks → air with no warning: gameserverkings "error missing mods in world"
  (https://www.gameserverkings.com/knowledge-base/minecraft/error-missing-mods-in-world.md), Surrogate mod
  (https://www.modpackindex.com/mod/23217/surrogate).
- Valheim custom pieces vanish when the mod is removed: Searica "More Vanilla Build Prefabs" docs
  (https://thunderstore.io/c/valheim/p/Searica/More_Vanilla_Build_Prefabs/v/1.2.0/), Steam discussion
  (https://steamcommunity.com/app/892970/discussions/1/3409802983866133982).

## NOT live-tested
No throwaway game server was created. The brief described node-6 (`cmuw1x5o50000hlr0xtmx60xs`) as a disabled
test bed, but on 2026-10-06 the DB shows it `enabled=true, acceptsProvisions=true` with a PAYING customer VPS
(`syntech-vps`, created 14:01 UTC). Provisioning throwaways there touches the same NAT/port allocation as a live
customer, which the premise no longer covered — so the live round trip (toggle on a real Paper/Valheim/Rust
server, restart, read the log) is still owed. Harness idea: provision a Paper + a Valheim BepInEx throwaway once
the owner confirms a node, install LuckPerms / a Thunderstore plugin, run DISABLING via the portal, restart, confirm
`judgeModHealth` shows it absent, re-enable, confirm loaded; on Valheim also check
`/opt/valheim/data/bepinex/BepInEx/plugins` after each step.
