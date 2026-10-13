# AI Mod & Plugin Builder: Executive Summary (2026-10-06)

## What it is
A standalone web product where a Minecraft server owner describes a feature in plain words ("a /shop GUI using my economy") and gets a **working, tested, safety-scanned plugin installed on their server in about 5 minutes**. It can then be improved from what happens on the server.

- **Targets:** Paper plugins and vanilla datapacks first, Fabric server mods next, then Rust (Oxide) and Valheim (BepInEx).
- **Architecture:** built standalone, with its own auth and database. "Sign in with Nxeon", the shared wallet and one-click install plug into Nxeon's existing Partner API and mods engine.
- **Working names:** *Modwright* standalone, shown in Nxeon as *NxLabs Studio*. Never put "Minecraft" in the name.

## Why we can win
- **The market is thin.** The real competitors are Player.Games (credit packs from $8, says it compiles and boots a server) and Orca (YC, about $20/mo, bundles its own hosting). No hosting company we found offers this.
- **Our edge is proof plus place.**
  - Proof: every build is played by a bot on a throwaway server against tests written from the user's own spec, and gets a safety report. Competitors stop at "it compiles and boots".
  - Place: we already host the server, so we can do one-click install with backup and rollback, and "fix this" straight from server errors.
- **Nxeon already has most of the hard plumbing:**
  - a mods engine with backup and rollback;
  - a pinned server-jar mirror for Paper 1.12 to 26.3;
  - throwaway smoke-test servers (Nxeon Verified);
  - Kodely-style SSO and a Partner API.

## How it works
1. A guided chat builds a structured **spec card**: commands, permissions, GUIs, config, messages and acceptance tests.
2. The user sees instant previews (GUI menu, chat, permission tree), then confirms the plan and the price.
3. Code is generated from tested templates.
4. The build runs in a sandbox with no internet.
5. A bytecode safety scan checks for backdoors, network access and command execution.
6. Unit tests run, then a live bot test on a real Paper server.
7. Failures go through an automatic repair loop (up to 3 tries).
8. The output is a signed jar plus full source.
9. Install comes with backup and one-click rollback.

**Failed builds are never charged.**

## Numbers (estimates until the Phase 0 spike measures them)
- **AI cost per medium plugin:** about $0.95 (range $0.50 to $2.50). Edits cost about $0.30; datapacks about $0.30. Compute on our own hardware is about $0.02.
- **Models:**
  - Sonnet 5.5 for chat and code;
  - Opus 5.5 for the plan and hard repairs;
  - Haiku 4.5 for moderation and log triage;
  - Fable 5.1 offline only, to author the pattern library.
- **Pricing (proposal):**
  - a fixed price per build, about $0.75 / $2 / $4.50 by size, charged only if the tests pass;
  - or subscriptions: Free (datapacks plus 2 small builds), Creator $9.99, Pro $24.99;
  - builds bundled into Nxeon Minecraft plans.
- **Effort and timeline:**
  - Phase 0 spike: 2 weeks, about $300 of API spend.
  - MVP: 10 to 12 weeks.
  - Closed beta: 4 weeks.
  - v1 (Connector for any server, fix-from-logs, Fabric, resource packs, Skript): 3 to 4 months later.
- **Infrastructure:** one new VM on **nxeon-bhs1** (8 vCPU / 24 GB) as the build and test farm. Singapore has no spare capacity, and the primary node crashed from memory exhaustion today. The farm must never run on the primary.

## Honest limits
- Plugins cannot add truly new blocks or items. Custom-looking items need a resource pack; new blocks need client mods.
- AI-generated plugins cannot be listed publicly on Modrinth (policy since 2026-08-13), so we position this as tooling for your own server.
- A first local test confirmed the build toolchain works. It also showed why templates matter: an idiomatic `final` main class silently breaks MockBukkit, the standard plugin unit-test library.

## Top risks
1. **Mojang EULA wording.** It reportedly says mods are yours "as long as you don't sell them for money". We must charge for the service, never for plugins, and get counsel to confirm before a paid launch.
2. A plugin that passes its tests can still miss what the user meant. The spec-confirmation step and editable acceptance tests are the mitigation.
3. Abuse: backdoors and malware. Mitigated by layered refusal, the bytecode scan, signing and a review queue.
4. Repair loops burning money. Per-job spend caps, and failed builds are free (we absorb that cost, so we must measure it).
5. Minors as users. A 13+ age gate, and payments need an adult or guardian.

## Phase 0 spike (do this first)
A CLI-only pipeline with 3 templates, run against **40 human-written benchmark prompts** (easy, medium, hard) plus **10 adversarial prompts**. It compares Sonnet 5.5 and Opus 5.5 for code generation and runs on a bhs1 VM.

**Go criteria:**
- at least 90% compile;
- tests pass on at least 90% of easy, 70% of medium and 40% of hard prompts;
- median time of 6 minutes or less;
- median cost per passing medium build of $1.50 or less;
- all 10 adversarial prompts blocked, with false blocks at 5% or less.

## Decisions for the owner
1. Brand: standalone name, NxLabs Studio, or a Kodely sub-brand.
2. Wallet: shared Nxeon wallet (needs new hold/capture API endpoints) or separate credits.
3. Pricing model and free-tier scope.
4. Approve a farm VM on nxeon-bhs1.
5. MVP targets: Paper plus datapacks (recommended); is Skript or Fabric wanted early?
6. Launch versions: 1.21.11 plus the current 26.x line (needs a Java 21 and Java 25 toolchain).
7. Output licence: MIT with source included (recommended).
8. Age policy for accounts and payments.
9. Approve the Phase 0 budget (about $300 API plus 2 weeks).
10. Counsel review: the EULA monetization wording, GPL output, the terms of service and the minors policy.

Full details: `PLAN.md`, `RESEARCH.md`, `UX.md` (same folder).
