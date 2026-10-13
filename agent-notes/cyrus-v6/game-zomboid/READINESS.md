# Project Zomboid in Cyrus: readiness checklist and explainer (2026-10-08)

Status: **not live** (`soon`). Flipping it to live is the owner's decision. Branch `feature/cyrus-v6-game-zomboid`.

## What is done

- `lib/cyrus/games/zomboid.ts`: verified GameSupport (versions 42.21 → 41.78, install side `both`, plain-language install text, 17 dangerous-API rules, breakage risks with guards, outdated signals, categories, sources, unknowns) plus a `knowledge` pack (14 API-sheet lines, 12 Build 41→42 failure rules with regex detectors).
- `lib/cyrus/engine/games/zomboid.ts`: the template generator rewritten for Build 42.15+ and the 42.13 multiplayer rules (server-authoritative effects, shared timed actions, JSON translations, `ItemType`/registry ids, own script module, per-mod Lua folders, guarded fire, no map files). API check: `API-CHECK.md`.
- `lib/cyrus/games/zomboid.validate.ts`: static validator (layout, mod.info, Lua 5.1 structure lint written in TypeScript, dangerous APIs, failure rules, MP rules, script braces, JSON translations).
- `test/cyrus-game-zomboid.test.ts`: every category × model × six prompts must pass the validator with zero blocking issues, plus negative tests.

**Verified here (node-2, 2026-10-08):** `tsc --noEmit` clean; `test/cyrus-game-zomboid.test.ts` 21/21; a sweep of all 12 archetypes x 3 models x 6 prompts (216 mods) has zero blocking validator issues (warnings only for per-frame handlers and ModData.transmit, which are expected and reviewed). Nothing has been loaded in a real game.

Known limitation: Katara (3-file) drafts fold everything into one shared file, which loads before the game's client UI code, so their keybinds fall back to the default key instead of appearing under Options > Mods. Saka and Yakko output does not have this limit.

## What is left before it can go live

1. **Real-model generation path.** Today Zomboid output comes from the deterministic template, not from the AI build service (which only builds Minecraft). The live product needs the build service to: take the GameSupport `knowledge` pack as context, generate, run `validateZomboidMod`, feed blocking issues back for repair, and only then show the mod. Owner decision: when to wire it, and whether Zomboid gets its own service endpoint.
2. **Load test in a sandbox (not run).** Needs nothing proprietary in git, but it needs compute:
   - Project Zomboid dedicated server, downloaded by SteamCMD anonymously (app **380870**) inside a throwaway container, the same way Nxeon's own Zomboid image installs it. Nothing is redistributed: Valve's tool fetches it into the sandbox.
   - Steps: copy the mod into `<cachedir>/mods/<ModId>/`, set `Mods=<ModId>` in `Server/servertest.ini`, boot with a fresh world, wait for "SERVER STARTED", run a few game minutes, then grep `console.txt` / `Logs/*DebugLog-server.txt` for `ERROR`, `STACK TRACE`, `attempted index`, `Object tried to call nil` mentioning the mod's files. Exit code + log excerpt = the verdict.
   - Lua unit tests: run the generated busted spec with a free Lua 5.1 (`lua5.1` + `busted`, or the open-source `wasmoon`/`fengari` npm packages). Not installed anywhere today; adding them is a dependency or system-package decision for the owner.
   - Limits: a headless server never runs `lua/client` code, so HUDs, context menus and keybinds still need a human (or a scripted client, which is not available).
   - Resources: about 4 to 6 GB RAM and 2 vCPU per test run (Build 42 is heavy; Nxeon sells 6 GB as the smallest Zomboid plan). Must run on a sandbox VM, never on the build VM or a customer VM.
