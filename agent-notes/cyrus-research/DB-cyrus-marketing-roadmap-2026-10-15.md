# DB: Cyrus marketing roadmap, built from what Nxeon actually did (2026-10-15)

Status: RESEARCH and PLANNING only. No code, no DNS, no send, no post, nothing under /opt/nxeon edited. Production DB was read with SELECT-only aggregate queries (read-only transaction, no PII written here; partners and creators are counted, not named).

How to read this: every number is tagged. **(DB)** = measured from the Nxeon production DB on 2026-10-15, window 2026-07-23 to 2026-10-15 (about 12 weeks; the site is young). **(note)** = from an agent note or docs file. **(web)** = from a fetched or searched page with the URL given. **(proposal)** = my suggestion with no benchmark behind it. **UNKNOWN** = nothing I read answers it. Where a vendor makes a claim about itself I say so; those are marketing, not evidence.

---------------------------------------------------------------------------
## 0. The five things to take away

1. **Nxeon never had a traffic-quality problem it could see, then a conversion problem it could not fix.** Raw sessions in the week of 2026-10-05 were 80,003, human sessions 1,141, human visitors 671, signups 85, deployed 28, paid 4 (DB, GrowthReport). About 98.6 percent of raw sessions were non-human. Until the bot classifier shipped (2026-10-01) every top-of-funnel number Nxeon looked at was inflated. Cyrus must measure human-only from day one.
2. **The one channel that worked was not planned: AI assistants.** ChatGPT is the first touch of 31.9 percent of human, non-mod entry visits (1,583 of 4,969, 90 days) and of 402 of 1,019 signups in the last 110 days (DB). It cites concrete, factual pages (free Minecraft, pricing, game hosting), not generic content. For Cyrus, "be the page ChatGPT cites for 'AI Minecraft plugin maker'" is the first-order SEO goal, ahead of Google rankings.
3. **Volume without a path to a paid action converts at about zero.** The free-intent landing pages produced 83 signups and 0 servers (friction report, 14 days); of 108 free Minecraft servers only 19 (17.6 percent) were ever woken, 4 (3.7 percent) reached multiplayer, and 2 owners paid (DB). Cyrus's equivalent is: a signup who never gets a mod installed on a server and joined by a player is not activated, however cheap the signup was.
4. **Scaled, templated pages hurt Nxeon.** ~65,000 near-templated mod pages went live in about a week and Google stopped crawling them within days (analysis note 2026-10-06; 28 search-referred visits across 64,853 mod pages in 30 days). Cyrus's community mod and library pages must be a quality-gated trickle, not a flood.
5. **Creators want money up front, not commission.** Of 49 creators who answered Nxeon's partner outreach, 26 said no to commission, 15 quoted flat rates between $100 and $5,000, others asked for CPM of $10 to $25 (note, creator-fixed-fee CSV). The 50 percent first-purchase discount plus 40 percent commission programme produced 290 clicks, 18 signups, 2 paying customers and $6.60 of accrued commission in its first 19 days (DB). A Cyrus creator programme must be a hybrid (seed, code, fixed fee for the few that matter), not rev-share alone.

Also load-bearing and easy to miss: **Cyrus has zero real external users today** (1 token account, 23 projects, 1 user, 26 mod pages of which 2 are public, no waitlist exists, the private beta allow-list has 2 emails; DB). Everything in sections 4 and 5 starts from absolute zero. And **the plan prices are placeholders ("to be announced")**, so no price-based message or paid-acquisition ROI can be computed yet.

---------------------------------------------------------------------------
## 1. INVENTORY: every growth lever Nxeon built or used

Ratings: WORKED = measurable positive effect; PARTIAL = some effect or too early; NO EFFECT = built and live, no measurable effect; INERT = built, switched off or never run; HARM = made things worse. "Cash" = money spent outside engineering; I found no record of ad spend in any file I read, so ad cash is UNKNOWN.

### 1.1 Acquisition: organic and AI

| # | Lever | What it is | Numbers | Verdict | Cost / notes |
|---|---|---|---|---|---|
| A1 | GEO / AI-assistant citation (unplanned) | Concrete factual pages (free-minecraft, free-vps, game hosting, pricing) cited by ChatGPT; `llms.txt`; AI-search bots allowed in robots | ChatGPT referrer on 1,583 human non-mod entries in 90d = 31.9% (DB). Top landing for ChatGPT in last 30d: /free-vps 86, /free-minecraft 79, /vps 43, /pricing 25, /minecraft-server-hosting 25 (DB). First-touch of 402/1,019 signups (DB). Self-reported "heard about us": ChatGPT 254 plus about 30 free-text variants, Google 104, YouTube 44, friend 12, TikTok 9, Reddit 7, skipped 452 (DB). Signup to ever-paid for ChatGPT-first-touch: 12/402 = 3.0% (DB) | WORKED for reach, weak for money | Cash 0. No control over it. Reputation risk: it cited free-intent pages that cannot satisfy the intent |
| A2 | Classic SEO programme | Sitemap sections, index policy, price tokens in titles, audits (baseline score 94.4), IndexNow, GSC read-only OAuth, `/admin/seo` | Google organic first-touch: 497 entries (10.0%); 71 signups; 6 ever paid (8.5%) (DB). GSC opportunities table: 15 rows, 630 impressions, 3 clicks (DB, snapshot not total) | PARTIAL | Engineering heavy. IndexNow sweep is OFF by default (note) |
| A3 | Programmatic mod catalogue (NxLabs) | 64,853 mod pages from upstream catalogues | 16,357 of 18,466 "direct" entries were /mods pages and 12 of those 16,357 had an interaction (DB). Googlebot mod fetches fell from ~30/h to 0/day after 09-27; 28 search-referred visits in 30 days (note) | HARM (scaled-content demotion, moderate confidence 55%, note) | Cause was originality of upstream text, not technical. Quality bar and 10K-download floor shipped after the cliff |
| A4 | Bulk blog (346 posts) | 346 posts created 07-23 to 08-16, "Best X mods 2026" template | 575 human entry visits to /blog in 90d = about 1.7 per post (DB). The template ranks page 1 for some exact phrases (note) | NO EFFECT at this scale | Posts were written in bulk, a flat curve |
| A5 | Free tools suite (16 tools) | Generic devops tools plus game tools | About 77 pageviews all-time across all 16; only latency-test (29) and server-status (11) have pull (note 2026-09-22) | NO EFFECT | The claim "ChatGPT cites tools" was checked and was wrong |
| A6 | Per-game and per-location landing pages | ~42 game families, game x location matrix, "alternative to X" and "migrate from X" pages | 73% of game x location pages were orphaned and 81 to 87% near-duplicate before the audit (note). Effect on signups not separable | PARTIAL | Audit fixed internal links and duplicate hosts |
| A7 | Free tiers as acquisition | Free Minecraft (Docker + mc-router, sleeps when idle), free-vps page, dormant free community Valheim | 108 free MC servers since 2026-08-25; 19 woken (17.6%), 4 multiplayer (3.7%), 2 owners ever paid (1.9%), 1 public listing (DB). Signups jumped from ~20/week to ~155/week when free tiers launched (note). /free-vps: 83 signups, 0 servers, 0 paid (friction report) | WORKED for signup volume; NO EFFECT on revenue | Real infra cost. "Free VPS" title pulled the wrong intent |
| A8 | Public server directory | Listing of customer and free servers (G6), ingest of external lists | DirectorySubmission rows: 0 (DB) | INERT | Built, no submissions |
| A9 | Review programme | Trustpilot invite sweep, neutral wording | Review rows 0 (DB); sweep default OFF (note) | INERT | |
| A10 | Third-party listings | AlternativeTo, HostAdvice, LowEndTalk, Product Hunt drafts | Drafts only, nothing submitted (docs/growth/LISTINGS-AND-OUTREACH.md) | INERT | |
| A11 | Riddle promo ($100 credit) | 4-gate puzzle, login-gated | 4 attempts by 2 users, 0 winners (DB) | NO EFFECT | A gimmick with a hidden entry path |

### 1.2 Acquisition: outbound, creators, partners

