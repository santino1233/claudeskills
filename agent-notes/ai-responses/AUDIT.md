# Live-chat bot and ticket corpus audit (2026-10-06)

Source: the prod DB, SELECT only. Customer data is summarised here. Snippets are short and anonymised.

## Corpus

**Live chat:** 94 conversations, 1,032 messages.
- 495 visitor messages, 313 human-agent messages, 224 bot messages.
- 90 conversations had a bot message. 44 had a human agent.

**Bot messages by type:**

| Type | Count |
|---|---|
| Model (LLM) answers | 161 |
| Pre-rework keyword or retrieval era (14–15 Aug: blog-snippet dumps, canned clarifiers) | 16 |
| Canned "Let me get a teammate…" | 20 |
| "None of our team are free…" | 11 |
| "Transferred to a ticket" (admin action) | 8 |
| Degraded "brief problem reaching my assistant" (dead key, 25–26 Aug) | 5 |
| Empty body (the model emitted only a `[[cards]]` directive) | 3 |

**Tickets:** 77 tickets, about 850 messages.
- 439 from customers, 411 from staff.
- 11 of the staff messages are bot chat transcripts copied in with an `[AI reply]` prefix.
- **No AI-drafted or auto-sent ticket reply path exists in the code.** I checked every `askClaude` caller. The only AI write to Ticket is the chat tool `open_support_ticket`, which creates a NEW ticket owned by the customer. It is now consent-gated (see below).

**Reply length:**
- Bot model answers: median 66 words, p90 132, max 244. 92 of 161 were over 60 words and 45 were over 100.
- Human chat agents: median 11 words, p90 42.
- Human ticket replies: median 18 words, p90 147.

**Human requests:** customers asked "talk to a human" 26 times. The bot never spoke after an agent joined (0 violations), so the aiPaused and agent gate was already working.

## Classification of the 161 bot model answers

These are hand-labelled, and one answer can carry several labels.

| Label | Count |
|---|---|
| Correct and clean | 55 (34%) |
| Correct but too long or robotic | +11 |
| Wrong fact | 42 |
| Hallucinated feature, button, policy or promise | 24 |
| **Any factual error (wrong or hallucinated)** | **65 (40%)** |
| Too long (labelled) | 47 (45 are over 100 words) |
| Robotic or filler | 11 |
| Missing information | 6 |
| Should have escalated | 3 |
| Should NOT have opened a ticket or handed off without consent | 8 |
| Leaked internals | 2 |
| Empty body | 3 |

## Top failure patterns (anonymised)

1. **Stale or static facts contradicted the product.** This was the biggest category.
   - "We don't have a 4GB Valheim tier". It exists at $9.99. Seen 3 times.
   - "Project Zomboid pricing isn't in my info". It is in the catalogue.
   - "Nxeon doesn't offer per-region selection". Singapore, Canada and Germany are picked in the wizard.
   - "No free Minecraft… port-forward your home router". Seen 3 times, including in Turkish, before the KB fix.
   - "every VPS includes a dedicated IPv4". Reality: one is assigned only when the pool has a free address, otherwise shared NAT. The add-on costs $2.99. Singapore's pool currently has 0 free.
   - "I don't see a 30-day money-back guarantee". The bot argued with a customer who had seen the checkout. The real rule is a **72-hour** first-order guarantee.
   - "Windows Server 2016 or any OS you want". There is no Windows image.
   - Retired "Nano" VPS quoted.
2. **Invented UI and procedures.**
   - It walked a customer through "Settings tab → three-dot menu → Danger Zone → scroll down" for 6 turns looking for a cancel button.
   - It said "a temporary password gets emailed to you". Passwords are never emailed.
   - It described an "upload .mcaddon in the Add-ons section" that doesn't exist.
   - It said "the console/RCON lets you swap in a custom world".
   - It said "switching to Fabric wipes your world". It doesn't.
3. **Promises it couldn't keep.**
   - "They typically respond within the hour during business hours".
   - "it'll refund the charge since it failed to provision". Failed provisions are not auto-refunded.
   - "the team will restart that VM for you".
   - "I've noted your email and someone will reach out". No mechanism exists.
   - "let me search that… give me a sec?"
   - "refund processes on the next billing cycle".
4. **Wrong language.**
   - A Korean question was answered in Chinese.
   - Japanese questions were treated as off-topic and answered in English.
   - "I'm only set up to chat in English". This was false, and the same bot answered in Arabic and Turkish elsewhere.
5. **Tickets opened without asking.** 7 of 15 bot tickets were opened on a first message or a quick-reply chip ("I need technical help…"), worded as if the customer wrote them. Raw ids like `[cm…]` were shown to customers.
6. **Too long, and robotic in places.** Examples: 244-word refund replies, a 239-word game list, "(Results got cut off, but you've got the idea…)", and "the knowledge base says do not quote a region…", which leaked the instructions.
7. **The tool didn't show free Minecraft servers.** Free-tier owners were told "you don't have any active services" 4 times. The table is separate.
8. **Bad handoff loop.**
   - A repeat "talk to a human" produced wait, then "none free… drop your email for a callback" (when the email was already known), then the same again. This happened 3 times in one chat.
   - "operator" was answered as Minecraft `/op`.
   - The handoff regex also fired on "someone", "agent", "rep" and "live chat" inside normal questions.

**Human-agent issues for the owner** (not changed by this branch):
- The OVH vendor name was used in one chat reply.
- "Our provider's stated policy" and "the maintenance they are performing" appeared in tickets.
- Agents gave "CPU is dedicated" and "99.99% / 99.80%" uptime figures with no backing in the code. Standard VPS CPU is shared and oversubscribed. /legal/sla says 99.9%.
- A competitor was disparaged.
- A root password was posted in plain text in a ticket.
- A stock Trustpilot closer was sent 7 times, sometimes badly timed.

## What worked (human exemplars → style rules)

- **Answer first, outcome first.** For example: "We've sorted this at the network layer — you're now on a dedicated address", followed by the connection details.
- **Short, specific pings for status.** For example: "What address are you connecting to? We'll check the logs."
- **Honest limits stated plainly**, with a real alternative. For example: "no extract button yet — upload the zip and we'll extract it for you".
- **Ask one targeted question** (player count, game, location) before sizing.
- **Explicit permission before a risky step**, and data integrity stated first.

## What customers actually ask (chat plus tickets, by frequency)

1. Server down, won't start, stuck provisioning or ERROR. "The VM must be running…" alone appeared 4 times.
2. Game config, mods, plugins, world upload or download, file manager.
3. Ports, IP, dedicated IPv4, NAT, port 80/443. There were 4 near-identical tickets.
4. Prices and tiers per game, intro vs renewal ("will it go up after month one?").
5. Region and latency: move to Singapore from Germany or Canada.
6. Refunds and the money-back guarantee, cancellation, wallet refund.
7. CPU model, dedicated vs shared vCPU, steal.
8. Free Minecraft (where it is, Bedrock?).
9. DDoS capacity and vendor.
10. Windows, custom specs, custom quotes.
11. Payment methods (GCash, PayPal), wallet top-up amounts.
12. Support and Discord link, response time, SLA.
13. Root password, login and email change.
