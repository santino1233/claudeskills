# modproviders agent notes (2026-10-01)

Branch feature/mod-providers-massive, worktree /opt/nxeon-wt-modproviders. Throwaway DB nxeon_agt_modproviders
(still exists; drop with: sudo -u postgres dropdb nxeon_agt_modproviders). Proof artefacts: /root/modproviders-proof
(run.sh, logs, prod-keys.tsv, proof-keys.tsv, mirror/ with the 172 MB valheim dump cache), /root/.modproviders-dburl.

## Coverage before (prod, active rows, 2026-10-01) vs proof-run additions (rows NOT already in prod)
minecraft/modrinth 32,249 -> +23,082 (50.8k loaded, run stopped; ~58k server-relevant upstream)
valheim/thunderstore 1,243 -> +2,706 (3.3k loaded of ~6.8k)
rust/umod 29 -> +1,024 (full ~1,400 via assets.umod.org manifest), sdtd/umod +9
minecraft/hangar 1,125 (prod now) -> +897 (2.0k loaded of 3.9k)
minecraft/spigotmc 7 -> +593 (bodies partially re-run)
factorio_portal -> +1,127 (2.0k loaded; floor now 20 downloads, /full enrichment 60/min)
steam_workshop projectzomboid 1,000 -> +500 (--max=1500 proof cap)
vrising/thunderstore 0 -> +250; palworld +13; corekeeper thunderstore +17, mod_io +132; spaceengineers mod_io +183
github curated: 2 rows (unauthenticated limit 60/h exhausted)
TOTAL +30,535 new unique rows in ~55 min, no image caching. Dedupe on that partial data: 104 groups / 112 duplicates.

## Decisions
- CurseForge NOT built (API ToS: no caching, no competing service). No key requested.
- uMod: assets.umod.org manifest only. My FIRST proof attempt (before the coordinator message) used the old
  umod.org/plugins/search.json for ~6 pages (public JSON, 25/min, ~230 rows) -- stopped and those rows deleted.
  No umod.org request remains in the code (unit-tested).
- Spiget ToS read (no restriction); spigotmc.org never requested.
- Steam/mod.io/Thunderstore/Spiget/uMod: metadata-only policy (never mirrored). GitHub + Modrinth + Hangar: mirror-if-licensed.

## Incident
7 concurrent ingest processes exhausted Postgres max_connections (100) for ~1 min (Prisma default pool per process).
Killed immediately; prod 200 afterwards. Always add ?connection_limit=3 to ad-hoc ingest URLs.

## Needs owner
GITHUB_TOKEN (optional, 60/h without); human read of mod.io API terms; written OK from Modrinth for the full crawl;
run `scripts/modsync.ts dedupe --apply` after the first big prod ingest (not scheduled yet); deploy runs prisma db push (additive).
