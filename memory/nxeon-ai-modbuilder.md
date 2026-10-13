---
name: nxeon-ai-modbuilder
description: "Planned flagship AI mod/plugin builder for game servers (Minecraft first), standalone service first, Nxeon-pluggable later; research+plan phase started 2026-10-06"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-10-06T16:03:00.864Z
---

Owner idea (2026-10-06): AI that builds mods/plugins for customers' game servers. Must be a FLAGSHIP that "could stand as its own service", with an easy-to-use interface and a "massive asset library". Build STANDALONE first, architected to plug into Nxeon later (shared wallet/credits/SSO like Kodely, an install API into Nxeon's mods engine).

Minecraft order agreed in planning: Paper/Spigot plugins (server-side, no client mod) -> vanilla datapacks -> Fabric server-side; later Rust Oxide, Valheim BepInEx. Pipeline: chat spec -> templated codegen -> sandboxed build -> static safety scan -> automated in-game test on a throwaway server -> self-repair -> one-click install with backup/rollback -> iterate from logs.

**Why:** differentiator + standalone revenue; owner wants proper research (open-source to build on, legal asset sources) before building.

**How to apply:** research/plan deliverables live in /root/agent-notes/ai-modbuilder/ (EXECUTIVE-SUMMARY.md, RESEARCH.md, PLAN.md, UX.md). Next step after the plan is a measured Phase 0 spike (success rate + cost per plugin) before promising anything to customers. Mojang vanilla assets cannot be redistributed. Related: [[nxeon-kodely]], [[nxeon-model-split-preference]].

2026-10-06: owner wants the private pre-release test to run on ArmanJR/claudebox (Claude Code in Docker, uses the owner's Claude SUBSCRIPTION OAuth token, HTTP POST /prompt). OK for owner-only testing; public release must move to a real API key (subscription can't power a public service). Run off the primary, bind to localhost, pin image digest, review install.sh before running. Phase 0 test stays on the plan.
