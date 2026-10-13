# Cyrus studios v2: design notes (mockups, 2026-10-10)

Files: `item-designer.html`, `menu-quest.html` (tabs Menus / Quests), `mod-packs.html`, `import-mod.html`, `datapack-studio.html`. Self-contained, no network. Sources `src/` (v1 kit + `v2.css`/`ext.js`), build `tools/build.py`, shots `tools/run-shots.sh` (node-2, capped) into `shots/` (28 PNGs). Query params pick states; `ctl=0` hides the mockup bar.

## Principles
- **One product.** The shell copies the shipped studio (impl-shots/texture-*): the real portal sidebar and top bar, the Cyrus bar (wordmark, crumbs, context switch, Mod assets, token chip, theme), glass panels with mono eyebrows, the inspector tab anatomy, the conic-rim prompt dock at the bottom of the centre column.
- **One accent.** Violet means selected or primary. Cyan only means "now" (the simulator playhead). Green, amber, red only mean pass, warn, fail/blocking.
- **Typed, never node soup.** Graphs are columns (When, Only if, Do) with nested loop containers; blocks show their config path (`a0.n1`).
- **Caps are budgets.** Every limit is a meter or a counter (`20/64 actions`, `3/16 biomes`, `214/2048 progress chars`), and an overrun shows the validator's own code and message.
- **Honesty.** Real-client gameplay is "not verified" everywhere. "Not run" is never a pass. Sample content is labelled. The one illustrative Test Flight state is bannered as such. The attested scan never says safe.

## Mapping to backend data
| Screen | Data and caps |
|---|---|
| Item Designer | `ItemDesign` v1 (the Void Reaper fixture verbatim). Budget meters = `budgetOf()` ported 1:1 vs `BUDGET` (64/32/8/512/3), nodes 48, depth 3, 16 actions per list. Gate column = the `Ability` protocol (re-entry, cooldown, charges, conditions). Parameters = `params.ts` paths (`items.void_reaper.abilities.void_pull.a0.radius`) with `CAPS` ranges; saving shows "config.yml only, config_version 1→2, 27 Java files unchanged". Structure fields name the one Java file they rebuild. Simulator = `simulate.ts` semantics: charge = held/max, per-owner mark cap with oldest replaced, feedback text on cooldown. Asset chips run `canAsset` (texture top plan, sound Saka+). |
| Menus | `MenuDesign` chest (shop fixture: 6 rows, 28 list slots, 30 config entries, prev/next 48/50). Cost types item / xp_levels / economy; the CostCharger order room → pay → take → give drives "Try it". Checks use real codes (`economy_needs_vault`, `cost_loop`, `arbitrage_loop`, `slot_overlap`). |
| Quests | `QuestDesign` (trial_one/two/three, daily_bread fixtures): requires, branches (max 3), repeat daily, objectives with counts, rewards (max 8), stored-progress size from `progressEntryChars`. Backend is in progress (feature/cyrus-r11, uncommitted). |
| Mod Packs | Inventory (`scanServer`, redacted keys counted), findings with the engine's class/severity/resolution table, server-only findings separated, `notChecked` listed, `nxpack.json` summary (merged pack, `required: false`, changelog), compatibility row (static / boot, `not_run`), dynamic plan (1 combined + differential boots), the unit install steps and backup lifetime. Install off: `CYRUS_MODPACK_INSTALL_REAL`. |
| Import | ImportDemo fixture: ingestion caps, build files read-not-run, attestation + share consent with the text-version ids, SPDX detection, the allowlist (placeholderapi, vault-api), `unsupported: X`, the attested profile's 5 real warnings, revision 0 facts from the node-2 run, token estimate from the reserve table (Saka standard 60–220). Jar = analysis only, dock disabled. |
| Data packs + worldgen | DataPackSpec v1 resource kinds and pack caps, six pinned versions, per-version emitted JSON (attributes + `#rrggbb` from 1.21.11, music list from 1.21.4, carvers map on 1.21.1), the function allowlist and refusals (live "Try a command"), function limits, the template layout spec (palette chars, `.` void, 48³, 32768 blocks, 16 loot containers), the cost heuristic and per-class recommendation, the restart / new-chunks banner. |

