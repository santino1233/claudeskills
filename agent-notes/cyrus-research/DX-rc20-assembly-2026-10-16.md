# DX - rc20 assembly (2026-10-16)

Branch `release/cyrus-rc20`, worktree `/tank/dev-worktrees/cyrus-int7`, from main = release/cyrus-rc19 = 45ab0502 (live).
**Head: bc678074.** Nothing pushed, deployed, promoted or applied; /opt/nxeon, DNS, nginx and production data untouched.
Every commit made with `git -c core.hooksPath=/dev/null`. Owner script: `ship-rc20.sh` (same directory; `bash -n` OK).

## 1. Merges (one `--no-ff` commit each, in order)
| # | Commit | Branch (head) | Conflicts / resolution |
|---|---|---|---|
| 1 | a5d770a4 | fix/cyrus-creature-wiring-recovery (984615ac) | clean (37 files) |
| 2 | ad93bde0 | feature/cyrus-room-studio (2fafa81a; contains feature/cyrus-structures d67a623f) | see below |

Then bd3f0ca6 regenerated docs references, bc678074 one suite fix.

Conflicts in merge 2 (both branches forked from 45ab0502):
- `services/modbuilder/Dockerfile`: COPY union = rc19 list + `wiring.js` + `rooms.js roomspecs.js roomstudio.js room-studio.js`
  (test/modbuilder-dockerfile passes; deploy-modbuilder.sh derives its file list from the Dockerfile).
- `services/modbuilder/prompts.js`: systemPrompt keeps the structures/rooms sections AND the wiring branch's
  `opts.creatureCode ? EXISTING_CREATURES_SECTION`; exports union. **PROMPT_VERSION `mb-2026-10-16.2`** (wiring had 10-16.1,
  room-studio kept 10-15.1 although it added prompt sections) - strictly newer than both; test/modbuilder-efficiency pin,
  docs/cyrus/25-build-service.md and 27-training-and-knowledge.md tables updated. failure-rules.json (rules-2026-10-15.1) and
  the techniques/boss-model versions unchanged; nothing else pins the prompt version.
- `services/modbuilder/server.js`: both helper blocks (creatureCp/usesCreatureApi + ROOM_PROMPT_VERSION/rmOn); callClaude keeps
  the wiring branch's per-call `turns`/`budgetUsd` caps + `creatureCode` and adds room-studio's `structures` / `rooms` opts.
