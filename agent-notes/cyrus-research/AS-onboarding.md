# AS: Cyrus game onboarding kit (r47, 2026-10-11)
Branch `feature/cyrus-r47-onboarding` (worktree `/tank/dev-worktrees/cyrus-r47`), commits 009ec774a6 + merge of latest r2 (678c22af40). Nothing deployed, registered or switched on.

## Delivered
- `docs/cyrus/onboarding/`: **PLAYBOOK.md** (phases 0-9, entry/exit criteria, 8 owner gates G0-go...G9-launch, scorecard 8 weighted criteria + 4 knockouts, threshold GO 65+ / LATER 50-64 / NO <50, tooling decision tree, licence + Windows-worker rules, Nxeon touchpoint table, maturity ladder, frugality, how it stays current), **CASE-STUDIES.md** (Minecraft reference, Terraria/Valheim/Zomboid retro-fit, Hytale + FiveM on hold; retro scores; studios-per-game matrix; 9 cross-game contract gaps), templates (9) + agent briefs (common rules, screening, R1-R9 Sonnet, B1-B5 Opus, review), IMPROVEMENTS, LESSONS (6 seeded), CHANGELOG 1.0.0, records + TODO for 6 games.
- `lib/cyrus/onboarding/` (pure, seam-clean): ladder exit criteria as code, `checkRecord` health rules, derived capability manifest, TODO parser, records loader.
- `scripts/cyrus/new-game.ts <id>`: adapter (planned), GameSupport stub, empty knowledge pack, eval stub (30+10 in `services/modbuilder/eval/games/`, outside the Minecraft globs), record, TODO, doc stubs; idempotent; `--docs-only`, `--dry-run`, `--manifest`. Registers nothing.
- Admin: read-only "Game onboarding" section on `/admin/cyrus/games`. DOCUMENTATION.md section.

## Ran (node-2 via devhost)
- `test/cyrus-onboarding.test.ts` 17/17 (scaffolder runs in a temp mirror, type-checks generated files with the TS API, seam, profile, health, clean-up).
- Real-tree check: scaffolded `zzfakegame` in the worktree, full `tsc --noEmit` clean, onboarding + host-seam + db-split + engine-core + foundation + eval-set 135/135, then removed.
- Full Cyrus suite (cyrus* + modbuilder*): 2594/2595. The 1 failure is pre-existing on r2: `test/cyrus.test.ts` "every page renders through the gated loader" fails on `app/dashboard/cyrus/notifications/page.tsx` (r40), not touched here.
- tsc clean (before and after the r2 merge).

## Not run / open
- No Hytale/FiveM code (on hold). No adapter stubs for Terraria/Valheim/Zomboid (proposed).
- `docs/cyrus/README.md` exists only on r46: it should link `onboarding/README.md`. When r46 merges, re-run `scripts/cyrus/docs-build.ts`: its references (modules/scripts/tests) will need the new files. My docs pass r46's link + IP/secret checks (one "1.4.5.8" version string reworded).
- r45 capability manifest had no commits; reconcile later.
- Finding: Minecraft adapter declares pack delivery + boot "planned" (flags off), so the derived manifest shows Texture/Sound/Model Studio as planned (lesson L6).
- Owner gates all unsigned; retro-fit games carry `retrofit: true`.
