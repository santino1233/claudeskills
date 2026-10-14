# BR: cyrus.my landing off demo mode (2026-10-14)

Branch `feature/cyrus-site-live` (worktree /tank/dev-worktrees/cyrus-live-site, from main f12841d2). NOT published, NOT promoted, no flag touched.

## What changed
- Prompt box is a real form: GET /sign-in?prompt=... -> post-login /new?prompt=... (kept through sign-up via `next`). `/new` pre-fills the box. Helper `lib/cyrus/bridge/prompt-handoff.ts`; `safeCyrusNext` cap 512 -> 1536.
- Hero animation labelled "illustration", types into the placeholder only (never the value); no fake build on submit; removed fake Advanced panel, fake API-key "Connect" form, invented `survival-01` server/mod list.
- Plans: static page shows no numbers. New anonymous `GET /api/cyrus/launch` (state closed|public, tokensLive, same plan rows as in-app Compare plans, real Stripe price or "To be announced"); page shows them only when tokensLive. Plan buttons -> /sign-up?next=/account?tab=billing. Rollover rules (plans.patch copy) shown only when live.
- Honest beta: note under the prompt; signed-in non-allow-listed accounts land on a "Cyrus is in private beta" panel at /sign-in instead of a 404 (callback routes them there). No waitlist exists in the codebase, so wording is "invited testers only".
- /legal/{terms,privacy,aup,sla} (and /legal) now served ON cyrus.my (app/cyrus-host/legal, same documents) instead of 302 to nxeon.cloud. Featured section no longer links nxeon.cloud (title plain text, CTA via /sign-in?next=/new?like=slug).
- Docs: docs/cyrus/06-portals.md, CYRUS-MY-LAUNCH.md, apps/cyrus-site/README.md, regenerated reference/*.md.

## Verification
- tsc 0 errors (devhost). Tests green: cyrus-site-links (new, 16), cyrus-site-landing, cyrus-bridge-routing/sso/ux, portals-routing, qa-polish, launch-check, docs-coverage, plans-copy. `cyrus-featured-mods.test.ts` fails to IMPORT under devhost (server-only module error in lib/cyrus-mods/featured; unrelated to this change, not verified on main); its new render assertions were checked with plain node.
- Browser (Playwright on node-2, desktop 1440 + mobile 390, landing + sign-in + legal through a local nginx stand-in): prompt typed -> /sign-in?prompt=..., sign-up and start links carry /new?prompt=..., legal terms render on cyrus.my with no nxeon.cloud links, launch API 200 (closed, tokensLive false). Screenshots in scratchpad `.../shots/` (not committed).
- Note: in `next dev` the middleware rewrite to /cyrus-host/* 404s (needed a temp local patch to screenshot); production behaviour was not changed (middleware.ts untouched).

## Gameplay gallery (added, second commit on the branch)
New section `#gameplay` after "In game": 7 webp (1600x900, 160-230 KB each, originals not in git) in apps/cyrus-site/src/assets/gameplay/, scroll-snap carousel with arrows/keys, lazy images, captions only describe what is visible (weapons, floating islands, shrinking-world countdown, quest log, performance panel, new biome, server admin tools). publish.sh check ok (4.98 MB, cap 40 MB). Desktop + mobile screenshots verified.

## NOT done
- (superseded, gallery is done) Gameplay screenshots gallery (second task): the board card "Cyrus game play mod screens" and /opt/nxeon/board-uploads could not be read (the sandbox classifier denied production DB / prod path reads). Needs the owner to copy the 7 PNGs + card text to e.g. /root/claudeskills/agent-notes/cyrus-research/gameplay-shots/ and re-run that task. Plan: resize to 1600px webp q80 under src/assets/gallery/, lazy-loaded scroll-snap section after "In game", captions from the card only; check cap is 40 MB (MAX_BYTES), so size is fine.
- Left alone: nxeon.cloud/cyrus page's "Demo · scripted sample" (components/cyrus/marketing/CyrusDemo.tsx) is on the Nxeon site, not cyrus.my.
- Game list "Soon" tiles (Hytale, FiveM, ...) are roadmap claims; kept, owner may want them cut.

## Owner commands
Merge + portal first (new /api/cyrus/launch, legal pages, sign-in beta panel need the app):
    cd /opt/nxeon && git merge --ff-only feature/cyrus-site-live && bash scripts/promote-production.sh --skip-staging-check
Then the landing (from the merged checkout on the primary):
    apps/cyrus-site/publish.sh check
    CYRUS_SITE_FEATURED_JSON=https://nxeon.cloud/api/cyrus/featured apps/cyrus-site/publish.sh publish          # dry run
    CYRUS_SITE_FEATURED_JSON=https://nxeon.cloud/api/cyrus/featured apps/cyrus-site/publish.sh publish --go     # atomic swap
    apps/cyrus-site/publish.sh rollback --go                                                                      # if needed
(Featured JSON 404s until the mods public flag is on: then no section, by design. Publish before promote and the page falls back to static beta wording; legal links would still redirect until the portal is promoted.)
