# I: Headless Blender code-modelling PoC (Cyrus L4 route a)

Run 2026-10-10 on node-2, workspace `/tank/nxeon-build/tmp/blender-poc/`. One agent, no sub-agents, no paid APIs. Sources in `blender-poc/src/` (harness.py, sbx.sh logic, prop scripts per round). Renders and glbs in `/root/agent-notes/cyrus-research/blender-poc/` (glbs in `out/`).

## Setup (VERIFIED)
- Blender **5.2.2 LTS** (current LTS per blender.org/download/lts) portable tarball, sha256 `84098912...a168` matched the file published at download.blender.org. Never installed system-wide.
- Run only as `blender --background --factory-startup --python harness.py -- prop.py name`.
- Sandbox: a transient systemd unit in `nxeon-build-agents.slice` holding the node-2 build lock (same properties as run-capped.sh plus extras). I called systemd-run directly because `devhost` insists on a git worktree of the repo, which would have changed the repo.
- Extras: `PrivateNetwork=yes` (no network), User=nobody, `ProtectSystem=strict`, `/opt /tank /var/lib /mnt` replaced by empty tmpfs apart from the Blender dir (read-only) and a work dir, MemoryMax 4G, CPUQuota 400%, TasksMax 256, RuntimeMax, no capabilities, NoNewPrivileges.
- Renderer: Cycles CPU, 32 spp, denoise, 640x480 (crate) / 768x480 (rifle), 3 views + contact sheet. EEVEE not tried (no GPU). Three.js/Playwright render of the glb: **not done (UNVERIFIED)**; glb checked via Blender re-import and Khronos gltf-validator instead.
- Harness prelude (`mat`, `box`, `cyl`, `prism`, join-by-material, smart_project, export, render) is fixed code I wrote once. It is effectively a tiny parts kit, so per-prop scripts are shorter than a cold start would be.

## Results per prop
| | Crate (A) | Rifle (B) |
|---|---|---|
| Rounds used | 3 of 6 | 4 of 6 |
| Wall per round | 26-28 s (render ~21 s inside Blender, rest ssh/scp) | 26 s |
| Triangles (final) | 6,720 | 2,732 |
| Objects after join by material | 5 (64 before) | 3 |
| Per-object non-manifold edges (bmesh) | 0 | 0 |
| UV present | yes, all objects (smart_project) | yes |
| glb valid | validator: 0 errors, 0 warnings; Blender re-import tri count equal | same |
| glb size | 476 KB | 187 KB |
| Quality vs intent | **7.5/10** | **6.5/10** |
| Est. tokens | ~15k (UNVERIFIED, from session counter) | ~20k |

Quality is my own judgement from the renders. The crate reads as a sci-fi supply crate: panels, ribs, chunky corner caps, latches, end handles, glowing strip. The rifle is recognisably AK-pattern in side, 3/4 and top views: curved magazine, slanted grip, gas tube, wood furniture, muzzle brake, front sight. It looks stylised-blocky and flat-shaded with no wear or textures.

## Round log (renders: `<prop>-r<N>-<3q|side|back|top>.png`, sheet `<prop>-r<N>-sheet.png`)
| Round | What changed |
|---|---|
| crate-r1 | First script. Pale and overexposed; read as a filing cabinet; glow strip hidden behind a panel. |
| crate-r2 | Darker palette, chunky corner caps, ribbed panels, yellow label, glow moved in front of the panel, handles moved up. Reads as a crate. |
| crate-r3 (final) | Darker lid, saturated glow, lid ribs, join by material, exposure -0.9. (The exposure change reached node-2 only for r3; r1 and r2 were rendered at exposure 0 because my sync script forgot harness.py.) |
| rifle-r1 | First script. Already recognisable; mag thin, wood pale, trigger guard a full ring. |
| rifle-r2 | Darker wood, U-shaped trigger guard, fatter mag and grip, butt plate, trunnion. |
| rifle-r3 | Added cover ribs and handguard grooves. The cover ribs looked like a rail comb (a regression). |
| rifle-r4 (final) | Removed cover ribs, kept grooves. |
Final sheets: `crate-final-sheet.png`, `rifle-final-sheet.png`.

## What failed or was weak (VERIFIED from renders)
- First attempts have wrong proportions, colours and exposure. Most gains came from looking at the picture (hidden glow strip, regression from the cover ribs); the numeric checks alone caught none of them.
- "Manifold" is per closed shell. Parts overlap and are not boolean-unioned, so the mesh is not one watertight solid. Interior faces are wasted triangles.
- Rifle details are cuboid and cylinder primitives. Organic curves (stock, grip) are crude. Texturing is flat colours only; no normal bake or LOD was attempted.
- 1 m scale holds (bbox 1.03 m rifle; crate 1.14 x 0.70 x 0.65 m including handles and feet).

## Safety (sandbox probes VERIFIED)
A model-written script runs full Python inside Blender: `os`, `subprocess`, `socket`, file access, `bpy.ops.wm.url_open`.
| Probe | Result in sandbox |
|---|---|
| connect to 1.1.1.1, DNS, curl subprocess | blocked (no network namespace) |
| read /root, /etc/shadow, other pids' environ | permission denied |
| list /opt, /etc/nxeon-build, /var/lib, /home | empty |
| write /etc, /usr, /tank | read-only filesystem |
| write to work dir; run `id` | allowed; uid 65534 |
| `while True`, 100 MB allocation loop, fork bomb | killed at the timeout; killed by OOM in 4 s; contained by TasksMax and timeout. No units left behind. |
Not verified: kernel-exploit escapes (a systemd unit is not a VM). The real worker needs a stronger boundary (gVisor, microVM, or an allow-list that rejects `import os/subprocess/socket` before running) plus the same no-network and cap properties. Pre-run static rejection and the sandbox should both be used.

## Cost
About 5k tokens per round (script 1.5-2.5k output, image read ~2k, stats 0.5k), 3-4 rounds, so roughly 15-20k tokens per finished prop here with a fixed prelude. A cold start without the prelude, or props 3-5x more complex, would be higher; I did not measure that. Compute is about 25 s of 4 CPU threads per round. A customer price must cover: tokens x rounds (and retries that end in rejection), CPU seconds, human fix time, and the risk of failed or rejected jobs. I cannot back a dollar figure without current token pricing and failure rates.

## Recommendation
- **GO for the code-modelling route for stylised hard-surface props** (crates, lanterns, simplified guns) as a "draft for a human to fix". Not a GO for hero or realistic assets, organic shapes, or likeness.
- A **parts kit** (bevelled box, panel, handle, cylinder, curved-profile prism, join and UV, material presets, camera and light rig) would cut tokens per round, lock scale and conventions, and make failures less likely. Add a union-then-cleanup pass so the output is closer to one watertight mesh.
- Measure next: (1) 20+ varied prompts, success rate at <=4 rounds, tokens per success; (2) a vision-model "look" step instead of me, and how often it catches regressions like rifle-r3; (3) boolean union, decimate to `meshBudget`, LOD and bake time; (4) in-engine load (three.js/FiveM) and texture quality; (5) the stronger sandbox; (6) a blind rating of "not cheap" by the owner.
