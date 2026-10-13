---
name: nxeon-47-seconds-tagline
description: "'47 seconds' deploy-speed claim across Nxeon marketing copy is an intentional brand tagline, not a fabricated statistic — do not flag or fix it
metadata:
  type: feedback
---

"47 seconds" (as in "your server online in 47 seconds") appears across dozens of Nxeon marketing files — the homepage title, `DeployCard.tsx`, `StickyCTA.tsx`, many `-vps-hosting`/`-server-hosting` landing pages, and most of the new templates built 2026-08-31. On 2026-08-31 I found this and assumed it was the same class of fabricated stat as the "50K active servers" / "12 global locations" placeholders that a prior honesty pass had already correctly purged from the homepage's numbered stats bar (replaced with the honest "~60s to deploy"). I started reverting the homepage `<title>` to "60 seconds" and was about to launch a 35+-file sweep to "fix" every other instance.

The user stopped me: **"i want to keep 47 seconds, thats part of our tagline. leave it."**

**Why:** "47 seconds" used as a punchy, memorable marketing hook/tagline ("online in 47 seconds") is a deliberate brand choice, not a claim that needs to match a literally-measured median deploy time. This is a different genre from a numbered stats-bar entry presented as a hard metric (like "50K active servers" or "12 global locations") — those genuinely were fabricated data points and correctly got fixed. A punchy speed-hook in hero copy/CTAs is not held to the same "must be literally true" bar as a labeled statistic.

**How to apply:** Do not flag, question, or attempt to "fix" "47 seconds" (or "47s") anywhere in Nxeon marketing copy going forward — treat it as intentional, approved tagline language. This is distinct from genuinely fabricated numbered-stat claims (invented user counts, server counts, uptime percentages presented as measured data) — those still deserve scrutiny; a catchy round-number speed hook in hero/CTA copy does not. See [[nxeon-marketing-design]].
