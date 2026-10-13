# cfg-source: Source-engine appliers (cs2, cs16, tf2, l4d2, gmod, kf2), 2026-10-02
Branch feature/game-config-source, worktree /tank/nxeon-wt-cfg-source (from feature/game-config-apply-core).
All built from image source; NO real server apply was run. Details: docs/DOCUMENTATION.md "Source-engine families".
Owner flags: cs16 template mounts empty /opt/cs16 over /hlds (likely cannot boot, never real-provisioned); tf2 stock cfg rcon_password overrides env;
fresh TF2 servers previously had join password "changeme". cs2 inline applyCs2 removed (image rewrites server.cfg every boot).