| # | Lever | What it is | Numbers | Verdict | Cost / notes |
|---|---|---|---|---|---|
| B1 | Creator Partner Program | Per-partner code and link `/partner/<code>`, lifetime 50% off first purchase and 10% off after for the referred customer, per-partner commission (14 kol partners average 40%, 3 others average 26.8% (DB)), partner portal, media kits, per-creator promo video generator, payouts ledger, refund reversal | 17 active partners. 290 clicks (2026-09-26 to 10-15), 18 converted to a signup (6.2%), 21 attached customers across 5 partners, 2 of them have paid, commission accrued $6.60 on $16.48 base, 0 payouts (DB). Click spread: 153 clicks to 2 signups, 44 to 1, 43 to 6, 39 to 9 (DB). 101 clicks in one week vs 8 the week before (friction report) | PARTIAL, too early | Large engineering investment. The 50/40 structure makes first-month revenue near zero by design |
| B2 | Creator outreach | 513-row creator CSV (80 Minecraft/Bedrock, median 51.3K subscribers), invite flow with name/channel prefill, owner-approved previews, custom invites from a real staff mailbox | 258 invites, 256 sent, 13 accepted (5.0%) (DB). `creator_partner_invite_custom` 214 sent, 34 opened (15.9%), 1 click; `creator_partner_invite` 42 sent, 5 opened (DB). Outreach queue: 157 sent on 10-01 to 10-02, 2 failed (DB) | PARTIAL: 17 partners signed | Opens are not reliable (Apple Mail privacy prefetch inflates them, general knowledge) |
| B3 | Creator fixed-fee research | Replies from 49 creators | 26 no commission, 11 yes, 4 open to talk; 15 quoted: $100 to $5,000 per integration; CPM asks $10 to $25 (note CSV) | Informative | This is the single most useful commercial data point |
| B4 | Creator kits and promo generator | Per-creator mp4s in 5 languages, endframes, how-to text; HyperFrames render worker on node-2 | 6 creators with kits, 12 MB per video (note); adoption by creators UNKNOWN | UNKNOWN | Built on branch, render worker on node-2 |
| B5 | Cold-email engine | Lead DB (1,709 cold-ready US business leads, 2,681 no-website prospects), warm-up, rotation, reply loop, master inbox, DNS verification | Relay is PAUSED by default (Gmail not accepting the IP; setting `cold_email_relay_paused`) (note). Visits with utm_source coldemail: 380 entries (7.6% of human non-mod, DB), campaign tag `local_a` 137 | INERT / BLOCKED on deliverability | These leads are US businesses, wrong audience for Cyrus |
| B6 | Marketing agent (monitor and draft) | Hourly scan of 8 subs plus HN; drafts disclosed replies; human posts manually | Signals/drafts counts not queried; never posts (note). Reddit signups first-touch: 3 (DB) | PARTIAL | Reusable as-is for Cyrus |
| B7 | Peer referral | Code per user, both sides rewarded at first paid action | 1 referred signup in all of Sep, 0 in Oct (DB). `referral_reward_cents` setting has no reader (note) | NO EFFECT | No moment in the product asks for it |

### 1.3 Conversion and lifecycle

| # | Lever | What it is | Numbers (75-day email window, DB) | Verdict |
|---|---|---|---|---|
| C1 | Deploy-wizard rework | Defaults over page count, geo region preselect (10-01), server-name and play-address defaults (branch, not deployed), guest configurator, fast path, money-back note, local payment methods (flags all OFF) | Game wizard: 56% lost at the Server step because two required text fields started empty (NX-conversion note). Payment step reached then paid: 26% (friction report). Mobile: 100 signups, 1 server, 2 paid (friction report) | PARTIAL, mostly undeployed |
| C2 | Onboarding emails | 3-step drip (explore, tips, checkin) | explore 233 sent / 18 opened (7.7%); tips 226 / 33 (14.6%); checkin 170 / 36 (21.2%); 0 to 4 clicks each | NO EFFECT visible |
| C3 | Transactional emails with CTAs | server_deployed, email_verify | server_deployed 176 / 55 opened (31.3%) / 16 clicked (9.1%); email_verify 255 / 116 (45.5%) | WORKED (these are the highest-engagement mails) |
| C4 | Deploy win-back | 50% off first month after wizard abandonment | 648 sent, 91 opened (14.0%), 15 clicked (2.3%); 0 redeemed COMEBACK50 in the 14-day friction window (friction report) | NO EFFECT on revenue; discount is not the lever |
| C5 | Promos and flash sales | EXIT25, TRIAL798, flash_sale, first-month-free (hosting only) | flash_sale 463 / 31 opened (6.7%) / 2 clicked; trial798 560 / 42 (7.5%) / 3; coupons: EXIT25 4 redemptions, TRIAL798 2; PromoRedemption 14 consumed, 2 renewed | WEAK |
| C6 | Abandoned-checkout and dormant win-back | Built, OFF by default | n/a | INERT |
| C7 | Email shell v2 and tracking | Dark branded shell for 66 templates, pixel plus click rewrite, secret-link exemption, one-click unsubscribe, EmailLog | 6,088 SENT, 340 FAILED all-time (DB) | WORKED as infrastructure |
| C8 | Email deliverability stack | SPF/DKIM/DMARC verified healthy 2026-08-22 (note); Gmail sample 10 lines 0 deferred (GrowthReport) | | WORKED |

### 1.4 Measurement and attribution

| # | Lever | What it is | Verdict |
|---|---|---|---|
| D1 | Human-only analytics | Bot classifier, trafficQuality(), humanFunnel(), include-bots toggle | WORKED; changed how every other number reads. 34,050 non-bot vs 139,901 bot rows in the last 30 days (DB) |
| D2 | `/admin/conversion` (branch, not deployed) | Funnel SVG, drop-off reasons, payment outcomes, abandoned value; metric definitions in NX-conversion note | Ready to reuse |
| D3 | `/admin/growth` weekly scoreboard | Monday-start UTC snapshot per week into GrowthReport, hourly check | WORKED |
| D4 | `/admin/retention` | Day 1/7/30 return from union of activity tables | Showed only about 5% of signups return (note) |
| D5 | Deploy funnel events | Step, select, error, payment outcome, dwell | 4,265 rows (DB) |
| D6 | Attribution capture | UTM, gclid, fbclid, visitorId; self-reported "heard about us" (452 skipped) | PARTIAL; 408 of 1,019 recent signups have no linked first touch (DB), so source attribution is incomplete |
| D7 | Ad pixels and offline conversions | Meta pixel + CAPI (SPA PageView fix, fbc from fbclid), Google Ads offline upload | Meta live; Google Ads upload INERT (AdsConversion 0 rows, DB); paid entries tiny: 27 gclid and 50 Meta/IG (DB, 90d) |
| D8 | CyrusAttribution consent system | Consent cookie (180 days), attribution 30 days, reject-all as easy as accept, ad ids need marketing consent, hashed email only, conversion outbox | 0 rows in CyrusAttribution and CyrusConversion (DB): built, OFF (`CYRUS_CONSENT`, `CYRUS_ATTRIBUTION`, `CYRUS_CONVERSIONS`) |

### 1.5 Community and content programmes (mostly dormant)

| # | Lever | State |
|---|---|---|
| E1 | Community Discord blueprint | Documents only; no community guild exists; owner decisions D1 to D6 open (docs/COMMUNITY-DISCORD-*.md) |
| E2 | Clubs / clans / LAN programme | `/clubs` 404 until flag; no discount numbers decided |
| E3 | Free public Valheim server | Built dormant |
| E4 | Game playbooks (wipe day, patch day) | Default OFF |
| E5 | What's New changelog | Customer-facing only rule; live |
| E6 | Newsletter | 4 subscribers, 0 campaigns (DB) |
| E7 | Ad creative generator (13-piece launch pack) | Delivered 2026-08-10, not run as a campaign that I can find |

### 1.6 What the inventory says (honest summary)

- **What worked:** AI-assistant citation of concrete pages (unplanned), human-only measurement, transactional mails that sit on the user's critical path, per-creator code/link tracking plumbing.
- **What did not:** bulk content (blog, tools, 65K mod pages), generic discounts as a win-back, gimmicks (riddle), peer referral with no product moment, outreach to a wrong-audience lead list, and every free tier as a revenue source.
- **What is still unproven because it is new or off:** creator partners (19 days of data), conversion wizard fixes (undeployed), review programme, directory, community, offline conversions.
- **Pattern:** each lever that "scaled" before it was quality-gated or activation-gated either did nothing or hurt. Levers that sat directly on the user's next-step path (deployed mail, wizard defaults) outperformed levers that merely added reach.

---------------------------------------------------------------------------
## 2. FIT ANALYSIS: reuse, adapt, or skip for Cyrus

Cyrus differs from Nxeon in three ways that decide fit: (1) the buyer is a Minecraft server owner or hobby modder, not a generic hosting buyer; (2) the product has variable AI cost per action, so free = real money; (3) there are no users yet, so the first job is a controlled activation loop, not reach.

