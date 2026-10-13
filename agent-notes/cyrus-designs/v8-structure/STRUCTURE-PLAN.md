# Cyrus v8: mod structure (declutter, sub-branches, mod suites)
2026-10-11, branch `feature/cyrus-r45-structure`. Flags: `CYRUS_MOD_SUITES` (off). Mockups: `mock-forge.html`, `mock-suite.html`, `mock-declutter.html` (shots in `shots/`).

## 1. Capability manifest (declutter)
One pure function, `usableFor(game, version, ctx?)` in `lib/cyrus/manifest`, derived only from what already exists: the game adapter (routes, asset delivery, asset profile incl. catalog `accepts`, mesh budget, motion capability), the version registry (capabilities such as `itemModelDefinitions`, `dialogApi`, `animatedCreatures`), the designer feature check (`designFeatures`), `GameSupport` (categories, example prompts) and the plan gate (`canAsset`). Nothing is hand-listed per game.

It returns, for the game and version: studios, asset kinds, routes, designers with their component palettes, library kinds, templates, example prompts, part (module) kinds, and `whyNot` help entries.

**Three states, one rule each:**
| State | When | UI |
|---|---|---|
| usable | the game and version can use it, the plan allows it, the host switch is on | shown |
| locked | usable by the game, blocked only by the PLAN | shown with the lock + upgrade (existing behaviour) |
| hidden | the game or version cannot use it (no route, no delivery, catalog `none`, version capability missing with no fallback), or the host switch is off | not shown; game/version reasons become one `whyNot` line in a small "Why is X not here?" help entry; a switched-off feature gets no line (never leak a flag) |

Examples: Minecraft hides the Mesh studio (no mesh route: `meshBudget` absent, catalog `model: none`), shaders/skies/keybinds/HUD widgets (client-mod route `unsupported`), HDRIs, decals, PBR sets. Minecraft 1.21.1 hides item model states (legacy fallback only), 1.21.1-1.21.6 hide Dialog menus. Terraria, Valheim and Zomboid have no adapter yet: code-only, so every asset studio, designer and asset library kind is hidden and only "describe it" + Files remain (their config exporters are planned), with their own example prompts. An unknown game gets an empty manifest (fail closed).

**Applied to:** the studio switch in `StudioShell`, the project page studio list, the library browser and `catalog_search` (kinds the game cannot use are dropped, not shown as locked; per-entry `games[game].fit` stays), the designer palettes (version-only actions/states/layouts), new-mod flow (game, version, category and template pickers), the templates gallery (each template carries `games` + `needs`).

