# MC-PAGES: Minecraft marketing pages plan for Cyrus + Nxeon (2026-10-17)

This is a plan only. No code was changed, nothing was built or deployed, and no paid model was called.
Grounded in these notes: CQ, CR, CN, DB, DC, DD, DP, screens-mod-pages, DV, DW, DX (rc20), STRUCTURE-BUILDER-GUIDE, MOD-SLATE and CT. Code was read in the rc20 worktree `/tank/dev-worktrees/cyrus-int7` (`lib/cyrus/structures/studio/*`, `tokens/config-pure.ts`, `tryit/policy.ts`, `uploads.ts`, `kill-switches.ts`, `docs/cyrus/03-studios.md`) and in `/opt/nxeon/app/(marketing)`.
**Web evidence (2026-10-17):** §1.5 holds the WebSearch/WebFetch pass. Two limits apply. First, WebSearch returns a filtered set of links, not Google's real ranking, so "prominent results" does not mean "top 5". Second, minecraft.net timed out, so its legal text is quoted from mirrors. The only verified volumes are Semrush free-page figures for related head terms. **Every target query (schematic generator, plugin generator, datapack generator, image to schematic ...) has no verified volume.** Measure them with GSC after launch, or with a Keyword Planner run by the owner.
**State correction (2026-10-17):** rc20 **is deployed**: portal release 20261016T124900Z-bc678074, modbuilder:0.25 live. Room Studio is live in production but behind `CYRUS_ROOM_STUDIO` (default OFF). Image-to-room is being built now on `feature/cyrus-room-studio-image`.

---

## 1-page summary

