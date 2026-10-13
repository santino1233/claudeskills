# Ground truth used by the chat assistant (verified 2026-10-06, code plus prod SELECT)

The live versions of these facts are served by `get_platform_facts` (lib/kb-facts.ts). This page is a snapshot.

## Regions and network

**Regions** (lib/node-regions.ts, Node table):
- Singapore (sgp1: 4 nodes, 2 accepting new orders), Canada (bhs1) and Germany (fsn1).
- The location is picked in the deploy wizard. A full region refuses the order and suggests others (lib/region-placement.ts).
- Shared hosting has no location choice.
- Free Minecraft is on node-2, which is Germany.
- Region moves are not self-serve. `region_transfer_enabled` is off, so moves are done by the team.

**IPv4:**
- VPS: `dedicated_ip_default=true`. A VPS gets a dedicated IP only when the region's pool has a FREE address, otherwise it uses shared NAT (worker/index.ts:825-856).
- Pool right now: Singapore 0 free, Germany 1 free, Canada 1 free.
- Add-on price is $2.99/mo (Setting `dedicated_ip_price_cents=299`). It can be bought at checkout or later, for VPS and game servers.
- NAT port forwards: up to 10 per server, public ports 20000-29999 (lib/actions-server.ts:252, lib/ipam.ts).

**CPU:**
- No CPU model is stored. No pinning is implemented. vCPU is oversubscribed, RAM ×1.5 and disk ×3 (lib/capacity.ts).
- **Marketing pages claim "dedicated vCPU" and "AMD EPYC 9654" / "AMD Ryzen", which the code doesn't back.** This needs an owner decision.

**DDoS:**
- "Always-on" in marketing. The homepage claims "up to 1 Tbps".
- The bot quotes no number and no vendor.

## OS images, root password, setup time

**OS images:** Ubuntu 20.04/22.04/24.04, Debian 11/12/13, AlmaLinux 8/9 and Rocky 8/9, plus panels and apps. There is no Windows image and no custom ISO.

**Root password:**
- Click-to-reveal in the Root access card, with a reset button (`resetRootPassword`).
- It is never emailed (lib/email-templates.ts).

**Setup time:**
- The provisioning overlay says "usually under two minutes".
- The "47 seconds" brand tagline is left alone.

## Money

**Refunds** (lib/refund-policy.ts):
- 72-hour first-order money-back. It is processed manually by an admin; nothing auto-refunds it.
- Immediate VPS cancel credits the unused term to the WALLET.
- Game servers get $0 on immediate cancel (proration.ts:279).
- Hosting cancel gets no refund.
- Domains are non-refundable.
- Wallet-to-card refunds are discretionary (terms.ts:54).

**Payments:**
- Card via Stripe, plus Apple Pay and Google Pay through the Stripe express element.
- PayPal is live: env configured, kill switch defaults on.
- Crypto: not configured.
- Local methods (PayNow etc.): all off.
- No GCash and no bank transfer.
- Everything is charged in USD.
- Wallet top-up: preset or custom amount, $5 to $5000.

**Terms and dunning:**
- Terms: annual −20%, 24 months −30%, 36 months −40%. Domains: 2 years −5%, 3 years −10%.
- Intro price applies to the whole first term (`introTermMonths` is NULL).
- Dunning: retries on days 1, 3 and 5, then suspension. With no card, suspension comes after 3 days. Warning on day 7, deletion on day 14.

**Coupons:**
- WELCOME10 (the bot coupon) is valid: 10%, first order, 200 uses, expires 2027-08.
- TRIAL798 (the 7-day trial) expired 2026-09-29, so there is no trial now.
- First month free is HOSTING only.

**Expired coupons still flagged active=true:** NXSAVE40, NXFLASH40, WINTER50, PEERPUSH20, FREEMONTH and TRIAL798. They are harmless if expiry is enforced, but worth a cleanup.

## Support and SLA

- Support promise: "A human replies to every message within one business day" (lib/support-promise.ts). The game-servers marketing page says "24/7 Expert Support", which contradicts it. **Owner decision needed.**
- SLA (/legal/sla): a 99.9% target with 10/25/50% wallet credits. The PromoCarousel shows "99.98%". **Owner decision needed.**
- Discord: https://discord.gg/hqVZdDJH2 (PromoCarousel).
- No legal entity, country or registration number is published. A human agent told a customer "Canada".

## Game panel

**Tabs:** Overview, Console, Files, Mods & Plugins, Backups, Players, Schedules, Settings, Activity. There is no Manage tab and no Networking tab.

**Files:** upload (files and folders), download a file, extract archives, edit, rename, delete. No move or copy. Only works while the server is running.

**Mods:**
- One-click for Minecraft Java (Modrinth, Hangar, Spigot), Valheim (Thunderstore), Rust (uMod), CS2, Factorio and Core Keeper.
- About 16 games are install-by-ID.
- The rest are manual.

**Console:** command box only for MC, CS2, Palworld, ARK, ARK:SA, PZ, TF2 and L4D2.

**Backups:**
- Automatic backups are OFF by default for game servers (28 of 33 off).
- Server-image backups can be restored self-serve.
- A world archive is download-only.

**Slots** are a recommendation, not a cap.

**Upgrades:** tier up is self-serve and wallet-only. Downgrade goes through support.

**Cancel:** Settings > Danger Zone.

**Failed provision:** no auto refund. The page offers "Retry provision".

## Free Minecraft

- Java only. Needs a verified email.
- Idle sleep after 15 minutes. Wake takes about 23-33 seconds.
- Address: `<name>.play.nxeon.cloud`.
- 9 types and 4 modes.
- It has a separate panel with no Files, SFTP or backups.
- It lives in the `FreeMinecraftServer` table, not Server.