| Lever | Verdict | Why, and the Cyrus-specific change |
|---|---|---|
| A1 GEO / AI citation | **Reuse and make primary** | ChatGPT was 32% of entries. Build cyrus.my facts pages (what it does, what it cannot do, pricing when final, supported versions, real example builds with prompts), `llms.txt`, per-page clean HTML, and the 30-prompt AI-visibility panel (`scripts/growth/ai-visibility-panel.ts`) with Cyrus prompts |
| A2 Classic SEO tooling | **Reuse the machinery, not the page counts** | Sitemap sections, index policy, IndexNow, GSC OAuth, audits all exist. The Cyrus SEO plan (CQ) and the technical branch (CR) are written; the blocker is deploying them. Keep pages few and each backed by a reproducible build |
| A3 Programmatic mod/library pages | **Adapt with a hard gate** | CQ already specifies the quality bar (>=250 words unique text, media, tested status, near-duplicate noindex, 2,000 URL cap on the library). Add: no mass publishing; publish at most N per week (proposal: 25) until GSC shows indexed over 70% of submitted |
| A4 Bulk blog | **Skip** | Replace with 10 use-case pages and 5 guides already in CQ section 7, each anchored in a real build |
| A5 Free tools | **Adapt, one only** | Only game-adjacent tools pulled traffic. A "Minecraft plugin idea to prompt" or "does my plugin version match my server" helper is plausible but UNKNOWN; do not build generic tools |
| A6 Landing-page factory | **Skip** | Cyrus has no per-game, per-location surface. Per-game pages only when a game is really supported (CQ rule) |
| A7 Free tier | **Adapt: one free build, not a free tier** | Starter grant is 70 tokens (about 1.5 Katara builds, 0 Saka builds at 500 tokens per USD, BL note). Message it as "one free build", never "free" or "free forever". Cost per signup is about $0.14 at the Katara median ($0.092 fresh) |
| A8 Server directory | **Skip for now** | 0 submissions. Revisit only if "mod installed on server X" becomes a signal worth showing |
| A9 Review programme | **Adapt late** | Needs real paying users. Ask for a review only after a second successful install |
| A10 Third-party listings | **Reuse** | AlternativeTo (Kodari is listed, web), HostAdvice not relevant, Product Hunt only at public launch. Draft copy exists for Nxeon; rewrite for Cyrus |
| A11 Riddle gimmick | **Skip** | |
| B1 Creator Partner Program | **Reuse machinery, redesign the offer** | Per-partner code, click log, attach, commission, ledger, portal, kits all exist and are already wired to Cyrus (`cyrusPartnerCommission` hook, CyrusAttribution to `nxeon_ref` handoff, r44, flags OFF). Redesign terms: see section 4.4 |
| B2 Creator outreach flow | **Reuse as-is** | CSV matching, DRAFT invites, owner preview, staff mailbox sending, suppression, unsubscribe. 80 Minecraft/Bedrock channels already in the CSV |
| B3 Fixed-fee research | **Use as the pricing floor** | Budget Cyrus creator spend from these quotes, not from theory |
| B4 Kits / promo generator | **Adapt** | New brief for Cyrus (prompt, result, install on camera). The render pipeline is reusable |
| B5 Cold-email engine | **Skip for Cyrus** | Leads are US small businesses; relay paused; wrong ICP. Do not mass cold-email server owners (consent and platform-reputation risk) |
| B6 Marketing agent monitor/draft | **Reuse with new sources** | Add Cyrus keywords ("minecraft plugin", "custom boss", "how do I make a plugin") to r/admincraft, r/MinecraftServer, r/feedthebeast; keep human-post-only and disclosure line "I work on Cyrus". Reddit API access needed (WebFetch could not read Reddit from this box) |
| B7 Peer referral | **Adapt: tokens, tied to first verified install** | Nxeon proves a bare code does nothing (1 referred signup). Put the ask at the moment of delight and reward the first Test Flight pass plus install, not the signup. See 4.6 |
| C1 Wizard fixes | **Reuse the principles** | Defaults over fields, say what was preselected and why. Cyrus's "new mod" flow should prefill a prompt from the landing form (already built, BR note), and show cost first (exists) |
| C2 Onboarding drip | **Replace with event-triggered mails** | Time-based drips got 8 to 21% opens and about 0 clicks. See 4.7 |
| C3 Critical-path transactional mails | **Reuse as the model** | Build finished, install result, join address mail are the highest-engagement type |
| C4 to C6 Discount win-back | **Skip** | Discounts did not move anyone; token cost makes discounting expensive. Use "here is the next step" win-back |
| C7 Email shell v2 and tracking | **Reuse as-is** | Cyrus mails are currently a separate self-contained template (`lib/cyrus/notify/templates.ts`, keeps Cyrus palette); `CYRUS_NOTIFY` is not set in prod, so no Cyrus lifecycle mail is sent today |
| D1 to D3 Analytics | **Reuse as-is, extend** | Add a Cyrus funnel section to `/admin/conversion` and to the GrowthReport snapshot |
| D6 to D8 Attribution and consent | **Reuse; turn on at the right moment** | Consent system is built and stricter than Nxeon's default-on-opt-out; keep it. Make "how did you hear about us" a visible optional field on the invite or waitlist form (452 skipped on Nxeon) |
| D7 Paid pixels | **Adapt** | Cyrus conversion outbox exists; start with first-successful-install as the conversion event, not signup |
| E1 Discord | **Adapt, owner decisions first** | The blueprint recommends a separate community guild; Cyrus can be a section of it. Decisions D1 to D6 are the gate |
| E2 Clubs | **Skip** | Not a Cyrus audience |
| E5 What's New | **Reuse** | Customer-facing only |

---------------------------------------------------------------------------
## 3. CYRUS PLAYBOOK: research-based

### 3.1 Where Minecraft server owners and modders actually discover tools

Evidence quality is mixed and I label it. Search tooling here is US-only, cannot read Reddit, and returned vendor pages for many queries.

| Surface | What is verified | What is not |
|---|---|---|
| Plugin repositories (SpigotMC, Modrinth, Hangar, BuiltByBit, Polymart, CurseForge/Bukkit) | Hosting-panel docs consistently send owners to SpigotMC, Hangar and Modrinth first; BuiltByBit and Polymart for paid (web: docs.minekeep.net/server-administration/adding-plugins, kb.falixnodes.net, mintservers.com knowledgebase). Some hosts embed repository search in the panel, so repositories are discovery layers that hosts already index | Relative traffic share between them: UNKNOWN |
| Server software | Paper about 62%, Spigot 17%, Purpur 10% of plugin-reporting servers on bStats' Bukkit page (web: test.bstats.org/global/bukkit; undated snapshot; only servers running opted-in plugins). So Cyrus's default target (Paper plugins) matches the majority | Hosted-server share running plugins: UNKNOWN |
| Search and AI assistants | On Nxeon's own data, ChatGPT first-touch 31.9% of human non-mod entries, Google 10.0% (DB) | Search volumes for "ai minecraft plugin generator": UNKNOWN (CQ also had no keyword tool) |
| Reddit (r/admincraft, r/MinecraftServer, r/feedthebeast) | Nxeon's marketing agent monitors them. Reddit-first-touch signups: 3 (DB). General norm: roughly 90% participation to 10% self-reference (web: redship.io Reddit self-promotion guide; not specific to these subs) | The actual r/admincraft self-promo rule: NOT VERIFIED (Reddit unreachable from the tool; two mirrors showed only the first rules: topic, descriptive title, effort). Owner must read the sidebar before any post |
| Discord | PaperMC guidelines: community "is not a marketplace", avoid buying/selling services, no advertising in usernames (web: papermc.io/community/guidelines). player.games runs a Discord that doubles as a credit-earning loop (web: player.games, vendor claim) | Plugin-dev Discords' rules on tool posts: UNKNOWN |
| YouTube | 44 Nxeon signups self-report YouTube (DB, from paid creator sponsorships); creators quote $100 to $5,000 per integration (note) | Which Minecraft-plugin creators have the largest audiences now: UNKNOWN (search returned dated lists). The Nxeon CSV has 80 Minecraft/Bedrock channels with median 51.3K subscribers (DB file) |
| TikTok/Shorts | 9 Nxeon signups self-report TikTok (DB) | No verified evidence of format performance for plugin content |
| Server list sites, forums, newsletters | No verified data gathered | UNKNOWN; candidate list in 3.2 is unverified |

### 3.2 Platform rules that constrain "post a listing" tactics (verified where stated)

