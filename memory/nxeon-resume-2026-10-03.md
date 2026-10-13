---
name: nxeon-resume-2026-10-03
description: "Where the 2026-10-01..03 marathon stopped: what is live, what is built-but-unmerged (branches), what is waiting on the owner, and the safe order to resume"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-10-03T03:26:14.785Z
---

Owner paused on 2026-10-03 (had to leave). Nothing risky was scheduled; one read-only agent (off-site backup audit/design, branch feature/complete-offsite-backups) may still be finishing.

**Live on prod (promote script, release f334b55d and later):** growth batch (creator revenue exclusion + magenta creator names + Free/Creator tags, G1 analytics, G2 flags-off payments, G3 SEO, G4 content, G5 games/mods, G6 directory overhaul, G7 community), Zomboid admin-password apply, deploy-wizard copy fix, restart/slow-start fix, config-apply FRAMEWORK + Terraria applier + Terraria TShock 6.2.1 update path. All 3 Terraria servers updated to TShock 6.2.1 / 1.4.5.8.

**Built, NOT merged to main (verify then merge, then ONE promote):**
- integ/game-config-wave (7 family appliers merged, 48 families covered; known gap: NXEON_GAMECFG_APPLIERS=off does not gate install-time bakes; tightened field validations need owner review)
- fix/grant-required-fields (grant form with per-game required fields + billing wording), fix/mod-install-coverage (Core Keeper mod.io installer, honest mods UI)
- feature/directory-block-other-hosts (needs additive db push: 4 ExternalServer columns)
- feature/complete-offsite-backups (agent may still be running)
- fix for DST mod-install orphaning the world volume and the exit-143 "stopped shows failed" bug were spawned as chips, not built.

**Owner decisions pending:** Singapore capacity (new node + spec), node tuning one node at a time (ARC caps, compression, swappiness; node-5 canary), Abiotic Factor blank-password behaviour, Conan image unsellable, Enshrouded shared password, join-password fields for 12 games (Palworld first), Hetzner->OVH Germany move (medium effort, addresses change, VM move engine still unrehearsed), Dropbox encryption-key location, Terraria template update (`scripts/terraria-template-update.ts --apply`), mirror sweep flag, workspace.trynxeon.com app (VM nxeon-team-pm on node-4 behind Caddy + temporary basic-auth; guardrail = vm-isolate.sh + vm-ingress.sh), directory v2 plan at /root/research/directory-v2-plan.md (phase 1 = Valve import with attribution + schedule + liveness).

**Facts to remember:** off-site Dropbox backups (rclone remote dropbox:nxeon-backups, env /etc/nxeon/backup-offsite.env) stopped 2026-09-14 (timer disabled 09-15, cause unknown); catch-up of today's DB dumps + host-config done to dropbox:nxeon-backups/manual-catchup-2026-10-03; timer still disabled on purpose until the backup design is approved. The primary is overloaded (swap full, load >10) partly from agent test jobs: prefer node-5 / /tank worktrees. Scripts that write to the prod DB need NXEON_DB_TARGET=nxeon. Classifier blocks remote shell writes to customer VMs and key installs: use platform jobs (GAME_CONFIG / GAME_POWER / GAME_UPDATE) or hand the owner the command. Research reports: /root/research/*.md.

**Backup agent paused (2026-10-03 ~03:50 UTC), branch feature/complete-offsite-backups WIP 42d4e88cdd, design in /root/research/backup-design.md ("RESUME HERE" list), notes /root/agent-notes/backups.md.** Audit findings: Dropbox archives are PLAINTEXT (host-config tar there holds PVE keys, Cloudflare tokens, .env); node-5 has 5 of 8 VMs with no backup anywhere and its /tank/backup is a plain dir on a 20 GB root fs (96% full; needs ZFS dataset data/backup first); node-4 VMs 648/649 unbacked; Postgres roles/WAL/letsencrypt/nft/rclone config/secrets files not backed up; Dropbox plan is a Plus trial ending ~2026-10-12; vzdump at 04:30 UTC = 12:30 Singapore; real throttle is vzdump --bwlimit (ionice does nothing on NVMe). Design: age encryption (owner holds private key off-box), per-node windows from player telemetry, gate on PSI/swap/ARC, weekly off-site for VPS/games, daily for infra. Scratch to clean: /tank/age-test on the primary. To resume: SendMessage the agent (id a1a5a79642d016afa) to continue the resume list.
