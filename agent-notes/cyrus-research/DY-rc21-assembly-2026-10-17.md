# DY - rc21 assembly (2026-10-17)

Branch `release/cyrus-rc21`, worktree `/tank/dev-worktrees/cyrus-int8`, from main = release/cyrus-rc20 = bc678074 (live;
modbuilder:0.25 live). **Head: 1b4eba93.** Nothing pushed, deployed, promoted or applied; /opt/nxeon working tree, DNS,
nginx and production data untouched. Commits made with `git -c core.hooksPath=/dev/null` (the plain `git merge` for merge 1
runs no post-commit hook; its message was then amended with hooks off). Owner script: `ship-rc21.sh` (`bash -n` OK), plus
`rc21-image-cli-smoke.sh` (`bash -n` OK; its message generator was run locally: valid 16x16 PNG, no paid call).

## 1. Merges (one `--no-ff` commit each, in order)
| # | Commit | Branch (head) | Conflicts / resolution |
|---|---|---|---|
| 1 | 818bee9b | fix/cyrus-preserve-config-defaults (33b09353) | clean (38 files) |
| 2 | b600f1f7 | feature/cyrus-room-studio-image (d60ef5f1) | docs only, see below |
| - | 1b4eba93 | docs-build regeneration | - |

Merge 2 conflicts: `docs/DOCUMENTATION.md` keep-both (both 2026-10-17 entries); generated `docs/cyrus/reference/
build-service.md` and `tests.md` taken from HEAD and regenerated. `services/modbuilder/server.js` auto-merged (image branch:
run() stdin, ROOM_JOBS guard deps, /health roomStudio.images, /rooms body limit; fix branch: keepDefaultsStep) - reviewed.
Overlap checks:
- prompts.js: only the fix branch changed it -> **PROMPT_VERSION mb-2026-10-17.1** (rc20 had 10-16.2; the image branch did
  not touch prompts.js, its own versions are `roomimage-1` and `imageguard-2026-10-17.1`). test/modbuilder-efficiency pins
  10-17.1; failure-rules / golden files do not pin the prompt version. preserve `pv-2026-10-17.1`.
- Dockerfile: no new service files in either branch (preserve.js, configs.js, roomstudio.js, route.js, room-studio.js are
  already COPYed); test/modbuilder-dockerfile passes.
- placeholder-keys.json: `cyrus_tok_room_studio_image_hold` already listed by the image branch (43 keys); cyrus-launch-check passes.
- authz table: image branch change auto-merged.
- flag-notes.json: MB_ROOM_IMAGE_GUARD / MB_ROOM_CRITIQUE / MB_ROOM_CRITIQUE_MIN_USD present (image branch).
- features.json (in merge 2): new entry "Room Studio image input (image-to-room)" (flags CYRUS_ROOM_STUDIO + the three MB_),
  wiring-recovery and Room Studio entries -> "merged to main (rc20, live; modbuilder:0.25)", refine-guard entry notes the
  rc21 keepDefaults step.

## 2. Generated references (node-2 via devhost)
docs-build: 5 stale (flags-and-env, feature-map, documentation-index, tests, build-service) -> regenerated, `devhost pull`
each, local diff confirmed (+152/-150), committed; `--check` exit 0 after. mc-coverage, cyrus-api and nxeon-platform
gen-openapi `--check`: up to date.

## 3. Verification (tree 1b4eba93; node-2 PSI avg10 0.00 before every run)
- tsc: first attempt OOM (NODE_OPTIONS passed on the primary side is NOT forwarded by devhost); after
  `scripts/devhost env set NODE_OPTIONS=--max-old-space-size=10240`: **exit 0**.
- rc20 suite list (`test/modbuilder*` + `test/cyrus*` = 267 files, + conversion-funnel, list-guard, email-rollout,
  email-templates-overhaul, server-deployed-email, critical-email-retry, filemanager-guards, filemanager-jail, upload-paths,
  ticket-reply-errors, cfg-projectzomboid, zomboid-admin, game-power-start): **5024 tests, 5023 pass, 0 fail, 1 skipped**.
- Whole repo `test/*.test.ts`: **9018 tests, 8868 pass, 53 fail, 97 skipped**. Failing files = exactly rc20's 25-file list
  (DX section 4: admin-*, auth-lockouts, billing-terms, checkout-*, proration, purchase-consent, promo-race, ...) plus
  node-agent-cpu-affinity (a known full-run contention flake on main; isolated on rc21: 7/7 pass). Baseline = the rc20 run
  on bc678074 (52 fail), which is the same tree as main. **No rc21-only failure.**
- Not run: any paid model call (image path, keepDefaults on a real refine), Test Flights.

## 4. Other branches (`for-each-ref refs/heads/feature/cyrus-* refs/heads/fix/*`, not in rc21)
Same known list: feature/cyrus-v6-library, -v6-game-rust, -v6-game-palworld (10-08), fix/terraria-listener (10-05),
fix/vps-ram-allocation (09-28), fix/game-config-envkey-audit (09-24). No branch in refs/heads with a commit since
2026-10-16 is missing from rc21. Nothing merged beyond the two.

## 5. Deploy facts (ship-rc21.sh)
- No new manual SQL vs rc20; prisma/schema.prisma, deploy/, apps/cyrus-site/, Dockerfile, deploy-modbuilder.sh unchanged.
  The script still diffs and would apply additive files in one transaction per DB.
- modbuilder image required. Build VM tags up to 0.25 (live, container `modbuilder`, CLI 2.1.241) -> script picks **0.26**;
  /health checks: promptVersion mb-2026-10-17.1, preserve pv-2026-10-17.1, roomStudio.images roomimage-1, image guard version.
- Staging and production both run bc678074. Promote BUILD_MAX_MIN=45, wait_node2, prompt before each production step.

## 6. Owner-only
1. Image CLI check after deploy: `bash /root/claudeskills/agent-notes/cyrus-research/rc21-image-cli-smoke.sh` (one Haiku
   call, 16x16 red PNG as base64 stream-json on stdin of `docker exec -i modbuilder claude -p --input-format stream-json ...`,
   `--max-budget-usd 0.05`, about 0.2 US cents; PASS = clean result naming "red"). The live CLI lists `--input-format`
   (checked, free). No real image call has been made yet.
2. `cyrus_tok_room_studio_image_hold` PLACEHOLDER 45 (extra hold for image jobs, on top of `cyrus_tok_room_studio_hold` 60).
3. `CYRUS_ROOM_STUDIO` (default OFF) - image input lives behind it; staging first.
4. Service flags MB_ROOM_IMAGE_GUARD (on, fail closed; keep on), MB_ROOM_CRITIQUE (on), MB_ROOM_CRITIQUE_MIN_USD (0.15).
5. Privacy line wording in the studio (images never stored or logged).
Plus rc20 carry-overs (upload store, KEEP_PROMPTS, Litematica test) and rc19 ones (DM, DK, Google secret, DQ, public
switches, DS, DP, DN).