- **Modrinth (web, fetched 2026-10-15, modrinth.com/news/article/ai-policy-and-disclosures and modrinth.com/legal/rules):** policy announced 2026-08-13, grace period ended 2026-09-27. Projects "cannot be entirely or primarily comprised of content created or derived from generative AI output" (rule 6.2) and may not be published publicly if so. AI-assisted projects where the human contributed "in a primary and significant way" are allowed but must carry the "Contains AI-generated content" disclosure (6.1: substantial AI code, AI assets, design relies on generative AI, or page text relies on AI). AI images for gallery and icons are not allowed. **Consequence for Cyrus: a prompt-only Cyrus mod is likely "primarily AI output", so publishing it on Modrinth is probably against the rules, and a Cyrus account must never auto-post there.**
- **Hangar (web, hangar.papermc.io/guidelines):** no AI rule found; advertising is not allowed; no paywalls or license keys; related documents such as docs and tutorials, source and support Discords are allowed links. A Cyrus-built plugin is a normal plugin; a project that is an advertisement for Cyrus is not allowed.
- **SpigotMC:** resource guidelines on AI NOT FOUND. UNKNOWN. Owner or agent must read spigotmc.org resource rules before telling users it is fine.
- **CurseForge:** no AI policy found. UNKNOWN.
- **Product Hunt:** asking for upvotes is against its guidance; incentivised votes can drop or remove a product (web: Product Hunt help centre via secondary summaries; not read directly).
- **Hacker News Show HN (web, news.ycombinator.com/showhn.html):** "something you've made that other people can play with"; "Don't post landing pages or fundraisers"; "If your work isn't ready for users to try out, please don't do a Show HN"; asking friends to upvote is not ok. **A waitlist cannot be a Show HN.** Plan Show HN only when anyone can try it.
- **Mojang:** see 6.1. I could not retrieve the primary document (timeouts); points below are from secondary summaries.

**Net effect on tactics:** "launch posts on Modrinth/Hangar/Spigot" from the original brief is mostly not viable as promotion for Cyrus the service. The right shape is: Cyrus hosts the mod pages itself (the community mod pages already built), provides an "AI disclosure kit" for authors who choose to publish elsewhere, and spends repository effort on being a good citizen (docs, source, support link), not on listing Cyrus.

### 3.3 Competitors and positioning

| Product | What I verified (source) | Claims that are vendor-only |
|---|---|---|
| player.games | No-code AI plugin and mod builder for Spigot/Paper/Fabric/NeoForge (web: player.games/create-minecraft-plugins-without-coding and player.games). Output: compiled JAR with full source. "Validated against real servers". Free to start; linking Discord earns starter credits and activity "up to 75 more every day"; credit packs, no prices on the homepage (a search snippet said packs start at $8; I could not re-verify). Localised pages (en, de, es, pt-BR, zh-CN). Hytale and Palworld in nav | "30,000+ active creators", "10,000+ mods built (last 6 months)", "13m 26s average idea-to-mod", "98.2% real-server test pass rate" are homepage claims with no method shown |
| Kodari | AlternativeTo listing: one-time purchase $10 to $150 plus limited free version; no reviews (web: alternativeto.net via search; the page itself returned 403) | |
| BukkitCode | Hangar project, version 1.1.0, Paper 1.12 to 1.21.11, web agent exports a project file that an in-server compiler builds; 3 downloads, 0 stars, published 2026-08-28 (web: hangar.papermc.io/SeraphinaNiko/BukkitCode) | |
| ModCrafter | Datapack generator on a lovable.app subdomain (web, per CQ) | |
| MCreator | Established visual mod maker (not fetched; 403). Positioning: you design in a GUI, no AI-first | |
| MythicMobs | Dominant custom mob/boss plugin; free tier plus Premium and Premium+ (web: wiki.mythiccraft.io/mythicmobs/Premium-Features). Pre-made configs and commissioned mobs sell on BuiltByBit with no fixed prices (web search) | "free covers 95% of needs" is a third-party estimate |

Observed market gaps (inference, not measured): (a) every competitor sells "plugin from a prompt"; none that I found sells a verified, installed, rolled-back mod including art and sound assets; (b) none shows cost before a build; (c) social proof from competitors is vendor-made, so a transparent, reproducible showcase beats claims; (d) the recurring user complaint about AI plugins (from an ARK plugin-forum poll, used as a proxy, web) is "looks like it works, breaks on update, hurts performance, destroys trust in plugins". Proof of testing and rollback answers exactly that.

**Differentiated positioning statement (draft, claim-checked against internal docs):**
> Cyrus is the AI mod studio for Minecraft server owners. Describe the mod in plain words; Cyrus builds the plugin and its art, sounds and models, boots it on a real Paper server before you see it, and installs it on your Nxeon server with one click and a rollback. You see the cost first and you keep the source.

Claim checks: "boots on a real Paper server" = Test Flight gate (r12), but pass rate is UNMEASURED publicly (no paid baseline, BM note). "art, sounds, models" = texture, sound (Saka+) and model studios exist; creature model is gated ("26.1.2 or newer" note). "one click" is for Nxeon-hosted servers only; elsewhere it is a JAR plus source download. "cost first" = plan screen exists but under-states by 2.1 to 2.5x (BL note); fix before using this line in paid ads. Keep each sub-claim off the page until its evidence exists.

### 3.4 ICP segments and messages

| Segment | Who | Job to be done | Message (one line) | First proof asset | Channel |
|---|---|---|---|---|---|
| S1 Server owner, non-coder (primary) | Runs a Paper/SMP/minigame server for friends or a community, has no Java skills | Add a feature nobody sells (custom boss, quest, shop GUI) without hiring a dev | "Describe the boss you want. We test it on a real server first." | The dungeon or goblin boss story with real prompts, cost and fail points | AI search, r/admincraft help threads, Nxeon free-MC owners, Discord |
| S2 Hobby developer | Writes some Java, hits boilerplate and asset work | Skip scaffolding, get compile-clean code, keep the source | "Full source, real API, no lock-in. Cyrus does the assets you hate." | Public build log plus repo of one generated plugin; diff showing what the model got wrong | Hangar docs, GitHub, HN at public launch |
| S3 Modpack / datapack maker | Curates packs, needs custom items and recipes | Fill gaps in a pack | "Custom items, mobs and loot as a data pack or mod, with conflict checks." | Mod Packs conflict engine demo | Modrinth/CurseForge pack communities (do not post tool ads; contribute) |
| S4 Content creator | YouTuber/streamer with an SMP | A new feature for each episode; a story | "Make your series' next mod live on camera." | A creator-ready 60 second cut: prompt, build, join, play | Direct creator programme (4.4) |

Message discipline from Nxeon's lesson: state what is free and what is not (one free build), say "private beta, invited testers" until it is public (BR note says the page already does), never promise a pass rate you cannot show.

### 3.5 Content formats to test (hypotheses, not proven)

Evidence anchors: ChatGPT cites concrete, factual pages; bulk blog and tools did nothing; creators ask for fixed fees; player.games leads with demo videos and a showcase (web). So test few formats, each with a kill metric:

1. **Real-build case files** (the 100-floor dungeon story, goblin boss, crates quest): prompt, plan screen, cost, failures, install, play clip. Honest about misses (the Infinite Dungeon run was blocked by the daily token cap and killed twice by the 600 s wall clock before mega-staging existed, CK and CM notes). Format: long page plus 60 s cut. Kill if under 100 human visits and 0 signups after 21 days.
2. **"I asked AI to make X" video** with a human host: only with a real, passing build. Test with 3 mid-size creators before making your own.
3. **Before/after clips**: stock server vs server with the mod, 15 s, for Shorts/TikTok. UNKNOWN effect; cheap to test.
4. **Speedbuild**: timelapse of build, test flight and install (about 8 to 12 minutes real time; Saka fresh builds median 450 s, BL note). Use the live progress feed (CL note).
5. **Prompt library**: public, opt-in, "prompts that produced a passing mod" with output pages; doubles as SEO and activation.

Do not use fabricated reviews, unreproducible comparisons, or an AI-voiced "customer" quote.

---------------------------------------------------------------------------
## 4. 90-DAY ROADMAP (Mon 2026-10-19 to Sun 2027-01-17)

Principles: activation before reach; every wave gated by data; every claim backed by a reproducible build; human approval before anything external is sent or posted (matches the standing no-send-without-approval rule).

### 4.0 Preconditions that already exist or are blocked

