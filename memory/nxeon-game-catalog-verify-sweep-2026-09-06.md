---
name: nxeon-game-catalog-verify-sweep-2026-09-06
description: "Background agent ran a real provision→verify→teardown sweep on 10/47 game families, found and shipped 8 real bugs incl. a security exposure and a same-day production regression; owner decisions pending, 32 families unswept, harness preserved"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-09-06T11:18:04.737Z
---

**Context**: owner asked to verify every game catalog provisioning end-to-end — not just connectivity,
but actually changing configs post-provision and confirming they take effect, since that's where past
customer issues actually came from. Launched as a background agent (task id `a6a056522a5720333`,
~6h runtime, 500 tool calls, 578k tokens). It provisioned each family for real on node-2, verified
external reachability, verified a real settings-apply round-trip, then tore down before moving on.

**Result: 10 of 47 families fully swept, 9 real bugs found, 8 shipped to prod same session.**
Verified independently (not just trusted the agent's own report): all 9 commit hashes exist in
`git log` on `/opt/nxeon`, HEAD matches the working tree with no stray changes from this work, prod's
`nxeon-web` last restarted (11:02 UTC) after the last of these commits landed (10:45 UTC), and
`REAL_APPLY_FAMILIES` in `worker/game-config.ts` is confirmed live as
`["palworld", "minecraft", "rust", "valheim"]`.

**The bugs, in the order they matter:**
1. **Security**: 8 game families (rust, ark, projectzomboid, etc.) auto-forwarded their RCON/admin
   port to the internet during the health-check step and never retracted it — and the underlying
   images ship default admin credentials (`docker`, `changeme12`) nothing ever overrides. Confirmed
   live off-box: a freshly provisioned Rust server's RCON answered a full `serverinfo` dump from
   outside. Fixed (`196e5c9`) by retracting the admin-port forward once the health-check that needed
   it is done — the platform's own RCON tooling tunnels over SSH and never needed the public forward
   at all. No customer was exposed (the one live Rust server predates auto-forwarding), but the next
   order of any of the 8 would have been.
2. **Same class, different angle** (`3be5383`): those same 8 families were handing customers their
   RCON port as the "join" address, not the actual game port — `GAME_PORT` was being used as both the
   health-check target and the customer-facing port, when it's only correct for the former. Same root
   cause the live customer `rust-w75hko` outage (found migrating that VM to node-2) turned out to be.
3. **Production regression from a *different*, concurrent Claude Code session** (`c59d9bc`, fixed by
   `b13b2ab`): a same-day commit sized new game VMs from the catalog's advertised numbers instead of
   `Math.max(gamePlan, basePlan)`. Correct for RAM/cores, but shrank disk on 116 of 121 plans and broke
   Project Zomboid within hours (`No space left on device` at 91.8% install, real customer impact).
   Caught because this sweep's own PZ provision hit the identical failure. This is the second time in
   one day this session's own audits caught a *different* concurrent session's regression before it
   spread further — see also [[nxeon-node1-cpu-and-devapp-relocation]] for the CPU-load side of the
   same day's concurrent-session activity.
4. Rust settings never applied (image builds its launch line from a different env-var scheme than the
   code assumed) — rewritten, verified by reading every field back off the live game via RCON
   (`66da137`). Valheim reported success while changing nothing — same shape, same fix (`206cc85`).
   Terraria could never provision at all (TShock's interactive world-selection prompt hung forever) —
   fixed with `WORLD_FILENAME` + `-autocreate` (`3c90f5d`). A 300s "big download" timeout was declaring
   healthy-but-slow installs as failed — replaced with an is-it-still-working probe (`08a16a1`+`d6fbb91`).
   vmid-skip reasons were misattributing 7 live customer VMs as orphaned backups (`7e49150`).

**RESOLVED, not an open item**: `projectzomboid-kc0kcr`'s RAM reduction (8192→6144MB) was NOT a
regression — owner confirmed (2026-09-06) it was the *correct* fix. Before `c59d9bc`, game orders
were provisioned at their linked `basePlan`'s full size instead of the advertised `gamePlan` size, so
this customer (and, per the owner, "a lot of other games") was silently *over*-delivered RAM relative
to what was actually sold — an unintended-generosity/margin bug, not a benefit owed to the customer.
`c59d9bc` correcting RAM/cores down to the advertised size was right; only its blanket application to
*disk* was wrong (games routinely need more disk than advertised, unlike RAM/cores apparently having
had slack). Owner's explicit instruction: leave this specific case and the broader
advertised-vs-actual RAM/cores discrepancy across the catalog alone for now — don't restore this
customer, don't launch a wider audit unprompted. Revisit only if asked.
- **CS2 is currently unsellable**: needs 66.2 GiB installed against plans offering 25–50GB, plus a
  root-owned bind-mount vs. uid-1000 container mismatch, plus an install too slow for any realistic
  health-check window. Fixing the tier/pricing is a pricing call, not a code fix.
- **No game's advertised disk size has ever been checked against real install requirements.** The
  `Math.max()` fix (bug #3) is a safety net, not a resolution — CS2 66.2 GiB / ARK 22.9 GB / PZ >15 GB
  measured so far, more unmeasured.
- Per-server **generated** RCON passwords (vs. relying on the port-retraction fix alone) is a real
  hardening feature to consider, not something this sweep built.
- 5 families have no `GamePlan` and cannot be ordered at all today: `schedule1` (deliberate),
  `plutoniumt4/t5/t6/iw5`.
- Postgres `max_connections=100` with 58 idle pooled connections observed across four app instances
  broke one of the sweep's own staging builds — a deploy-reliability hazard worth a look independent
  of the game catalog work.

**Not done**: 32 families never swept (sdtd, vrising, enshrouded, factorio, gmod, conan, unturned,
theforest, sonsoftheforest, bedrock, dragonwilds, sunkenland, abioticfactor, corekeeper, icarus,
arkasa, soulmask, dst, vintagestory, necesse, tf2, l4d2, nightingale, squad, spaceengineers, kf2,
barotrauma, sandstorm, mordhau, theisle, stationeers, eco, empyrion). Watch arkasa/ark/sdtd/conan/icarus
for the same disk-size question, and bedrock/conan/terraria/vrising for the mount-ownership question
bug #3's cousin might also apply to. The ~42 families (all but palworld/minecraft/rust/valheim) with no
`applyRealConfig` case still cannot have settings changed post-provision at all — unchanged, documented,
not part of this sweep's mandate to build.

**How to apply**: the harness is preserved at
`/tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/sweep/` — each remaining family is
one `bash sweep-one.sh <family>` away, so resuming doesn't need re-deriving the approach. Before
resuming, though, the owner-decision items above (especially CS2's tier and the disk-size audit) may
change what "verified" should even mean for the remaining families — worth checking with the owner
before just re-running the same procedure on the rest.
