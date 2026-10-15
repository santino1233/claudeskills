# MOD SLATE: 12 big Cyrus mods for YouTube + training data (2026-10-15)

Read-only research. No builds were run, no code was changed, nothing ran on node-2 or production. This file is the only output.
Sources (all read for this plan): CK-infinite-dungeon, CU-more-mobs, DJ-no-creature-cap, DS-guard-false-positives, BU-rc12, BV-owner-batch, BZ-eval-realism, CI-boss-model, KNOWN-BUGS.md (this folder); docs/cyrus/02-engine.md, 12-gaps-and-roadmap.md; lib/cyrus/adapters/minecraft-coverage.json (lanes, 92 archetypes, `stillCannot`); lib/cyrus/creature/spec.ts + templates.ts; lib/cyrus/sound/spec.ts; lib/cyrus/textures/dsl.ts; services/modbuilder/golden/ (77 goldens, results.json all pass on 1.21.1/.4/.8/.11); services/modbuilder/eval/real-world-v1.json (80 prompts); /root/cyrus-eval/dungeon-2026-10-15 stage records; thumbnail images/16.webp.

---

## 0. One-page summary

**What Cyrus can really deliver today (1.21.x, vanilla client + server-pushed resource pack):**
- Paper plugin code for anything on the 77 goldens (arenas, quests, menus, shops, pets, mounts, cutscenes, holograms, structures, instanced void-world dungeons, world events).
- Animated creatures: BetterModel display-entity models on an invisible vanilla base mob. Templates exist for **humanoid, floating_ghost and quadruped only** (features: horns/hood/cape; hood/crown/claws; horns/mane/spikes). `flyer` and any other body (spider, serpent, biped dinosaur, mech) need the explicit form: up to 48 KB per rig (~12k output tokens) and a real chance of hitting the $4 build budget. No per-build creature cap any more; 64 per mod is an abuse guard (DJ).
- Designer lanes: items with abilities (10 triggers, 21 actions incl. hitscan/beam/area_blast), chest menus, quests, bosses (1-5 phases, up to 8 telegraphed attacks, boss bar, minions, waves), glyph HUDs (action bar, boss bars, sidebar).
- Sounds: synthesized sets, 8 events per set, 4 variants, 60 s per set, 256 events / 480 s per mod. Item textures + item states (1.21.4+). Data packs (recipes, loot, advancements, enchantments, jukebox songs) and worldgen in the mod's own dimension (restart, new chunks only).
- **Cannot** (client mod needed): new block/entity types, shaders/fog/sky, free HUD, real vehicles, custom particle textures, voice, network/Discord.

**Blockers to fix BEFORE filming anything with creatures (P0):**
1. BetterModel pack never reached clients on 1.21.x (overlay refused + no hand-off on the standard install path): creatures render as magenta/black cubes on camera. Fix is on `feature/cyrus-followups`, not deployed.
2. Guard false positives on boss-ability refines (guard-2026-10-15.1, branch `fix/cyrus-guard-false-positives`, needs image).
3. Change builds can silently drop the creature attach (dungeon 1.13.0 lost `depend: BetterModel` while still listing 4 creatures). Needs a "every recorded creature is still attached" check on change builds.
4. `MB_BOSS_MODEL` (designer boss wears a rig) is OFF.
5. Owner account daily cap 5,000 tokens: about 9-10 builds a day. The slate is ~90 builds.

**Measured cost units (used for every estimate below):**
| Unit | What | USD | Tokens charged | Source |
|---|---|---|---|---|
| C | fresh core build | 0.36-1.24 (avg 0.83) | 178-622 | BV, 11 builds |
| S | small content refine (a theme, a system) | 0.65-0.85 | 326-425 | CK steps a, b, d1 |
| K | creature refine (1 animated creature + wiring + sounds) | 1.70-2.16 | 849-1,080 | CK step c, Frost Colossus |
| H | heavy refine (reworks generation/arenas/whole loop) | 2.08-3.79 | 1,042-2,367 | CK stages 8, 7, d2 |
| refusal | guard refusal | 0.003 | 0 | DS |
| budget fail | one call/build over the cap | 2.5-4.1 real USD, 0 charged | 0 | CK 9a, 9b, mb6e5e2e |
About 500-625 tokens charged per USD. Only one-creature K refines are measured; the CU/DJ data says rig count barely drives output (~150 tokens per template rig), so 2-3 template rigs per K is an assumption, not a measurement.

