# Massive test mod: "The Gloam" (stress test of every Cyrus lane), for the preview account

Account: nicholas.sj.albanese@gmail.com. Target: Minecraft Paper 1.21.11. First run on a THROWAWAY server (Test Flight / Try It), then the safe lanes to `minecraft-f3izjh` (a broken worldgen pack stops a server at its next start, so worldgen is never delivered to the real server first).

## The idea (paste as the first prompt; then one scoped prompt per module)
**The Gloam**: a haunted twilight forest biome that bleeds into the overworld. Grim ruins, ember-lit paths, an old warden who needs help, a merchant who trades for relics, three relics to find, and a three-phase boss, the Hollow Regent, guarding the last ruin. Music changes when you enter the biome and again for the boss fight. Everything is tunable from a config screen.

## Modules (one mod, one namespace; edit one module or the whole thing)
| Module | What it contains | Cyrus lanes it exercises |
|---|---|---|
| Biome | Gloamwood biome (dark purple-grey grass/foliage/sky/fog colours, ember particles, ambient cave-like sounds), spawn weights, 2 ruin structures (Warden's Hold, Regent's Spire) from templates, loot chests | datapack + worldgen studio (needs CYRUS_DATAPACK_STUDIO + CYRUS_WORLDGEN, throwaway server only), structure templates, restart banner + rollback |
| Items | Gloam Lantern (right-click: light + reveal nearby relics, cooldown), Ember Blade (charged strike, hold sneak then release), Warden's Staff (ability graph: mark -> pull -> explosion, mana cost), 3 relic items, Regent's Crown (drop), recipes | item/ability designer, ability graph, 17-component library, item models + states (staff charge, blade swing), display contexts, textures |
| NPCs + quests | Warden Isolde (quest giver, dialogue tree with a choice), Old Mab (merchant: shop menu paid in relics), quest line "The Gloam Trial": talk -> find 3 relics (biome structures) -> choose (spare or slay a captive) -> report back -> reward; daily bounty | menu + quest designers, branching dialogue, click-hardened shop, progress storage, NPC entities (vanilla villagers with custom names/skins via item/display props; custom creature models need 26.x + BetterModel: out of scope on 1.21.11) |
| Boss | The Hollow Regent: 3 phases at 100/66/33% HP, attack patterns (shockwave, summon wisps, drain beam, teleport), arena rules + cleanup, boss bar, difficulty scaling, drops | boss/encounter designer, boss HUD |
| HUD + audio | Boss health meter and phase pips via glyph HUD, mana bar for the staff, subtitles; ~14 custom sounds (lantern hum, relic chime, blade swing, boss roar, phase change, wisp whisper, ruin door, ambience) and TWO music tracks: biome theme (loops while inside the biome) and boss theme (loops during the encounter) | glyph HUD, sound studio (synth + CC0 library picks via catalog tools), music/loop handling, subtitle keys |
| Motion + effects | Ruin door that opens on relic placement (display-entity hinge), ritual circle (flipbook particles) around the Regent's Spire, boss phase-change explosion, lantern flicker | motion core (display-entity transforms), particle presets, sound cues on the timeline |
| Config | Every number tunable: boss HP/damage/phase thresholds, relic counts, shop prices, ability cooldowns/mana costs, biome spawn weights, music volume, difficulty presets (easy/normal/hard) | config studio (values-only edits, reload without rebuild) |

## Acceptance (what "passes" means, each recorded)
1. Plan shows the module tree and cost estimate first; the live token meter and live asset previews run during the build; spend per module and per revision is shown.
2. Cross-references validate (quest -> NPC/items/boss, shop -> relics, boss drops -> items).
3. Test Flight boots on 1.21.11 with all designers, datapack and worldgen; playtest bot completes the quest path; worldgen loads (a deliberately broken variant is refused and rolled back).
4. In a real client: pack prompt/accept, textures in hand/GUI/ground/frame/head, staff and blade states, subtitles + sounds, music switches at the biome border and for the boss, boss bar + HUD update per phase, shop and dialogue menus work and cannot be exploited, door motion, ritual effect, config reload changes a value live.
5. Edit-one-module test: change only the boss (scoped prompt) and only config values; confirm the other modules' files are byte-identical.
6. Honest record of what failed, what Cyrus could not express, and cost per module.

## Flag order for this test (owner-only, after the deploy; one at a time)
Already in the deploy: CYRUS_DESIGNER, CYRUS_ITEM_STATES, Test Flight gate, managed plugins/delivery. Add for this mod: CYRUS_DATAPACK_STUDIO then CYRUS_WORLDGEN (web), CYRUS_MOD_SUITES (web), CYRUS_CONFIG_STUDIO (web), CYRUS_LIVE_ASSETS (web + service), CYRUS_CATALOG_TOOLS + CYRUS_CATALOG_INDEX (needs the index file and an API key or the subscription guard: see runbook 6.10), cyrus_studios_enabled stays off (preview accounts already have the studios).
