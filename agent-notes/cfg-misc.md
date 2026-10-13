# cfg-misc (2026-10-02)
Branch feature/game-config-misc, worktree /tank/nxeon-wt-cfg-misc. Families: dayz, armareforger, sandstorm, ets2, ats (fivem deliberately untouched, still flagged, legally sensitive).
Nothing verified on a real server (fake-guest tests only). Details + per-field table: docs/DOCUMENTATION.md "Misc families".
Findings: DayZ image seeds password "Docker"/admin "adminDocker" at first boot and the cfg only exists after first start; ets2/ats GAME_REINSTALL refused to run (quoted -v mount regex, fixed); sandstorm map/password/maxPlayers never applied before (no LAUNCH_SERVER_ENV) and serverName had no envKey.
