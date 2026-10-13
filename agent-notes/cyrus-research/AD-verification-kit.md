# AD: Verification readiness (r33, 2026-10-11)

Branch `feature/cyrus-r33-verify2` (worktree `/tank/dev-worktrees/cyrus-r33`), with the latest r2 merged in. Nothing deployed, no flag on, no paid call.

## 1. Eval harness (commit 5fea10aa9d): DONE, tested with a fake CLI only
- The eval set grew from 124 to 178 prompts. The new `sets/studio.jsonl` holds 19 texture, 15 sound and 20 designer prompts.
- The lanes now cover the recommended first run: 30 texture, 20 sound, 20 designer and 20 plain prompts, 90 builds on 1.21.11.
- One command: `scripts/cyrus/eval-run.ts`. It can do a dry run, use presets or lanes, pick versions (26.x is skipped until buildable), set a budget cap, resume after an interruption, run Test Flight, and write `baseline.json` + `report.md`.
- Scored per stage (compile, scan, refused, assets, quality, boot, playtest); cost recorded per build.
- First run estimate (`lib/cyrus/estimate.ts`): **$9.73-$22.23 on saka** and $16.93-$38.18 on yakko.
- **Not measured:** asset and designer builds may cost more than the estimate says. The estimator is anchored on plain builds only.
- **Tested** end to end through the real `server.js` with a fake CLI: plain, texture, sound and designer builds, a fake Test Flight, the budget stop and resume.
- **Not run:** any paid build. I also have not checked whether VM 88001's image accepts `tier`/`assets` (the runbook still has the image rebuild pending).

## 2. Real-client test day (commit 17fe7d5c29): kit built and the server boots; no client has tested it yet
- Built from fixtures, no model calls: per-version packs (texture, pistol states, ffmpeg-rendered sounds, HUD fonts) and 4 designer showcase plugins compiled with the pinned JDK.
- It ships a CHECKLIST.md with 20 steps and the exact commands, plus a `results.json` form.
- `ingest` flips `resourcePackClientVerified` only from recorded passes on a client of exactly that version.
- **RAN (node-2):** the kit built for 1.21.1-1.21.11. Plugins compile for 1.21.4 and later; 1.21.1 lacks an API classpath, as the kit reports. A throwaway Paper 1.21.11 server booted on 127.0.0.1 with all 4 plugins enabled. The pack was served with a matching sha1. Stopped afterwards.
- **Fixed along the way:** flat-world config, non-BMP glyph escapes, Vault dependency (emerald costs).
- **Unverified:** whether the commands are accepted in a real client.

## 3. Pass-rate page + evidence badges (commit 9eaa03d4ab): DONE, flag off
- `/mods/cyrus/pass-rates` uses only an accepted real baseline, Test Flight gate records (a rate per version only from 10 flights) and client-verify evidence. Otherwise it shows an honest empty state.
- `evidenceBadges()` is built but not yet placed on mod pages.
- Shots are in `cyrus-designs/impl-shots/passrate-{empty,sample}-{dark,light,phone}.png`. The sample shots use dev-only data, labelled as such.
- Marketing is dark-only, so light looks the same. A 15 px phone overflow comes from the shared site header (it also appears on /pricing).

## 4. Docs
DOCUMENTATION.md "Cyrus verification readiness", runbook row 6.11 + "Verification jobs", OWNER-ACTIONS "Verification readiness", tracker section 13.

Owner: choose the eval budget, then run the test day (see OWNER-ACTIONS).
