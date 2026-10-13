# cfg-unreal (agent `unreal`), 2026-10-02
Branch feature/game-config-unreal, worktree /tank/nxeon-wt-cfg-unreal (from feature/game-config-apply-core). Families: ark, arkasa, conan, soulmask, theisle, dragonwilds.
Docs: docs/DOCUMENTATION.md "Game config appliers" table rows + "Unreal families" subsection. Tests: test/cfg-unreal.test.ts (50 tests, fake guest). No real server apply was run.
Shared-file touches: lib/game-config-appliers.ts (6 imports + 6 lines + optional `handlesVariant`), worker/game-config-appliers/{index,types,run}.ts, worker/game-config.ts (1 line: `variant:`),
worker/game-variant.ts (import + rename scriptWithConfig->scriptWithTerraria + 1 call), lib/game-config.ts (my 6 families' fields only: envKey/pattern/help), test/_fake-docker-guest.ts (mkdir/chown no-op), docs.
Open: Conan image never worked here; variants for conan not handled; ARK rate fields need ARK's first start before they apply.