| Item | State | Needed for |
|---|---|---|
| SEO technical branch (robots, sitemap, canonical, OG, JSON-LD) | Built (CR), NOT deployed; cyrus.my currently serves Nxeon robots and Nxeon-canonical legal pages (CQ audit) | Everything indexable |
| Community branch (username gate, author tags, library page, admin tools) | Built (CP), NOT merged; schema push needed | Mod pages with author tags |
| Google login on cyrus.my | Built (CS), NOT deployed | Signup friction (Nxeon: 70 to 80% Google sign-in) |
| Legal pages | Written (CT); no acceptance versioning | Public launch |
| Token economy | OFF (`cyrus_tok_live` not set); plan prices placeholders; 500 vs 300 tokens-per-USD undecided | Pricing messages, paid tests |
| Eval baseline | NONE paid (BM); rc11 first-try pass 75.7% on 70 builds and a projected 97.1% after fixes (BT; a projection, not a live number) | Any pass-rate claim |
| Waitlist | Does NOT exist; allow-list `preview_access_emails_modbuilder` has 2 emails | Invite waves |
| Lifecycle mail | `CYRUS_NOTIFY` not set | Activation mail |
| Reference showcase | Infinite Dungeon NOT built (blocked at daily cap, CK); goblin and crates mods exist (CQ) | Hero content |

### 4.1 Launch sequence (waves)

| Wave | When | Size (proposal) | Who | Gate to proceed |
|---|---|---|---|---|
| W0 private alpha | Weeks 1 to 3 | 25 | Hand-picked: Nxeon Minecraft server owners (paid and the free-MC owners who woke a server), 8 to 10 creators from the CSV (10K to 100K subscribers), a few hobby devs | See gates below |
| W1 | Weeks 4 to 5 | +100 | Waitlist, ordered by fit (has a server, answered "what do you want to build") | Same |
| W2 | Weeks 6 to 8 | +300 | Waitlist plus W0/W1 referrals | Same, plus cost per active user within cap |
| W3 | Weeks 9 to 11 | +1,000 | Waitlist, creator codes live | Plus moderation and report queue working |
| Public | Weeks 12 to 13 (target Jan 12 to 14) | open | Everyone | All launch gates (6.4) |

Wave gates (proposal, no benchmark exists; revise after W0):
- Median time from signup to first Test-Flight-passed build under 30 minutes.
- At least 50% of invited signups start a first build within 48 hours; at least 60% of first builds pass without a human fix.
- At least 40% of passed builds are installed on a server within 24 hours.
- Support load: median first response under 12 hours with the person available.
- Spend: average AI cost per activated user under the cap set from the plan price (price UNKNOWN, owner).

### 4.2 Week by week

| Wk | Dates | Product / growth work | Content / SEO | Community / creators | Owner vs agent |
|---|---|---|---|---|---|
| 1 | Oct 19 | Promote CR SEO, CP community, CS Google login, CT legal after review; verify GSC (DNS TXT), Bing import, IndexNow, `www` 301 | Home head (canonical, OG, JSON-LD) live; capture week-1 baseline | Choose W0 list | Owner: promote, DNS, decisions. Agent: verify, runbooks |
| 2 | Oct 26 | Waitlist (email, double opt-in, "what will you build", server type: Nxeon / elsewhere / none, "how did you hear"), position and share link; invite mechanism with codes; event instrumentation (4.8); paid baseline eval | Plain "what Cyrus can and cannot do" page and `llms.txt` for cyrus.my | Send W0 invites after owner preview | Agent builds; owner approves copy and eval spend |
| 3 | Nov 2 | Activation emails (4.7) on shell v2; `CYRUS_NOTIFY` on; "invite a friend to join" card after install; cost screen honest (calibrated estimates, BL/BM) | Complete the Infinite Dungeon staged run (owner raises daily cap); capture screen recordings of 3 hero builds | W0 feedback calls (15 min each) | Owner records and runs calls |
| 4 | Nov 9 | W1 invites (+100); /admin/conversion Cyrus panel; weekly review starts | Use-case pages 1 to 3 (custom weapon, boss, GUI shop) with real prompts and outputs (CQ) | Seed 5 creators (free access, no obligation) | Agent drafts; owner approves claims |
| 5 | Nov 16 | Fix top 3 drop-offs found in W0/W1 data | Use-case 4 to 6; guide G1 (custom boss) | Discord section opened (needs community guild, E1 decisions) | Owner decides D1 to D6 |
| 6 | Nov 23 | W2 starts (+300); referral loop v1 behind flag (4.6) | Guide G2 (100-floor dungeon plugin) if the real build passes | First "mod of the week" spotlight | Owner picks spotlight; agent produces page |
| 7 | Nov 30 | Mod pages public for invited users only (gated flags); report and ban flow verified | Use-case 7 to 8; comparison page (honest, facts only) | Creator programme v1 live (4.4) | Owner signs creator terms |
| 8 | Dec 7 | W2 review; decide W3 | Guide G3 (plugin without coding); Cyrus entries on AlternativeTo (prepare) | Monthly build-off #1 announced | Owner runs contest rules past legal check |
| 9 | Dec 14 | W3 starts (+1,000); paid tests begin (4.9) | Use-case 9 to 10; G4 (quests) | Creator integrations scheduled for Jan | |
| 10 | Dec 21 | Holiday freeze on risky deploys; monitoring only | Build-off results, spotlight | | Owner: pause |
| 11 | Dec 28 | Public-readiness review against gates (6.4) | G5 (install on a server, backups, rollback) | Creator videos publishing | Owner decides go / no-go |
| 12 | Jan 4 | Public opening prep; Show HN prep (needs a no-signup try path or accept that HN is not for this stage) | Press kit, changelog | | Owner decides launch day |
| 13 | Jan 11 to 17 | Public launch; Show HN (only if tryable), Product Hunt, AlternativeTo, creator wave, Discord event | Launch post: build log, numbers from waves (real) | | |

### 4.3 Content calendar tie-in with the SEO plan

Follow CQ section 7 (use-cases 1 to 10, guides G1 to G5) but gate each page on a reproducible build. Add: (a) the dungeon and goblin case files as the two anchor pages; (b) a "what Cyrus cannot do" page (limits as a trust and GEO asset); (c) a monthly "what we got wrong" post; (d) the prompt library once there are 50 opt-in passing prompts. Cadence: about 2 pages a week, never a batch drop. Measure with CQ section 8 KPIs and the alert thresholds in CQ section 6.

### 4.4 Creator and partner programme for Cyrus (rev-share design using the Nxeon machinery)

Two different meanings of "creator" must not be mixed: **promo partners** (YouTubers who bring users; Nxeon `ReferralPartner`) and **mod authors** (users who publish; `CyrusCreator` with username). This section is about promo partners.

What Nxeon already provides (reuse): code and `/partner/<code>` link; click log; automatic attach at registration; commission on net paid invoices only, idempotent; refund and chargeback reversal; partial payouts ledger; portal with analytics, media kit and promo generator; invite flow with owner preview; cross-host attribution from cyrus.my via consented `attr` (r44) into the `nxeon_ref` cookie; Cyrus plan commission hook (r38).

Evidence for design: 26 of 49 replying creators reject commission; quotes run $100 to $5,000; CPM $10 to $25; the Nxeon 50/40 structure yielded 2 payers from 21 attached customers in 19 days.

Proposed tiers (proposal, owner sets numbers; plan prices are UNKNOWN):
1. **Seed (no obligation)**: free Saka or Yakko tokens for a fixed amount, a 15 minute onboarding call, no required post. If they mention it, they follow disclosure rules (6.3). Target 10 to 15 creators. Cost: tokens at AI cost (a Saka fresh build median $0.55, so 200 tokens a creator is cents to dollars).
2. **Code partner**: referred user gets a one-time bonus of tokens (not a percent discount, because discounts did nothing for Nxeon win-back); partner earns a recurring share for a fixed window, for example a percentage of net plan revenue for 12 months, not lifetime. Because AI cost is variable, pay on revenue after estimated AI cost, or cap per user. Nxeon's own note warned 40 to 50% lifetime is aggressive for hosting margins; it is worse for variable-COGS AI.
3. **Fixed-fee integration** for the few that matter: 60 to 90 second integration with code and link. Nxeon quotes for comparable channels: $100 to $5,000; use channels at or below $1,000 for tests. Pay half before and half after upload, which one creator quoted themselves.
4. **Hybrid**: fixed fee plus a lower commission (11 creators say yes to commission alongside; 1 asked for fixed plus 40%).

Terms to put in writing (agent drafts, owner approves): disclosure requirement and wording; no claims about pass rate or "unlimited"; brand and Mojang rules (6.1); approval of any claim about outputs; kill on policy breach; payout terms (Nxeon has no payout minimum or schedule decided, note). Kit: prompt text, a real build to film, the result mod to install, endcard, the `?ref=` link and code, and the honest "private beta" line.

### 4.5 Community plan (Discord, showcase, contests, spotlight)

