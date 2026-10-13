# cfg-sim (families eco, empyrion, spaceengineers, vintagestory, mordhau, squad)
Worktree /tank/nxeon-wt-cfg-sim, branch feature/game-config-sim (from feature/game-config-apply-core).
Started 2026-10-02. Sources fetched: CM2Walki/Mordhau + Squad entry.sh/Dockerfile/README (raw github), ScottLusk steamcmd-eco configure_server.sh (Network.eco key names),
mmmaxwwwell SE README. Eco/VS/Empyrion official wikis were Cloudflare-blocked (403).
DONE: all 6 families built + tested (test/cfg-sim.test.ts, 67 pass incl core tests), tsc 0 errors. No real server apply run.
Shared edits: lib/game-config-appliers.ts (6 import+registry lines, optional applyAtProvision flag), lib/game-config.ts (help text for eco/empyrion/SE),
worker/game-config-appliers/index.ts (6 register lines), worker/game-variant.ts (scriptWithSim block), worker/index.ts (applyAtProvision condition), worker/game-control.ts (post-reinstall GAME_CONFIG queue), docs appended subsection.
