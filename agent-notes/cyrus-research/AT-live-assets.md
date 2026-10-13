# AT - Cyrus live asset streaming (r48, 2026-10-11)
Branch `feature/cyrus-r48-liveassets` (worktree `/tank/dev-worktrees/cyrus-r48`, latest r2 `5cbdeb0389` merged in: `6a2ab2c02a`). NOT merged, NOT deployed, `CYRUS_LIVE_ASSETS` off in both envs, no migration, no paid call.

## Commits
1. `b2f4e37254` service: `services/modbuilder/liveassets.js` classifies asset spec paths by kind. The spec being written rides the existing draft protocol (`/live?assets=1`, Writes only, 64 KB cap). Finished writes, verdicts (problems / validated / dropped), library picks and `built` go into a 240-event ring and a stored timeline (160 events / 384 KB). Without `assets=1` the answer is byte-identical. The Dockerfile copies the new file.
2. `fd6bc150c1` portal: partial-JSON reader, seq-ordered live state, interpreters that pass only validated, capped specs to the pure renderers. `follow.ts` adds GenEvent `asset`. New replay route.
3. `61010c1084` UX: split / stacked / phone-strip layouts, tabs, auto-focus, Pin, honest labels, gallery, Replay, reduced motion, pause offscreen, low-end caps.
4. `94a1166f08` tests + fixes from the shots (sound layers overlapped, duplicate names, tab scroll, preset tracks while drafting, footnote hidden under the dock).
5. `bc8ef2afbc` docs: DOCUMENTATION section, docs/cyrus 06/11/12, flag notes, references regenerated.

## Ran (node-2)
- `tsc` clean. New `cyrus-liveassets` 17/17 and `cyrus-liveassets-e2e` 8/8. The e2e runs the real service with a hand-written fake CLI streaming 12 spec files. It checks: drafts arrive before complete, then verdicts, then built; nothing outside assets/ leaks; plain `/live` is unchanged; the replay matches; flag off records nothing.
- After the r2 merge: `tsc` clean, full Cyrus + modbuilder suite **2639/2639**. That includes the host-seam, db-split and docs-current checks.
- 22 shots in `cyrus-designs/impl-shots/live-*.png`: a mid-stream frame per kind on desktop and phone, the gallery, the narrow panel and reduced motion. They replay the recorded real-service stream into the real build screen through a dev-only hook. I looked at them and fixed what they showed.

## Not run / gaps
- No real model stream, no build VM, no `next build`. The shots inject a recording; they do not show a live forge.
- WebGL was off for the shots (node-2 load stalled screenshots of the stage canvas).
- AI mesh rounds: renderer only, because meshgen runs outside builds.
- Creature preview is rest pose (no bone rotations). Sound preview plays synth layers only.
- In the expanded panel the floating dock/trace covers the bottom of both columns. This is pre-existing.

Owner list: OWNER-ACTIONS "r48".
