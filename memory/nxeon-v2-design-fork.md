---
name: nxeon-v2-design-fork
description: /opt/nxeon-v2 on port 3021 — the Nexion design fork; it now LIVES on node-2 and carries its own CLAUDE.md + handover doc
metadata: 
  node_type: memory
  type: project
  originSessionId: 2aa2dcca-a502-4055-9d89-9bae0c754838
  modified: 2026-09-11T06:23:32.115Z
---

`/opt/nxeon-v2` (branch `design/v2`, port 3021, https://v2.q4w8zt3ky6vn2sm.nxeon.cloud)
is a clone of the real Nxeon codebase where the Nexion design is built, so no
restructure is needed at migration time. Isolated: own DB `nxeon_v2`,
`NXEON_SANDBOX=1`, Proxmox/Stripe/registrar/SMTP pointed at dead endpoints.

**It runs on node-2 (`nxeon-fsn1`, 178.63.94.114), and that is where the work
belongs now.** As of 2026-09-11 the tree carries its own `CLAUDE.md` (operating
manual: which box you're on, the build command, non-negotiable rules, the traps)
and `docs/NEXION-V2.md` (direction, what's built, what's open). **Read those
first — they are more current than this memory.** Production's inherited
CLAUDE.md is preserved at `docs/CLAUDE-production-inherited.md`; it describes the
primary node and following it from this tree would hit live production.

**Never build on the primary node.** It is 8 cores at load ~11 running the
customer game-server VMs. The old loop built twice per deploy — once on the
primary to verify, once on node-2 to ship. From the primary use
`scripts/deploy-node2.sh` (ships the commit, typechecks + builds on node-2, and
refuses a dirty tree or a divergent remote). On node-2 just `./rebuild.sh`.
Only one box can be the source of truth at a time: the deploy does
`git reset --hard`, so once work moves to node-2 the primary's copy is stale.

Login: `admin@nxeon.local`, password in `/root/nxeon-v2-credentials.txt` (mode 600,
present on BOTH boxes). NOT `/root/nxeon-sandbox-credentials.txt` — that belongs to
`/opt/nxeon-sandbox`, a different session's tree, and the v2 seed clobbered it once
on 2026-09-05.

Node-2 runs a PRODUCTION build via `rebuild.sh` (~125s), not `npm run dev`:
~0.8 GB instead of ~4.5 GB on a box measured against customer VMs. Nothing
hot-reloads, so every change needs a rebuild. It skips the marketing site by
default (`NX_FULL=1` to include it). Screenshot harness is `scripts/shot.mjs`
(committed, logs in and captures full-page PNGs).

**How the design port is structured** (commit `cfd552f`), two layers:
1. **Tokens** — `app/globals.css`. Slot NAMES (`brand-*`, `navy-*`, `accent-*`,
   stock `slate-*`) are KEPT and only their VALUES repointed to Nexion, which
   reskins ~390 files without editing them. The Nexion component layer is appended
   AFTER the original so its recipes win on shared class names. `.label` renamed
   `.nx-label` (the original is a form label).
2. **Per-screen** — `components/nx/` (+ assets in `public/nx/`), pages split into a
   server half owning queries/money maths and a client view owning layout.

**Why the split matters:** any figure a page shows must keep coming from the real
lib function (e.g. monthly spend via `renewalCharge`), never re-derived in the view.

Related: [[nexion-ui-sandbox]] (the no-backend design sandbox on 3020, still the
source of the components), [[nexion-design-canvas]], [[nxeon-build-isolation]],
[[nxeon-node1-cpu-and-devapp-relocation]].
