# Palworld in Cyrus: readiness (2026-10-08, game-palworld agent)

Branch `feature/cyrus-v6-game-palworld`. Palworld stays `status: "soon"`; going live is the owner's call.

## Palworld in Cyrus on Nxeon: the Linux-only scope (owner decision 2026-10-08)

Nxeon runs Palworld on the **native Linux dedicated server only** (no Windows, no Wine/Proton). What Cyrus does:

| Request | What Cyrus does on Nxeon | Players install? |
|---|---|---|
| Server rules and balance: XP, capture, day/night length, pal and player damage, hunger, stamina, drops, gathering, work speed, egg hatch time, item weight, death penalty, PvP, hardcore, raids, fast travel, base and guild limits, randomizer, performance limits | **Builds a server settings preset** (`PalWorldSettings.ini`), checked against Pocketpair's documented keys with safe ranges | No (console players can join too) |
| Visual / interface tips: pal stats overlay, colour grade | **Builds a client-side tip**, labelled "client-side only: your own Windows PC, not your server" | Only the player who wants it |
| Anything needing a server script (spawn tables, rare variants, weapon retunes, base-job loops) | **Refuses**, says why (Palworld only loads server scripts on Windows), and offers the closest settings preset where an honest one exists (spawns -> spawn/drop rates, weapon -> player damage, worksite -> work speed, loot -> drop/gathering rates, partner regen -> pal HP regen) | n/a |
| Single-player / co-op-host scripts (spells, loot satchel, companion, expeditions, quests) and both-sides scripts (mount speed) | **Refuses**: the game ignores them on a dedicated server | n/a |
| New textures, models, sounds, Blueprint mods | **Refuses**: need cooked Unreal 5.1 packages on every player's PC | n/a |

The generator can still produce the other Lua kinds (`palworldLuaPackage`) and the validator lints them with
`{ nxeon: false }`, so nothing is lost if the policy ever changes, but `buildModFiles` (what customers get) never ships them.
Palworld must not be marked live on the strength of Windows-only mods; what is ready to consider is the settings preset path.

## Verdict: Linux vs Windows (confirmed from primary sources)

