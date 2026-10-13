# terraria-update (2026-10-02)
Branch fix/terraria-tshock-update (from feature/game-config-apply-core), worktree /tank/nxeon-wt-terraria-update, commit 9d7dbf534f. Docs: docs/DOCUMENTATION.md "Terraria image update, version catalogue and local mirror" (has owner rollout + rollback).
Image: ryshe/terraria is unmaintained -> ghcr.io/pryaxis/tshock:6.2.1 (index sha256:70e59a8e..., image id sha256:9b5081fd...). Mirror = docker-archive tarballs via skopeo in /tank/nxlabs-mirror/terraria.
NOT verified: no real update/provision run; 6.2.1 log banner patterns loose (fails safe -> rollback); -world + -autocreate on the official image unproven on a real new server.
Depends on cfg-core branch (feature/game-config-apply-core) being merged first. Suite: same 46 pre-existing failures as base.