## 2. Sub-branches in the Forge
Selecting a mod pill opens its parts as a second fan beyond the pill (same links, glow and pill anatomy as categories -> mods). Breadcrumb grows one level: Core > Minecraft > Creatures & NPCs > Moth King Saga > Quests: The Moth Pact > Quest designer. Each part node shows its kind icon, a count ("3 items", "48 settings") and a status dot (passed / changed since flight / failed). Click a part: its studio opens scoped to that part (designs filtered to the module; texture/sound studios open on the module's slots). A plain one-module mod shows its part kinds (Items, Textures, Config...) derived from what it contains, so old mods get sub-branches too. Phones: the fan becomes a vertical list under the pill.

## 3. ModSpec v2: modules
`ModSpecV2 = ModSpecV1 + { schemaVersion: 2, modules[] }`. A module:
`{ id, kind, title, summary?, dependsOn[], requirementIds[], assets[] (slot ids), designs[] (design ids), files[] (owned path prefixes, e.g. custom hooks), provides[] ("item:frost_blade", "entity:moth_king", "quest:moth_pact"), uses[] }`.
Kinds: items, creatures, quests, menus, bosses, hud, textures, sounds, models, motions, config, datapack, worldgen, code.

- **One namespace** (`nx_<8>`): every `provides` id lives under the project's reserved namespace; modules never get their own.
- **Migration v1 -> v2:** a v1 spec becomes ONE module `main` (kind from its route/assets, owns every asset slot and design, requirements all). Lossless; `toV1()` drops modules so v1 consumers keep working. v1 stays the engine default while the flag is off.
- **Cross-reference validation** (structured issues, never throws): duplicate ids, dangling `dependsOn` / asset / design / requirement ids, self-dependency, cycles (with the cycle path), an asset or design owned by two modules, unassigned members (warn), `uses` that no module provides (dangling) or that a module provides but the user does not depend on (missing dependency), foreign namespace. With the design files, references inside designs (`nx_ns:<id>` in quests, bosses, menus, HUDs) are extracted and checked the same way.

## 4. Scoped edit and build
- `planScopedChange(spec, scope)`: scope = a module or the whole mod. The plan says what the change MAY touch (its designs, slots, owned files, its config keys `items.<id>.*`, `menus.<id>.*`...) and what is read-only context: the INTERFACES of its dependencies (provides lists with one-line signatures) and the uses its dependents make of it (so the edit cannot break them).
- `guardScopedResult(base, ours, theirs, plan)`: a three-way merge per source file. Inside scope: take theirs, unless ours also changed since base (a concurrent manual edit) -> conflict, ours kept, reported. Outside scope: ours always wins and the attempt is reported. Removing a `provides` id a dependent uses is refused unless the scope is the whole mod. Generated outputs (Java from designs, plugin.yml, config.yml layout) are derived and rebuilt, not merged.
- **Revisions:** still one revision chain per project (one jar). Each revision's engine record gains `scope` and `moduleHashes` (content hash per module). A module's revision history is the list of revisions where its hash changed; no new table.
- **Spend:** build tokens are attributed to the revision's scope; per-module spend = sum over its scoped revisions; whole-mod builds show as "whole mod" (never split by guess).
- **Test Flight:** module flight = the module's export (module + dependency closure) built and flown alone; whole flight = the full jar. Status per module: passed / failed / stale (hash changed since the last passing flight) / none.
- **Export a module:** the closure becomes a new v2 spec with a new namespace; ids are rewritten `nx_old:` -> `nx_new:`.

## 5. Decomposed generation (small AI context)
`planSuiteGeneration(spec)`: modules in dependency order; each step gets only its own requirements + dependency interfaces (not their designs). Per-step estimate from the existing estimator. A whole-mod build is the plan run step by step, then one compile, one jar, one whole flight. Not wired to a model on this branch (no paid calls).

## 6. Caps and performance budgets
Single-module mods keep today's limits byte-for-byte. Suites (flag on) get `SUITE_LIMITS`: up to 32 modules, 48 items, 24 menus, 64 quests, 8 bosses, 8 encounters, 4 HUDs, 16 motions, 200 design files. Runtime caps (live bosses, minions, tasks, particles per activation) are plugin-wide and do NOT grow. `suiteBudget()` warns honestly: periodic abilities per player per second, listeners, config settings, generated classes, expected compile time. The thresholds come from a real Test Flight of a large synthetic suite on 1.21.11 (boot time, RSS, MSPT); numbers not measured are labelled estimates.

## 7. Mod suite vs Mod Pack
| | Mod suite (new) | Mod Pack (exists) |
|---|---|---|
| What | ONE mod built from modules | several separate mods installed together |
| Namespace / jar | one / one | one per mod |
| References | modules reference each other, validated | mods do not know each other |
| Checks | cross-reference + one Test Flight | conflict engine + combined boot |
| UI copy | "Parts of this mod" | "Mods in this pack" |
A module can be exported into its own mod, which can then go into a Mod Pack.

## 8. Risks
- Bigger mods = longer builds and more tokens: per-module estimates first, whole-mod builds show the sum before spending.
- Scope leaks through generated code: only sources of truth are merged; derived files rebuild.
- Interface drift between modules: provides/uses checked on every scoped result.
- Hiding too much: a hidden item always has a `whyNot` line when the reason is the game, never a dead end.
- v2 as the default changes the stored spec version: kept off until the owner decides.

## 9. Owner decisions
1. Name: "Mod suite" + "Parts" (recommended) vs "Big mod" / "Modules".
2. Suite caps (above) and whether suites are plan-gated (recommended: modules ungated, asset gates unchanged).
3. Spend display: per part + "whole mod" bucket (recommended) vs splitting whole-mod builds by size.
4. When v2 becomes the stored default (lazy migration on read, no SQL needed).
5. Hidden items: show the "Why is X not here?" entry (recommended) or nothing.
