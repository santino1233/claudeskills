# O: Cyrus AI mesh (meshgen) as a service (2026-10-10)

Branch `feature/cyrus-r18-meshgen` (worktree `/tank/dev-worktrees/cyrus-r18`). Flags OFF, not wired into the build service, no migration. Docs: `docs/DOCUMENTATION.md` "Cyrus AI mesh (meshgen)". Owner items: OWNER-ACTIONS.md "AI mesh / meshgen service".

## What was built
- `lib/cyrus/meshgen/`: Zod specs (rifle, crate, sword templates; hard-surface kit; scratch submission; job request with budget, estimate, usage), template registry with model-facing spec cards, deterministic router over the cost ladder (0 catalog stub, 1 template, 2 kit, 3 scratch), token/cost estimator (prices are owner settings; none configured = tokens only), budget resolution from a new optional `AssetProfile.meshBudget`, TS GLB parser, post-processing checks, static scan for scripts, manifest + per-job record, node-2 runner, worker loop, model-facing tool contract (types only).
- `blender/`: harness, geometry kit, rifle template + parts (ported from PoC K), NEW crate and sword templates, NEW 10-shape parts kit (rung 2), AST guard for rung 3, `sbx-meshgen.sh` (PoC sandbox plus tmpfs work dir, file-size limit, regular-files-only copy back).
- Small additive changes outside meshgen: `AssetProfile.meshBudget?` (+ validator), `JobQueue.claim({types?})`.

## Ran (real, node-2, 2026-10-10)
Raw: `meshgen-flights-2026-10-10.json`; renders/glbs: `blender-poc/meshgen/`.

| Flight | Rung | Verdict | Tris | Sandbox wall |
|---|---|---|---|---|
| rifle_ak (PoC spec) | template | accepted | 1,452 (same as PoC) | 26.4 s |
| rifle_drum_lmg | template | accepted | 2,128 | 25.8 s |
| crate_scifi | template | accepted | 2,544 | 27.4 s |
| crate_wooden | template | accepted | 2,376 | 29.2 s |
| sword_knight | template | accepted | 1,330 | 19.6 s |
| sword_katana_glow | template | accepted | 930 | 19.0 s |
| kit_terminal | kit | accepted | 524 | 24.0 s |
| crate_decimate (1,200 budget) | template | accepted, decimated 2,520 -> 1,158 | 1,158 | 31.7 s |
| scratch_lantern | scratch | accepted | 1,368 | 27.1 s |
| scratch_escape (TS scan bypassed) | scratch | rejected by in-sandbox guard (9 issues) | - | 2.7 s |

- Selftest: 16 variant cases (every enum value of every template + kit) build with 0 non-manifold edges; 4 bad-enum cases raise errors naming the allowed values. Khronos glTF validator: 0 errors, 0 warnings on all 9 glbs.
- Cycles rendering is 16-28 s of each run; geometry under 0.05 s. Blender tarball sha256 matches the published file.
- Tests: `cyrus-meshgen.test.ts` 29/29, `cyrus-meshgen-blender.test.ts` 3/3 (real), full Cyrus suite 1501/1502 after merging r2 (cyrus-admin flake passes 31/31 alone), tsc clean.

My judgement from the renders (not a blind rating): crate_scifi 7.5, lantern (scratch) 7, katana 7, knight sword 6.5, terminal (kit) 6.5, wooden crate 6, drum rifle 5 (the drum magazine reads as a wheel). The decimated crate looks the same as the full one at 46% of the triangles.

## Not run
- Any model call. Every spec and script is a hand-written fixture; token figures are estimates (template and scratch fit the PoC's measured ranges; kit is an assumption).
- Vision "look" step, LODs, normal/AO bakes, boolean union (meshes are closed shells that overlap), UV overlap check, in-engine load (FiveM, UE, three.js).
- Catalog rung against the real catalog (fake matcher only), build-service wiring, plan gate.
- ssh transport from the primary (flights used the local transport on node-2; ssh is unit-tested with a fake).
- Kernel-escape test of the sandbox; isolated (microVM/gVisor) worker; GPU worker.

## Decisions made here
- Catalog fit "unknown" never routes to rung 0; threshold 0.75.
- Template choice needs a keyword hit; category alone never selects a template; exclude words win ("revolver" never gets the rifle).
- Characters/creatures/likeness refused on every rung; organic shapes only on rung 3.
- A rejected mesh stores renders but never the glb or manifest. `outputs[0]` is always the record.
- Busy build host = not_run + job failed (resubmit), never a silent wait past the job timeout.
- Manifest `provenance.generator` (proposed in the plan) is not added (the manifest is strict and shared); the generator `ai-mesh` is in the record and the manifest note.

## Next
Paid eval (20+ prompts per rung), vision look step, isolated worker for rung 3, real game budgets, more templates (pistol/shotgun, furniture, axe/hammer), fix the drum magazine variant.