- Discord: use the separate community guild approach from the Nxeon blueprint (support tickets must not share space with public chat). Cyrus channels: showcase, prompts-that-worked, fails-and-fixes, requests, changelog, help. Staff-run only until W2. Listing sites only after it has real members.
- Showcase: a post needs a join address or a clip of the mod working. Spotlight "mod of the week" = a curated page (existing `cyrus_featured_pages` and featured API), picked by the owner from public mods that pass Test Flight, have a screenshot or clip, and an author tag.
- Contests (monthly build-off): skill contest, theme set in advance, judged on a stated rubric, prize in tokens and a hosted-server month (cheap marginal cost) plus spotlight. Legal checks: official rules, no-purchase-necessary, age floor, taxes, and not implying Mojang endorsement.
- Do not copy a credit-for-activity Discord economy (player.games, vendor claim): it invites farming and costs real AI money per token.

### 4.6 Referral loop (tokens for invites, with safeguards)

Design: invite link per user from the post-install screen ("send this to the friend who will join") and from the mod page. Reward both sides in tokens when the invitee's first build passes Test Flight and is installed on a server. Safeguards: verified email only; reuse `starterEligibility` (blocks throwaway domains, normalises alias addresses and plus-tags); idempotency keys in the token ledger; monthly cap per referrer (proposal 10); reward tokens expire; refund or chargeback reverses; no cash value; block self-referral by same device or IP cluster; fraud review of any referrer above the cap. Honest expectation: Nxeon peer referral produced 1 referred signup in total, so do not forecast this loop; it exists to give the activated user a natural next action.

### 4.7 Email lifecycle (use the shared shell and tracking)

Build on shell v2 (header, dark card, icon tile, gradient button, footer, tracking pixel, rewritten links, one-click unsubscribe, secret-link exemption). Send via marketing class `product_news` only where it is promotion; transactional where it is account state. Event-triggered, never blast:

| # | Trigger | Message | Why |
|---|---|---|---|
| 1 | Waitlist join | Confirm, position, share link | Double opt-in |
| 2 | Invite | "Your invite", 3 starter prompts that prefill `/new?prompt=` | Reduces the blank-box problem |
| 3 | Signup, no build in 24h | One tailored starter (based on "what do you want to build") | Activation |
| 4 | Build finished | Result, cost, install button | Critical-path mail (highest engagement type on Nxeon) |
| 5 | Build failed or refunded | What happened, tokens returned, what to try | Trust |
| 6 | Passed but not installed (1h) | "Install on your server" or "download JAR + 3 steps" | Gap on the path |
| 7 | Installed, no player joined (24h) | Join address (Java and Bedrock if applicable), share card | Nxeon free-MC finding: "how do I invite a friend" was the first-hour question |
| 8 | First mod live | "Publish it" page and share image | Public page loop |
| 9 | Low tokens or daily cap hit | Plan options, honest cost | Revenue |
| 10 | Dormant 7, 21, 45 days | What's new + one suggested build | Retention (Nxeon: ~5% of signups return) |

Success metric per mail is the next product event, not opens (Nxeon: open rates 8 to 21% on drips; opens are unreliable). Frequency cap: one marketing mail per 3 days per user, none if they built in the last 24 hours. Note: `CYRUS_NOTIFY` must be set and the mail class mapped.

### 4.8 In-product growth loops (use what is built)

1. **Public mod page to remix**: author tag (username), stars, ratings, install button, remix tree; "Make this your own" opens `/new?like=<slug>`. All built; CyrusRemix, ratings, stars rows are 0 today.
2. **Light attribution**: README and LICENSE already carry author credit (CP note). Add plugin.yml `website`/description link to the mod page and one startup log line. Free tier on by default, paid can remove. Owner decision on any in-game text.
3. **Share links with OG card**: per-mod OG image is NOT built (CP gaps); build it.
4. **Test-Flight badge**: show "verified on Paper 1.21.11" only when real.
5. **Prompt library** (opt-in) feeding SEO and `/new` prefill.
6. **Continue on desktop**: 36 to 45% of Nxeon signups were mobile and almost none ordered (friction report). Mobile should do "send me this link and a starter prompt", not building.

### 4.9 PR and launch moments

| Moment | When | Rules and honesty |
|---|---|---|
| Directory listings (AlternativeTo etc.) | Public launch week | Truthful descriptions; Kodari is listed there already (web) |
| Show HN | Only when a real try path exists without waiting for an invite | Show HN rules above; owner must be present to answer all day |
| Product Hunt | Within a week of public launch | Do not ask for upvotes; incentivised voting risks removal |
| Reddit | Help threads first; "I built" post only after reading the sidebar | Disclosure line; marketing agent drafts, human posts |
| Modrinth / Hangar / Spigot | Not as promotion | See 3.2 |
| Creator videos | Jan | Disclosure 6.3 |

### 4.10 Paid acquisition tests (budget and kill criteria; proposal)

Total test cap (proposal) $1,500 across 90 days. Do not start before: pass-rate evidence exists, cost screen is honest, conversion event is first installed mod, consent is live. Ad conversion outbox exists; Google Ads upload is inert (needs developer token, note).

| Test | Budget | Hypothesis | Success | Kill |
|---|---|---|---|---|
| Google Search, exact and phrase "ai minecraft plugin generator" family | $15/day for 14 days, $210 | Intent exists and CPC is tolerable | Cost per first installed mod under $20 | Under 8 signups after $150, or cost per installed mod above $40 |
| Small creator fixed-fee (3 channels, 5K to 50K subs) | $500 to $900 | Right audience and a trackable code | Under $30 per installed mod | No attached signups after 21 days |
| Reddit ads on the 3 subs, if the platform allows the category | $100 | Cheap test of copy | CTR above the account baseline | CTR below 0.3% (proposal threshold; UNKNOWN norm) |
| Retargeting waitlist (hashed email, with consent) | $100 | Convert waitlist that stalled | Cost per invite acceptance | |

---------------------------------------------------------------------------
## 5. METRICS

### 5.1 North star

**Time to first working mod: minutes from account creation to a Test-Flight-passed mod installed on a server the user owns.** Count only human, verified-email users. Report the median and the share achieved within 24 hours. Proposed first targets: median under 30 minutes, 40% of activated accounts within 24 hours (no benchmark; set after W0). A stricter lagging version: "a second player joined the server with the mod installed" (needs server telemetry; the telemetry ingest returns 503 until its tables exist, Z note; A2S/RCON player counts exist for Nxeon-hosted servers).

### 5.2 Activation funnel definitions

Human visitor (same definition as `/admin/conversion`: isBot false, botKind null or human, no webdriver) -> waitlist join -> invite accepted -> signup (verified email) -> username claimed -> first prompt submitted -> plan screen acknowledged -> build started -> build succeeded -> Test Flight passed -> install requested -> install OK -> first player joined (Nxeon-hosted only) -> second build within 7 days -> mod published -> invite sent -> paid. Each step is one event with account and session id, deduped per actor (same dedupe pattern as the deploy funnel route).

### 5.3 Leading indicators and where they come from

| Indicator | Why | Source |
|---|---|---|
| Waitlist conversion, invite acceptance | Demand and mail quality | New Cyrus tables |
| First prompt within 24h of signup | Blank-box problem | CyrusProject/build rows |
| First build pass rate (Test Flight) | Product quality | Build records; eval baseline |
| Cost per build vs shown estimate | Honesty and margin | Ledger (BL note) |
| Install success and rollback rate | Trust | Delivery status |
| Share and remix click-through | Loop strength | Link events |
| Referral reward rate | Loop | Ledger |
| Creator code click to signup to installed mod | Channel quality | ReferralClick, PartnerCustomer |
| Indexed pages / submitted, non-brand impressions | SEO | GSC (CQ thresholds) |
| AI-assistant visibility score for 30 prompts | GEO | AI-visibility panel |
| Human share of sessions | Data quality | trafficQuality() |

### 5.4 Dashboards and review cadence

Extend the existing machinery rather than a new tool: a Cyrus panel in `/admin/conversion` (funnel, drop-off reasons, outcomes) and a Cyrus block in the GrowthReport weekly scoreboard (Monday-start UTC). Add a source breakdown that discards unlinked first touches explicitly ("unknown" was 40% on Nxeon). Weekly 30-minute review, Monday: human visitors, waitlist, invites, activation, pass rate, cost, creator code results, top 3 drop-offs, decisions. Monthly: content decay, keyword re-research from real GSC queries. Quarterly: positioning check against competitor claims.

Definitions to carry over from NX-conversion: human visit, engaged human, visitor, wizard actor, step conversion, drop-off reason ("no reason logged" shown rather than guessed), payments by method, abandoned value.

---------------------------------------------------------------------------
## 6. RISKS AND COMPLIANCE

