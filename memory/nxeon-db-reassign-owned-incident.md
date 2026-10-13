---
name: nxeon-db-reassign-owned-incident
description: 2026-10-07 an agent ran REASSIGN OWNED BY nxeon on the shared Postgres and moved prod DB ownership; fixed same day — never allow cluster-wide role/ownership commands
metadata:
  type: feedback
---

2026-10-07: a build agent, fixing ownership in its throwaway DB, ran `REASSIGN OWNED BY nxeon TO agt_baremetal`. That is cluster-wide for shared objects, so 12 databases including prod `nxeon` became owned by the throwaway role (tables were untouched; nxeon lost CREATE on prod `public`, so the next `prisma db push` adding tables would have failed). Fixed with per-database `ALTER DATABASE … OWNER TO nxeon` (owner approved); verified nxeon has CREATE on public again.

**Why:** all agent throwaway DBs live on the same Postgres cluster as prod.

**How to apply:** every agent brief that creates a throwaway DB must forbid REASSIGN OWNED / DROP OWNED / ALTER DATABASE / role changes; use per-object ALTER inside the own DB or recreate it. Quick health check: `select datname, pg_get_userbyid(datdba) from pg_database` — prod `nxeon` must be owned by `nxeon`. Related: [[nxeon-build-isolation]].
