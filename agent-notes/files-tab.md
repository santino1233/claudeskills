# files-tab (2026-10-05)
Branch feature/files-tab-game-files, worktree /tank/nxeon-wt-filestab. Commits b086ce717f, e3152cc854.
Files: lib/game-files-roots.ts, components/customer/files/GameFilesBar.tsx, FileBrowser.tsx, app/dashboard/servers/[id]/page.tsx, test/game-files-roots.test.ts, docs/DOCUMENTATION.md.
Live probe (read-only test -d): minecraft(paper), valheim(bepinex+vanilla), palworld, projectzomboid reachable and verified. Every other running family is on node 51.79.162.96 which refused SSH from here.
Mismatches vs GAME_CONTROL.dataRoots (unverified live): terraria /opt/terraria/worlds, rust /opt/rust/server, enshrouded /opt/enshrouded/server.
Screenshots + harness: /root/agent-notes/files-tab/ (fake-guest harness, not the real tab).
tsc 0 errors; suite 46 failures (same count as baseline), none in touched files.