- Docs keep-both: DOCUMENTATION.md, `_data/features.json` (both entries; states set to "merged in release/cyrus-rc20, not
  deployed"; the refine-guard entry to "merged to main (rc19, live; modbuilder:0.24)"); generated references regenerated.
- Auto-merged without conflict: lib/cyrus/admin/flags.ts, host/types.ts, authz table, coverage json, golden results.json.

## 2. Generated references (node-2 via devhost)
`tools/cyrus-api/gen-openapi.ts`, `tools/nxeon-platform/gen-openapi.ts`, `scripts/cyrus/mc-coverage.ts`: `--check` exit 0 (no change).
`scripts/cyrus/docs-build.ts`: 5 pages stale (flags-and-env, feature-map, documentation-index, tests, build-service) ->
regenerated, pulled with `devhost pull`, local diff confirmed (+143/-280), committed; `--check` exit 0 after.
Golden `mc-structure-rooms`: results.json row (line ~1342) and minecraft-coverage.json rows present; flights NOT rerun.

## 3. Fix found by verification (root cause) - bc678074
`test/cyrus-launch-check` "placeholder-keys.json is exactly the catalog's PLACEHOLDER-marked settings": room-studio added the
PLACEHOLDER setting `cyrus_tok_room_studio_hold` (config-pure.ts, 60) but not to `scripts/cyrus/lib/placeholder-keys.json`, so
launch-check would not list the undecided price. Added it (42 keys). Red on the room-studio branch itself.

## 4. Verification (tree bc678074; NODE_OPTIONS=--max-old-space-size=10240 via devhost env; node-2 PSI avg10 0.00 each time)
- `scripts/devhost tsc`: **exit 0**.
- Suites `test/modbuilder*.test.ts test/cyrus*.test.ts` (265 files) + conversion-funnel, list-guard, email-rollout,
  email-templates-overhaul, server-deployed-email, critical-email-retry, filemanager-guards, filemanager-jail, upload-paths,
  ticket-reply-errors, cfg-projectzomboid, zomboid-admin, game-power-start: **4986 tests, 4985 pass, 0 fail, 1 skipped**
  (nginx -t). First run (before bc678074): 4984 pass, 1 fail (the one above).
- Whole repo `test/*.test.ts` (612 files), one run each:
  - rc20: 8980 tests, 8831 pass, **52 fail**, 97 skipped.
  - main 45ab0502 (temp worktree cyrus-int7-main): 8866 tests, 8706 pass, 54 fail, 9 cancelled, 97 skipped.
  - Failing files in rc20 (all also failing on main): admin-actions-guards, admin-console-guards (2), admin-destructive-controls,
    admin-server-360, api-http-surface, auth-lockouts (4), billing-terms (4), checkout-fulfilment, checkout-metadata,
    customer-actions-guards, dedicated-release-pure, hosting, invoice-number, invoice-renewal, ip-fleet-alerts, light-theme,
    offers-pricing, portal-ui-audit (2), pricing-display-vs-charge (3), promo-race (3), proration (9), purchase-consent (9),
    registrar-leak-guard, terraria-mirror.
  - Extra on main only (load/contention flakes in the full run): admin-fleet, ai-agents-page, modbuilder-preflight-pipeline
    (10 cancelled), node-agent-cpu-affinity; admin-console-guards crashed at load on main's full run.
  - Isolated runs, main vs rc20 identical: admin-console-guards 16/18 (2 fail: app/admin/page.tsx REVENUE_WHERE / MRR helper),
    proration 19/28, billing-terms 4/8; admin-fleet 16/16, ai-agents-page 10/10, modbuilder-preflight-pipeline 9/9,
    node-agent-cpu-affinity 7/7 on both. **No rc20-only failure.**
- Not run: real Test Flights (mc-structure-rooms already flown), paid-model Room Studio run, real-client Litematica load,
  cyrus-nxeon-integration-real.
- Temp worktree + node-2 workspace cyrus-int7-main removed; node-2 workspace cyrus-int7 kept.

## 5. Other branches (`for-each-ref feature/cyrus-* fix/*`, not ancestors of rc20)
Same list as rc19: feature/cyrus-v6-library, -v6-game-rust, -v6-game-palworld (WIP 10-08), fix/terraria-listener (10-05),
fix/vps-ram-allocation (09-28), fix/game-config-envkey-audit (09-24). No branch in refs/heads with a commit since 2026-10-15
is missing from rc20. Nothing merged beyond the two.

## 6. Deploy facts (ship-rc20.sh)
- No new manual SQL vs rc19 (prisma/manual-migrations unchanged; schema.prisma = one comment). Script still diffs and would
  apply additive files in one transaction per DB (refuses DROP/TRUNCATE/DELETE/UPDATE/RENAME/ALTER TYPE).
- modbuilder image required: wiring.js, rooms.js, roomspecs.js, roomstudio.js, room-studio.js, prompts 10-16.2. Build VM tags
  0.23, 0.24 (live) -> script picks **0.25**; it checks /health for promptVersion mb-2026-10-16.2, features.rooms, roomStudio.
- Service defaults: MB_WIRING_RESTORE on, MB_ROOMS on, MB_ROOM_STUDIO on (portal flags decide use).
- Precondition: main == release/cyrus-rc19 exactly. Staging currently runs 45ab0502. Promote BUILD_MAX_MIN=45, wait_node2.
- No nginx / landing step this time (deploy/ and apps/cyrus-site/ unchanged).

## 7. Owner-only
1. `CYRUS_ROOM_STUDIO` (env, default OFF): studio page /dashboard/cyrus/<id>/studio/rooms, API /api/cyrus/assets/v1/rooms*,
   build lane assets.room, token holds. No paid-model run yet; try on staging first.
2. `cyrus_tok_room_studio_hold` PLACEHOLDER 60 (Saka; Katara x0.45, Yakko x2.75), settles at measured cost.
3. Upload store (shared with PNG uploads): `lib/cyrus/studios/deps.ts` builds one only for `CYRUS_UPLOAD_STORE=local` with
   NODE_ENV != production (`CYRUS_UPLOAD_DIR`, default .data/cyrus-uploads). Production: PNG uploads, room uploads and
   /rooms/save -> 503 uploads_off. Options: (a) keep off; (b) allow local in production (code change: lift the NODE_ENV guard
   or a new value) with CYRUS_UPLOAD_DIR on persistent backed-up storage outside release dirs; (c) object-store adapter.
4. `CYRUS_ROOM_STUDIO_KEEP_PROMPTS` (default OFF = hash + length, D-60).
5. Litematica load test of the .litematic export (v6) in a real client.
Plus the rc19 carry-overs (DM, DK, Google secret, DQ, public switches, DS, DP cleanup, DN).
