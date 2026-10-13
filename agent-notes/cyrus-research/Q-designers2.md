# Q: Designers part 2 (boss + encounter designer, HUD and glyphs), 2026-10-10

Branch `feature/cyrus-r20-designers2` (worktree `/tank/dev-worktrees/cyrus-r20`), from `feature/cyrus-r2`, latest r2 merged in (clean). Commits: `91d39e2922` bosses, `0338e587fd` HUD, `615330eabd` follow-up (HUD live preview, scripted-player flight, docs), two r2 merges (last `28fdbfce08`). Nothing deployed, merged to main, migrated or switched on; `CYRUS_DESIGNER` stays off. Docs: "Cyrus boss and encounter designer", "Cyrus HUD and glyphs". Owner sections appended to OWNER-ACTIONS.md. Raw flights: `designers2-flights-2026-10-10.json` (keys `boss`, `hud`, `playtest`).

## 1. Boss and encounter designer (DONE)
- IR on the existing design files (`"kind":"boss"` / `"encounter"`; item, menu, quest designs and their goldens unchanged): closed list of 20 vanilla bases, 1-5 one-way phases by health (onEnter actions, self buffs), up to 8 telegraphed attacks built from the existing action vocabulary under the item library's Budget (+ new typed actions leap, summon, heal_self, self_effect, arena-wide texts), arena (leash, participants, empty-arena despawn, time out / enrage), boss bar, capped minions, player-count and difficulty scaling, drops by damage share (vanilla items, design items, the project's data pack loot tables), wave encounters with rewards.
- Verified components: Bosses hub (ONE 10-tick AI timer), BossEffects, DropTable, Encounters, BossCommand, per-version BossCompat. Never persistent, never griefs / burns / converts / hurts each other, leftovers swept; caps 4 bosses, 48 minions, 2 encounters x 24 mobs.
- Every number / text is a config.yml setting; edits change config.yml only (Param.ptr). TS simulator incl. a java.util.Random twin. Router words, prompt part, service + portal kind-aware, mod page line, bundle + `boss.v1.schema.json` regenerated.

## 2. HUD and glyphs (DONE)
- `"kind":"hud"` designs: glyphs (15 Cyrus presets tinted, or small pixel grids), bars from glyph segments, values (health, food, XP, air, ability charges / cooldown, a boss's health), conditions; delivered only in the action bar, per-player boss bars and a per-player sidebar (never replacing another plugin's scoreboard). No shaders / free positioning / widgets; minimap-style requests get a "needs a client mod" notice.
- The mod's own font `<ns>:hud` (bitmap cells + space font), codepoints from the project's home glyph block (engine-core identifiers); the pack builder ships it, the portal sync builds it. Live preview command for any online player.

## 3. RAN
- Unit: `cyrus-boss` 71, `cyrus-hud` 23, pipeline +1; the Cyrus + builder suite after merging the latest r2 (twice): 1984/1984; tsc clean; all artifacts current.
- javac 0 warnings, strict scan clean, reproducible jars on Paper 1.21.11 (JDK 21) and 26.2 (JDK 25), both items; boss flights repeated after the merge.
- Boss Test Flight, both lanes: 55 RCON + 2 log checks: spawn refusals, the RNG / scaling twin identical on the JVM, phases by /damage, a test-target slam on a villager (20 -> 15.5), minion cap, leash, no loot for /kill, ground drops, empty despawn, the full Ash Trial, clamping, migration, cleanup on stop; edit jar config-only.
- HUD Test Flight, both lanes: 22 RCON checks: codepoints from the Java strings == TS == the emitted font; 8 rendered channels identical to the TS twin; clamping, migration, the command chain; edit jar config-only.
- A scripted Mineflayer player (Paper 1.21.11 only): 5 of 5 scenarios: summon item spawns the boss, the bot is a participant and gets the spawn message and phase title, slam + leap hit it as a real target (slowness applied; the wither skeleton's own melee too), its killing blow puts the loot in its inventory; the HUD reads its live values (staff charges 5 -> 4 after a real right-click, the live boss's health %).
- The deliberately broken boss (10 codes) and broken HUD (9 errors) are rejected; no jar.

## 4. NOT RUN / not verified
- No real Minecraft client: nothing was SEEN (font loading, glyph alignment, boss bar / sidebar / action bar on screen, particles, sounds). The bot does not load packs and records chat and titles only.
- Knockback on a client (Mineflayer did not move), projectiles hitting a player, several players, XP, protection plugins, a player on 26.2 (no verified bot).
- javac only on 1.21.11 and 26.2 (others compile per API sheets, `javacVerified: false`).
- No paid model build: the prompt parts and validators are unit-tested only.

## 5. Found and fixed in passing
- Item classes imported `<pkg>.abilities.*` even when no design had an ability (javac failure for ability-less mods); now only when the package exists (no golden changed).

## 6. Owner decisions (details in OWNER-ACTIONS.md)
Loot only for >= 10% damage share (none for /kill); bosses never persistent (a restart ends the fight); difficulty multipliers 0.75 / 1 / 1.25; HUD glyph codepoints are derived from the home block, not reserved in `CyrusIdentifier` (safe: own font); the image rebuild must include `designer-boss-example.json` + `designer-hud-example.json`; a real-client test day; a small paid eval.