| # | Recommendation |
|---|---|
| 1 | **Domains.** cyrus.my owns every creation-tool page, guide, gallery and glossary page. nxeon.cloud owns hosting only (`/minecraft-server-hosting`, `/free-minecraft`, `/minecraft-bedrock-server-hosting`). Each topic gets exactly one canonical URL. Cross-links go both ways: "run it on Nxeon" from cyrus.my, "add custom mods with Cyrus" from Nxeon. Do not duplicate the `cyrus.my/host/*` matrix against nxeon.cloud hosting pages: leave it noindex, or canonical it to Nxeon. |
| 2 | **Flagship page:** `cyrus.my/minecraft-structure-generator`. It has a prompt box and a paste/drag image, and gives **1 free generation per signed-in, verified account**. Signed-out visitors get the 8 real worked-example rooms they can explore, plus free re-roll and kit swap (compiled in the browser, $0 model cost). The free generation includes the preview and **a real download**, with no watermark dark pattern. |
| 3 | **Positioning against BlockGPT** (DW, FACT). BlockGPT makes colour-voxel shells: no block states, no chests, no lighting, and its downloads are paywalled. Cyrus makes **playable rooms**: walkable, lit, real stairs and slabs, markers for mobs, loot and the boss. Cyrus rooms export to .schem, .litematic and .nbt, and the "Use in my mod" button drops the room into a Test-Flight-booted plugin. Against MCreator: Cyrus is prompt-first and server-side (Paper). |
| 4 | **Page set: 6 tool landings, about 12 room-variant pages, 1 gallery, 8 guides, 3 idea lists, 4 glossary pages, 3 honest comparisons, 2 hosting bridges.** That is about 40 URLs, a quality-gated trickle (Nxeon's 65k templated pages were dropped by Google: DB §0.4). |
| 5 | **Build order.** P0 (about 9 agent-days): flagship plus 4 variants plus the free-gen mechanism. P1 (about 10): plugin, creature, texture/pack and datapack tools, Test Flight, gallery. P2 (about 10): guides, glossary, idea lists, comparisons. Total about 30-35 agent-days plus owner flag flips. |
| 6 | **Hard dependencies.** rc20 is deployed (20261016T124900Z-bc678074, modbuilder:0.25), so Room Studio exists in production. Still needed: `CYRUS_ROOM_STUDIO=1` (default OFF), a decision on the production upload store (it currently returns 503 `uploads_off`), and `cyrus_content_public_enabled` then `cyrus_content_index_enabled` + `CYRUS_SITEMAP_CONTENT=1`. The cyrus.my nginx app-path regex (`deploy/cyrus/nginx-cyrus-my.conf` L72, identical to the live vhost as of 10-17) already passes games/mods/host/blog; every new root (`minecraft-*`, `guides`, `learn`, `ideas`, `compare`, `gallery`) must be added there AND to `WEB_ROOTS` in `lib/cyrus/web-paths.ts` (L23), otherwise the edge 404s it with `X-Cyrus-Edge: denied`. Image-to-room is in progress on `feature/cyrus-room-studio-image`. The page needs it merged, plus the safety rules in §6.1. |
| 7 | **Cost.** Room Studio holds 60 tokens (PLACEHOLDER, `cyrus_tok_room_studio_hold`) and settles at measured cost. DW estimates $0.08-0.12 of model cost per Saka generation (estimate; **no paid run has happened yet**). At a 500-free-generations/day global cap that is about $40-60 a day worst case (estimate). |

**Single biggest risk: the age and legal mismatch.** Minecraft's audience skews young, but the Cyrus/Nxeon Terms are 18+ (CT item 12). A free, viral, image-upload tool marketed on Minecraft keywords will attract under-13s and photos of real people. Without an age gate, image moderation and a no-storage default, the tool creates a COPPA/GDPR-K exposure, plus IP exposure from "build Hogwarts" prompts. Close this before launch. A close second: quality. Room Studio is deployed but flag-off, and no paid-model calibration run is recorded yet (DX §4). Run 50 calibration generations before launch and publish only real renders.

---

## 1. Strategy

### 1.1 Brand and domain split

| Topic | Canonical home | Other host |
|---|---|---|
| AI creation tools (structure, plugin, creature, texture, sound, datapack, designers, Test Flight) | cyrus.my | nxeon.cloud links to it; no copies |
| Community mods, Spotlight, "Made with Cyrus" gallery | cyrus.my `/mods`, `/gallery` (DC built `/mods/<slug>`) | nxeon.cloud `/mods/cyrus/*`: 301 to cyrus.my once `CYRUS_SITE_PRIMARY=1` (CR); until then do not serve both as 200 |
| Guides, glossary, idea lists | cyrus.my `/guides`, `/learn`, `/ideas` | none |
| Minecraft server hosting | nxeon.cloud `/minecraft-server-hosting`, `/free-minecraft`, `/minecraft-bedrock-server-hosting` (exist) | cyrus.my `/host/minecraft*` (DC): keep noindex, or canonical to nxeon.cloud, to avoid two hosting pages competing |
| Pack hosting (Pack Loader) | cyrus.my `/packs/` is disallowed in robots (CR); it is infra, not a page. Explain it in a guide | — |

Note: `.my` is a ccTLD. Google may treat it as a Malaysia geo signal, and that cannot be changed in GSC (CQ §9). Monitor impressions by country, and keep a long-term `.com`/`.gg` option open.

### 1.2 Positioning (claims only where evidence exists)

| Versus | Their real state (source) | Cyrus line (must stay true) |
|---|---|---|
| BlockGPT | Text/image to static schematic. 5 free previews/day, no download. $1 trial, then $9/$19/$49 a month. Commercial use only on Pro. Output: full cubes, no block entities (DW, one sample file) | "Rooms you can actually play: doors, light, loot spots and boss markers. Download the file, or drop it into a working mod." |
| MCreator | Visual GUI mod maker, not AI-first (DB, domain knowledge; page not fetched) | "Describe it instead of wiring it. Server-side Paper, nothing for players to install." Never claim Forge/Fabric client mods |
| player.games | AI plugin builder with localized landing pages per software (CQ, DB) | "Booted on a real Paper server before you see it (Test Flight), one-click install on Nxeon with rollback." Do not quote a pass rate: unmeasured publicly |
| Misode / mcstacker | Free hand-made datapack/command generators (CQ) | Complement: link to them honestly from the datapack page |
| MythicMobs / BetterModel | Config plugins (CQ) | "Animated custom mobs with no config files: Cyrus writes the plugin and the BetterModel rig." Creature templates are humanoid/ghost/quadruped only (MOD-SLATE) |

### 1.3 Audience segments

| Segment | Entry page | Hook | Safety note |
|---|---|---|---|
| Server owners (primary, DB S1) | plugin maker, structure generator, server ideas | custom boss / arena / dungeon without Java | — |
| YouTubers / creators (S4) | gallery, mod slate pages, ideas | "make your next episode's mod on camera" | FTC/ASA disclosure on any seeded tokens (DB §6.3) |
| Mod hobbyists / devs (S2) | plugin maker, glossary, Test Flight | full source, real API | — |
| Builders / map makers (new, BlockGPT audience) | structure generator + variants | free room, download .schem/.litematic | — |
| Kids/teens + parents | arrive from any page | — | Terms 18+: an age gate at sign-up, a parent FAQ page, no data from under-13s |

### 1.4 Funnel (each step is a real event already defined in DD)

SEO landing → interact with an example (free, no account) → sign in (Google/Nxeon, verified email) → 1 free generation → download or "Use in my mod" → starter tokens (70, `cyrus_tok_starter`) → plan or top-up → mod installed on a Nxeon server (tokens are also granted on Minecraft server purchase: `grantForGameServerPurchase`, DC).

---

## 2. Page inventory

Effort is in agent-days (ad). Priority 1 is highest. "Live data" means real counters or renders only.

| Pri | URL (cyrus.my unless noted) | Keyword cluster (volumes UNVERIFIED) | Intent | Type | Primary CTA | Embeds real data/UI | ad | Depends on |
|---|---|---|---|---|---|---|---|---|
| 1 | `/minecraft-structure-generator` | ai minecraft structure generator; minecraft schematic generator; ai minecraft build generator; image to minecraft schematic | tool | tool page | Generate (1 free) | Room Studio prompt, image drop, worker preview (`room-worker.ts`), 8 real example renders, exports | 4 (page) + 3 (free-gen) + 1 (wire in the image branch + §6.1 safety) | rc20 live; `CYRUS_ROOM_STUDIO=1`; new public endpoint; `feature/cyrus-room-studio-image` merged (no upload store needed) |
| 2 | `/minecraft-structure-generator/<variant>`: boss-arena, lava-arena, castle-hall, crypt, spooky-swamp, ice-cave, ruined-temple, throne-room, dungeon-room, medieval-village-house*, treehouse*, pvp-arena* | "minecraft boss arena schematic", "lava arena", "castle interior schematic" ... | tool/download | programmatic (quality-gated) | Generate this style | that kit's real renders (≥3 unique seeds per page), prompt presets, a downloadable example .schem | 0.5 each after the template (2 for the template) | kits exist for castle, lava, swamp, ice, crypt, ruins, throne, generic. *Village, treehouse and PvP need new kits/ops (`kits.ts`, `ops.ts` "tree"); publish only when they pass `quality.ts` ≥70 |
| 3 | `/minecraft-plugin-maker` | ai minecraft plugin generator; make a minecraft plugin without coding; minecraft server plugin ai | commercial/tool | landing | Describe your plugin (sign in) | real build examples from MOD-SLATE / owner batch (prompt → commands → Test Flight result) | 2 | content flag; real builds only |
| 4 | `/minecraft-custom-mob-maker` | minecraft custom mob maker; custom boss plugin; animated mobs | tool | landing | Make a creature | real creature renders (bonewarden, cinderhusk, direwolf, hexwitch: DP), BetterModel explainer | 2 | P0 BetterModel pack fix deployed (DP), else creatures show as magenta cubes on camera |
| 5 | `/minecraft-test-flight` | test minecraft plugin before install; is this plugin safe | informational | explainer | See a real report | a real Test Flight transcript (e.g. `structures-flights-2026-10-16.json`: boot 19.7 s, checks) | 1 | none |
| 6 | `/gallery` (+ `/mods/<slug>`) | made with cyrus; minecraft plugins made with ai | browse | gallery | Install / Remix | Spotlight API, real counters ("New" at zero), rooms saved with an opt-in licence | 2 (gallery; mod pages exist) | `cyrus_mods_public_enabled`, seed real mods (DC script), report flow |
| 7 | `/minecraft-resource-pack-maker` (texture + pack) | minecraft resource pack maker; minecraft texture generator ai | tool | landing | Paint an item | real texture-studio outputs, held-item render loops (CN) | 1.5 | — |
| 8 | `/minecraft-sound-maker` | minecraft custom sound effects; minecraft sfx generator | tool | landing | Make a sound set | real synthesized sets (audio players, lazy) | 1 | Sound studio is on the Saka plan |
| 9 | `/minecraft-datapack-generator` | minecraft datapack generator; ai datapack | tool | landing | Generate a datapack | real datapack lane outputs (recipes, loot, advancements) | 1.5 | page only if the datapack is downloadable standalone (verify) |
| 10 | `/minecraft-menu-quest-hud-designer` | minecraft gui shop plugin; quest plugin; custom hud | tool | landing | Design a menu | Designer previews (shop menu, daily quests) | 1.5 | — |
| 11 | `/ideas/minecraft-server-ideas`, `/ideas/minecraft-plugin-ideas`, `/ideas/minecraft-mod-ideas` | minecraft server ideas; plugin ideas | informational | evergreen list | "Build this idea" (prefilled prompt) | each idea tied to a real MOD-SLATE build or flagged "not built yet" (no fake screenshots) | 1 each | slate builds for screenshots |
| 12 | `/guides/*` (8): use a .schem with WorldEdit; load a .litematic with Litematica; place .nbt with structure blocks; add a custom boss to your server; make a plugin without coding; install a plugin on your Nxeon server; build a dungeon room for Cyrus (from STRUCTURE-BUILDER-GUIDE); BetterModel resource pack explained | how to ... | informational | HowTo guide | Try the generator | real screenshots, real commands | 0.75 each | none (WorldEdit/Litematica load test still VERIFY: DX §7.5) |
| 13 | `/learn/*` (4): Paper vs Spigot; plugin vs datapack vs mod; schematic formats (.schem/.litematic/.nbt/.mcstructure); what is a resource pack server push | paper vs spigot; plugin vs datapack vs mod | informational | glossary | contextual tool | format tables from DW §4.1 | 0.5 each | none |
| 14 | `/compare/cyrus-vs-blockgpt`, `/compare/cyrus-vs-mcreator`, `/compare/ai-plugin-makers` | blockgpt alternative; mcreator alternative | commercial | comparison | Try free | factual tables, dated, sourced; no "best" | 1 each | legal review of competitor claims |
| 15 | nxeon.cloud `/minecraft-server-hosting` (exists): add a "Custom mods with Cyrus" block; cyrus.my `/guides/run-cyrus-mods-on-nxeon` | minecraft server hosting with custom plugins | transactional | bridge | Deploy server | live GamePlan prices, token-grant block only when `cyrus_tok_live` is on (DC) | 1 | Nxeon page edit (shared marketing header D1 overflow open) |

Not built (deliberately): per-unsupported-game pages, plugin-name mirror pages, "best X" lists without real outputs, Bedrock-first pages (`.mcstructure` writer not built).

---

## 3. Free generation mechanism

### 3.1 Who counts as a "user"

| Option | Abuse resistance | Cost exposure | Verdict |
|---|---|---|---|
| Anonymous, 1 per IP/cookie | weak (VPNs, cookie clearing) | unbounded without caps | no |
| Anonymous preview + watermark, paid download | medium | medium | no: copies BlockGPT's dark pattern (DW §5.5 says not to) |
| **Signed-in, verified-email account, 1 lifetime free generation** + Turnstile + caps | strong: reuses the starter-token guards (verified email, alias dedupe, throwaway block: DB §6.5) | bounded by the global cap | **recommended** |
| Signed-out visitors | — | $0 | explore the 8 real examples: re-roll seed, swap kit and change size are compiled in the browser (`compose.ts` is client-safe), no LLM. Optional email capture ("send me this room") |

### 3.2 Design

| Item | Rule |
|---|---|
| Entitlement | New Setting-backed grant `cyrus_free_room_gen` (one row per account: used, jobId, at), checked in `startRoomJob` before the plan gate. It bypasses `canStructure` (top plan) for exactly one job at the **Saka** tier. The hold comes from a house reservation, not the user's wallet, so the account keeps its 70 starter tokens |
| Verification | verified email + Cloudflare Turnstile on the start POST (no Turnstile in the repo today: new, about 0.5 ad) |
| Caps | per IP 3 free/day (across accounts), per /24 10/day, **global 500/day** (Setting `cyrus_free_room_daily_cap`), plus the existing `ROOM_STUDIO_LIMITS` (4/min, 30/h) |
| Kill switch | `cyrus_free_room_enabled` Setting (fail closed like `cyrus_builds_paused`), plus `cyrus_ai_gw_kill` already global |
| Cost (ESTIMATE) | DW: Saka $0.08-0.12 per generation; hold 60 tokens (PLACEHOLDER). At 500/day the worst case is about $40-60 a day. **Measure the first 50 real generations before launch** (none have run: DX §4) |
| What the free user gets | full preview, checks panel, free re-roll/kit swap, **download** .schem/.litematic/.nbt (clean or with markers). "Use in my mod" needs a project and plan, which is the upsell |
| Outputs licence | the user may use the room, including commercially. Cyrus keeps a display/training licence only if they share (DW §6). Default share licence: CC-BY-4.0 (owner decision) |
| Storage | prompt kept as hash + length (D-60, `CYRUS_ROOM_STUDIO_KEEP_PROMPTS` off). Spec and job record already stored in the `cyrus_room_job:<id>` Setting |
| Analytics (real counters only) | DD beacons: `prompt_focus`, `prompt_submit`; add `free_gen_start/ok/fail`, `export_click{format}`, `use_in_mod_click`, `signup_from_tool`. Server-side: free grants used per day, cost per generation from the settle step |
| Caching | tool pages are static shells (CDN-cacheable); the entitlement state comes from a no-store `GET /api/cyrus/rooms/free` call. Never cache the personalised HTML at Cloudflare. Set `Cache-Control: private, no-store` on the API, and keep `Vary` minimal |

### 3.3 Image input (in progress on `feature/cyrus-room-studio-image`; rules the public page needs on top of it)

| Rule | Value |
|---|---|
| Path | reuse `lib/cyrus/uploads.ts` validation (5 MB, PNG/JPG/WebP, max 1 for the free generation). Do **not** need the upload store: in memory, passed to the vision call, then discarded |
| Processing | re-encode server-side (strips EXIF/GPS), downscale to ≤1024 px |
| Moderation | vision pre-check: refuse sexual content, gore, minors, identifiable real people ("build my friend" stays refused in v1), logos/characters. Then a text guard on the derived brief (`prompt-check.ts`, `guard/refusal-rules.ts`) |
| Output | the vision pass writes a **style brief** (palette roles, layout, props) → normal room spec (DW §5.6). It produces "inspired by", not a replica |
| Copyright stance | copy on the page: "Upload your own art or a photo of a place for inspiration. We build an original room in that style. We refuse recreations of named copyrighted buildings or characters." |
| Effort | the feature itself is being built now. For the public page: about 1 ad of moderation and free-tier wiring, if the branch does not already cover §6.1 |

### 3.4 Code to extend (rc20 tree)

`lib/cyrus/structures/studio/jobs.ts` (start/poll, hold, plan gate) · `http.ts`, `route.ts` (API `/api/cyrus/assets/v1/rooms*`) · `flags.ts` · `compose.ts`, `preview.ts`, `render.ts` (client preview) · `exports.ts` · `examples.ts` (8 real worked examples, hand-authored, not model output: label them that way) · `components/cyrus/studios/RoomStudio.tsx`, `room-worker.ts` · `lib/cyrus/tokens/config-pure.ts` (`cyrus_tok_room_studio_hold`, starter) · `lib/cyrus/uploads.ts` · `lib/cyrus/kill-switches.ts` · `lib/cyrus/guard/*`, `lib/cyrus/prompt-check.ts` · `lib/cyrus/analytics/*` (DD) · `lib/cyrus/web-paths.ts` + `lib/cyrus/bridge/routing.ts` (new public paths) · `deploy/cyrus/nginx-cyrus-my.conf` (app-path regex).
New: a public endpoint `/api/cyrus/rooms/free` (its own authz table entry), `lib/cyrus/structures/studio/free.ts`, and a public `app/(cyrus-web)/minecraft-structure-generator/*`. Today the studio lives under `/dashboard/cyrus/<build>/studio/rooms` and needs a build id, so the public tool needs a project-less mode.

---

## 4. Technical SEO

| Area | Rule |
|---|---|
| URLs | lowercase, hyphenated, no trailing slash. Tool: `/minecraft-<thing>-<maker|generator>`. Variants: `/minecraft-structure-generator/<style>`. Guides `/guides/<slug>`, glossary `/learn/<slug>`, ideas `/ideas/<slug>`, compare `/compare/<a>-vs-<b>` |
| Titles | `<Primary keyword> | Free AI tool - Cyrus` (≤60 chars). Fix the double brand from screens-mod-pages ("| Cyrus Mods — Nxeon") |
| Descriptions | 140-155 chars; state what is free and the formats; no "best" |
| Schema | Tool pages: SoftwareApplication (applicationCategory DeveloperApplication; offers only once prices are final). Guides: HowTo. FAQPage only with visible Q&A. VideoObject on slate embeds. ImageObject for renders. BreadcrumbList on every page. No AggregateRating (note: `lib/cyrus-mods/seo.ts:39-61` emits AggregateRating: make sure it only renders with real ratings). `lib/cyrus/seo.ts` has metadata/robots/sitemap builders only (`cyrusPageMetadata` L184, index defaults false) and no JSON-LD; JSON-LD today is scattered (`lib/cyrus-site/blog.ts`, `hosting.ts` faqJsonLd, landing index.html). Add a shared `lib/cyrus-site/jsonld.ts` (0.5 ad) |
| Internal links | tool ↔ its variants ↔ format guides ↔ glossary; every page → gallery + Test Flight; footer → Nxeon hosting; Nxeon hosting → plugin maker / structure generator |
| Sitemap | add section `tools` + `guides` to `lib/cyrus/seo-sitemap.ts` behind `CYRUS_SITEMAP_CONTENT`; lastmod only from real edits; variants only when they pass the quality gate |
| Canonical / hreflang | self canonical on cyrus.my. Off-host `/cyrus-web/*` stays noindex. Fix the og:url = site root bug (screens-mod-pages). No hreflang (English only) |
| Indexation | **staging noindex** (staging robots is `Allow: /` today and fixture pages were crawlable: screens-mod-pages). Portal pages: stop the root-layout canonical to the homepage |
| CWV budget | LCP < 2.5 s, INP < 200 ms, CLS < 0.1, JS < 150 KB before interaction. Preview = the existing pure-TS isometric renderer in a Web Worker (no three.js needed). The LCP image is a static AVIF render of the example; the interactive preview hydrates on interaction |
| OG images | none per page today (only Nxeon `app/opengraph-image.tsx` and a static Cyrus jpg). Build: auto-generated from the real render (`png.ts`, server side) at 1200x630 per variant / per saved room, pre-rendered at publish, not on request (1 ad) |
| Programmatic quality | each variant: ≥3 unique real renders with distinct seeds, ≥250 words of unique text (kit materials, room features from `quality.ts` report, sizes), its own downloadable example. Near-duplicate shingle check, otherwise noindex. Cap 20 variants until GSC shows >70% indexed |
| E-E-A-T | named Cyrus team author, build logs with real numbers and failures (DC blog), dated "last tested" stamps, method notes |
| Refresh | monthly: re-render on kit changes, update competitor tables (dated), prune pages with no impressions after 90 days |
| Measurement | GSC domain property (CR runbook), the Analytics tab (DD, human-only), IndexNow. KPIs in §7 |

---

## 5. Content and asset production

| Asset | How | Agent-days |
|---|---|---|
| Example renders | `scripts/cyrus/roomstudio-artifacts.ts` + `png.ts` from `examples.ts` (8 exist in `room-studio-examples/`). For variants: new hand-authored seeds/specs (no model cost), or real paid generations once calibrated | 1 |
| Downloadable examples | `exports.ts` on the same specs | 0.25 |
| Video | MOD-SLATE first 3 (Eleven Thrones, Arcane Academy, The Static), embedded on plugin/mob/ideas pages with lazy facade (poster + click) | slate cost ~$24-35 (MOD-SLATE) |
| Screenshots | real in-game only; label approximations ("Cyrus preview, colours approximate") | — |
| Gating | example downloads free and ungated; generated rooms need sign-in |

---

## 6. Legal and policy

| Topic | Rule |
|---|---|
| Brand | Footer on every page, prominent: **"NOT AN OFFICIAL MINECRAFT SERVICE. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT."** This is the Usage Guidelines template "NOT AN OFFICIAL MINECRAFT [PRODUCT/SERVICE/EVENT/etc.]..." (mirror captured 2026-09-11: https://conductatlas.com/platform/minecraft/minecraft-usage-guidelines/provision/CA-P-025271/mandatory-not-official-disclaimer-requirement/). minecraft.net timed out on 2026-10-17; verify on the primary page |
| Naming | The guidelines allow Minecraft in "a secondary name, secondary title, or description" if it "is not the dominant element or the distinctive part" (CA-P-025281). Minecraft may not be the primary name (CA-P-025283). No Minecraft logo in our logo (CA-P-025285). Domains must not "appear official" (CA-P-025297). So: "Cyrus: AI structure generator for Minecraft" is fine. The H1 "AI Minecraft structure generator" works as a description under the Cyrus brand. Never name a product "Minecraft Builder" or register minecraft* domains |
| Commercial scope | The guidelines cover the fan community and do not license companies to promote unrelated products (https://minecraft.net/en-us/article/commercial-use-guidelines-updated). Cyrus is a Minecraft-related tool: keep the not-affiliated line and no official look. Counsel to confirm |
| Server-owner content | Monetisation rules (quoted in https://www.gameserverkings.com/knowledge-base/minecraft/monetising-your-server/): same access price for everyone; cosmetics OK except capes; gameplay entitlements only without competitive advantage; virtual currency with no real-world value; all-ages content, no gambling. The "plugin ideas" and "server ideas" pages must only suggest EULA-safe monetisation |
| Assets | no Mojang textures in previews (colour table only, already the design) |
| EULA | Cyrus sells a generation service, not mods. Public mods stay free downloads; the marketplace stays parked (DB §6.1) |
| Kids | Terms 18+ (CT). Options: (a) keep 18+ with an age gate at sign-up and copy aimed at adults/server owners; (b) 13-17 with guardian consent (legal work). Under-13: never. Add a parent FAQ. No images of people |
| Generated structures | the user's to use; Cyrus kits/stamps licensed to them; refuse IP replicas |
| Competitor pages | factual, dated, sourced; no logos; no scraping (BlockGPT ToS forbids automated access: DW) |
| AI disclosure | "AI-generated" label on gallery items; Modrinth bans primarily-AI projects (DB §6.2): tell users |

---

## 7. Phased roadmap

| Phase | Scope | ad | Gates / owner actions |
|---|---|---|---|
| P-1 | rc20 is already live. Run 50 Room Studio generations on staging (or for prod preview accounts) to calibrate cost and quality; staging noindex; legal age decision (§6.1) | 1 + owner | `CYRUS_ROOM_STUDIO=1` on staging first |
| P0 | Flagship page, free-gen mechanism (entitlement, Turnstile, caps, kill switch), 4 variants (boss arena, lava, crypt, castle), nginx paths, sitemap section, OG | 9 | `CYRUS_ROOM_STUDIO=1` prod, `cyrus_content_public_enabled`, then index flags |
| P0.5 | Merge `feature/cyrus-room-studio-image`; add the §6.1 image safety rules + the free-tier path | 1-2 | image branch review; moderation policy |
| P1 | plugin maker, creature, texture/pack, sound, datapack, designer landings; Test Flight explainer; gallery | 10 | `cyrus_mods_public_enabled`, BetterModel fix live, seed real mods, upload store decision (only for "Use in my mod" saves) |
| P2 | 8 guides, 4 glossary, 3 idea lists, 3 comparisons, Nxeon bridge block, 8 more variants | 10 | slate videos |
| Ongoing | refresh, GSC review weekly | 0.5/week | — |

**Success metrics (real, measurable).** Indexed/submitted per section >70% by day 60. Non-brand impressions on structure/plugin clusters (GSC). Tool page → free generation start rate. Free generation success rate (validator pass, ≥70 score). Free → export rate. Free → "Use in my mod" → paid conversion. Measured cost per free generation vs the $0.12 estimate. CWV pass rate. Baselines are all zero today.

**Risks.**

| Risk | Mitigation |
|---|---|
| Age/legal (biggest) | as in §6 |
| Generic or boxy output (DW top risk); there is no paid baseline | calibrate first; publish only real renders |
| Cost spike | global cap plus kill switch |
| Thin programmatic pages | quality gate and cap |
| Upload store 503 | the free tool doesn't need it; "Use in my mod" does |
| Litematica v6 export unverified in a real client | label it beta until tested |
| `.my` geo signal | monitor impressions by country |
| BlockGPT Mods launch | lead with the end-to-end mod story |

---

## 8. Flagship page wireframe: `/minecraft-structure-generator`

Visual language follows Cyrus: black chrome, purple glow, display font, plain honest copy.

| Section | Content |
|---|---|
| Hero | H1 "AI Minecraft structure generator". Sub: "Describe a room or drop in a picture. Get a playable build with doors, light and loot spots, as .schem, .litematic or .nbt. Your first one is free." Prompt box (2,000 chars), image drop zone ("paste, drag or pick: your own art or a place, no people"), presets (kit chips: Castle, Lava, Swamp, Ice, Crypt, Ruins, Throne), size (24/40/56/64), Generate button |
| Proof strip | 8 real example renders (hand-authored examples, labelled) → click loads one into the preview |
| How it works | 3 steps: describe → Cyrus checks it (walkable, lit, markers) → download or use in a mod |
| Why it is different | table: real stairs/slabs, lighting guarantee, markers, slice view vs "colour-voxel shells" (no competitor named here) |
| Formats | how-to links: WorldEdit, Litematica, structure block |
| Use in a mod | Test Flight + Nxeon one-click |
| FAQ | free? / licence / Bedrock (not yet) / max size 64x32x64 / images kept? (no) |
| Footer | not-affiliated line |

| State | UI |
|---|---|
| Empty | example loaded in the preview, prompt placeholder "a lava boss arena with a central platform and hidden chests" |
| Signed out, clicks Generate | modal: "Sign in to use your free generation", Google/Nxeon. Prompt kept in sessionStorage |
| Generating | live preview grows as the spec streams in (partial-JSON); checks fill in; "about 30-60 s" (measure) |
| Result | preview (iso / plan / slice), checks report with score, re-roll / swap kit free, downloads, "Use in my mod" |
| Out of free | "You've used your free room. Rooms cost about N tokens (shown live from the hold); you have M." CTA: plans / top-up; re-roll and kit swap stay free |
| Error | refused (guard): explain + suggest an original; validator fail: "we couldn't make that walkable, try simpler", and no charge (a job without a spec is free); caps hit: "busy today, try tomorrow"; kill switch: "paused" |

### 10 sample page outlines

| # | Page | Outline |
|---|---|---|
| 1 | `/minecraft-structure-generator/boss-arena` | H1 "Minecraft boss arena generator"; 3 renders (lava caldera, throne hall, ice sanctum); what makes a good arena (focal platform, ≥6 pillars, hazards: from `quality.ts`); preset prompt; download example; use with a custom boss → creature maker |
| 2 | `/minecraft-structure-generator/spooky-swamp` | drowned mangrove hall render; materials list from the swamp kit; lighting note (dark by design); FAQ |
| 3 | `/minecraft-plugin-maker` | hero prompt → sign-in; 3 real builds (prompt, commands, Test Flight line); what it can/can't do (MOD-SLATE "cannot" list); source code ownership; Nxeon install |
| 4 | `/minecraft-custom-mob-maker` | real rig renders; templates (humanoid, ghost, quadruped); how BetterModel and the auto resource pack work; limits; boss phases |
| 5 | `/minecraft-test-flight` | what is booted (real Paper, version pinned), the checks list, a real transcript excerpt, what it doesn't prove (no client) |
| 6 | `/guides/how-to-use-schem-files-worldedit` | HowTo: install WE 7.3+, folder, `//schem load`, `//paste`; v2 vs v3; troubleshooting; CTA to the generator |
| 7 | `/learn/plugin-vs-datapack-vs-mod` | table (server/client, install, power, Cyrus support); when to choose each; links to the 3 tools |
| 8 | `/ideas/minecraft-server-ideas` | 15 ideas, each with: what it is, "built with Cyrus" link or "not built yet", prefilled prompt button |
| 9 | `/compare/cyrus-vs-blockgpt` | dated table from DW facts (pricing, free tier, formats, block states, gameplay data); where BlockGPT is better (statues, big sculptures, Bedrock); sources |
| 10 | `/gallery` | filters (rooms / mods / creatures), Staff picks with reason, real counters "New", licence per item, report button |