## Component inventory (React)
- Shared: `StudioShell` (existing), `DesignerSwitch`, `TargetVersionChip`, `BudgetMeter({label, used, cap})`, `IssueList({issues})`, `QualityPanel` (reuse).
- Item: `ItemHeader`, `AssetRefChip({kind, key, decision})`, `AbilityGraph({ability, selected})` → `TriggerBlock`, `GateChain`, `ActionBlock`, `LoopContainer`; `ParamField({path, value, cap, changed})`, `ParamsPanel`, `PendingEditBar({edits, files, configVersion})`, `DesignSimulator({design, events})`, `DisplayContextPreview` (reuse the shipped In game view), `DesignDock` (parameter-request preview).
- Menu: `SlotGrid({rows, slots, list, page, mode})`, `Slot`, `SlotInspector`, `ClickProtocol({steps})`, `ConfigListTable`. Quest: `QuestChain`, `QuestFlow` → `StepCard`, `ObjectiveRow`, `BranchColumns`, `RewardChips`; `QuestSimulator`.
- Packs: `MemberList`, `InventorySummary`, `FindingCard({finding, onResolve})`, `ManifestSummary`, `CompatRow`, `UnitInstallCard`.
- Import: `UploadKinds`, `IngestChecklist`, `AttestationForm`, `DetectedFacts`, `DependencyRow({state})`, `AttestedScan`, `RevisionZeroCard`.
- Data packs: `ResourceTree`, `VersionStatusRow`, `BiomeForm` (+ one form per kind), `EmittedJson({version})`, `TemplateEditor({layers, palette})`, `IsoPreview`, `FunctionSafety`, `WorldgenCost`, `RestartBanner`.

## Interaction details
- Graph and Parameters edit the same value; selecting a block highlights its settings; old values show struck through.
- Menus: Edit selects slots (numbers on hover); Try it buys with a sample inventory and shows each protocol step; arrows page the list.
- Quests: chain cards select a quest; player events advance the simulator; +24 h re-opens the daily.
- Packs: Apply / Acknowledge / Undo per finding; Install and Test Flight stay disabled while anything blocks.
- Data packs: the target version changes JSON and checks; paint template cells with a palette char; upper layers dim in the preview.
- Narrow (< 760 px): summary plus Approve / Reject on every screen.

## Accessibility
Kit focus rings; status always has text, not colour alone; `role="checkbox"`/`aria-checked`, `aria-required`; MC-coloured names sit on a dark chip in light mode; reduced motion stops the glint and dock rim. Open: keyboard painting for the slot grid and template cells, screen-reader summaries of the graph and the timeline.

## Deliberately excluded
Free-form wiring and code blocks (`run_command` does not exist), the dialogue-menu editor, forms for every resource kind (biome, template and functions are drawn), creatures/RigSpec, vanilla item art, prices, invented test results.

## Open questions for the owner
1. **Item icons.** The mockups use pixel icons drawn here. Production needs a source: our own icon set, or icons rendered from the client's assets (licence check)?
2. Should settings-only edits skip the model and cost 0 tokens (`planDesignEdit` is built, not wired)?
3. Menu and quest designers are still in progress on feature/cyrus-r11. Are dialogue menus and the 8-menu / 16-quest limits the scope you want?
4. Can a Mod Pack install while user-decision warnings are open (today: yes, unless acknowledgement is required)?
5. Third-party members: search Modrinth/Hangar, or paste a link? The download allow-list isn't wired.
6. Worldgen restart: automatic after install, or confirmed by the customer? On uninstall, keep or archive the dimension folders?
7. Are "Try it" and the quest simulator customer-facing, or creator-only?
8. Attestation and share-consent wording: approve the texts shown?
