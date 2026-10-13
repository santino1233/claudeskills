# Cyrus · Terraria: readiness checklist + how Terraria modding works

Branch `feature/cyrus-v6-game-terraria` (worktree `/tank/dev-worktrees/cyrus-v6-game-terraria`). Written 2026-10-08.
Status in `lib/cyrus/games.ts`: **not flipped to live** (owner's call).

## Verdict first: two products on two game versions

| | TShock server plugin | tModLoader content mod |
|---|---|---|
| Game version | **Terraria 1.4.5.8** | **Terraria 1.4.4.9** |
| Loader | TShock 6.2.1 (TerrariaServerAPI 2.1, .NET 9) | tModLoader v2026.08.3.0 stable (.NET 8) |
| Players install | nothing | tModLoader (free Steam app, needs Terraria); the server sends the mod on join |
| What it can do | commands, permissions, rewards, events, vanilla items/enemies/bosses/buffs | anything new: items, enemies, bosses, mounts, biomes/world gen, UI, music, screen effects |
| **Runs on a Nxeon Terraria server today** | **Yes.** New servers run `ghcr.io/pryaxis/tshock:6.2.1`; plugins go in `/opt/terraria-plugins` and the existing installer restarts and confirms TShock's "Plugin X vY initiated." line (rolls back otherwise). | **No.** Nxeon never installs tModLoader. A tModLoader mod built by Cyrus can be downloaded and used on the player's own tModLoader server, nowhere on Nxeon yet. |

tModLoader has not moved to 1.4.5 (a contributor-only `1.4.5-dev` beta exists; "many months" per
tModLoader issue #5070), so a tModLoader server and a 1.4.5 TShock server cannot share players. They are two products.
Cyrus picks the flavour per request, records it in `cyrus.mod.json` (`flavor`, `target`, `side`, `playersInstall`),
and the validator refuses any file that mixes TShock and tModLoader code. The Nxeon installer already refuses
non-TShock Terraria mods (`lib/mod-install-support.ts`).

## What was verified for real (2026-10-08)

- Every API the generator emits compiles: **78/78** generated mods (26 prompts x Katara/Saka/Yakko) via
  `scripts/cyrus/terraria-compile-check.sh` on node-2. TShock plugins compile with .NET 9 SDK + the public TShock
  6.2.1 NuGet package to a `.dll`; tModLoader mods compile with .NET 8 SDK + the public tModLoader v2026.08.3.0 release
  and are packaged to a real `.tmod` by tModLoader's own `-build`. No game files were needed or used.
- Static validator + 100+ pure unit tests (`test/cyrus-game-terraria.test.ts`).
- NOT verified: that the mods load and behave in a running game/server (no load-test yet), how placeholder art looks,
  balance.

## Readiness checklist (what is left before Terraria can go live)

### Must have (TShock plugins, the part that can run on Nxeon)
1. **Compile step in the Cyrus pipeline.** Today the compile runs only in the dev harness. The build service
   (`services/modbuilder/`, owned elsewhere) needs a Terraria job: write files, `dotnet build -c Release` with the TShock
   package from a local NuGet cache, return `<Name>.dll` only (not the TShock dlls copied next to it), sandboxed (no
   network after restore, CPU/memory/time caps). The commands are in the harness script.
2. **Validator gate.** Call `validateTerraria(files)` before showing a build; block on `severity: "block"`.
3. **Load test on a throwaway server.** Start `ghcr.io/pryaxis/tshock:<pinned>` in a sandbox with the dll in
   `/plugins`, `-autocreate 1`, wait for "Plugin <Name> v<ver> initiated.", stop. Same proof the Nxeon installer uses;
   needs Docker (or podman) on the build host, which node-2 does not have in the agents slice today. Owner decision.
4. **Hook Cyrus "Install on my server" to the existing TShock installer** (`worker/game-mods.ts` Terraria path) with
   the built `.dll` instead of a GitHub asset. Lifecycle agent's area.
5. **End-to-end test on a real Nxeon Terraria server** (staging/throwaway, never a customer's): install, join with a
   vanilla 1.4.5.8 client, run the command, uninstall.

### Needed for tModLoader content mods (product decision first)
6. **Decide whether Nxeon offers a tModLoader server variant** (Terraria 1.4.4.9 + tModLoader, `DedicatedServerUtils`
   docker/compose in the release zip). Without it, content mods are "build + download" only and must be labelled so.
7. If yes: `.tmod` + `enabled.json` into `tModLoader/Mods`, restart, check `server.log`. Players need tModLoader and
   accept the "not from Workshop" download prompt (tModLoader shows it for every mod that is not on the Workshop).
8. Load test: `tModLoader.dll -server` headless with the mod enabled (the release zip ships the server; no Terraria
   assets are needed for a dedicated server, to be confirmed in that test).

### Maintenance (version table)
9. **TShock:** nothing to do in Cyrus when the platform bumps `TERRARIA_PINNED_VERSION` within TShock 6.x; the generator
   and `GameSupport` read it. A new TShock **major** needs a `TSHOCK_LINES` row (a unit test fails until it exists),
   and every plugin must be rebuilt (outdated signal). If TerrariaServerAPI changes ApiVersion, update the validator.
10. **tModLoader:** on each monthly stable (1st of the month) bump `TML_TARGET` in `lib/cyrus/games/terraria.ts` and the
    `TML_RELEASE` default in the harness, rerun the harness, read the migration guide entry for that month.
    Always build on stable, never preview (players on stable cannot load a preview-built mod).
11. When tModLoader 1.4.5 goes stable: add a 1.4.5 target, port the generator (tModPorter), and the two products can
    finally share a game version.

### Owner decisions
- Offer a tModLoader Terraria server (and accept that its players need tModLoader)? Until then, label content mods
  "download for your own tModLoader game/server".
- Allow Docker/podman on the build host for live load tests?
- Placeholder art policy: content currently borrows the player's own game images by reference (allowed, nothing is
  copied). Fine for launch, or require creators to upload art before publishing to the store?

## How Terraria modding works (1-page explainer, also for marketing)

**Two ways to mod Terraria.** A *server plugin* changes how a server behaves: chat commands, permissions, rewards for
beating a boss, welcome kits, boss-rush events. It runs only on the server, so everyone joins with the normal game and
installs nothing. A *content mod* adds things the game has never had: new weapons, enemies, bosses, mounts, biomes,
music and visual effects. Because the game itself has to draw them, everyone who plays needs the mod too.

**Server plugins (TShock).** TShock is the standard Terraria server toolkit. Plugins are small C# libraries loaded
when the server starts. They can do anything the base game already supports: give vanilla items, spawn vanilla bosses,
apply buffs and debuffs, react when an enemy is hit or killed, add commands with permissions. Cyrus writes the plugin,
keeps its settings in its own file (reloaded with `/reload`), cleans up every hook when it unloads, and targets the
exact TShock and Terraria version Nxeon servers run. Install = drop the `.dll` into the server's plugin folder and
restart; Nxeon checks the server log to confirm it loaded and rolls back if it didn't.

**Content mods (tModLoader).** tModLoader is a free, separate Steam app for anyone who owns Terraria. Mods are C#
projects: a `build.txt` (name, version, which side needs it), content classes (items, NPCs, projectiles, mounts,
world-generation steps, UI), and localization files for names and tooltips. Players build or download the mod, and when
they join a tModLoader server, the server sends them any mod it needs automatically. tModLoader updates monthly; Cyrus
builds on the stable release so the mod loads for the most players, and records the version it targets.

**What can break, and how Cyrus avoids it.**
- *Wrong server type:* a content mod never loads on a TShock server and vice versa. Cyrus picks the right one and says
  which server it needs.
- *Version mismatch:* players on another game version cannot join. Cyrus records the target version and warns when a
  new game, TShock or tModLoader release makes a mod outdated.
- *Missing art:* tModLoader refuses to load an item without a picture. Cyrus uses the matching picture from the
  player's own game until the creator adds theirs, so mods always load (no game files are copied).
- *Multiplayer desync:* effects that run on one player's game only. Cyrus spawns enemies and bosses only on the server,
  applies player effects only for the local player and syncs enemy behaviour.
- *Harm:* Cyrus blocks code that deletes files, edits saves, opens network connections, starts programs, uses native
  code or freezes the server, before the creator ever sees the build.

**Sources:** TShock 6.2.1 release + source, TerrariaServerAPI source, TShock NuGet package; tModLoader v2026.08.3.0
release, ExampleMod (MIT), ModLoader source (ModSide, ModNet, ModOrganizer, AssemblyManager), wiki (build.txt, players'
guide, developers' guide, migration guide), ModUploadRules.md, TERMS_OF_USE.md, issue #5070. Full list with URLs in
`lib/cyrus/games/terraria.ts` `sources`.
