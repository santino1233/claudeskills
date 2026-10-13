---
name: nxeon-playnxeon-migration
description: playnxeon.com migration for NEW game servers (existing stay on play.nxeon.cloud); branch built, not merged/deployed, cutover steps pending owner
metadata:
  type: project
---

Owner request 2026-10-08: new game servers (paid + free Minecraft) get `<name>.playnxeon.com`; existing servers stay on `play.nxeon.cloud`; playnxeon.com root forwards to the game-servers marketing page.

**State:** branch `feature/playnxeon-domain` commit 96efee2c41 (worktree /tank/dev-worktrees/playnxeon). tsc clean, 141/143 tests (2 fail on main too: server-only import). Nothing merged/deployed. Live Cloudflare check done (read + one throwaway record created+deleted; zone back to its 2 placeholder records). Not verified: a real Minecraft client joining on the new domain, nginx/certbot.

**Design:** nullable `connectDomain` on Server + FreeMinecraftServer (NULL = legacy), filled at creation only; settings `game_domain_new` (default playnxeon.com) and switch `game_domain_new_enabled` (OFF); helper lib/game-domain(-rules).ts; DNS per-server zone; env var `CLOUDFLARE_PLAYNXEON_API_TOKEN`; one shared name namespace across domains. Token stored at /root/secrets/cloudflare-playnxeon.env (never print). Token cannot create Cloudflare redirect rules => root forward is an nginx 301 to https://nxeon.cloud/game-servers (deploy/playnxeon/INSTALL.md).

**Cutover (owner approval needed at each live step):** 1 merge + deploy-staging + promote-production (additive, switch off). 2 owner adds the token env var to /opt/nxeon/.env (classifier blocks me editing .env), restart web+worker units. 3 `node scripts/playnxeon-dns-prep.mjs --env-file /root/secrets/cloudflare-playnxeon.env` dry run then --apply (wildcard A -> 178.63.94.114, root A -> 51.79.162.96, www DNS-only). 4 nginx + certbot for playnxeon.com/www. 5 flip the switch in Admin > Settings > Free Minecraft, run ROLLOUT.md checklist. Rollback = switch off.

**Known unfixed:** renaming a paid server leaves the old name's DNS records. Owner should rotate/scope the token after migration (was pasted in chat).
Docs: /root/agent-notes/playnxeon/{AUDIT,ROLLOUT}.md
