# How Valheim modding works (one page)

*For the Cyrus team and the marketing page. Checked 2026-10-08 against Valheim 1.0.16/1.0.17. Sources are at the bottom.*

## The short version
Valheim has no official mod support. The community runs mods through **BepInEx**, a loader that starts with the game and loads plugin DLLs written in **C#**. Plugins change the game with **Harmony** patches: small pieces of code that run before or after one of the game's own methods. Most content mods also use **Jötunn**, a free library that handles the boring parts (adding items, recipes, locations, translations) and makes sure everyone on a server runs the same mod version. Mods are shared on **Thunderstore** and installed with a mod manager (r2modman, Thunderstore Mod Manager, Gale).

Iron Gate's only request to modders is written into the game itself: set `Game.isModded = true`, so the main menu shows the game is modded. In 1.0 this also switches **achievements off** for that game.

## Where a mod has to be installed
Valheim runs much of the world on the players' PCs, not on the server: whoever is closest simulates the creatures, smelters and ships nearby. So:

| Kind of mod | Server | Every player's PC |
|---|---|---|
| New items, weapons, food, armour, creatures, ships, buildings, locations | yes | **yes, same version** |
| Changes to things the nearest player simulates (smelter speed, taming, spawns) | yes | **yes** |
| HUD, minimap, music, colour grading, personal QoL | not needed | only players who want it |
| Pure server-side tools (logging, admin helpers that only the server runs) | yes | no |

If a content mod is missing on a player's PC, that player sees invisible or broken objects, or (with Jötunn's version check) is refused at the door with a clear message. That is why Cyrus marks content mods "server + every player" and enforces matching versions.

**Console players** (PS5, Xbox, Switch 2 since 1.0) cannot install mods. A server that requires a mod becomes PC-only; server-only mods keep crossplay working.

## How a Cyrus Valheim mod is built
- One C# project (`.csproj`, .NET Framework 4.8) with a plugin class (`[BepInPlugin]`), Harmony patches in `src/Patches/`, a pure balance class with unit tests, a BepInEx config file, English text, a Thunderstore `manifest.json` and a `cyrus.json` (target game version, install side, dependencies).
- It is compiled against the real Valheim assemblies. Nxeon never ships those: the build points at the game install (or the free dedicated server) on the machine doing the build.
- Every number is in the config (`BepInEx/config/com.cyrus.<mod>.cfg`), so server owners tune it without code.
- The plugin checks the running game version at startup and logs a warning if Valheim has moved past the version it was built for.

## How mods break
- **Game updates.** Valheim 1.0 (2026-09-09) shipped with an engine upgrade and no public test branch: the old BepInEx pack and most mods failed to start that day. Smaller patches rename methods or change their arguments (in 1.0 the smelter's "add ore" message gained a second argument), which quietly disables the affected feature.
- **Order of updates.** BepInExPack first, then Jötunn, then the mods. An old loader with new mods fails the same way as the reverse.
- **Version mismatch** between server and players for content mods.
- **Removing a content mod** drops its items from inventories and chests the next time they load. Back up worlds and characters first.

## Safety
Cyrus refuses to ship a Valheim mod that touches the internet, starts programs, loads code at runtime, uses native or unsafe code, deletes files, reads outside its own folder, changes admin or ban lists, or quits the game. Build files cannot run commands. Thunderstore's rules also ban malware and untested AI-generated mods, and ask for AI-assisted code to be disclosed, which Cyrus does in the README and the DLL's metadata.

## Sources
BepInExPack_Valheim (Thunderstore page, versions, changelog) · Jötunn (Thunderstore, GitHub changelog, vanilla data lists) · JotunnLib on NuGet · Thunderstore wiki (creating a package, global rules) · valheimgame.com news · HostHavoc and ConnectHosting 1.0 server notes · the Valheim 1.0.16 dedicated-server assemblies (Steam app 896660). Full URLs are in `lib/cyrus/games/valheim.ts` → `sources`.
