# BUILD HOST — all builds and heavy dev work run on node-2, not the primary

**Since 2026-10-07 (owner decision).** The primary (ns5002569, 51.79.162.96) only serves the live site:
prod web/worker, Postgres, customer VMs. Parallel agent builds there pushed load to 16+, filled swap
and hard-crashed it on 2026-10-06. Everything heavy now runs on **node-2 = nxeon-fsn1
(178.63.94.114)**, inside a capped systemd slice.

Full technical write-up: `docs/DOCUMENTATION.md` → "Build host (node-2)".

## What runs where

| Work | Where | How |
|---|---|---|
| Production / staging release builds (`npm install`, `prisma generate`, `next build`) | node-2, `nxeon-build-prod.slice` | automatically by `scripts/promote-production.sh` / `scripts/deploy-staging.sh` |
| Schema push, pre-cutover smoke (:3095), cutover, restarts, rollback | primary | same scripts, unchanged |
| Agent `tsc`, tests, `next build`, `next dev`, Playwright, throwaway DBs | node-2, `nxeon-build-agents.slice` | `scripts/devhost` (below) |
| Editing files, git commits | primary, in **your own worktree** | as before |

## Caps on node-2 (it also runs ~13 customer VMs — never touch them)

- `nxeon.slice` CPUWeight 20 / IOWeight 10 (VMs in `qemu.slice` win any contention ~5:1)
- `nxeon-build.slice`: **CPUQuota 900 % (9 of 12 threads, raised 2026-10-08), MemoryMax 10 G, MemoryHigh 9.5 G, no swap**
  - `nxeon-build-prod.slice`: release builds — CPUWeight 1000, MemoryLow 6 G, oom_score_adj 500
  - `nxeon-build-agents.slice`: agent work — **MemoryMax 7 G**, oom_score_adj 1000 (dies first)
- every process: nice 10, ionice best-effort 7. Build files live on `tank` (separate SATA SSD);
  VMs are on `rpool` (NVMe), so build IO never hits their disks.
- **Build lock** on node-2: `/run/lock/nxeon-build.lock` — one heavy job at a time
  (release builds, `devhost build|test`, `devhost run --lock`). Locked agent jobs are capped at
  25 min by default so a promote (waits max 30 min) is never starved.

## How agents work from now on

1. Make your own worktree on the primary (never work in `/opt/nxeon` or `/opt/nxeon-staging`):
   `git -C /opt/nxeon worktree add /tank/dev-worktrees/<name> -b <branch> main`
   You do NOT need `node_modules` in it (and never symlink one in).
2. Edit with your normal tools. Then, from inside the worktree, run heavy things on node-2:
   ```
   /opt/nxeon/scripts/devhost tsc                    # npx tsc --noEmit
   /opt/nxeon/scripts/devhost test [test/x.test.ts]  # tsx --test (takes the build lock)
   /opt/nxeon/scripts/devhost build                  # next build (takes the build lock)
   /opt/nxeon/scripts/devhost run -- <cmd...>        # anything else; add --lock if heavy
   /opt/nxeon/scripts/devhost db push                # schema into YOUR throwaway DB
   /opt/nxeon/scripts/devhost dev                    # next dev on node-2 127.0.0.1:<port>
   /opt/nxeon/scripts/devhost tunnel <port>          # reach it from the primary (curl/Playwright)
   /opt/nxeon/scripts/devhost run -- npx playwright test ...   # or run Playwright ON node-2
   /opt/nxeon/scripts/devhost pull <path> [dest]     # copy screenshots/reports back
   /opt/nxeon/scripts/devhost stop [name|all]        # ALWAYS stop dev servers when done
   /opt/nxeon/scripts/devhost rm                     # when finished: units, DB and node-2 copy gone
   /opt/nxeon/scripts/devhost status                 # node-2 load, slice memory, lock, running units
   ```
   Each command mirrors your worktree's source (git-tracked + untracked-not-ignored; never
   `.git`, `node_modules`, `.next`, `.env*`) to `/tank/nxeon-build/wt/<name>` on node-2, installs
   deps there when `package-lock.json`/schema changed, and runs the command in the agents slice.
   The node-2 copy is disposable — commit in your primary worktree only.
3. **Throwaway database**: every workspace gets its own `wt_<name>` on node-2's private Postgres
   cluster (`127.0.0.1:5433`, role `nxeon_agent`, never exposed). `DATABASE_URL`, a random
   `AUTH_SECRET`, `APP_URL`, `PORT` are preset. Extra non-secret env: `devhost env set K=V` (it
   refuses any value that is a live prod/staging value). **Agents never need, and must never use,
   production DB credentials.**
4. Only if node-2 is down: say so to the owner. Do not fall back to building on the primary.

## Forbidden (hard rules)

- **No `next build`, full test suites, dev servers, Playwright or JDKs on the primary.** Use devhost.
- **Never run `REASSIGN OWNED`, `DROP OWNED`, `ALTER ... OWNER`, `CREATE/ALTER/DROP ROLE`, or any
  database-ownership command** — on any cluster, including node-2's throwaway one.
- **Never `pkill`/`killall` by pattern** (`next`, `node`, `npm`, ...): it hits prod/staging too.
  Stop by unit (`devhost stop`) or by the PID on your own port.
- **Never `git add -A` / `git add .`** — add only the files you changed.
- Never touch customer VMs (`qm`, `qemu.slice`) on node-2; never raise the slice caps.
- Never copy a production `.env` (or any secret) to node-2. Never print secrets.
- Never build in `/opt/nxeon` or `/opt/nxeon-staging`; never `git checkout` there.

## Deploys (owner/root only)

`scripts/deploy-staging.sh [ref]` → verify → `scripts/promote-production.sh` — unchanged usage;
the build now happens on node-2 automatically. `--build-local` = emergency fallback (old on-box
build) if node-2 is unreachable. Rollback unchanged: `scripts/rollback-release.sh --production`.

## Admin

- Re-provision / refresh node-2 (idempotent): `scripts/buildhost/provision.sh` (ships the
  primary's exact Node toolchain to `/opt/nxeon-build/node`, re-applies slices, datasets, mirror,
  Postgres). Run it after upgrading Node on the primary — promotes refuse a version mismatch.
- Release build log on node-2: `/tank/nxeon-deploy/<env>/build.log`.