3. **End-to-end test on a real Nxeon 42.21 server.** Confirm: a mod in the cache folder `mods/` loads on the dedicated server with only `Mods=`; the `Mods=`/`WorkshopItems=` format the installer writes (official 42.15 guide: plain MOD_IDs; community sources disagree on a backslash); clients get kicked or warned when files differ; a Workshop-published copy downloads for players on join.
4. **Distribution to players.** Every player needs the same files. The only automatic path is the Steam Workshop, which needs the **creator's own Steam account** (and game licence) to upload; Nxeon cannot upload on a customer's behalf. Owner decision: (a) guide creators to upload via the in-game uploader with a Cyrus-generated `workshop.txt` + preview, or (b) offer "private server pack" downloads that players install by hand. Until then, multiplayer Cyrus mods are only practical for small groups.
5. **Install flow guard.** Nxeon offers PZ variants `b42` (default, stable public branch = 42.21 today) and `b41` (Legacy). Cyrus mods must only install on `b42` servers (lifecycle agent).
6. **Version table maintenance.** On every stable build: read the Steam news feed (app 108600) for "Modding Changelog"/"Migration Guide" posts, re-run the API check against the new JavaDocs, bump `PZ_TARGET.testedOn`, update `versions`, add failure rules. The "Build 42 Support Update" (rest of 2026) promises more modding changes and an official modding guide.
7. **Assets.** Items/vehicles reference icons, models and textures that are not generated; sounds reference `.ogg` clips. `ASSETS.md` lists them. The render/texture plug-in (research agent) would fill this.
8. **Policy.** The Indie Stone's Modding Policy (2.4) forbids selling access to mods. Cyrus can charge for the tool, but the community/mod store must keep Zomboid mods free to download, credit forks (4.1–4.3), and never label a mod "official" (2.2.3). Owner should confirm the community agent's store design respects this.

## Project Zomboid modding in one page (also for the marketing page)

**No loader to install.** Project Zomboid reads mods itself. A mod is a folder with a `mod.info` (id, name, version) and a `media/` folder of Lua scripts and plain-text "script" files that define items, recipes, vehicles and sounds. The game runs Lua 5.1 through Kahlua, a Java implementation, and exposes most of its Java classes to Lua.

**Build 42 is a different game for modders.** Build 42 became the default on 29 July 2026 (42.20; 42.21 is current, Build 41 lives on in the `legacy41` beta). Mods now sit in a version folder (`42/`) next to a `common/` folder for big shared assets; items declare `ItemType = base:weapon`; names, recipes and options are translated through UTF-8 JSON files; tags and weapon categories are registry ids like `base:screwdriver`. Almost every tutorial on the internet is for Build 41, which is why generic AI output breaks here and why Cyrus checks every file against the Build 42 rules first.

**Three Lua folders.** `shared` runs everywhere, `client` on each player's game (UI, keys, what the player sees), `server` on the server (and in singleplayer). Cyrus keeps all game-changing logic on the server: since multiplayer returned in 42.13, items and health that a client changes on its own are thrown away. Players' games detect a trigger and ask the server; the server checks distance, cooldowns and what the player is holding before anything happens.

**Everyone needs the mod.** Unlike a Minecraft plugin, a Zomboid mod runs on the server and on every player's PC, and the files must match. Servers list Workshop ids in `WorkshopItems=` and mod ids in `Mods=`; players then download the mods automatically when they join.

**How mods break.** A new build renames an API (the 42.21 stats system, for example), a Build 41 mod lands on a Build 42 server, two mods ship a file at the same path, or client-side code fights the server. Cyrus pins every mod to a minimum build, uses per-mod folders, puts every number behind a sandbox option with an on/off switch, and flags mods that a new game build may have broken.

**How to tune them.** Every generated mod adds its own page under Sandbox Options, so a server owner can change power, cooldowns, chances or turn the mod off without touching code; keybinds live under Options > Mods.

**Safety.** In April 2026 fourteen malicious Workshop mods wrote files outside the game folder; the game then removed and later restored `loadstring`. Cyrus blocks code-from-strings, file access, reflection, save deletion, admin and Steam-identity calls and obfuscated text before a mod is ever shown.
