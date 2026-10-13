# Cyrus Config and Stats Studio: design + plan (v5, 2026-10-10)

Owner request: every number a mod can tune (mob health and speed, weapon fire rate, ability cooldowns, shop prices, boss phases, quest rewards, arena timers...) gets a manual editor. Nobody has to prompt the AI to change a number. Cyrus knows which tunables to OFFER for each kind of mod. Stats with a visual (walk speed, attack speed, scale) play live in the viewport. Game-neutral schema; per-game exporters apply it. Branch `feature/cyrus-r23-config`, code in `lib/cyrus/config/`.

## 1. ConfigSpec v1 (the one param model)

```
ConfigSpec { schemaVersion: 1, file: "config.yml", category?, reload?: { command }, groups[], params[], presets[] }
Group      { id, label, help?, order? }
Param      { key (dotted config path), group, type, label (<=60), help? (one line, <=200), default,
             unit?, min?, max?, step?, safe?: { min?, max?, note? }, options? (enum), item? (list), columns? (table),
             maxLength? (text), assetKind? (asset-ref), applies: "live" | "reload" | "restart",
             visual?: { channel, clip?, ref }, tags[], advanced?, readOnly? }
Preset     { id ("easy" | "normal" | "hard" | own id), label, values: { key: value } }
```

