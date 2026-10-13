# Cyrus × Rust: readiness and how Rust modding works

Agent: game-rust (Cyrus v6). Branch `feature/cyrus-v6-game-rust`, worktree `/tank/dev-worktrees/cyrus-v6-game-rust`.
Research date: 2026-10-08. Current Rust build: **2634.289.1** (October 2026 forced update, 1 Oct). Next forced update: **Thu 5 Nov 2026, 19:00 UTC**.

Rust stays **`soon`** in `lib/cyrus/games.ts`. Making it `live` is the owner's call. The list below is what's still missing.

---

## Part 1: How Rust modding works (one page, also usable on the marketing page)

**A Rust mod is a server plugin.** It's one C# source file (`MyPlugin.cs`). The server compiles it, so you don't build it first. Two frameworks run these plugins:

- **Oxide (uMod).** The long-standing standard, MIT open source. It ships patched copies of the game's server DLLs. Plugins live in `oxide/plugins`, settings in `oxide/config`, saved data in `oxide/data`, translations in `oxide/lang`, logs in `oxide/logs`.
- **Carbon.** A newer framework that runs the same Oxide plugins unchanged. Instead of shipping patched DLLs it patches the game at runtime, and it uses `carbon/plugins` and similar folders. Oxide and Carbon can't be installed on the same server. Nxeon offers Oxide today. Carbon isn't offered yet.

