# cfg-mixed (2026-10-02)
Branch feature/game-config-mixed, worktree /tank/nxeon-wt-cfg-mixed (from feature/game-config-apply-core). Not merged/deployed.
Families: projectzomboid (extended on top of worker/zomboid-admin.ts), dst, unturned, theforest, sonsoftheforest, stationeers.
Docs: docs/DOCUMENTATION.md "Mixed-family appliers". Tests: test/cfg-*.test.ts (+ test/_cfg-mixed-helpers.ts). All fake-guest only; NO real apply run.
Research clones (read-only image sources) in /tank/cfgmixed-research; registry-config helper in the session scratchpad (imgcfg.sh).
Hazards found: worker/game-mods.ts applyDstWorkshop recreates dst without its anonymous /opt/storage volume (likely orphans world); The Forest catalog script has no SERVER_STEAM_ACCOUNT_TOKEN so the image refuses to start.