### 6.1 Mojang / Minecraft brand and content (NOT fully verified)
I could not load Mojang's primary Usage Guidelines (timeouts). From secondary sources: commercial use is a section of the Usage Guidelines; servers may charge under conditions; the Minecraft name may not be the first word of a server name or imply official affiliation; selling mods outside an approved platform is disputed between summaries; the permissions can be withdrawn at any time (web: gameserverkings.com monetisation guide, minehut wiki MUG FAQ, conductatlas summaries, minecraft.net EULA snippet). Cyrus implications (proposal, verify before launch):
- Keep "not affiliated with Mojang or Microsoft" and no use of the logo as a brand mark (already in the Terms, CT note).
- Do not put "Minecraft" first in product or domain naming; do not use official-looking marks.
- Cyrus sells a generation service (tokens), not mods; public mod pages must remain free downloads. The creator-sells-mods marketplace is parked (Mojang EULA question, FULL-PLAN note) and should stay parked.
- Owner or counsel should read the primary document and record the answer in docs/cyrus/10-decisions.md.

### 6.2 AI-content and repository policies
Modrinth bans primarily-AI projects and requires disclosure (3.2). Spigot and CurseForge UNKNOWN. Give authors a disclosure kit; never auto-publish; show "AI-generated" status on Cyrus pages.

### 6.3 Creator promotion (FTC, ASA/CAP)
- FTC (web, ftc.gov/business-guidance/resources/disclosures-101-social-media-influencers): disclose any financial or material relationship including free product; put it with the endorsement, audible and visible in video, repeated in live streams; avoid "sp", "collab", stand-alone "ambassador"; do not endorse something not tried; applies to posts from abroad reaching US consumers.
- UK ASA/CAP (web, asa.org.uk influencer guidance and law-firm summaries): affiliate links and discount codes count as advertising and need an upfront "Ad" or "#ad"; own-product promotion is also expected to be labelled; labels like "aff" are not safe.
- Therefore every creator contract must require disclosure wording and a link to the rules; seeded free tokens are a material connection. Also AI capability claims need substantiation: never quote a pass rate without a published method and date.

### 6.4 Consent, privacy, and data
- Consent system stricter than Nxeon's: nothing optional before a choice, reject-all as easy as accept, 180-day choice, 30-day attribution, ad ids only with marketing consent, hashed email only (CT, `lib/cyrus/analytics/consent.ts`). Keep default OFF flags until the banner and copy are live. Withdrawal does not stop an already queued conversion (CT open item); close before paid tests.
- No legal acceptance versioning exists (CT); add before public launch.
- Waitlist and lifecycle mail: double opt-in, unsubscribe on every marketing mail, suppression (existing). Do not cold-email server owners at scale.
- Data export and delete exist (`CYRUS_GDPR_ERASE`); keep the 14-day wait wording honest.
- User text on public pages may contain personal data; scan before indexing (CQ).

### 6.5 Product, cost, and reputation risks
- **Cost opacity**: the plan screen under-states cost by 2.1 to 2.5x for Saka and Katara change builds (BL). Selling "see the cost first" with that gap invites refunds and chargebacks. Fix first.
- **Free-token abuse**: starter 70 tokens is already guarded (verified email, alias dedupe, throwaway block); referral and Discord rewards need the same guards.
- **Quality claims**: no paid eval exists; competitor claims of 98.2% are vendor-made and will make any number you publish look low unless the method is shown.
- **Scaled-content risk**: repeat of the Nxeon mod-page cliff. Mitigation: publish cap, quality bar, near-duplicate noindex.
- **Platform dependence**: ChatGPT citation is unmanaged; ccTLD .my is a Malaysia geo-signal Google may weigh against a global English audience (CQ; cannot be changed in GSC).
- **Reliability**: build wall-clock kills and daily token cap hit the owner in the dungeon run (CK, CM); invited testers will hit them too. Staging for mega prompts is built but flagged OFF.
- **Brand voice**: Nxeon speaks as itself and never names a third-party infrastructure provider. Legal pages must name processors (Anthropic and others); marketing should not lead with the model vendor; owner to confirm how to treat this.
- **Measurement bias**: Nxeon's raw traffic is 98.6% non-human; Cyrus must not report raw sessions anywhere.

---------------------------------------------------------------------------
## 7. TOP 15 ACTIONS (ranked by impact over effort)

Owner = needs the owner's hands or decision. Agent = can be done by an agent on a branch, then owner promotes.