**Install and reload.** Drop the `.cs` file into the plugins folder. Within seconds the framework compiles it (Roslyn, C# 14) and loads it. Edit the file and it hot-reloads. No restart, no downtime. On first load the plugin writes its own config file, and you edit that to tune it.

**Players install nothing.** Rust has no client modding: the game client is protected by Easy Anti-Cheat and has no mod loader. Plugins still change a lot of what players experience:
- menus, HUDs and overlays (CUI, drawn by the server and sent to each player),
- chat commands and messages,
- custom versions of existing items (renamed, re-skinned with Steam Workshop skins, given new behaviour),
- spawned NPCs, vehicles, crates and events,
- gather rates, loot, crafting, raid rules and weather.

They can't add new 3D models, textures or sounds that aren't already in the game.

**How a plugin plugs in.** The framework calls named methods ("hooks") when things happen in the game: `OnEntityTakeDamage` when something is hit, `OnPlayerInput` on key presses, `OnLootSpawn` when a crate fills, and so on. There are about 737 hooks today. A hook that returns a value can cancel the game's action, for example blocking damage.

**Permissions** follow `<plugin>.<permission>` (for example `frostaxe.use`) and are granted with `oxide.grant group default frostaxe.use`.

**The monthly cycle (the main reason plugins break).** Facepunch ships a forced update on the **first Thursday of every month**: 18:00 UTC in UK summer time, 19:00 UTC otherwise. On that day:
1. Every server must update. Clients on the new build can't join old servers because the protocol number changes (2633 → 2634 in October).
2. Oxide must update the same day, because it ships patched game DLLs. 2.0.7783 came out within hours on 1 Oct, followed by hotfix builds.
3. Plugins that used game code Facepunch changed stop compiling and unload.

Real examples from Oxide's own patch manifest:
- **September (2633):** `ItemContainer.CanAcceptItem` and `PlayerInventory.CanWearItem/CanEquipItem` gained a player parameter, and the `OnComposterUpdate` hook was removed.
- **October (2634):** `ItemContainer.Insert/Remove` gained a player parameter, and new Gen2 livestock animals arrived with their own hooks.

**Server rules (Facepunch's Community Server Guidelines, updated 15 Jul 2025).**
- Servers that change gameplay must be listed as **Modded**. Oxide does this by default (`"Modded": true`) and warns at startup when it's off.
- You may charge fees, take donations and sell cosmetics.
- You may **not** give players paid Facepunch DLC they don't own, pretend to be an official server, or circumvent paid content.

**Safety.** Oxide plugins aren't sandboxed. A plugin can read files, open network connections or start programs with the server's rights. That's why every Cyrus plugin goes through a strict static check before anyone sees it.

---

## Part 2: What Cyrus does for Rust now (this branch)

| Piece | File |
|---|---|
| Verified GameSupport (default export), plus version table, forced-update calendar, paths and the `knowledge` pack (38 API sheet lines, 9 failure rules) | `lib/cyrus/games/rust.ts` |
| 737 hook names Oxide/Carbon really call (generated) | `lib/cyrus/games/rust.hooks.ts` |
| Static validator (structure, manifest, dangerous APIs, failure rules, hooks, permissions, data folder, cleanup) | `lib/cyrus/games/rust.validate.ts` |
| Generator upgraded: verified APIs only, `oxide/…` layout, `cyrus.mod.json` manifest, target build in the header, unload cleanup, safe class names | `lib/cyrus/engine/games/rust.ts` |
| Compile harness (Roslyn against a reviewed stub surface; real-DLL mode ready) | `tools/cyrus/rust-check/` |
| Unit tests (pure) | `test/cyrus-game-rust.test.ts` |
| Monthly refresh script | `/root/agent-notes/cyrus-v6/game-rust/refresh-rust-facts.sh` |

**What the generator fixed (the handoff code had none of these flagged as `plausible:`, so every API was checked):**
- `PhoneController.PositionToGridName` → `MapHelper.PositionToString` (unconfirmed → used by 14 plugins).
- `BUTTON.FIRE_THIRD` (middle mouse) → `BUTTON.RELOAD` (R). FIRE_THIRD appears in no current plugin or call site.
- Wolf prefab `wolf/wolf.prefab` → `wolf/wolf2.prefab`. The old one no longer exists.
- Removed the horse prefab `nextai/testridablehorse` (gone).
- Frost: `temperature.SetValue` + `SendChangesToClient` (unconfirmed; temperature is recomputed every tick anyway) → cold damage + `wetness.Add`.
- Fire: `FireBall.lifeTimeMin/Max` (unconfirmed) → spawn, track, kill on a timer and in `Unload()`.
- Flight: `ApplyInheritedVelocity` (unconfirmed; player movement is client-side) → vehicle lift only.
- `damageTypes.Add` (unconfirmed) → `damageTypes.Set` when the hit doesn't carry that type yet, otherwise `Hurt` on the next tick, so hooks never nest.
- `task.owner` → `crafter.owner` (the hook's third argument, confirmed in the decompiled call site and in ZLevels).
- `Plugin.Call<bool>` throws when the other plugin returns null (Oxide `Plugin.cs` uses `Convert.ChangeType`) → raw `Call` + type test.
- Boombox station switching with `http://radio.example.com` URLs removed. It pointed the server at an external stream and used an unconfirmed API.
- Custom items had a random fake Workshop skin ID (2,000,000,000+). Now the skin ID defaults to 0 and the item is identified by shortname + display name (+ skin, if the owner sets a real Workshop skin). No fake Workshop IDs get sent to clients, and no DLC skins are used.
- **Found by the compile harness, not by reading:** every Yakko plugin with ally checks (38 of 540 sample projects) declared `[PluginReference] private Plugin Clans, Friends;` without `using Oxide.Core.Plugins;`, so it would not have compiled on any server. Fixed in the generator, and the validator now blocks it (`compile-using`).
- A mod named "Item" (or any game type name) would have produced `class Item : RustPlugin`, shadowing the game's `Item` class. Names like that now become `ItemPlugin`.

Every prefab path and item shortname the generator can emit was checked against Carbon's index for 2634.289.1. All 30 prefabs and 31 item shortnames are present.

---

## Part 3: Verification harness assessment

| Level | Needs | Status |
|---|---|---|
| Static lint (`rust.validate.ts`) | nothing | **Done**, runs in tests and can run on every build/edit |
| Roslyn compile against Cyrus's stub surface (`tools/cyrus/rust-check`, mode 1) | .NET 8 SDK (free, MIT) | **Built.** SDK installed user-locally on node-2 at `/tank/nxeon-build/wt/cyrus-v6-game-rust/node_modules/.cyrus-dotnet` (no system change). Catches syntax, typos, wrong types/overloads against the reviewed API list. |
| Roslyn compile against the real game (mode 2) | Rust Dedicated Server `RustDedicated_Data/Managed/*.dll` + Oxide release DLLs | **Not run.** Needs the owner's OK (below). |
| Load test on a real server (plugin loads, self-test passes) | A throwaway Rust server + Oxide | **Not run.** |

**What the owner would need to provide for mode 2 (a real compile).** Nothing has to be bought. The Rust Dedicated Server is free (Steam app **258550**, anonymous login, as used by Oxide's own build). On the build host:
```
steamcmd +force_install_dir /tank/nxeon-build/rust-ref +login anonymous +app_update 258550 -beta public validate +quit
# + unzip the matching Oxide.Rust-linux.zip from github.com/OxideMod/Oxide.Rust/releases over it
tools/cyrus/rust-check/run.sh --refs /tank/nxeon-build/rust-ref/RustDedicated_Data/Managed
```
Notes:
- The download is several GB, and it's refreshed once a month after the forced update.
- These are Facepunch's proprietary files. They stay on the build host, are **never committed, never copied into a customer download, never redistributed**. The tool only references them at compile time.
- Decision needed: OK to keep a reference copy of RustDedicated on node-2's `tank` dataset?

**Mode 3 (load test)** would start that server headless with a tiny procedural map (`+server.level "Procedural Map" +server.worldsize 1000 +server.maxplayers 1`), copy the plugin plus its `tests/<Name>SelfTest.cs`, and run `<cmd>.selftest` over RCON.
- It needs about 4-6 GB RAM for a few minutes, so it doesn't fit inside the 7 GB agents slice next to other work. It would need its own slot or a small dedicated VM.
- Owner decision.

---

## Part 4: Checklist before Rust can go live

**Owner decisions**
- [ ] Approve a reference RustDedicated copy on the build host for real compiles (mode 2), or say no and accept stub-compile + lint only.
- [ ] Approve (or not) a load-test sandbox: its own small VM or a time-boxed slot. Never on a customer VM.
- [ ] Decide on Carbon support. Nxeon only offers Oxide today, and the GameSupport says so (Carbon folders are documented but untested).
- [ ] Flip `rust` to `live` in `lib/cyrus/games.ts`, after the items below.

**Engineering**
- [ ] Wire `validateRustProject` into the real build path, so a `block` finding stops delivery and a `warn` finding is shown on the build card. This is the efficiency/lifecycle agents' pipeline; the call is one line: `validateRustProject(files)`.
- [ ] Wire `knowledge.apiSheet` into the generation prompt and `failureRules[].fix` into the repair prompt. Owner: efficiency agent.
- [ ] Hook the real-AI path (not just the templates) through the same validator and the stub compile.
- [ ] Install flow: copy `manifest.install` (+ optional `optionalInstall`) to `/opt/rust/<path>` on the customer's server. No restart is needed. Then read `oxide/logs` / the console for `Loaded plugin <Title> v<x> by Cyrus` (already parsed by `lib/mod-health.ts`). Owner: lifecycle agent.
- [ ] Outdated warnings: on each forced update (use `nextRustForcedUpdate()`), mark every installed Cyrus Rust plugin whose `targetGameVersion` ≠ `RUST_CURRENT_VERSION` as "needs re-check", and notify creators. Owner: lifecycle agent.
- [ ] Gameplay plugins carry `serverListing: "modded"`. The install flow should warn if the server's `oxide.config.json` has `"Modded": false`.
- [ ] One end-to-end test on a real Nxeon Rust server you own (not a customer's): install a generated plugin, run its self-test, unload, confirm cleanup (no stray NPCs/UI).

**Maintenance (monthly, about 30 min after Oxide releases on wipe day)**
- [ ] Run `refresh-rust-facts.sh <worktree>`. Review the hook diff and any "PREFAB GONE" / "ITEM GONE" lines.
- [ ] Add the new build to `RUST_VERSIONS` (mark it `current`, the old one `unsupported`) and update `RUST_VERSION_LABEL` / `RUST_MIN_LOADER`.
- [ ] Turn real signature changes into `knowledge.failureRules`. Regenerate `rust.hooks.ts`.
- [ ] Re-run `test/cyrus-game-rust.test.ts` and `tools/cyrus/rust-check/run.sh` (plus mode 2 if approved).

---

## Sources
- Oxide: https://github.com/OxideMod/Oxide.Rust (+ `resources/Rust.opj` history), Oxide.Core, Oxide.CSharp; releases https://github.com/OxideMod/Oxide.Rust/releases
- Carbon: https://docs.carbonmod.gg (first plugin, Oxide porting), metadata https://api.carbonmod.gg/meta/carbon/hooks.json, `/meta/rust/{prefabs,entities,items}.json`; releases https://github.com/CarbonCommunity/Carbon/releases
- Facepunch: https://wiki.facepunch.com/rust/Hooks, https://wiki.facepunch.com/rust/Weather, https://facepunch.com/legal/servers
- Wipe calendar: https://www.gameserverkings.com/knowledge-base/rust/wipe-day-guide/
- API usage corpus: 69 current plugins from https://umod.org/plugins (Kits, NTeleportation, RaidableBases, ZLevelsRemastered, Clans, Friends, …)

## Unknowns (also in GameSupport.unknowns)
- Rust's game assemblies are closed. Member names are cross-checked against decompiled call sites and current plugins, not compiled against the real DLLs.
- Facepunch's plugin-guidelines support article returned 403. The Community-vs-Modded rule comes from Oxide's own startup warning and secondary sources.
- Carbon on Nxeon is untested.
- Whether players can rename items in 2634, which would let them fake a name-identified custom item. Setting a Workshop skin ID closes this.
