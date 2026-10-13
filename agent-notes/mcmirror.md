# MCJ mcmirror — Minecraft server-software mirror (2026-10-01)
Branch feature/minecraft-jar-mirror, worktree /opt/nxeon-wt-mcmirror. Commits 362db465c6, 9e8face341, 891991c06f, b576a980bd (merge main), 04e7e463f1. Main merged in; tsc clean; mcjars 29/29, game-variant 21, game-runtime 48, provision-speed 19.
Docs: docs/DOCUMENTATION.md § "Minecraft server-software mirror" + change entry.
Owner at deploy: zfs create -o quota=100G -o mountpoint=/tank/nxlabs-mirror tank/nxlabs-mirror && chown nxeon:nxeon /tank/nxlabs-mirror ; additive db push (McMirrorProvider, McMirrorRun, McJarPin); restart worker; lower NXLABS_MIRROR_MAX_BYTES to <=55G or quota 150G (full MC fill ~10-11 GB).
UNVERIFIED: a real itzg container booting with the pinned env (no docker on prod allowed) — watch the first pinned provision on staging; settings-apply recreate path with pin not run against a VM; rescue script --apply never run.
Throwaway DB dropped, .env/.next removed.