| # | Action | Impact | Effort | Who | Needs owner decision |
|---|---|---|---|---|---|
| 1 | Deploy the already-built Cyrus SEO technical branch, community branch, Google login, legal pages; verify cyrus.my robots, sitemap, canonicals; verify GSC and Bing | Very high (foundation; today cyrus.my legal pages canonicalise to the Nxeon home) | S for owner (promote, DNS TXT), S agent verify | Owner promotes, agent verifies | Canonical host model (cyrus.my vs nxeon.cloud for mod pages) |
| 2 | Build waitlist and invite-wave mechanism (double opt-in, role and server-type questions, referral position, wave sizing, codes) | Very high | M | Agent | Wave sizes, gates, "how did you hear" required or optional |
| 3 | Instrument the activation funnel and add a Cyrus section to /admin/conversion and the weekly scoreboard; human-only | Very high | M | Agent | North-star target numbers |
| 4 | Run the paid baseline eval, fix cost-estimate under-statement, decide Saka model and tokens-per-USD; only then allow pass-rate and cost claims | Very high (every claim depends on it) | S to M, $10 to $20 spend (BM) | Agent runs; owner approves spend | Saka on 5.5, 500 vs 300 tokens per USD, prices |
| 5 | Finish the Infinite Dungeon real run and capture 3 hero builds with recordings | High | S agent, owner raises cap and records | Both | Daily cap, who is on camera |
| 6 | Seed W0: 25 hand-picked users (Nxeon Minecraft owners, 8 to 10 mid creators), white-glove onboarding, 15-minute calls | High | S | Owner | List approval; creator email previews (standing rule) |
| 7 | Event-triggered activation mail set (section 4.7) on shell v2; set `CYRUS_NOTIFY`; post-install "invite a friend" join card | High | M | Agent | Copy approval |
| 8 | cyrus.my facts pages, `llms.txt`, and the 30-prompt AI-visibility panel for Cyrus (GEO first) | High | S to M | Agent | Claims review |
| 9 | Use-case pages 1 to 6 and guides G1 to G3 from CQ, each with a reproducible build, 2 per week | High | M ongoing | Agent drafts, owner approves | What counts as "reproducible" sign-off |
| 10 | Creator programme v1: seed tier, hybrid code plus fixed fee for 3 to 5 channels, disclosure kit, Cyrus media-kit brief | Medium to high | M | Agent builds kit/terms; owner negotiates | Commission %, window, fixed-fee budget, payout terms |
| 11 | Turn on public mod pages (invited users first), report flow, ban flow, quality gate, author tags; per-mod OG image | Medium | S to M | Agent; owner flips flags | Launch pair flags, in-game attribution text |
| 12 | Community: Discord section, showcase rules, first "mod of the week", monthly build-off | Medium | S to M | Owner creates guild; agent writes rules and templates | Blueprint decisions D1 to D6, contest legal check |
| 13 | Marketing agent: add Cyrus sources and keywords (human-post-only, disclosure line) | Medium, cheap | S | Agent | Reddit API credentials, posting accounts |
| 14 | Referral loop v1 (tokens on invitee's first installed mod, caps, reversal) | Medium (uncertain) | M | Agent | Token amounts, monthly cap |
| 15 | Public launch package: Show HN only if a real try path exists, Product Hunt, AlternativeTo, paid tests within the $1,500 cap | Medium | M | Owner leads | Go/no-go, budget, launch date |

Owner decisions needed before work starts (collected): canonical host model; plan prices and token economy; wave sizes and gates; whether any in-game or plugin.yml attribution is acceptable; commission versus fixed-fee budget; who appears on camera; daily token cap for the dungeon run; Mojang guideline review; marketing spend cap; Discord blueprint D1 to D6; model-vendor naming in marketing.

---------------------------------------------------------------------------
## Appendix A: what I could not verify (do not treat as fact)

- r/admincraft, r/MinecraftServer, r/feedthebeast self-promotion rules (Reddit unreachable).
- Mojang Usage Guidelines primary text (timeouts); only secondary summaries.
- SpigotMC and CurseForge AI rules; PaperMC Discord channel rules.
- Search volumes for any Cyrus keyword; CPCs; creator audience sizes today; which newsletters or server-list sites matter (candidates such as Planet Minecraft, server list sites and community newsletters are unverified).
- Competitor numbers (player.games users, pass rate, speed) are homepage claims; Kodari price range from a search snippet of an AlternativeTo page that returned 403.
- Product Hunt rules were read via secondary summaries; "best day" claims unverified.
- Nxeon ad cash spend; partner creative adoption; whether coldemail tagged visits were creators or business leads.
- Source attribution for 408 of 1,019 recent signups (no linked visit). A cluster of 22 signups (19 ever paid) arrived with a nxeon.cloud subdomain referrer on the directory page; that pattern looks like internal or test accounts and I excluded it from conclusions; owner should check.
- The "paid" definition here is "has at least one PAID invoice above zero" and excludes `excludeFromRevenue` accounts; wallet-only spenders without invoices are not counted.

## Appendix B: sources

Internal: /root/CLAUDE.md; memory/MEMORY.md; agent-notes/NX-conversion-2026-10-15.md; cyrus-research/CQ-seo-plan-2026-10-15.md, CR-seo-tech-2026-10-15.md, CP-community-audit-2026-10-15.md, CT-legal-2026-10-15.md, CS-google-login-2026-10-15.md, BR-site-live-2026-10-14.md, BM-readiness-audit-2026-10-13.md, BL-token-savings-plan.md, BT-rc11-first-try-2026-10-14.md, CK-infinite-dungeon-2026-10-15.md, CM-mega-staging-2026-10-15.md, CYRUS-FULL-PLAN.md; agent-notes/seo-discoverability/ANALYSIS.md, signup-friction/REPORT.md, creator-fixed-fee/creators-want-fixed-fee.csv, creator-promo/BRIEF.md, creator-kits/MEDIA-KIT-BRIEF.md, nx-marketing-emails-report.md, nx-email-rollout-report.md; /opt/nxeon/docs/DOCUMENTATION.md (growth G1 to G7, Marketing Agent, Cold Email, Creator Partner Program), docs/growth/LISTINGS-AND-OUTREACH.md, docs/cyrus/CYRUS-MY-LAUNCH.md; lib/cyrus/tokens/*, lib/cyrus/analytics/*, lib/cyrus-bridge/attribution.ts; memory notes nxeon-seo-growth-strategy, nxeon-creator-partner-program-live, nxeon-referral-and-currency, nxeon-free-minecraft-tier, nxeon-meta-pixel, nxeon-riddle-and-ads, nxeon-retention-winback-emailtrack.

Web (fetched or searched 2026-10-15):
- https://modrinth.com/news/article/ai-policy-and-disclosures/
- https://modrinth.com/legal/rules
- https://hangar.papermc.io/guidelines
- https://hangar.papermc.io/SeraphinaNiko/BukkitCode
- https://papermc.io/community/guidelines
- https://www.player.games/create-minecraft-plugins-without-coding and https://www.player.games/
- https://alternativeto.net/software/kodari/about/ (via search)
- https://wiki.mythiccraft.io/mythicmobs/Premium-Features
- https://news.ycombinator.com/showhn.html
- https://www.ftc.gov/business-guidance/resources/disclosures-101-social-media-influencers
- https://www.asa.org.uk/static/790d2e01-e3f8-4fea-b3c99ef91a9f04dc/Influencerguidance2023v4-FINAL.pdf (via search summary)
- https://test.bstats.org/global/bukkit (via search)
- https://modrinth.com/news/article/creator-monetization and https://modrinth.com/legal/cmp-info (via search; creator rewards revenue-share model: creators' share reported as 75/25 in the latest version seen, 90/10 earlier; verify before using as a design reference)
- https://www.gameserverkings.com/knowledge-base/minecraft/monetising-your-server/ and https://minehut.wiki.gg/wiki/MUG_FAQ (via search)
- https://redship.io/blog/reddit-self-promotion-rules-2026 (general Reddit norm)
- https://docs.minekeep.net/server-administration/adding-plugins ; https://kb.falixnodes.net/falix/dashboard/content/plugins ; https://mintservers.com/lt/knowledgebase/where-to-find-mods-and-plugins-for-your-minecraft-server

---

## 9. Content, spotlight and hosting cross-sell (appended 2026-10-15 by the content-engine agent; code on `feature/cyrus-content`, design in `docs/cyrus/20-content.md`, report `DC-content-engine-2026-10-15.md`)

**Scope.** The owner asked for blogs, a "best mods of the week" spotlight, game and mod pages, SEO, and Nxeon hosting cross-sell pages with a code and tokens. Everything below is BUILT behind switches (all off) and NOT deployed. One request was refused on purpose: artificially inflated views, ratings and invented authors. The honest equivalent (real counters that read "New", an editorial Staff pick and Mod of the week, real Cyrus-built seed mods under "Made by the Cyrus team") is what ships, and it fits section 4.5 of this plan (spotlight = curated, with a reason, from public mods that pass Test Flight).

### 9.1 Page inventory (cyrus.my)

| Page | Count at launch | Indexable when | Purpose |
|---|---|---|---|
| `/games`, `/games/minecraft` | 2 | content public + indexing on | game hub; spotlight, categories, real captures, hosting CTA |
| `/games/<soon game>` | up to 6 | never (stub) | honest "coming soon", no dates |
| `/mods` | 1 | at least one mod passes the bar | This week, Staff picks, all mods, categories, search |
| `/mods/<slug>` | one per published mod (26 pages exist; 2 public today) | summary >= 120 chars, >= 1 command or feature, Test Flight not failed | the share-ready page: author tag, real counters, one-click install, honest status |
| `/host` | 1 | a Cyrus game with a plan and a location | hosting hub |
| `/host/<game>` | 1 per priced game (46 render; only Cyrus-live games index: Minecraft) | game is Cyrus-live or owner-allowed | "Minecraft server hosting" |
| `/host/<place>` | 1 per enabled node region (3 today: Singapore, Germany, Canada) | at least one indexable game | "Singapore game server hosting" |
| `/host/<game>/<place>` | game x place | indexable game | "Minecraft server hosting in Singapore"; today 3 indexable URLs, 135 more render noindex |
| `/blog`, 5 posts, `/blog/rss.xml` | 7 | content public + indexing on | build logs and honest limits (supports the CQ guide plan) |

### 9.2 Templates

Three hosting layouts (showcase = a game, place = a location, compact = game in a location) plus the hub; one mod page layout; one post layout. Every template: Nxeon logo, a short hero on an original illustration (generated by `scripts/cyrus/web-art`), four true feature tiles, real plan cards (price per month from GamePlan), the discount block ONLY when the coupon exists, the token block ONLY when the economy is live and the scope covers the game, an FAQ built from visible facts, JSON-LD.

### 9.3 KPIs (all from GSC, the existing attribution tables and the new real counters; baselines are zero)

- Search: indexed vs submitted per section (core, mods, host, blog); impressions and clicks on host and blog URLs; non-brand queries in clusters E, H, I of the CQ plan; CTR on `/host/minecraft`.
- Funnel: page view -> "Install on my Nxeon server" click -> install; `/host` click -> deploy wizard -> paid order with `coupon=<code>`; tokens granted per server order (ledger `server_initial`).
- Spotlight: real views, installing accounts and ratings per picked mod vs unpicked (a causal-looking chart is NOT the claim; this is only to learn whether staff picks get seen).
- Quality: share of mod pages passing the bar; share of host URLs indexed; zero fabricated counters (a test, not a KPI).

### 9.4 Rollout order

1. Owner applies the one additive table, merges, deploys (staging, then promote). 2. nginx app-path list. 3. Seed the real mods and picks (dry run first). 4. Create the CYRUS coupon only if the owner decides the terms (otherwise the block stays hidden). 5. Open `cyrus_content_public_enabled` for the W0 private alpha (pages visible, noindex). 6. Week 6 plan item "first mod of the week": pick it in Admin > Cyrus > Spotlight. 7. At public launch: `cyrus_content_index_enabled`, `CYRUS_SITEMAP_CONTENT=1`, submit the sitemap, add Games / Mods / Host / Blog to the landing nav.

### 9.5 Risks

- A discount or token promise the system does not honour: mitigated by construction (the page prints only what the coupon row and the live token settings say); the open item is the owner's decision on the code's terms.
- Doorway pages: the host matrix can reach ~190 URLs; only Cyrus-live games are indexable (3 URLs today), cap 2,000, owner-extendable per game.
- Thin mod pages: quality bar; unpublished or failed-flight mods drop out of lists and the sitemap.
- Looking empty at launch: seed with REAL mods only; the honest empty states say what is missing. Do not "fix" emptiness with invented numbers (FTC fake-review rule and equivalents, and the repo rule).
- Views are page renders by non-bots, not unique visitors; labelled "views". No cookie or fingerprint is stored for counting.
- ccTLD `.my` geo signal and the nxeon.cloud canonical decision remain with the owner (CQ section 9).
