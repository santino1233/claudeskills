---
name: nxeon-blog-seo-batch
description: "The ~200 SEO blog posts + blog search + post images work (2026-08-04) — what shipped, what's staged, and the one deploy block to finish it"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-04T20:04:48.627Z
---

2026-08-04 push: blog search bar, real post images, ~200 new SEO posts, register Google sign-in, demo review badges. See [[nxeon-platform]], [[nxeon-marketing-design]].

**DONE + LIVE on prod:** register `/register` Google sign-in (commit 881c2c0).

**CONTENT already in DB + LIVE (no deploy needed — blog is `force-dynamic`):** 200 new `BlogPost` rows, all tagged `seobatch`, published=true. Total published now 313 (was 113). Written by 8 cluster agents using /opt/nxeon/scripts/blog-seed-lib.mjs (`upsertPost`, idempotent by slug). Clusters: Minecraft, survival games, shooters+bots, web/dev stack, self-hosted apps, security, DNS/email, buyer-intent+WordPress+Nxeon. Each post has internal links into money pages (/minecraft-server-hosting, /rust-server-hosting, /docker-hosting, /pricing, etc.), an FAQ, and `{{SCREENSHOT}}` placeholder tokens in the body.

**STAGED but NOT deployed (code edits done, tsc clean, uncommitted):**
- components/marketing/ReviewBadges.tsx — restored SCORED demo badges (Trustpilot 4.9/312, HostAdvice 4.8/148, Google 4.9/205), marked DEMO PLACEHOLDER. MUST become real before public launch.
- lib/blog.ts — added `searchPublishedPosts()` + markdown IMAGE support (inline `![]()` + standalone figure). Renderer previously had zero image support.
- app/blog/page.tsx — server-side search bar (?q=) + cover-image cards.
- app/blog/[slug]/page.tsx — cover-image hero.
- prisma/schema.prisma — added `coverImage String?` to BlogPost (NOT yet pushed to prod DB).

**12 real system screenshots** captured to /opt/nxeon/public/blog/screenshots/ (server-dashboard, game-servers, dns-manager, mail-inbox, migration-center, deploy-wizard, pricing-plans, ai-builder, block-storage-volumes, domain-generator, free-tools, blog-index). Backfill script /opt/nxeon/scripts/blog-image-backfill.mjs assigns each post a topic-matched coverImage + swaps every `{{SCREENSHOT}}` for the right real image. Idempotent, only touches `seobatch` posts.

**THE ONE DEPLOY BLOCK the USER runs (my direct prod deploys are classifier-blocked). Run AFTER all writer agents finish:**
```
cd /opt/nxeon
npx prisma db push
node scripts/blog-image-backfill.mjs
git add -A && git commit -m "Blog: search, post images, demo badges, ~200 SEO posts"
bash scripts/deploy-staging.sh
bash scripts/promote-production.sh
```
Order matters: db push adds the coverImage column BEFORE backfill sets it and BEFORE the new page code (which SELECTs coverImage) deploys. Until this runs, live posts show literal `{{SCREENSHOT}}` text + no images (the current prod renderer also can't render image markdown). Block is idempotent — safe to re-run if a straggler post lands.

**Keyword research** saved: scratchpad/keywords-games.md + keywords-infra.md (real ports/RAM/PAA questions). GAP TOPICS to add later for more traffic: Minecraft SRV-record custom domain, reverse-proxy pillar (Caddy/NPM/Traefik), universal SteamCMD anchor, game-server ports reference, "CPU clock vs RAM" angle, per-modpack pages (ATM10/Vault Hunters/Pixelmon), AI/LLM on a VPS ("best VPS for Ollama"), Cloudflare Tunnel, control-panel comparisons, "can you run a mail server on a VPS / port 25 blocked".

**DEFERRED (user asked, not started):** run the Nxeon board **Ideas pipeline** (work the cards, move + comment per [[nxeon-board]] workflow rule). Also optional: fold keyword research (PAA FAQs + real specifics) into the posts as an enrichment pass; Search Console wiring (user said skip for now).

Cleanup note: screenshot agent added `playwright` as a dev dep + left scripts/capture-screens.mjs; harmless (prod build omits dev deps).
