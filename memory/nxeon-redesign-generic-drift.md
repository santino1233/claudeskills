---
name: nxeon-redesign-generic-drift
description: Redesign/mockup-matching work goes generic unless working from the literal reference file with real iterative screenshot comparison
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-26T18:58:07.153Z
---

When asked to redesign something to match a provided mockup, the output repeatedly came back "generic" / "nothing like what you generated" — burning the user's tokens on rejected rounds (Singapore hero v4, v5, and the first pass at the network map before it was scoped down and redone carefully).

**Root cause, confirmed by comparing the failures to the one clean success:** the generic outcomes all happened when working from a *description* of the mockup (my own recollection, a text summary, or a mismatched/wrong screenshot) instead of the actual image file. The one case that converged well — [[nxeon-figma-design-system]]'s standalone `SingaporeNetworkMap` component — worked because the agent `Read` the real reference image directly and ran an honest build → screenshot → compare-side-by-side → adjust loop for 4 full rounds before stopping.

**Why:** without a literal image to check against, generation defaults toward the same handful of generic AI-design patterns (the artifact-design skill documents this same failure mode for artifacts). A description, even a careful one written by re-reading the image, loses the specific proportions/positions/details that make a design read as "this one" instead of "a plausible one."

**How to apply, every time a redesign/mockup match is requested:**
1. Get the literal reference file onto disk (ask the user to paste it to wherever's convenient — this session used the Nxeon admin board — rather than working from a text description of it, even a detailed one).
2. Do NOT stop after one build pass. Screenshot the actual result, `Read` it next to the reference, and explicitly check composition, spacing, colors, and copy before calling it done. Iterate at least 2-3 rounds as a default, more if it's still off.
3. When the user says "stop relying on our existing site styling, make it look different" — that instruction itself is a signal the generic-drift risk is high; take it as seriously as a literal image mismatch.
4. If dispatching a subagent for the actual build, hand it the reference file path directly and put the same iterate-and-compare loop in its instructions explicitly — don't assume it will do this on its own.

**2026-10-07 Bare Metal concepts:** round 1 (standalone static HTML mockups, flat cards, no owner art) was rejected outright: "not a good representation of the current visual language… assets and styling just isn't the same", "portal ones too basic", "tags should be actual tags". Round 2 was rendered IN the real app (worktree /tank/dev-worktrees/bm-concepts, branch design/bm-concepts, route /dashboard/dedicated/concepts?c=a..d behind NXEON_BM_CONCEPTS=1, shot via devhost on node-2) using the My Services hero/card anatomy, owner renders (public/nx/art, nx/svc, nx/preview/hero-racks.webp) and aurora plates. Root cause of "mixed and matched": components/dedicated/bm.css uses its own CHARCOAL palette (#0f141b cards) while the portal is navy (rim-hi, rgba(10,22,48)). Review page: https://claude.ai/artifact/JixAG64ZuX7bTHeEApVa7w (db collection picks2).
