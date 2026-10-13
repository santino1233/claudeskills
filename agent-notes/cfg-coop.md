# cfg-coop (game config appliers: factorio, satisfactory, abioticfactor, corekeeper, necesse, barotrauma)
Branch feature/game-config-coop, worktree /tank/nxeon-wt-cfg-coop (from feature/game-config-apply-core 60aa1cdd07).
Truth sources read (scratch copies in the session scratchpad coop/): wolveix/satisfactory-server run.sh, factoriotools/factorio-docker docker-entrypoint.sh,
Pleut/abiotic-factor-linux-docker entrypoint.sh, escapingnetwork/core-keeper-dedicated scripts, andreas-glaser/necesse-docker-server entrypoint.sh,
thijsvanloef/barotrauma-server-docker init.sh + templates.
Key findings: barotrauma env vars only apply on FIRST creation of serversettings.xml and the image's sed is case-sensitive so MAX_PLAYERS (MaxPlayers=) and
PUBLICITY (IsPublic=) NEVER applied even then; abiotic blank ServerPassword falls back to "password" (bash :-); satisfactory/corekeeper schema keys had no envKey so
checkout values were never baked.
DONE: 2 commits on feature/game-config-coop. tsc 0 errors; test/cfg-*.test.ts (6 files) + 25 related test files pass (368/370, 0 fail).
No real server apply was run for any family (fake-guest tests only). See final report for per-family field table and shared-file touch list.
