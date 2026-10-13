---
name: nxeon-cyrus-release-pass-2026-10-09
description: State of the Cyrus release pass on integ/golive (committed, NOT deployed): what is done, what is still open, how to deploy and flip flags
metadata:
  type: project
---

Branch integ/golive (worktree /tank/dev-worktrees/golive), last commit 9c94b7d1a1 at time of writing. Owner said: do everything, deploy nothing until all done; owner runs merge + `scripts/promote-production.sh` (classifier blocks me).

**Done in code:** public-studio flag + prompt check + token chip site-wide + top-bar Cyrus; new 3D Y token (white on dark) + code-drawn badges; NxLabs tabs/icons/hero/banner/game strip (cover, name, versions) + marketing mod template with SEO/JSON-LD; /cyrus page fully rebuilt (hero = live core + prompt, sticky 6-scene how-it-works, game cards with covers/language/versions, featured-mods rail and screenshots grid that hide when empty, drawn-by-code texture demo, sound); synthesised sound (lib/cyrus/sfx.ts, off by default); texture renderer + pack builder (lib/cyrus/textures, NOT wired to studio yet); build-service scan hardening (services/modbuilder/scan.js, needs VM 88001 redeploy); docs in DOCUMENTATION.md "Cyrus release pass".

**Open:** 26.x in the build service (VM image), wire textures end to end, real in-game screenshots (owner drops files in public/cyrus/marketing/shots + manifest.json), real Stripe top-up test, free starter tokens decision, measure NxLabs speed on prod.

**Deploy:** merge ff-only, promote, redeploy build service, then flip `cyrus_studio_public_enabled` + `cyrus_tok_live` together via /root/agent-notes/set-setting.sh. Keep `cyrus_public_enabled` (marketing) and `cyrus_mods_public_enabled` off until the owner has reviewed the new /cyrus page.

**Tests:** full suite on node-2 has 52 pre-existing failures identical on main (billing/pricing drift etc.); none from this work.

**Gotchas:** /cyrus is generated: edit tools/nxm/native/cyrus/{body.html,page.css,page.js} then `python3 tools/nxm/port_pages.py cyrus` (never hand-edit app/nxm/_pages/cyrus). Screenshot harness: /root/agent-notes/golive-mktshots.sh and golive-nxshots.sh. Related: [[nxeon-golive-decisions-2026-10-08]].

**Late 2026-10-09 additions:** refunds commit e135686909 (from another session) merged into integ/golive (main is now an ancestor, ff-only stays clean). Owner decisions: starter tokens = ONE free build (cyrus_tok_starter=70, built, lib/cyrus/tokens/starter.ts); launch on 1.21.x, 26.x next (needs JDK 25 + Gradle 9 + image rebuild; Paper 26.2 API is class major 69). /cyrus has NO sub-nav now (owner hated it); screenshots already carry the owner's "Created with Cyrus" mark so no overlay badge. Owner's prompts-view request answered in /root/agent-notes/cyrus-backend-prompts.md. The owner-supplied Claude router key (cc/ model prefix, injects ~1.4k tokens, renames tool names with `_ide`) was tested: it authenticates and answers, but is NOT wired anywhere; never store that key. Real Stripe top-up test NOT done (devhost refuses staging creds; needs staging deploy). Economy e2e (throwaway DB) passes: /root/agent-notes/golive-economy.sh.
