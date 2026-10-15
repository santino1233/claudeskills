# CK: Minecraft: The Infinite Dungeon, staged portal run (2026-10-15)

STATUS: BLOCKED at stage 1 by the real `daily_cap` gate ("5,000 tokens a day"). Nothing was built, nothing charged. Not bypassed.

Account cmrztujaw0002hlazl58i3lsi, balance 11,877, reserved 0 (unchanged). The previous batch (BV note) used ~4.4k of the 5,000/day rolling window between ~18:00 and 19:19 UTC on 2026-10-14. Refused at 06:2x UTC 2026-10-15; the window should free from ~18:43 UTC 2026-10-15 (earliest builds age out first), or the owner raises the cap.

## Prepared (committed, branch feature/cyrus-dungeon-run, worktree /tank/dev-worktrees/cyrus-dungeon, commit 4d273085)
- scripts/cyrus/qa-dungeon.ts: planner (change-aware, coach hook) -> createModBuild(requirePlanAck, model auto, approved lanes, planAck). Stage 1 = fresh build; stages 2-6 and `--fix "text"` = REFINE via `{ baseBuildId, changeRequest }` on the last succeeded journal build (same body app/api/cyrus/generate sends for a refine; plan screen is POST /api/cyrus/plan with change:true). Waits for terminal + Test Flight, writes per-build records.
- scripts/cyrus/qa-dungeon-prompts.json: the 6 stage prompts in the owner's voice.
- Stage 1 plan lanes the planner chose: designBoss, designHud, config build; everything else skip (no creature/texture lane for the core).

## Tracker
1. [blocked] Stage 1 core: rerun after cap frees.
2. [todo] Stages 2-6 refines, one fix refine max per stage, stop on 2nd failure of same stage.
3. [todo] Spend cap 4,500 tokens: at ~400-600 tokens/build the 6 stages (~3,000) will not fit one 5,000/day window together with any other usage; plan on 2 days or a cap raise (>= ~9-10 builds/day per hold sizes).
4. [note] A stage refine of a growing mod will hold more than a small build; expect later stages above 600.

## Commands (owner/QA, from the worktree)
```
/tmp/claude-0/run.sh stage 1      # wrapper: sources /opt/nxeon/.env, NODE_PATH=/opt/nxeon/node_modules, tsx scripts/cyrus/qa-dungeon.ts ... --user cmrztujaw0002hlazl58i3lsi --out /root/cyrus-eval/dungeon-2026-10-15
/tmp/claude-0/run.sh stage 2 ... 6
/tmp/claude-0/run.sh stage 3 --fix "targeted fix text"   # only the one allowed repair refine
/tmp/claude-0/run.sh status
```
Install/try (once a stage succeeds): portal Cyrus library -> the mod -> install on server; in game `/dungeon start`, `/dungeon status`, `/dungeon leave` (or `/dungeon abandon`) returns to the overworld; config in plugins/<PluginName>/config.yml.

Honest outcome so far: no mod exists yet; the "what works / what does not" sections cannot be written.
