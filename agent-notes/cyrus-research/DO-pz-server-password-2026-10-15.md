# PZ server join password (2026-10-15)
Branch feature/pz-server-password, worktree /tank/dev-worktrees/nx-pz-password (uncommitted until verified; not pushed/deployed).

## Findings
- Join password was never settable: PZ schema had only ADMIN_PASSWORD/RCON_PASSWORD. servertest.ini ships `Password=` blank, so PZ servers are OPEN by default. The support reply claiming an automatic password was wrong. No such claim exists in lib/kb-facts.ts or the PZ marketing page (grep clean); only lib/game-connect.ts had a "gap" note (now fixed: join key = Password).
- ini path: VM `/opt/projectzomboid/config/Server/servertest.ini` == container `/project-zomboid-config/Server/servertest.ini` (SERVER_NAME=servertest).
- Image: per lib/game-applier-specs/projectzomboid.ts (read off the image's start.sh), start.sh rewrites only DefaultPort, UDPPort, RCONPort, RCONPassword, MaxPlayers each start; Password is untouched, so an ini edit persists across restarts. I could not re-read start.sh itself here (image not on this host): verify live with grep -i password in the image scripts.
- Applier: only writes keys in `touched`; it does NOT overwrite a manual Password line unless a save includes the Password field.

## Change
Schema field `Password` (Access, "Server Password", pattern ^[A-Za-z0-9._@%+=-]{0,64}$, blank = open); spec secret:true in PZ_INI_FIELDS (stopped edit + read-back + rollback); fresh-install seed skips blank; game-connect join; docs/DOCUMENTATION.md row + dated note. "Open"/whitelist not added. Tests appended to test/cfg-projectzomboid.test.ts.
