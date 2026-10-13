---
name: nxeon-checkout-conversion-research
description: What the checkout/conversion evidence actually says for the Nxeon deploy wizard — and which widely-quoted numbers are fabricated
metadata:
  type: reference
---

Research done 2026-09-05 for the single-page deploy wizard. Sources are
Baymard, NN/g, peer-reviewed journals and the competitors' own live flows.

**The premise "one page converts better" is not supported.** Baymard's position
is that page count is close to irrelevant — *"the number of form fields impacts
overall usability far more than the number of steps."* Average checkout is 11.3
fields; most sites need 8. So cut FIELDS, not pages.

**The single highest-leverage move is pre-selected defaults.** DigitalOcean's
create page: *"The most popular defaults are pre-selected, so you can scroll to
the bottom of the page and create a Droplet immediately."* Johnson & Goldstein
(2003, Science) — opt-in→opt-out roughly doubled consent, 42%→82%. Only
non-committal defaults: nothing that adds to the total.

**Top abandonment reasons** (Baymard, 70.22% avg across 50 studies):
extra costs 40% · card distrust 19% · forced account 18% · too long 17% ·
can't see total up-front 12%. So: show the true total INCLUDING the renewal
price before any payment field, and visually ENCAPSULATE the card fields — in
testing the container did the work, not which seal was used.

**Pre-ticked paid add-ons are illegal in the EU.** CRD 2011/83/EU Art. 22: consent
inferred from a default the consumer must reject entitles them to
reimbursement. A pre-ticked backup is a chargeback generator. EU B2C must also
display VAT-INCLUSIVE prices wherever a selling price appears — relevant to the
open VAT decision.

**Plan-table psychology:** centre-stage effect replicates (Valenzuela & Raghubir
2009 — inferred popularity, not attention). The DECOY effect does NOT (Frederick
et al. 2014; Yang & Lynn 2014) — do not build a decoy tier. Use ONE badge, not
two. Choice overload is conditional (Chernev 2015): it bites hardest under
preference uncertainty — exactly the game-server buyer who doesn't know what RAM
they need, which argues for a use-case selector that recommends a tier.

**Numbers circulating online that are FABRICATED — never cite these:**
"Baymard found multi-step beats single-page in 67% of tested cases" and "a
15-field form across three steps beats a 10-field single page by 11-14%" are not
on Baymard's site at all. Also unverifiable: "most popular" badge +16-30%,
money-back guarantee +21%/+26%/+300%, Mailchimp +21% annual framing, Formstack's
"multi-step converts 3x" (correlational), Shopify one-page "+7.5%" (one store,
no A/B test).

**Competitor split:** developer clouds (DigitalOcean, Hetzner, Vultr) configure
BEFORE commit with a live price and no guarantee — hourly billing is the risk
reversal. Retail hosts (Hostinger) sell a plan, then configure AFTER payment,
with 30 days money-back. Game hosts are tighter still: Shockbyte 72-hour
self-serve refund, GPORTAL a $1.42 3-day trial. Hetzner puts type/size BEFORE
location so the price anchor lands first.

**Add-ons convert best post-purchase**, on the provisioning screen, where the
order is already banked and cannot be lost. Keep only spec-relevant ones inline.

See [[nexion-ui-sandbox]], [[nxeon-hosting-wizard]], [[nxeon-deploy-winback]].
