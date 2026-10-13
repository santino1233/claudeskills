# Cyrus release backlog (owner's list, 2026-10-09). Goal: a releasable Cyrus; weekly usage 96% used, resets 23:00 UTC 2026-10-09.

## A. Launch-critical (studio-only public release)
- [ ] Gibberish / non-mod prompts must be refused BEFORE any tokens are reserved ("Yo Yo Yo" game made a mod): cheap heuristic + the service's Haiku classifier; clear message, no charge.
- [ ] Token economy LIVE together with the public studio (non-economy accounts are unmetered today). Verify charging for a non-preview account.
- [ ] Pin the Cyrus token balance site-wide for anyone who has EVER had tokens (even at zero); hidden only for accounts that never had any. Sidebar or top bar.
- [ ] Move Cyrus out of the sidebar into the top bar with an enticing entry; remove the old "Mod Builder" sidebar item for everyone.
- [ ] Studio: remove the dark/light toggle inside the Cyrus app (top bar has one). Gray out unsupported games so only Minecraft is lit. Deploy button -> the classic site-wide `btn-deploy`.
- [ ] Stuck "Compiling into a real plugin" in the live UI: build finished server-side in 64 s but nginx shows the stream stayed open ~2.5 min after (suspect: sequential per-file source fetches after the build ends in lib/cyrus/follow.ts, slow on the real service; mock is instant).
- [ ] After install: say clearly "restart your server to load it" (or offer Restart) and "commands need operator permission: run `op <name>`" (9mm /gun give looked "unknown" because nobody was op; plugin was fine).
- [ ] Minecraft versions: support what we need (26.x not supported by the build service yet).
- [ ] Flip switches: cyrus_studio_public_enabled (code written, in integ/golive working tree, NOT committed), cyrus_tok_live; keep cyrus_public_enabled (marketing) and cyrus_mods_public_enabled (NxLabs community) OFF until redone.

## B. Design / brand (after reset)
- [ ] Cyrus token: use the sidebar "Y" SVG; produce PREVIEWS of a 2D token and a 3D token (several options) before applying site-wide.
- [ ] Own "Built with Cyrus" badges (owner's ChatGPT ones look low quality): create proper SVG badges; light-on-dark variant; correct sizes; the shield badge is unreadable -> use the Cyrus logo on the "not community tested yet" card.
- [ ] Marketing page /cyrus: bland. Cyrus core + prompt box in the hero; REAL in-game mod images (owner to supply screenshots; never fabricate); drop the 3-identical-badges section; use the Cyrus logo in the nav instead of plain text; must feel flagship/premium.
- [ ] NxLabs: top tabs look bad; Cyrus Mods section needs the Cyrus logo; every mod uses the same icon (give distinct icons); mod page hero is a mess (stacked, mixed-size buttons); add a wallpaper/banner behind the hero card; whole Cyrus mod page redesign; Cyrus <-> server integration review.
- [ ] NxLabs is extremely slow to open (measure; maybe heavy community queries).

## C. Features
- [ ] Texture code for Minecraft (no image generation): AI writes code that draws the texture (e.g. a Glock) -> resource pack (item_model + PNG), hosted by Nxeon and applied to the server.

## D. Health and safety before public
- [ ] Build-service safety scan gaps (THREAT-MODEL T20: reflection warn-only, method refs, DNS/dynamic code) fixed + human review.
- [ ] Abuse limits, spend caps, refusal rules, Stripe top-up tested for real, installs of others' mods stay OFF until scan fixed.

## Status 2026-10-09 (late)
DONE in code on integ/golive (not deployed): A (prompt check, public flag, token chip site-wide, top-bar Cyrus, studio fixes, op-permission install note), B (token + badges, NxLabs tabs/icons/hero/banner/game strip, mod marketing page + SEO, /cyrus overhaul, sound), C (texture renderer + pack builder: not wired), D (scan hardening: needs VM 88001 redeploy).
STILL OPEN: 26.x in the build service (needs a VM image: paper-api 26.x + a sheet + live compile test), wire textures end to end (service emits specs, host pack, apply to server), real in-game screenshots (owner: drop files + manifest.json), real Stripe top-up test, free starter tokens decision, deploy + flip flags together (cyrus_studio_public_enabled + cyrus_tok_live), measure NxLabs speed on prod.