Types: `number` (float), `int`, `range` ([lo, hi], e.g. spawn group size), `bool`, `enum` (options with labels), `text` (maxLength, single line), `color` (#rrggbb), `duration` (a number with a storage unit `ticks|s|ms`; the editor shows seconds), `sound-ref` (namespaced key, Sound Library id), `asset-ref` (texture/model/sound id of this project), `list` (scalars of one item type, maxItems), `table` (rows of typed columns: drop tables, shop price lists, wave lists, maxRows).

Two kinds of limits: `min/max` are HARD limits (the generated loader clamps to them, the editor refuses values outside them); `safe` is the BALANCE range (outside it the editor shows a warning, "Zombies at 500 health take ~80 hits with a diamond sword", but saves). Hard limits always contain the safe range and the default (validator rule).

`applies` says how a change reaches a running server: `live` (the mod re-reads the value without a command, rare), `reload` (`/<plugin> reload`; needs `reload.command`), `restart`. A spec without a reload command cannot declare `reload` (validator turns it into an error). The studio shows the strongest one among the changed keys as a badge and the delivery uses it.

`visual` links a stat to the viewport/motion core: channels `clipRate` (the named clip plays at value/ref speed: moveSpeed 0.35 vs ref 0.23 plays the walk clip 1.52x), `attackRate` (attack clip rate), `scale` (uniform model scale = value/ref), `fireRate` (gun fire clip / muzzle-flash interval), `tint` (color). `visualEffects(spec, values)` is pure and returns `{ clipRates: { walk: 1.52 }, scale: 1.2, ... }`; `applyToClock(clock, effects, clip)` calls `setSpeed` on anything with that method, so it works with Model Studio's `PlaybackClock` (r16) today and the Motion core's `createClock` (r21) when merged. No import of either.

Designer params are the same model: `fromDesignerParams(Param[])` maps the designers' `num/ticks/int/text/sound` params (min/max caps, role, path) into ConfigSpec params (`number/duration(ticks)/int/text/sound-ref`, hard limits = caps, tags = role, applies = reload via `/<cmd> reload`). The designers keep emitting their own config.yml byte-identically; the studio edits their values through ConfigSpec, and a values-only change is written into config.yml with the comment-preserving writer (no Java recompiled). One editor, one value model, one validator.

## 2. Relation to ModSpec

ModSpec v1 gets an optional `config` section: `{ spec: ConfigSpec, values?: { key: value } }` (optional, so every stored spec stays valid; JSON Schema regenerated). The schema is part of the mod (it changes only with a build); the values change in studio revisions. `validateModSpec` checks the section (keys unique, defaults within limits, presets reference real keys).

## 3. Category templates (what Cyrus offers by default)

Templates are data (`lib/cyrus/config/templates.ts`), keyed by template id, mapped from the universal categories. Each lists groups, params with default, unit, hard + safe range, applies, visual, and easy/normal/hard presets.

- **mob/creature**: max health, armor, movement speed (visual clipRate walk), follow range, attack damage, attack speed (attackRate), knockback, knockback resistance, scale (visual scale), XP drop, drops table (item, chance, min, max), spawn weight, group size (range), light level max, spawn biomes (list), despawn, glow color.
- **melee weapon**: attack damage, attack speed (attackRate swing), reach, knockback, crit multiplier, durability, sweep, enchantability, special-hit chance.
- **ranged weapon / gun**: damage, fire rate (rounds/min, visual fireRate), magazine size, reserve ammo, reload time (duration, visual clipRate reload), spread (degrees), recoil, projectile speed, range, falloff start, headshot multiplier, fire mode (enum semi/burst/auto), burst count, ammo item (asset-ref), fire sound (sound-ref).
- **armor**: armor points, toughness, knockback resistance, durability, set bonus effect + level, movement penalty.
- **ability/spell**: cooldown, range, strength, damage, heal, duration, mana/charge cost, charges, cast time, area radius, sound.
- **boss/encounter**: health, phase thresholds (list of %), damage per phase (table), enrage time, minion count, arena radius, bossbar color/text, loot table, respawn time.
- **shop/economy**: currency name, starting balance, price table (item, buy, sell, stock), sell multiplier, tax %, daily limit, interest.
- **quest/NPC**: objective counts, reward money, reward XP, reward items table, cooldown/repeat, time limit, NPC name, dialogue text lines.
- **minigame/arena**: min/max players, countdown, round time, rounds, lives, respawn delay, team count, kill score, win score, border size, kit list.
- **world/dimension**: ore vein size, veins per chunk, height range (range), structure spacing/separation, mob cap, day length, weather chance (restart applies).
- **custom item**: name, lore lines, rarity color, stack size, cooldown, uses/durability, effect + level + duration.
- **utility/admin plugin**: messages (text), prefix, colors, feature toggles (bool), intervals, permission defaults, limits, log level.

`templateIdsForCategory("creatures") -> ["mob"]` and `suggestTemplates(prompt)` (keyword table, zero tokens) choose them. Mods can declare params outside templates; templates are what Cyrus offers, not a cage.

## 4. How the AI declares tunables, and how the build verifies them

Prompt (new section, only when the build has `config` on): "Declare every tunable in `assets/config/schema.json` (ConfigSpec). Start from the template keys for this category (given in the request); add your own; read each key in code through `getConfig()` with the exact key string; never hard-code a number that has a key." The template's key list for the routed category goes in the user turn (system prompt stays cacheable).

Build checks (pure, in `lib/cyrus/config/verify.ts`, bundled into the service like designer-spec.js):
1. schema validates (Zod + rules).
2. every declared key is READ by the Java sources: the exact key string appears in a `getConfig()/getX("key")` style call or in the generated accessor's use. Unread key = error (a setting that does nothing is worse than none).
3. keys read in code but not declared = warning (listed so the editor still shows them via inference).
4. cheap magic-number heuristic: numeric literals passed to known stat APIs (`setBaseValue`, `setDamage`, `setCooldown`, `runTaskTimer` periods, `setVelocity(...multiply(n))`, `setFireTicks`) = warning with file and line, not a block.
5. config.yml is GENERATED from the schema (`renderConfigYml`): header, each group as a comment block, one `# label (unit, min-max). help` comment per key, defaults. If the model wrote its own config.yml it is merged: its comments and unknown keys are kept, declared keys added where missing.

Designer builds are unchanged (they already make every number a setting); their schema is derived from `designParams`.

## 5. Storage (values only)

A studio save is a new `CyrusRevision` kind `config` (pure kind list extended; the column is a string, no migration) whose manifest is the head's with config.yml's new sha, plus a `CyrusProjectAsset` row kind `config`, key `values`, provenance `{ values, specSha256, configYml, patch }`. No model call, no build, no token charge. The head check (expectedHeadId) gives 409 on a stale editor. Undo = a new revision with the previous values (revert never edits history).

## 6. Delivery

`deliverConfig(serverId, { projectId, revisionId, pluginName, configYml, applies, reloadCommand }, host)` runs through the orchestrator's existing transaction (journal, recover check, rollback): write `plugins/<plugin>/config.yml` through the journal, then apply as declared: `reload` -> the plugin's reload command over the console (a failure reply rolls back and re-runs reload on the old file), `restart` -> restart + health, `live` -> nothing. Health: plugin still enabled, no new error lines. Behind the existing `CYRUS_DELIVERY` and the new `CYRUS_CONFIG_STUDIO` (both off).

## 7. Imported mods: schema inference

`inferSchema(configYml, { pluginYml? })`: every scalar leaf becomes a param. Type from value (bool, int, number, `#hex` color, namespaced `sound` key, list); `duration` from `_ticks/_seconds/_ms` suffixes; unit from key words (health hp, speed, damage, radius/range blocks, chance/percent %, price/cost/money currency); label from the key; help from the comment above or on the line; hard limits from comments (`(0-100)`, `between 1 and 5`, `min: 1`, `max 20`), enum options from `one of: a, b, c` / `a|b|c`; groups from top-level sections; `applies` = reload when plugin.yml declares a command with a reload usage, else restart. Inferred specs are marked `inferred: true`, never get balance warnings they cannot justify, and keep every unknown key untouched on write.

## 8. Presets, diff, reset, undo

Presets per template (easy/normal/hard) + "custom" (whatever differs). `applyPreset` only touches keys the preset names. `diffValues(a, b)` lists `{ key, from, to }`; `applyPatch`, `invertPatch` (undo), `resetKeys(keys)` (back to defaults), `resetAll`. The editor shows changed keys, the diff before save, and which keys need reload/restart.

## 9. Per-game exporter contract

```
ConfigExporter { game, formats: ["yaml" | "json" | "toml" | "cfg"], applies: (live|reload|restart)[], reloadVerified: bool,
  render(spec, values, previousText?) -> { path, text }, read(text, spec) -> values, maturity }
```
Minecraft Paper: YAML at `plugins/<plugin>/config.yml`, reload by plugin command (verified on 1.21.11 + 26.2 here). Datapack-only mods: values become generated data files (restart/`minecraft:reload`), later. Other games: planned (FiveM `config.lua`, Hytale JSON) with maturity "planned".

## 10. Studio UI

`/dashboard/cyrus/<id>/studio/config`: groups in a left rail, search, a form generated from the schema (sliders + number inputs with units for bounded numbers, toggles, selects, color, duration in seconds, sound picker by key, list chips, table rows), preset chips, per-field reset, balance warnings inline, `applies` badges, a diff drawer with Save (revision) and Deliver. A preview panel (creature/weapon) with a clock that follows visual stats. Dark + light, narrow read-only.

## 11. "Just tweak a setting" recogniser

`planConfigEdit(text, spec)` mirrors the designers' `planDesignEdit` grammar (set X to N [unit]) against labels, keys and tags. Wire only if every clause resolves to exactly one key and the value is within hard limits; anything else goes to the model. Proposed: wire behind `CYRUS_CONFIG_STUDIO`, owner decides whether skipping the model is free.

## 12. Risks

- The model declares keys it never reads, or reads keys with a typo: verify step 2/3 catches both; magic numbers are only heuristic.
- A reload command that does not re-read everything (plain AI plugins): `applies` comes from the model; a real flight per build is the only proof. Default to `restart` when unsure.
- YAML subset: anchors, multi-document files and block scalars are kept byte-identical but not editable.
- Balance numbers in templates are judgement, not measurement.
- Imported mods: inferred ranges may be wrong; inferred params never clamp, they only validate type.

## 13. Owner decisions

1. Plan gate: editing numbers is not asset creation. Proposed UNGATED on every plan (server-side ownership/auth only, fail closed).
2. Values-only saves and deliveries cost 0 tokens?
3. Wire the "just tweak a setting" recogniser (skips the model)?
4. Automatic reload after delivery, or a "Deliver" click per change?
5. Show balance warnings to customers, or only to the owner/admin first?
6. Flag `CYRUS_CONFIG_STUDIO` order: after `CYRUS_DELIVERY`.
