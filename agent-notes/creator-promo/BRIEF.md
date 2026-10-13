# Brief: Creator Promo video generator in the partner dashboard

The owner wants every partner to be able to generate their own sponsored-segment video (their code, language and game) from the partner dashboard. They supplied a complete handoff.

## Read first
1. `/tank/handoffs/promo/START-HERE.md`, then `/tank/handoffs/promo/HANDOFF-nxeon-app-integration.md`, all of it. That is your spec (render contract, Prisma model, `lib/promo.ts`, API routes, dashboard card, render worker, admin batch, acceptance checklist).
2. The template's own docs: `/tank/handoffs/promo/creator-promo/README.md`.
3. `/root/agent-notes/BUILD-HOST.md`. Follow it exactly.

## One deliberate change from the handoff: where renders run
The handoff defaults to a capped systemd render service on the same host as the app. On Nxeon that host (the primary) serves the live site and customer VMs. It hard-crashed on 2026-10-06 from CPU load, so **renders must NOT run on the primary**. Run the render worker on **node-2** (nxeon-fsn1, 178.63.94.114) instead, in its own capped systemd unit under node-2's existing `nxeon-build.slice` (or a sibling slice with similar caps: nice 19, CPUQuota 200-300%, MemoryMax 6G, oom_score_adj high). It must never compete with release builds; take the existing build lock or yield to it.

node-2 must not get production DB credentials. So instead of the worker querying `PromoRender` directly, design a **pull API** on the app:
- **Claim:** `POST /api/promo/worker/claim`, authenticated by a dedicated shared secret header (new env var, e.g. `PROMO_WORKER_SECRET`, never logged).
  - It atomically claims the oldest QUEUED render, using the handoff's updateMany claim pattern.
  - It returns `{ id, variables, formats }`.
- **Progress:** `POST /api/promo/worker/{id}/progress` with `{ step, progress }`.
- **Upload:** `PUT /api/promo/worker/{id}/file/{name}` streams one finished file into the app's `PROMO_RENDER_DIR` on the primary, with a size cap and a filename whitelist.
- **Result:** `POST /api/promo/worker/{id}/done` or `/fail` with `{ error }`. Retries follow the handoff's rules.
- **Stale work:** on worker boot, a RUNNING render older than N minutes goes back to QUEUED.

Everything else (the user-facing API, the partner card, the admin batch, the 6/day limit, 14-day retention, the languages en/es/tr/hi/tl) follows the handoff.

## Relationship to the media kit (built in parallel)
Another agent is adding per-creator media kits to the partner portal on branch `feature/partner-media-kits`: owner-uploaded videos per creator, under `/opt/nxeon/partner-files/kits/<CODE>/`, shown in the partner dashboard's media kit tab. That branch is now MERGED into main and LIVE (commit f49d2c996d). Start your worktree from main, so your partner-dashboard card sits next to it and they share styling:
`git -C /opt/nxeon worktree add /tank/dev-worktrees/creator-promo -b feature/creator-promo main`

Generated renders appear next to the owner-uploaded kit, under a clear heading like "Make your own version". Read components/nx/PartnerMediaKit.tsx and lib/partner-kits.ts first and reuse their patterns (auth, file serving with Range, styling).

## Verify (the handoff asks for a real rendered video)
- Build and test on node-2 with your throwaway DB (devhost).
- Install HyperFrames' Chrome and ffmpeg on node-2 inside your worktree/user scope if possible. Ask before installing system packages; note it in the report if you can't.
- Run one real 16:9 render end to end through the pull API against your dev server: claim, render, upload, done. Show the result:
  - an end-frame PNG,
  - a few frames extracted with ffmpeg,
  - the measured render time under the cap.
- Partner card screenshots (idle, rendering with progress, done with downloads, the daily limit reached) and the admin batch, at 1440 + 390, dark + light. Use the real server-rendered route, not a client-only harness.
- Save everything to `/root/agent-notes/creator-promo/shots/` with `devhost pull`.
- `devhost tsc` must be clean. Run `npx hyperframes check` with 0 errors.

## Hard rules
- Explicit `git add <paths>` only; never `-A` or `.`. Don't commit renders, Chrome or node_modules.
- No production deploy, no merge to main, no production DB, no emails sent, no systemd units installed on node-2 permanently without saying so in your report. A dev-time unit you stop afterwards is fine.
- Never run role/ownership SQL. Never pkill or killall by pattern. Never touch customer VMs on node-2 (`qm`, `qemu.slice`).
- Keep node-2 agent memory low: two other agents may be running. Stop your dev server and any render processes when done.
- If the permission system denies something, don't work around it. Note it and continue.
- Brand voice: Nxeon speaks as itself; never mention third-party infrastructure.

## Deliverable
Commits on `feature/creator-promo`, the evidence above, and a short report:
- How to run the render worker on node-2 in production (exact unit file + env).
- Measured render times.
- What the owner must decide (the handoff's §7 list, answered with recommendations).