**Ranked slate:** 1 Infinite Dungeon: Eleven Thrones (finish) / 2 Arcane Academy / 3 The Static / 4 Party Games / 5 Critter Crew / 6 Blood Moon Outbreak / 7 Mob Fusion Lab / 8 Skyfall / 9 Colossus Siege / 10 Dino Frontier / 11 The Vault Job / 12 Iron Titans.
**First 3 to build:** Eleven Thrones (60% built, proves creature bosses on camera), Arcane Academy (fully covered lanes, the most textures and sounds per dollar, lowest risk), The Static (horror: 1-2 creatures, sound and glyph heavy, cheap, strongest hook).
**Slate total, clean runs:** about $95-144 and 48k-78k tokens (≈10-16 days at the 5,000/day cap). Add a contingency of one fix refine per mod (+$8-45) and unbilled budget failures (the dungeon's were $9.29).

---

## 1. Selection criteria

| Criterion | Test | Weight |
|---|---|---|
| Video hook | Explainable in one thumbnail line ("11 floors, 11 bosses") | 20% |
| Spectacle in the first 30 s | A custom animated creature, a big sound or a visual event shows up before 0:30 | 15% |
| Replay value | Systemic play (procedural floors, rounds, random events), not a one-time showcase | 10% |
| Cyrus coverage | Share of signature systems on `covered` archetypes/goldens rather than `partial`/`gap`; no `impossible` features | 20% |
| Training value | Teaches Cyrus something the corpus lacks (real-world-v1 is 80 single-shot prompts; the only long refine chain is the dungeon) | 20% |
| Cost and complexity | Fits a few days of the 5,000-token cap; no explicit-form rigs on the critical path | 15% |

Hard rules for every concept: target **Paper 1.21.11** (the only bot-verified version; Mannequin, GameRule.PVP, Dialog API and PlayerInputEvent are all there). Every system maps to a lane. Anything in `stillCannot` is designed out or swapped for its stated closest substitute.

---

## 2. The 12 mods

Lane shorthand: P plugin, T texture, IS itemStates, Snd sound, Cr creature, M3 model3d (display-entity props), DI designItem, DM designMenu, DQ designQuest, DB designBoss, DH designHud, Mo motion, Cfg config, DP datapack, WG worldgen.
Stage code: C/S/K/H = cost units above. "Fresh" = new mod; every later stage is a REFINE on the last succeeded build (qa-dungeon.ts `{ baseBuildId, changeRequest }`).

### Shared risk notes (apply to all)
- **Guard-safe wording** (DS; the fix is not live yet): every change text must stand on its own. Name the thing in full ("the Frost Colossus, the animated ice golem boss on floor 3"), never "we just added" or "keep the four creatures we already have". In a FIRST description, avoid the "separate world / without touching / saves your inventory" cue (recorded FP `fp-dungeon-escape`; write "each run happens in its own temporary dungeon world" once, plainly). Never write "in every chunk" (`fp-chunk-injection` is still refused under the new wording too). Combat words (slam, projectile, phase, explosion, TNT, kill) are fine.
- **Perf wording**: always state caps ("up to 30 zombies at once", "radius 12"). Unbounded spawns or world scans trigger the perf classifier `mustConfirm`, NxPerf (50 own spawns/s) and the stress test, which **blocks Install** on a fail.
- **Creature wording**: say "an animated creature with its own 3D model". The planner may not plan the creature lane for "a boss with its own look" without the word creature (CI follow-up).
- **Split rule**: one theme/system per refine. The dungeon's 9a/9b budget fails came from cramming (11 floors of theming plus a creature). Splitting fixed it every time.

---

### Mod 1. Infinite Dungeon: The Eleven Thrones (dungeon / boss rush): FINISH the existing mod
**Pitch:** an 11-floor descending dungeon where every third floor is a themed throne room with a real animated boss, ending at the Lich King.
**Thumbnail:** the existing image 16 (castle wall of six boss panels around a green hero). It is the series template, so build what it promises: banshee, lich king, ice golem, treant, lava golem, skeleton king, cave spider.
**5-min arc:** 0:00 portal flash, Frost Colossus roar / 0:30 Cyrus refine screen, "added a boss in one sentence" / 1:00 floors 1-3 (castle, ice arena, Colossus) / 2:00 swamp + Bog Treant / 3:00 lava + Magma Golem / 4:00 floor 11: Skeleton King, phase 2 the Lich King rises / 4:40 boss-rush mode tease plus download.
**State today:** v1.14.1 (mb6c1ca6ee26430b06081c): 6 themes + throne, boss arenas on floors 3/6/9/11, Hollow Banshee as a code mob, Frost Colossus model without abilities. 5 creatures delivered, cap lifted.

| Signature systems (8) | Lane |
|---|---|
| 11 floors, 6 themes + throne (done) | P, Cfg |
| Boss every 3rd floor + final (done) | P / DB |
| Frost Colossus abilities: icicle volley, slam + slow, frost nova, phase 2 | DB or P (code) |
| Bog Treant, Magma Golem, Skeleton King, Lich King models | Cr (humanoid horns/cape; floating_ghost crown) |
| Banshee model (floating_ghost hood/claws) replaces the code-mob look | Cr |
| Giant Cave Spider | Cr: **quadruped + spikes approximation** (no spider template) |
| Boss title cards, boss bars, music stingers | DH, Snd |
| Boss trophies (6 textured items) + `/dungeon bossrush` | T, DI, P |

**BOM:** creatures 10 total (5 exist + 5 new) / textures ~18 (6 trophies, 6 boss drops, 6 existing) / blocks-as-items 0 / sound events ~70 (10 creatures x 6 roles + 8 stingers) / particles: 4 ambient themes (exist) + 3 boss telegraphs / datapack: 7 advancements (one per boss) / GUIs: 0-1 (boss-rush select) / commands: existing `/dungeon start|status|leave|admin setfloor` + `bossrush` / config: per-boss health, floor-interval, max-floors.

**Staged build (6 refines on v1.14.1):**
| # | Unit | Change text (plain game design) |
|---|---|---|
| 1 | S | "The Frost Colossus, the animated ice golem boss in the floor 3 ice arena, gets three attacks: an icicle volley of 5 ice shards at the nearest player, a ground slam that deals damage and slowness within 6 blocks, and a frost nova ring every 20 seconds. Below half health it enters a second phase: attacks come faster and it summons 3 ice skeletons. Make sure it spawns in the floor 3 ice arena." |
| 2 | K | "Add the Bog Treant, an animated creature with its own 3D model (humanoid, mossy bark, horns like branches, glowing yellow eyes), as the floor 6 swamp arena boss: root grab that pulls a player in, poison spores cloud, summons 4 slimes at half health. Own hurt/death/attack/ambient sounds (creaking wood, wet groans)." |
| 3 | K | "Add the Magma Golem, an animated creature with its own 3D model (humanoid, cracked black rock with orange lava seams), as the floor 9 lava arena boss: fire slam, lava burst rings, magma cube minions." |
| 4 | K | "Give the Hollow Banshee its own animated 3D model (floating ghost, pale robe, long white hair, claws) and add the Giant Cave Spider, an animated creature (quadruped with spikes, dark red, glowing red eyes) that shoots webs that slow and spawns 4 cave spiders, on crypt floors." |
| 5 | K | "Floor 11 final boss becomes a two-phase fight: the Skeleton King (animated humanoid, gold crown via cape+accent colours, bone armour) with a spear sweep and skeleton guards; when he falls, the Lich King (animated floating ghost with a crown, purple robe) rises with soul bolts, a darkness pulse and a summoned ring of wraiths." |
| 6 | H | "Add a boss title card (big text + subtitle) and a short music stinger when each boss appears, a unique textured trophy item dropped by each of the six bosses, an advancement per boss, and a /dungeon bossrush mode that runs only the boss floors back to back with a timer on the sidebar." |
**Cost:** $9.53-13.28, 4,764-7,112 tokens (1.0-1.4 cap days). **Risk: MEDIUM.** Mainly guard (stage 1, refused twice before), the creature attach regression (KNOWN-BUGS 1.13.0), and the spider look (approximation). **Prereqs:** P0-1..3. P0-4 if stage 1 goes the designer route.

---

### Mod 2. Arcane Academy (magic / class system)
**Pitch:** pick one of four schools of magic, level up a spell tree, and pass a trial against an animated Arcane Golem.
**Thumbnail:** split 4-way: fire / ice / lightning / necromancy wizards casting into the centre, a giant rune circle, text "PICK YOUR MAGIC".
**5-min arc:** 0:00 lightning chain hitting 5 zombies / 0:30 class picker menu + Cyrus plan screen / 1:00 Pyromancer, 1:45 Cryomancer, 2:30 Stormcaller, 3:15 Necromancer raising minions / 4:00 Arcane Golem trial / 4:40 PvP spell duel tease.

| Systems (8) | Lane |
|---|---|
| Class picker + respec menu | DM |
| Mana bar + cooldown glyphs | DH |
| 4 schools x 3 spells (wands/tomes: hitscan, beam, area_blast, dash) | DI, T, IS (charging look), Snd |
| Necromancer minions (bounded, max 3) | P code mobs |
| Skill tree menu with points per level | DM, Cfg |
| Class quests (chains, 7 objective kinds) | DQ |
| Arcane Golem trial boss | DB + Cr (humanoid) |
| Robes armour sets per school | T (armour, 1.21.4+) |

**BOM:** creatures 1-2 (Arcane Golem, optional familiar) / textures ~28 (12 spell items, 4 wands, 4 armour sets = 16 pieces worth of equipment textures, spell tome) / blocks-as-items 1 (rune pedestal, M3 display) / sound events ~60 (12 spells x cast/impact + UI + golem 6) / particles: 12 spell trails (vanilla particles, within the 512 designer budget) / datapack: 8 advancements, 4 recipes / GUIs 3 (class, tree, respec) / commands `/academy class|tree|respec|stats` / config: every damage, cooldown and mana cost (designer = config.yml).

| # | Unit | Prompt |
|---|---|---|
| 1 | C | "A magic class mod called Arcane Academy. When a player first joins, a menu lets them pick a school: Pyromancer, Cryomancer, Stormcaller or Necromancer. Players have a mana bar shown on the action bar that refills over time. Start with the Pyromancer: a fire wand with its own drawn texture and three spells: fireball (right click), flame ring around you (sneak + right click), and a short fire dash. Each spell costs mana, has a cooldown and its own cast sound." |
| 2 | S | "Add the Cryomancer school to Arcane Academy: frost staff (own texture) with ice shard volley, a freezing beam that slows, and an ice wall made of temporary blocks that melts after 5 s." |
| 3 | S | "Add the Stormcaller school: storm rod with chain lightning (hits up to 4 targets), a wind gust that knocks back, and a thunder dash." |
| 4 | S | "Add the Necromancer school: bone tome that raises up to 3 skeleton minions for 30 s, a life-drain beam, and a bone shield." |
| 5 | S | "Add levels and a skill tree menu: XP from spell kills, 1 point per level, each spell has 3 upgrade ranks (damage, cooldown, mana)." |
| 6 | K | "Add the Arcane Golem trial boss, an animated creature with its own 3D model (humanoid, blue stone with glowing runes), summoned at a rune pedestal: three phases, rune beam, arcane slam, mana-drain aura; drops a school robe set." |
| 7 | S | "Add class quests (5 per school) and robe armour sets per school with their own worn textures, plus an Academy advancement tab." |
| 8 | H | "Add a duel mode /academy duel <player> with a 3-second countdown and balance pass: all spell numbers in config.yml, a PvP damage multiplier, mana regen setting." |
**Cost:** $7.39-11.44, 3,699-6,194 tokens. **Risk: LOW** (designItem weapons were measured exactly by the playtest bot; armour is wired since 2026-10-12). Watch: 1.21.4+ only for worn armour looks; a click ability needs cooldownTicks >= 4.

---

### Mod 3. The Static (horror)
**Pitch:** on Static Nights the radio hisses, something tall watches you from the treeline, and it only moves when you are not looking.
**Thumbnail:** dark forest, a player holding a flashlight, a very tall hooded figure half hidden by a tree, white eyes; text "DON'T LOOK AWAY".
**5-min arc:** 0:00 jumpscare (full-screen glyph + scream) / 0:30 "built by an AI in 7 prompts" / 1:00 radio static, footsteps behind you / 2:00 pages hunt / 3:00 the Watcher closes in when you turn / 4:00 escape ritual ending / 4:40 friends-co-op tease.

| Systems (8) | Lane |
|---|---|
| Static Night event scheduler (time, fog via darkness effect) | P (mc-events), Cfg |
| 8 lore pages to find (written books) | P (mc-books) |
| Sanity meter glyph HUD | DH |
| The Watcher: moves only when not in view (eval prompt "wendigo ... like weeping angel" exists) | Cr (floating_ghost hood/claws, tall scale) + P |
| Fake footsteps / whispers / radio static positional sounds | Snd, P |
| Jumpscare: full-screen glyph title + scream | DH (glyph), Snd |
| Flashlight with battery (on/off looks) | DI, T, IS |
| Hiding wardrobes (display-entity furniture) | M3 / mc-furniture |

**BOM:** creatures 2 (Watcher, Crawler) / textures ~10 (flashlight on/off, radio, pages, battery, jumpscare glyph, sanity glyphs) / blocks-as-items 2 (wardrobe, ritual altar) / sound events ~45 (whispers x4 variants, footsteps, static, heartbeat by sanity, scream, Watcher 6 roles) / particles 3 (ash, breath, ritual) / datapack 3 advancements / GUIs 0 / commands `/static start|stop|status` / config: night frequency, Watcher speed, sanity drain.

| # | Unit | Prompt |
|---|---|---|
| 1 | C | "A horror mod called The Static. Every few nights (configurable) a Static Night starts: players get a darkness effect pulse, a radio static sound plays, and a sanity bar appears on the action bar that drains in the dark and refills near light. 8 torn lore pages (written books) are hidden at random spots within 150 blocks of spawn; finding all 8 ends the night. Commands: /static start, /static stop, /static status." |
| 2 | S | "Add sound scares to The Static: footsteps that play just behind the player, whispers, a heartbeat that speeds up as sanity drops, and a radio item that crackles louder when a page is near." |
| 3 | K | "Add the Watcher, an animated creature with its own 3D model (very tall floating ghost, black hood, long claws, white eyes) that appears during Static Nights at the edge of view and only moves toward the player while the player is not looking at it; if it reaches you it drains a lot of sanity and teleports away. At most one per player." |
| 4 | S | "Add a jumpscare: when sanity hits zero, a full-screen scary face image flashes for half a second with a scream, then the player is set back to 30 sanity." |
| 5 | S | "Add a flashlight item (own texture, an on look and an off look) with a battery that drains; while lit it slows sanity loss and freezes the Watcher. Add hiding wardrobes players can place and hide inside." |
| 6 | S | "Add the ending: after 8 pages, a ritual altar appears; standing on it for 20 s while the Watcher hunts ends the night with a title and an advancement." |
| 7 | H | "Co-op tuning: sanity is per player, the Watcher hunts the lowest-sanity player, difficulty presets easy/normal/nightmare in config.yml." |
**Cost:** $6.74-10.59, 3,373-5,769 tokens. **Risk: MEDIUM.** The full-screen glyph jumpscare has no preset (gap G14) and no client has seen a glyph HUD. "Only moves when not looked at" is a code behaviour on a model whose clips BetterModel plays itself: unverified how it looks when the base mob is frozen. "Darkness" cannot change fog or lighting (shaders are impossible): use the darkness/blindness effects.

---

### Mod 4. Party Games by Nxeon (server mini-games)
**Pitch:** a lobby that rotates 6 microgames every round, with trophies, sounds and holograms. Drop it on an Nxeon server and have a game night.
**Thumbnail:** six-tile collage (snow spleef, TNT falling, block-disguise player, rising lava, hill crown, parkour) around a gold trophy; text "6 GAMES 1 MOD".
**5-min arc:** 0:00 lava rising under 8 players / 0:30 one-click install on Nxeon + Cyrus build / 1:00-4:00 six 30-s game cuts / 4:00 trophy ceremony, leaderboard hologram / 4:40 "host your own" call to action.

| Systems (8) | Lane |
|---|---|
| Lobby, queue, rotation, countdown, sidebar | P (mc-arena), DH |
| Spleef, TNT Run (corpus prompts; spleef failed the old budget in BV) | P |
| Hide & Seek with block disguise (block display) | P (corpus prompt) |
| Floor is Lava (rising fill, capped per tick) | P, NxPerf |
| King of the Hill, Parkour sprint | P (mc-parkour) |
| Trophies + victory sounds + fireworks | T, Snd |
| Leaderboard holograms | P (mc-holo, mc-leaderboard) |
| Arena setup wand + reset | DI, P |

**BOM:** creatures 0 / textures ~10 (3 trophies, setup wand, 6 game icons for the menu) / blocks-as-items 0 / sound events ~30 (countdown, start horn, elimination, win jingle per game) / particles: win burst, lava bubbles / datapack 6 advancements / GUIs 2 (game vote, stats) / commands `/party join|leave|vote|stats|admin setup` / config: round length, min players, rotation order.

| # | Unit | Prompt |
|---|---|---|
| 1 | C | "A mini-game lobby called Party Games. Players /party join; when 2-16 are queued, a 10-second countdown starts and a random game begins; after each round the winner gets a point on the sidebar and the next game starts; after 5 rounds the top player wins a trophy. First game: Spleef on a snow floor, last one standing wins. Admins mark the arena with /party admin setup spleef pos1/pos2. The arena is restored after every round." |
| 2 | S | "Add TNT Run to Party Games: blocks under players vanish shortly after they step, 2-minute rounds, last one standing wins." |
| 3 | S | "Add Hide and Seek: one seeker is blinded for 20 s, hiders are disguised as a random block, the seeker has 3 minutes." |
| 4 | S | "Add Floor is Lava: lava rises one layer every 8 seconds in the arena, highest survivor wins." |
| 5 | S | "Add King of the Hill: stand on the gold plate to earn points, most points after 2 minutes wins." |
| 6 | S | "Add a parkour sprint with checkpoints and a timer; best times saved." |
| 7 | S | "Add trophies (gold, silver, bronze items with their own textures), victory jingles, fireworks and a leaderboard hologram at the lobby." |
| 8 | H | "Hardening: per-game stats, a vote menu for the next game, arena reset for every game, everything in config.yml." |
**Cost:** $6.34-10.13, 3,176-5,539 tokens. **Risk: MEDIUM** on arena reset (the archetype's weak spot: "restore only blocks the mod changed") and the old spleef budget fail. Low asset count, so the spectacle comes from gameplay and the Nxeon angle.

---

### Mod 5. Critter Crew (pets / companions)
**Pitch:** hatch eggs into animated companions that level up, learn a job (fetch, heal, fight, mine) and evolve at level 10.
**Thumbnail:** a cute fox-kit, a mossy turtle and a glowing wisp in front of a player, an "EVOLVE!" burst; text "MY PETS EVOLVE".
**5-min arc:** 0:00 egg cracks, Ember Kit pops out / 0:30 Cyrus creature preview / 1:00 6 critters / 2:30 jobs / 3:30 level 10 evolution transform / 4:30 crew of 3 fighting together.

| Systems (7) | Lane |
|---|---|
| Eggs + hatch timer | DI, T |
| Follow + teleport catch-up, despawn on logout | P (mc-pets) |
| Levels, name + level hologram | P, DH |
| Companion menu (rename, job, stats) | DM |
| Jobs: fetch dropped items (corpus fox prompt), heal, fight, mine | P / MobGoals |
| Treats + affection + pet beds | T, DI, M3 |
| Evolution (swap to a second rig) | Cr |

**BOM:** creatures 12 (6 base + 6 evolved; humanoid/quadruped/floating_ghost only) / textures ~16 (6 eggs, 4 treats, collar, bed icon...) / blocks-as-items 1 (pet bed) / sound events ~80 (12 creatures x 6 roles, level-up, evolve) / particles: hearts, evolve burst / datapack 6 advancements / GUIs 2 / commands `/crew list|summon|dismiss|rename` / config: XP rates, evolve level.

| # | Unit | Prompt |
|---|---|---|
| 1 | C | "A companion mod called Critter Crew. Players craft or find critter eggs; an egg hatches after 60 s into a companion that follows its owner, teleports back if far, and is put away when the owner logs out. Companions gain XP when the owner kills mobs, show their name and level above their head, and have a menu (right click) to rename them and see stats. Up to 3 out at once." |
| 2 | K | "Add three companions with their own animated 3D models: Ember Kit (quadruped, orange fox with a flame mane), Moss Turtle (quadruped, green shell with spikes), Wisp (floating ghost, glowing teal). Each has its own cute sounds." |
| 3 | K | "Add three more animated companions: Rock Pup (quadruped, grey stone with horns), Sproutling (small humanoid, leaf hood), Frostbat (floating ghost, ice blue with claws)." |
| 4 | S | "Give each companion a job chosen in its menu: fetch dropped items, heal the owner slowly, fight nearby hostile mobs, or break nearby ore for the owner." |
| 5 | S | "Add treats (own textures) that give XP and affection, and a pet bed furniture item where companions rest to heal." |
| 6 | S | "At level 10 a companion evolves with a burst of particles and a sound: it gets stronger job stats." |
| 7 | K | "Add the six evolved forms as animated 3D models (bigger, same palettes with gold accents) and swap the model on evolution." |
**Cost:** $7.41-10.27, 3,703-5,137 tokens. **Risk: MEDIUM.** 12 rigs is within the measured flat server cost (to 24). Model swap on a live mob is code-side and unverified. Bats/birds have no flyer template: use floating_ghost.

---

### Mod 6. Mob Fusion Lab (mob mash-up)
**Pitch:** collect DNA from mobs, splice two in the Fusion Altar, and release one of 12 hybrid monsters.
**Thumbnail:** a lab altar with green lightning between a creeper and a spider, the "Creepider" hybrid emerging; text "I FUSED MOBS".
**5-min arc:** 0:00 Creepider explodes into baby spiders / 0:30 Cyrus "12 hybrids in 3 prompts" / 1:00 DNA hunting / 2:00 fusions montage / 3:30 hybrid battle arena / 4:30 bestiary book.
**Honesty:** fusion is a fixed recipe table (12 pre-designed hybrids), not runtime-generated models.

| Systems (7) | Lane |
|---|---|
| DNA vial drops (per mob type) | P (mc-drops), T |
| Fusion Altar (display-entity prop) + fusion menu | M3, DM |
| 12 hybrids as config-driven code mobs first (visible fallback) | P (mc-code-mob-roster golden) |
| Hybrid models (3 refines of 4) | Cr |
| Hybrid abilities (on-hit, lifesteal, slam, summon) | P registry |
| Tame / release / fight-for-you toggle | P |
| Bestiary book + advancements | P (books), DP |

**BOM:** creatures 12 / textures ~20 (12 DNA vials, altar, syringe, bestiary) / blocks-as-items 1 / sound events ~80 / particles: splice lightning, DNA swirl / datapack 12 advancements / GUIs 1 / commands `/fusion bestiary|release|admin give` / config: the hybrid table (base type, health, damage, abilities).

| # | Unit | Prompt |
|---|---|---|
| 1 | C | "A mob mash-up mod called Mob Fusion Lab. Killing mobs sometimes drops a DNA vial for that mob (zombie, skeleton, creeper, spider, enderman, blaze, slime, wolf). Players build a Fusion Altar; putting two different vials in its menu creates one of 12 hybrid mobs from a recipe table in config.yml, e.g. creeper+spider = Creepider. The hybrid is loyal to its creator for 5 minutes." |
| 2 | S | "Give every hybrid its behaviour from the table: Creepider explodes into 3 baby spiders, Blaze Wolf sets targets on fire, Ender Slime teleports when hit, ... (all 12 listed)." |
| 3-5 | K x3 | "Give Creepider, Blaze Wolf, Ender Slime and Bone Zombie their own animated 3D models (...)" / next 4 / last 4 (one palette and template per hybrid named in the prompt). |
| 6 | S | "Hybrid abilities get cooldowns and sounds; a hybrid fights for you when you whistle (sneak + right click with the altar key)." |
| 7 | S | "Add a bestiary book that fills in as you create hybrids and an advancement per hybrid." |
**Cost:** $7.41-10.27, 3,703-5,137 tokens. **Risk: MEDIUM** (the code-mob roster golden flew on all 4 versions; the risk is the look of 12 template rigs, and some mash-ups need two body plans that the 3 templates cannot mix).

---

### Mod 7. Dino Frontier (survival overhaul)
**Pitch:** dig up fossils, clone dinosaurs, tame and ride them, and travel through a Time Rift to a prehistoric jungle dimension.
**Thumbnail:** a player on a triceratops facing a T-rex silhouette in a jungle with a glowing portal; text "DINOSAURS IN MINECRAFT".
**5-min arc:** 0:00 Alpha Rex roar / 0:30 Cyrus build / 1:00 fossil dig / 2:00 incubator hatch / 2:45 ride a triceratops / 3:30 Time Rift jungle / 4:20 Alpha Rex fight.

| Systems (8) | Lane |
|---|---|
| Fossil drops + excavation brush | DP loot / P, T |
| DNA incubator (display prop) | M3, DM |
| Herbivores (quadruped horns/spikes) | Cr |
| Predators (biped: **explicit-form risk**) | Cr |
| Taming, saddles, riding + steering | P (mc-mounts, PlayerInputEvent) |
| Bone tools + armour set | T (armour), DP recipes |
| Prehistoric jungle biome in its own dimension | WG (restart, new chunks) |
| Alpha Rex boss | DB + Cr |

**BOM:** creatures 6-7 / textures ~22 / blocks-as-items 1 / sound events ~55 / particles: dust, roar shockwave / datapack: recipes 8, loot 2, advancements 8, worldgen biome + dimension / GUIs 1 / commands `/dino` / config: spawn weights, tame chance.

| # | Unit | Prompt |
|---|---|---|
| 1 | C | "A survival overhaul called Dino Frontier. Mining stone deep underground sometimes drops fossils (5 kinds, own textures). Players craft an excavation brush and a DNA incubator; putting a fossil and a bone block in the incubator hatches a baby dinosaur egg after 2 minutes." |
| 2 | K | "Add three herbivore dinosaurs with their own animated 3D models: Triceratops (quadruped, horns), Stegosaurus (quadruped, back spikes), Ankylosaurus (quadruped, spikes, low and wide). Hatched ones are tame." |
| 3 | K | "Add Raptor and T-Rex as animated creatures with their own models; they hunt players and animals in the jungle." (expect explicit form: run alone, one per refine if it hits the budget) |
| 4 | S | "Tamed dinosaurs can be saddled and ridden; the rider steers with movement keys; the triceratops charges." |
| 5 | S | "Add bone tools and a bone armour set with their own textures and recipes." |
| 6 | K | "Add Brachiosaurus (very large quadruped, long neck via mane) as a peaceful giant." |
| 7 | S | "Add a Time Rift portal to a prehistoric jungle dimension with its own biome; dinosaurs spawn there." |
| 8 | H | "Add the Alpha Rex boss with phases (roar stun, tail sweep, charge) in the jungle, balance spawns." |
**Cost:** $9.49-14.06, 4,745-7,504 tokens, plus a likely extra K for the explicit predators. **Risk: HIGH.** Biped dinosaurs have no template (G7). A ridden BetterModel mob is unverified (G8). Worldgen needs a restart and a broken pack stops the server (rollback kept).

---

### Mod 8. Skyfall (weather / disasters)
**Pitch:** a disaster forecast ticks down on the boss bar: meteor showers, tornadoes, acid rain, quakes, blizzards. Survive the week.
**Thumbnail:** a village under a meteor shower with a tornado on the horizon, a red "WARNING" boss bar; text "SURVIVE THE SKY".
**5-min arc:** 0:00 meteor impact / 0:30 Cyrus / 1:00-3:30 five disasters / 3:30 the Storm Elemental / 4:30 Apocalypse Week.
**Honesty:** no sky, fog or lighting changes (shaders impossible). Spectacle = falling block displays, particles, sounds, knockback and effects. Block damage is bounded and optional (off by default, "never griefing" style).

| Systems (8) | Lane |
|---|---|
| Disaster scheduler + forecast boss bar + siren | P (mc-events), DH, Snd |
| Meteor shower (block displays falling, area_blast, optional bounded craters) | Mo/P, DI comps |
| Tornado (particle column, pulls entities, capped radius) | P |
| Acid rain (damage unless under a roof) + hazmat suit | P, T armour |
| Earthquake (nausea, rumble, small falling block bursts) | P |
| Blizzard / heat wave + temperature glyph | P, DH |
| Shelter beacon + survival kit | DI, T |
| Storm Elemental creature | Cr (floating_ghost) |

**BOM:** creatures 1 / textures ~12 / blocks-as-items 1 (beacon prop) / sound events ~40 (sirens, rumbles, wind loops) / particles ~8 effects / datapack 6 advancements / GUIs 0-1 / commands `/skyfall trigger|forecast|stop` / config: per-disaster chance, radius, block damage on/off.

| # | Unit | Prompt |
|---|---|---|
| 1 | C | "A disaster mod called Skyfall. Every 20-40 minutes (configurable) a disaster is forecast: a boss bar counts down 2 minutes with a siren. First disaster: a meteor shower near players: fiery meteors fall for 60 s, each impact deals area damage and knockback within 4 blocks; crater block damage is off by default and capped at 20 blocks per impact when on." |
| 2-6 | S x5 | tornado / acid rain + hazmat / earthquake / blizzard + heat wave + temperature bar / shelter beacon + survival score |
| 7 | K | "Add the Storm Elemental, an animated creature with its own model (floating ghost of grey cloud with lightning claws), that spawns inside tornadoes." |
| 8 | H | "Add Apocalypse Week: disasters escalate each day for 7 days, final day stacks two; everything in config.yml." |
**Cost:** $7.39-11.44, 3,699-6,194 tokens. **Risk: MEDIUM** (perf: every disaster needs caps; the stress test blocks Install on a fail). A good teacher for bounded world effects.

---

### Mod 9. Colossus Siege (server PvE raid event, Nxeon hosting angle)
**Pitch:** a 10-block stone Colossus marches on spawn. The whole server mans ballistas and fights it in phases.
**Thumbnail:** a towering stone giant over a wooden camp, players on ballistas, a server boss bar "COLOSSUS 87%"; text "WHOLE SERVER vs GIANT".
**5-min arc:** 0:00 war horn, ground shake / 0:30 Cyrus "scale 4 creature" / 1:00 minion waves / 2:00 ballistas / 3:00 phase 2 stomp shockwaves / 4:00 the fall + damage-share loot / 4:40 "run this event on your Nxeon server".

| Systems (7) | Lane |
|---|---|
| Event scheduler, war horn, server boss bar | P, DB, Snd |
| Minion waves (encounter) | DB |
| Colossus model at scale ~4 (iron golem base 2.7 blocks x 4 ≈ 11) | Cr + DB model (scale hard bound 0.25-4) |
| Telegraphed stomp, arm sweep, rock throw; 3 phases | DB |
| Ballista props + harpoon crossbow (beam/hitscan) | M3, DI, T |
| Damage-share loot + titles + leaderboard | DB drops, P |
| Variant colossi (ice / lava) | Cr |

**BOM:** creatures 4 (Colossus, 2 minions, 1 variant) / textures ~10 / blocks-as-items 1 / sound events ~40 / particles: dust shockwave rings / datapack 3 advancements / GUIs 0 / commands `/siege start|stop|status` / config: health per player online, phases.

| # | Unit | Prompt |
|---|---|---|
| 1 | C | "A server raid event called Colossus Siege. An admin runs /siege start (or it starts every Saturday 8 pm server time): a war horn sounds for everyone, a server-wide boss bar appears, and 3 waves of 10 stone minions march on a camp location set in config. The boss's health scales with the number of players online." |
| 2 | S | "Add ballistas (placeable props players right click to fire heavy bolts) and a harpoon crossbow item with its own texture." |
| 3 | K | "Add the Colossus, an animated creature with its own 3D model (humanoid, mossy grey stone, glowing cracks), at 4x size, as the final wave boss." |
| 4 | H | "Give the Colossus three phases with telegraphed attacks: ground stomp shockwave (warned 2 s by particles), arm sweep, boulder throw; enrage at 20%." |
| 5-6 | S x2 | damage-share loot, titles, leaderboard / schedule, arena leash, config |
| 7 | K | "Add an Ice Colossus variant that rotates in on alternate weeks." |
**Cost:** $7.79-11.90, 3,896-6,424 tokens. **Risk: HIGH.** Scale 4 is past the boss-model soft range (0.5-2). Per-viewer display-entity cost with 20+ players is unmeasured (G20). Weak points (multiple hitboxes) are not in the designer: keep one hitbox.

---

### Mod 10. The Vault Job (heist / PvE)
**Pitch:** your crew breaks into a generated bank: keycards, laser grids, a drill, security bots, then escape before the timer ends.
**Thumbnail:** 4 masked players in front of a giant round vault door with red lasers and a security robot; text "WE ROBBED A BANK".
**5-min arc:** 0:00 vault door swinging open (motion) / 0:30 Cyrus / 1:00 crew roles / 1:45 lasers + keycards / 2:30 drill jams / 3:15 alarm, bots / 4:15 escape van / 4:40 payout.

| Systems (8) | Lane |
|---|---|
| Lobby, crew roles menu, timer, alarm states, payout currency | P, DM, DH |
| Bank built per run in its own temporary world (dungeon pattern) | P (mc-instanced-dungeon-lite) |
| Keycards (tiers) | DI, T |
| Laser grids (particle lines + damage) and cameras (line of sight) | P |
| Drill minigame (boss bar progress, jams) | P, DH |
| Vault door animation | Mo (display entity) |
| Security bots + guard captain | Cr (humanoid) + code mobs |
| Loot bags + upgrades shop | DI, DM |

**BOM:** creatures 2 / textures ~16 / blocks-as-items 3 (drill, vault door, camera) / sound events ~45 / particles: lasers, sparks / datapack 5 advancements / GUIs 3 / commands `/heist join|start|leave|shop` / config: timer, guard counts, payouts.
| # | Unit | Prompt (stage 1) |
|---|---|---|
| 1 | C | "A co-op heist mod called The Vault Job. Up to 4 players /heist join a crew and pick a role in a menu (Hacker, Driller, Muscle, Lookout). /heist start builds a bank in its own temporary heist world and teleports the crew there with a 10-minute timer on the sidebar. Stealing loot bags from deposit boxes earns Vault Cash, kept per player. Getting spotted raises the alarm." |
| 2 | H | bank layout: lobby, offices, security room, vault, built a few blocks per tick |
| 3-4 | S | keycards + lasers + cameras / drill minigame + vault door animation |
| 5 | K | security bots (animated humanoid, white plating, red visor) + guard captain |
| 6-7 | S | stealth vs loud mode / escape van zone + police waves |
| 8 | H | balance, 2 more bank layouts, Vault Cash upgrade shop |
**Cost:** $8.82-14.38, 4,415-8,136 tokens. **Risk: HIGH** (procedural building = the dungeon's most expensive stage class; a motion vault door "is not saved with the world" but is fine in a temporary run world).

---

### Mod 11. Blood Moon Outbreak (horde survival, "100 days" format)
**Pitch:** every 7th night the moon turns red and a scaling zombie horde, mutants and the Abomination hit your base.
**Thumbnail:** a fortified wooden base at night under a red moon, a hulking mutant zombie smashing a barricade; text "DAY 49 HORDE".
**5-min arc:** 0:00 horde sprinting at barricades / 0:30 Cyrus / 1:00 day-counter loop + barricades / 2:00 guns / 2:45 mutants / 3:45 Abomination / 4:30 "can we survive 100 days?".

| Systems (7) | Lane |
|---|---|
| Day counter, blood-moon schedule (corpus "zombie horde every 7 days"), red title | P, DH |
| Horde scaling with caps | P, NxPerf |
| Barricades + repair hammer | M3, DI |
| Shotgun (hitscan pellets), molotov (area_blast), crossbow mods | DI, T, IS |
| Mutants: Brute (corpus prompt), Screamer, Crawler | Cr |
| The Abomination boss | DB + Cr |
| Survivor trader (Mannequin on 1.21.11) menu | P, DM |

**BOM:** creatures 4 / textures ~14 / blocks-as-items 2 / sound events ~45 / particles: blood moon ash, molotov fire / datapack 5 advancements / GUIs 1 / commands `/outbreak day|status` / config: horde cap, scaling.
Stage plan: 1 C core loop ("... every 7th night a Blood Moon: red title, up to 20 + 5 per week zombies, capped at 60 at once ...") / 2 S weapons / 3 K three mutants / 4 K Abomination / 5 S barricades / 6 S trader + scoring / 7 H perf and difficulty.
**Cost:** $7.79-11.90, 3,896-6,424 tokens. **Risk: MEDIUM-HIGH**: the perf classifier flags mass spawns (the default is the safe capped version), and the stress test can block Install.

---

### Mod 12. Iron Titans (mechs / vehicles)
**Pitch:** summon a 5-block mech, climb in, steer it with WASD, fire an arm cannon and missiles, and duel other pilots.
**Thumbnail:** two giant mechs punching in a ruined city, sparks; text "I BUILT A MECH".
**5-min arc:** 0:00 mech drops from the sky / 0:30 Cyrus / 1:00 piloting / 2:00 weapons / 3:00 garage paint jobs / 3:45 boss mech / 4:30 PvP duel.
**Honesty:** real vehicles need a client mod; motion says vehicles are not a Minecraft target. This is a ridden animated creature (iron golem base), steered with PlayerInputEvent (1.21.4+). The model following the rider's facing is **unverified**.

| Systems (7) | Lane |
|---|---|
| Mech beacon summon + mount/dismount | DI, P (mc-mounts) |
| Mech model (humanoid, scale 2) | Cr |
| WASD steering, jump thrusters, fuel glyph | P (PlayerInputEvent), DH |
| Arm cannon (beam), missiles (area_blast), stomp | DI comps while riding |
| Garage menu: paint jobs, upgrades | DM |
| Enemy drones (code mobs) + boss mech | P, Cr, DB |
| Mech duels mode | P (mc-duels) |
Stage plan: 1 C mount + steer on a plain iron golem / 2 K mech rig / 3 H weapons while riding / 4-5 S garage, drones / 6 K boss mech / 7 H duels.
**Cost:** $9.22-14.84, 4,612-8,366 tokens. **Risk: HIGHEST.** Needs G8 first; build it last.

---

## 3. Ranked order and rationale

| Rank | Mod | Risk | Why here (dependency / learning) |
|---|---|---|---|
| 1 | Eleven Thrones (finish) | Med | Already 14 stages deep. Proves P0 fixes (pack hand-off, guard, attach check) and is the first client-verified creature video. Every creature mod after it depends on this proof. |
| 2 | Arcane Academy | Low | All covered lanes (designItem/Menu/Quest/HUD, armour). The most textures/sounds per dollar. Teaches a long designer chain (the corpus has none). |
| 3 | The Static | Med | Cheap. Sound + glyph heavy (the sound lane is under-used in the corpus). One creature with a novel behaviour. Best hook. |
| 4 | Party Games | Med | No creatures, so it films even if creature issues remain. Nxeon hosting video. Teaches multi-game rotation + arena reset (a known gap). |
| 5 | Critter Crew | Med | First 12-rig mod. Needs 1 and 3 proven. Teaches model swap + companion AI. |
| 6 | Blood Moon Outbreak | Med-High | Reuses Academy weapon patterns and dungeon code-mob roster; teaches perf-bounded mass spawns. |
| 7 | Mob Fusion Lab | Med | Reuses the code-mob roster and the creature batches from 5. |
| 8 | Skyfall | Med | Bounded world effects. Benefits from G13 (VFX presets). |
| 9 | Colossus Siege | High | Needs MB_BOSS_MODEL, scale 4, and display-entity cost measured with many viewers (G20). |
| 10 | Dino Frontier | High | Needs new templates (G7), ridden creatures (G8), worldgen. |
| 11 | The Vault Job | High | Needs the room-builder generalised (G10) and furniture/doors. |
| 12 | Iron Titans | Highest | Needs G8 and G7 (mech), plus 3 heavy refines. |

**First 3: Eleven Thrones, Arcane Academy, The Static.** Combined about $23.7-35.3 and 11.8k-19.1k tokens (≈3-4 days at the current cap). Lanes covered: creature x5, designBoss, designItem, designMenu, designQuest, designHud, texture, itemStates, sound, datapack (no motion, worldgen or riding). Two of three are low/medium risk, and if the creature fixes slip, Academy still ships.

---

## 4. Capability gaps to fix BEFORE building

| # | Gap | Hits mods | Where | Pri |
|---|---|---|---|---|
| G1 | BetterModel pack refused (2.2.0 overlays) and never handed off on the standard Mods-engine install path, so creatures are magenta/black on a real client | all with Cr | `normalizeBetterModelPack` overlay allowlist + `lib/cyrus/creature/after-start.ts` (branch `feature/cyrus-followups`); KNOWN-BUGS 2026-10-15 | P0 |
| G2 | Guard false positives on change text | 1, all refine chains | `services/modbuilder/route.js guardInput`, GUARD_PROMPT guard-2026-10-15.1 (branch `fix/cyrus-guard-false-positives`), image bump; `fp-chunk-injection` still open | P0 |
| G3 | Change build can drop the creature attach silently; the checker also false-warns on concatenated model keys | all with Cr | `services/modbuilder/creatures.js checkWorkspaceCreatures`, `lanegaps` (designer route checks boss-worn rigs only) | P0 |
| G4 | Designer boss cannot wear a rig unless `MB_BOSS_MODEL=1` | 1, 2, 7, 9, 11, 12 | `textures.parseAssetsRequest`, `designs.js rigsOf` | P0 |
| G5 | Daily cap 5,000 tokens on the owner/QA account (~9-10 builds/day) | slate | account cap setting (BV F0) | P0 (owner) |
| G6 | No typed ability library for non-boss creature mobs (abilities live in DB only or in free code; the dungeon's abilities refine was the guard-refused one) | 1, 3, 5, 6, 11 | `lib/cyrus/designer` boss components; code-mob registry prompt (CU section 4) | P1 |
| G7 | Templates only for humanoid / floating_ghost / quadruped; `flyer` has no template; no arachnid, serpent, biped-dino, mech, bird | 1 (spider), 5, 7, 12 | `lib/cyrus/creature/templates.ts` TEMPLATE_ARCHETYPES/FEATURES; explicit form = 48 KB/12k tokens per rig | P1 |
| G8 | Ridden animated creature (steering + model facing the rider's yaw) unverified | 7, 12 | golden mc-mounts + creature lane; new golden `mc-ridden-creature`; Motion says vehicles are not a target | P1 for 7/12 |
| G9 | Custom blocks: note-block lane OFF (`CYRUS_NOTEBLOCK_LANE`) + server-wide `disable-noteblock-updates` owner decision | 6, 10, 11 | `assets/blocks.json` generator; fallback furniture (mc-furniture) | P2 |
| G10 | Procedural rooms/buildings: no schematic, no jigsaw; room-template builder lives only inside dungeon code | 4, 10 | golden `mc-instanced-dungeon-lite`, `mc-structures`; promote to a reusable component | P1 for 10 |
| G11 | Arena reset only restores recorded changes | 4 | golden `mc-arena`; void-world-per-round from the dungeon golden | P1 for 4 |
| G12 | Music: a sound set is ≤ 60 s synthesized; no loopable long boss themes; library flag `CYRUS_SOUND_LIBRARY_CLEARED` | all (video feel) | `lib/cyrus/sound/spec.ts` MAX_SPEC_SECONDS; `mc-ambience`; jukebox_song datapack | P2 |
| G13 | VFX: vanilla particles only (custom particle textures need vanilla retexture, discouraged); motion presets (explosion, fire, smoke, muzzle) not offered as designer actions | 2, 8, 9 | `lib/cyrus/motion` presets -> designer actions; roadmap item 6 "effects/animation asset program"; caps 512 designer / 64 per datapack command | P2 |
| G14 | Full-screen glyph overlay (jumpscare, title cards) has no HUD preset; no client has ever seen a glyph HUD | 1, 3 | designHud glyph presets (15) | P1 for 3 |
| G15 | No real client has ever loaded a Cyrus pack (`resourcePackClientVerified=false` everywhere) | all | version registry; owner test-day. **Each filming session doubles as the client test day: capture it (section 6).** | P0 (process) |
| G16 | Test Flight verdict ignores `commands_registered` fails (BV F2); `mob_summon`/`item_give`/`gui_open` RCON checks not automated | all | `lib/cyrus/eval/realpass.ts`, real-world-v1 `meta.mustHaveVerifiable` | P1 |
| G17 | Designer no-model edit refused for mods with creatures (`designEdit` limit), so balance tweaks cost a full refine | 1, 2, 9 | CI follow-ups | P2 |
| G18 | Planned-vs-shipped mismatch (datapack planned, 0 shipped, BV F6; design downgrade to plain, BZ) | 2, 7 | planner + `lanegaps` | P1 |
| G19 | Big refines hit the $4 build / $2.5 call budget; splitting is manual | 1, 7, 10, 12 | planner: an auto-split like `roster.ts splitRoster` for change requests | P1 |
| G20 | Per-viewer display-entity cost and client FPS never measured; server cost measured flat only to 24 models | 5, 6, 9, 11 | `scripts/cyrus/creature-cost.ts` + a client run | P1 for 9 |
| G21 | Large scale models: boss model scale soft 0.5-2, hard 0.25-4; one hitbox | 9 | designer boss spec `model.scale` | P2 |

---

## 5. Series style guide ("Cyrus Originals")

| Topic | Rule |
|---|---|
| Series name | "Cyrus Originals" #01-#12; mod display name = the title above; plugin names PascalCase (`ElevenThrones`, `ArcaneAcademy`) |
| Namespace | Cyrus assigns `nx_<id>`; asset keys `<mod>.<thing>` lower_snake (e.g. `watcher.ambient`) |
| Version | Paper 1.21.11, semver per refine (dungeon pattern: 1.x.0 per stage) |
| Palette | Each mod: one dominant hue + one glow accent, max 6 colours per creature (template palette keys), 16 per rig. Series constant: glowing eyes on every creature (`eye` key, high value), dark outline colour `#1A1A22`. Saturated, high-contrast, readable at thumbnail size (image 16 style: each boss owns one colour) |
| Creature look | Prefer templates (reliable, ~150 tokens). Name features and palette in the prompt. Every hostile creature has all 6 sound roles |
| Sound design | Every mod ships: a start stinger (≤ 3 s), a win/clear jingle, a fail sting, UI click; hits ≤ 1 s; ambients ≤ 8 s with 2-4 variants; subtitles always on; boss stinger on spawn. Stay inside 8 events/set, 480 s/build |
| UI | Boss bar = threat; action bar = resource (mana, sanity, fuel); sidebar = score/timer. Never two sidebars (designHud rule) |
| Commands | `/<short> start|status|leave|stats|admin ...` + `/<short> about` |
| Credit | plugin.yml `description` ends "Made with Cyrus (cyrus.my)"; resource pack description "Made with Cyrus"; `/<mod> about` prints the credit + version; optional one-time join message (config `credit.join-message: true`); bestiary/lore books carry a last page credit; video lower third "Built with Cyrus in N prompts" + end card |
| Perf | Every spawner/effect has a cap in config; NxPerf left on |

---

## 6. YouTube packaging and training capture

### 6a. Per-mod packaging
| Mod | Title options | Thumb text | Chapters | Show in Cyrus | Build-in-public angle |
|---|---|---|---|---|---|
| 1 Eleven Thrones | "I Asked an AI to Build an 11-Boss Dungeon" / "Every 3 Floors, a New Boss" | 11 BOSSES | Hook, The AI build, Ice, Swamp, Lava, Throne, Boss rush | refine list v1.0 -> v1.20, creature preview, Test Flight pass | "15 prompts, 2 refused, here is why" (show guard FP + fix) |
| 2 Arcane Academy | "Minecraft, But You Pick a Magic School" / "AI Made 12 Spells" | PICK YOUR MAGIC | 4 schools, skill tree, golem trial, duel | plan screen lanes, texture studio, config.yml numbers | balance via config edits live |
| 3 The Static | "Don't Look Away (AI Horror Mod)" / "This AI Mod Made My Friend Scream" | DON'T LOOK AWAY | Night 1, pages, Watcher, ending | sound studio waveforms, glyph HUD | "I let the AI design the scare" |
| 4 Party Games | "6 Minigames, 1 Mod, 8 Friends" / "AI Built Our Game Night" | 6 GAMES 1 MOD | each game, trophies | the Nxeon install button, Test Flight | "Host it yourself on Nxeon" |
| 5 Critter Crew | "My Minecraft Pets Evolve" / "AI Made 12 Pets" | MY PETS EVOLVE | hatch, jobs, evolution | creature studio, 12 rigs | pick next critter by viewer vote |
| 6 Fusion Lab | "I Fused Minecraft Mobs" / "Creeper + Spider = ?" | I FUSED MOBS | DNA, fusions, battle | recipe table in config | viewers submit fusions (next refine) |
| 7 Dino Frontier | "Dinosaurs in Minecraft (No Client Mods)" | DINOSAURS | dig, hatch, ride, rift, Rex | worldgen plan, restart note | "the T-rex the AI could not draw" (honest failure) |
| 8 Skyfall | "Surviving AI Natural Disasters" | SURVIVE THE SKY | 5 disasters, elemental, week | perf caps on the plan screen | "why the AI refused to destroy my world" |
| 9 Colossus Siege | "Whole Server vs a 10-Block Giant" | SERVER vs GIANT | waves, ballistas, phases | boss design JSON, scale | live server event stream |
| 10 Vault Job | "We Robbed a Minecraft Bank" | WE ROBBED A BANK | roles, lasers, drill, escape | room builder stages | heist speedrun challenge |
| 11 Blood Moon | "100 Days of AI Zombie Hordes" | DAY 49 HORDE | loop, guns, mutants, boss | perf classifier choice | a series by itself |
| 12 Iron Titans | "I Built a Driveable Mech With AI" | I BUILT A MECH | pilot, weapons, garage, duel | limits card "real vehicles need a client mod" | "what Minecraft can't do, and how we faked it" |

### 6b. Training-data capture checklist (per build)
Use the formats that already exist. Do not invent new ones.
| Save | Format / location |
|---|---|
| Stage record (prompt, plan + lanes, coach, refused, status, errorCode, tokens held/charged, costUsd, attempts, repairs, aiCalls, assetsResult counts, warnings, jar, testFlight incl. stress) | qa-dungeon.ts record `stage-<n>[-fix]-<buildId>.json` + `journal.json` in `/root/cyrus-eval/<mod>-<date>/` (generalise `qa-dungeon.ts` + a `qa-<mod>-prompts.json` per mod) |
| Eval case per stage-1 prompt and per notable refine | real-world-v1 item shape: `key, v, cls, category, route, prompt, checks, stratum, style, mustHave{kind,value}, expectOutcome, assetKinds, expectLanes` (add as `rw-slate-*`; a refine chain needs a new `baseKey` field, owner decision) |
| Real-pass stages | `lib/cyrus/eval/realpass.ts` seven stages + taxonomy class for every non-pass (BZ) |
| Guard refusals | CyrusGuardRefusal row + mark false positives in Admin > Cyrus > Learning; add the text to `services/modbuilder/eval/guard-regression.json` |
| Failures + fixes | one fix refine max per stage (dungeon rule); real platform bugs go to `KNOWN-BUGS.md` (NOT `failure-rules.json`, which is only for javac patterns) |
| Playtest / client notes (G15) | per session: client version, pack prompt accepted y/n, each creature renders (y / magenta / invisible), clips seen (idle/walk/attack/hurt/death), sounds + subtitles heard, glyph HUD position, client FPS (F3), server TPS (`/<mod> perf status`), Bedrock y/n; screenshot + clip timestamp |
| Video link-back | stage -> video chapter timestamp map in the journal dir (`video.json`) |
| Learning loop | `CYRUS_LEARNING` on for these builds so token counts are kept (otherwise `toResult` drops them) |

Owner prompts are the owner's own data, so the privacy rule in 15-learning-loop (no request text without `--include-prompts`) is about customers. Keep these records in `/root/cyrus-eval`, not in a customer-facing store.