**Confirmed.** Pocketpair's own server guide says server-side mods work only on the **Windows** dedicated server
(https://docs.palworldgame.com/settings-and-operation/mod, fetched 2026-10-08). Their mod-loader docs list the
supported platforms as "Windows (Steam)" and "Windows dedicated server" only
(https://github.com/pocketpairjp/PalworldModUploader, `docs/en/01-General.md`). Nxeon's Palworld servers run the
native Linux server (`thijsvanloef/palworld-server-docker`; config at `Pal/Saved/Config/LinuxServer/`,
`lib/game-files-roots.ts`, `lib/game-control.ts`). So:

| What | Works on Nxeon's Linux servers today? | Players install? |
|---|---|---|
| **Server settings presets** (`PalWorldSettings.ini`: XP, capture, day/night, death penalty, hardcore, base limits, raids...) | **Yes.** Every dedicated server, any OS. | No. Console / Mac / Game Pass players can join too. |
| UE4SS Lua mods via the official loader (`Info.json` + `IsServer` rule) | **No.** Windows dedicated server only. | Only if the mod also changes client-predicted things (movement) or visuals. |
| PalSchema JSON data mods (a UE4SS mod) | **No** (needs UE4SS; Windows only). | Server-side data changes: no. |
| LogicMods / Paks (Blueprint, textures, models, audio) | **No**; also need cooked UE 5.1 packages Cyrus can't produce. | **Yes**, every player. |
| Client-only Lua (overlays, post-process, key-bound abilities in single-player / co-op host) | n/a (runs on the player's Windows PC) | Yes, each player who wants it. |

Ways Lua could reach Nxeon later, both **unverified by Nxeon**: (a) run the Windows server under Wine/Proton in a
separate image (community images exist, e.g. `ripps818/docker-palworld-dedicated-server-wine`); (b) the community
Linux port `XarminaEu/ue4ss-linux` (MIT, verified by its author on Palworld 1.0.1, LD_PRELOAD; hooks need resolved
addresses on stripped binaries, no Blueprint loader, folders must be lowercase `scripts`, and the official loader does
not run there). Owner decision: neither is pursued; Nxeon stays Linux-only.

## What was built

- `lib/cyrus/games/palworld.ts`: verified `GameSupport` + `knowledge` pack (API sheet from Palworld's published headers
  and the UE4SS docs, 13 failure rules) + `PALWORLD_KINDS` (server-settings / server-lua / both-lua / host-lua / client-lua
  with customer-facing reasons).
- `lib/cyrus/games/palworld.settings.ts`: 70 documented settings with types and safety ranges, a blocked list
  (passwords, ports, RCON/REST, player cap...), `mergeOptionSettings` (pure merge into an existing ini; a partial
  OptionSettings line is NOT a patch), `settingsIntent` (plain words -> changes, zero API cost).
- `lib/cyrus/engine/games/palworld.ts` (generator v2): settings presets; Info.json packages; side-aware main.lua that
  starts on dedicated servers and PCs; all 17 `plausible:` names resolved (fixed or removed, list below); authority
  checks before every state change; data tables found by short name; file access confined to the mod folder.
- `lib/cyrus/games/palworld.validate.ts`: static validator (package format, side rules, Lua block/bracket structure,
  blocked APIs, MOD_DIR file rule, knowledge failure rules, verified-hook list, settings key checks).
- `test/cyrus-game-palworld.test.ts`: generator x validator across every category/model, settings, negative cases.

### The 17 `plausible:` names, resolved
| Was | Now |
|---|---|
| `PalUtility:SendSystemAnnounce` | Verified (`PalUtility.h`), called with the world as context, server only |
| `StatusComponent:AddAdditionalEffect` | Does not exist. `StatusComponent:AddStatus(EPalStatusID)` |
| `PalTimeManager:GetCurrentDayTimeHour` | Does not exist. `UPalUtility:GetTimeManager():GetCurrentPalWorldTime_Hour()` + `UPalUtility:IsNight` |
| `PalDamageReactionComponent:ApplyDamageForMP` (pre-hook editing damage) | Does not exist. Post-hit hook on `CallOnActualDamageProcessed_ToAll` + bonus damage |
| `ShooterComponent:GetHasWeapon().ownItemId` | `GetHasWeapon():GetItemId().StaticId` (field is `ownItemID`) |
| `PalBaseCampModel.Transform / AreaRange` | Verified |
| `PalWorkProgress.CurrentWorkAmount / RequiredWorkAmount` | Verified |
| `CharacterParameterComponent:IsOtomo` | Verified |
| `player:GetRidingCharacter` | Does not exist. `UPalUtility:GetRidePal(player)` |
| `CharacterParameterComponent:GetWork` | Verified |
| `IndividualHandle.ID.InstanceId` | Verified |
| `DT_PalDropItem` CharacterID / ItemIdN / RateN | Verified (`FPalDropItemDatabaseRow`) |
| `PalSpawnerStandard.SpawnGroupList` | Not on any native class. Now `DT_PalWildSpawner` rows `LvMin_N/LvMax_N` (verified struct) |
| `PalPlayerState:EnterChat_Receive` | Does not exist. `PalPlayerState:EnterChat(FText)` |
| `AkGameplayStatics:PostEventByName` | Removed: no verified Wwise API; audio is a labelled template preview |
| Monster body `EmissiveColor` material param | Removed (unverifiable); variants keep lucky flag/rank/talents/scale |
| Bare `BeginDeferredActorSpawnFromClass` pal summon | Removed (breaks saves); "summon" effect staggers instead |

Also fixed (real bugs, not tagged): `SetHP` was called on the individual parameter (only the component has it);
`AddItem_ServerInternal` had 3 args (1.0 has 5); the mod never started on a dedicated server (ClientRestart +
IsLocalController only); `FindFirstOf("PalPlayerCharacter")` treated "first player" as "you".

## Readiness checklist (before Palworld can go live)

**Can ship now (owner decision)**
- [ ] Owner: approve **server settings presets** as the first live Palworld mod type in Cyrus.
- [ ] Wire the install: lifecycle agent applies `Cyrus.json.settings` via the existing Palworld path. On Nxeon the ini
      is regenerated from env vars on every boot (`applyPalworld`, `REAL_APPLY_FAMILIES`), so a preset must either map
      to panel fields (`lib/game-config.ts` PALWORLD schema covers only ~10 keys) or switch the server to
      `raw-config-mode` and use `mergeOptionSettings` with the server STOPPED. Needs a design choice.
- [ ] Confirm destructive settings (bHardcore, bPalLost, bAutoResetGuildNoOnlinePlayers) get an explicit confirm step in the UI.
- [ ] End-to-end on a throwaway Nxeon Palworld server: apply a preset, restart, read the ini back, check in game.

**Client-side tips (optional, lower priority)**
- [ ] One real run of the overlay and colour-grade tips on a Windows PC (needs a person with the game); unrun so far.
- [ ] Read the real 1.0.5 revision off the title screen and set `PALWORLD_MIN_REVISION` (today Pocketpair's example 82182).
- [ ] UI: show the refusal reason and the offered preset clearly (Cyrus.json `refused`, kind `unsupported`).

**Ongoing maintenance**
- [ ] Version table: bump `PALWORLD_CURRENT_VERSION` on every Palworld patch (1.0.0 Jul 10, 1.0.1 Jul 14, 1.0.2 Jul 28,
      1.0.2.1 Jul 30, 1.0.3 Aug 12, 1.0.4 Sep 7, 1.0.5 Sep 14 2026: every 1-4 weeks). Clients must match the server
      version, so old versions are "unsupported", and every mod gets the validator's "outdated" warning until rebuilt.
- [ ] Re-check the knowledge pack against a fresh PalworldModdingKit/header dump after each major patch.
- [ ] Watch: Steam app 2394010 build id, `Okaetsu/RE-UE4SS` experimental-palworld releases, `pocketpairjp/PalworldModUploader`, the server guide's config page.

## Verification harness assessment

Settings presets: the validator checks every key, type and range; the real check is applying one to a throwaway
Nxeon Palworld server and reading the ini back (see checklist). Client tips: `static-lint` (the validator) plus the generated busted spec for pure logic (not run here: no Lua on node-2).
A real load test needs nothing proprietary to be redistributed, but it does need the game server:
1. A Windows (or Wine) sandbox with the free dedicated server via SteamCMD (`app_update 2394010`, anonymous login).
2. UE4SS Palworld build (MIT, `Okaetsu/RE-UE4SS` experimental-palworld, or the Workshop package) placed per the loader.
3. Drop the package into `Mods/Workshop/<id>/`, write `Mods/PalModSettings.ini`, start the server headless, wait for
   world load, then parse `UE4SS.log` for the mod's "loaded" line and any "unavailable in this game version" / Lua
   errors, then stop. ~10 GB disk, 8-16 GB RAM per run: it cannot run on node-2's 7 GB agent slice.
Not implemented (needs a Windows/Wine VM and owner sign-off). `verification.canRunSandbox` stays `false`.
A cheap middle step that IS possible: install `lua5.4` + `luacheck` + `busted` on the build host to compile-check every
generated file and run the generated specs (needs the owner's OK to add packages to node-2).

## Owner decisions
1. Decided: Linux only. Server settings presets are the Palworld product; server scripts are refused.
2. Open: preset install path on Nxeon: panel fields only, or raw-config mode + merge?
3. Open: keep offering client-side tips (overlay, colour grade) at all, or settings presets only?
4. Open: OK to add Lua tooling (lua5.4/luacheck/busted) to node-2 for compile checks of client tips?

---

# How Palworld modding works (one page, also for the marketing page)

**Two very different things are called "Palworld mods".**

1. **Server settings.** Every Palworld server has a settings file (`PalWorldSettings.ini`) with about 100 switches and
   multipliers: XP rate, capture rate, how fast days and nights pass, how much pals and players hit, hunger, item
   weight, the death penalty, hardcore mode, raids, how many pals work at each base. Changing them needs no extra
   software, works on Linux and Windows servers, and **nobody who joins has to install anything**, including console
   players. This is what most server owners actually want ("double XP weekend", "hardcore rules").

2. **Script and content mods.** Palworld is an Unreal Engine 5.1 game. The community tool **UE4SS** lets mods run
   **Lua** scripts inside the game: they can hook the game's functions, read and change pals, items and data tables,
   and react to hits, spawns and time of day. Since v0.7 (Dec 2025) Palworld has an **official mod loader** and
   Steam Workshop support: a mod is a folder with an `Info.json` (name, package name, version, minimum game revision,
   dependencies and install rules) plus its files (`Scripts/` for Lua, `Paks/` for art and models, `LogicMods/` for
   Blueprint mods, `PalSchema/` for JSON data edits). Players switch mods on in the game's Mod Management menu.

**Where a mod runs matters.**
- Mods marked for servers (`IsServer`) run on the **Windows** dedicated server only. Linux servers, which most hosts
  use, can't load them yet.
- Anything visual (new looks, overlays, UI, sounds) and anything the game predicts on the player's PC (movement
  speed) has to be installed by **every player**, on a **Windows PC**. Console, Mac and Game Pass can't use mods.
- Single-player and the host of a co-op world run everything locally, so most mods "just work" there.

**Why mods break.** Palworld updates every few weeks, players can only join a server on the exact same version, and a
patch can rename the internal names a script relies on. Pocketpair's guideline: mods are at your own risk, never use
them on official servers, back up saves first, and delete (not just disable) mod files before updating.

**What Cyrus does.** On Nxeon (Linux servers) Cyrus turns a plain request like "double XP and shorter nights" into a
checked server settings preset that works for everyone on the server with nothing to install. When an idea would need a
script, Cyrus says plainly that Palworld can't run it on a Linux server and offers the closest preset instead. It can
also make small client-side tips (a pal stats overlay, a colour grade) for a player's own Windows PC, clearly labelled.
Textures, models and sounds need Unreal-cooked files and are not something Cyrus makes.
