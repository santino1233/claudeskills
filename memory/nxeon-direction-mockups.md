---
name: nxeon-direction-mockups
description: "6 visual-direction mockups of the Nxeon customer dashboard (deploy wizard, server page, domains, billing) built 2026-09-03 as Claude Artifacts for the owner to pick a direction; pure visual exploration, no app code"
metadata: 
  node_type: memory
  type: project
  originSessionId: d5fa93af-bbe2-4273-bebb-8cfef77d430a
  modified: 2026-09-03T23:14:06.587Z
---

On 2026-09-03 the owner asked (via /root/nxeon-mockup-directions-prompt.md) for six
distinct visual-direction mockups of the SAME four dashboard screens: deploy wizard,
server detail page, domains, billing. Directions: 01 Neon, 02 Liquid Glass (iOS 26),
03 Aurora/gradient mesh (closest to the real brand), 04 Command Deck, 05 Minimal
Editorial, 06 Holographic/iridescent.

Durable working copy (backed up here because the build agents' scratchpad lives under
/tmp and is session-scoped, not guaranteed to survive):
/root/nxeon-mockups-workspace/ — BRIEF.md (shared functional inventory + craft bar +
fictional persona data "Jordan Reyes / atlas-prod"), DIR-1..6 docs, refs/ (downscaled
JPEGs of the 5 key current-UI screenshots), mockups/<slug>.html (copied in as each
direction finishes), shots/.

Original live-build location (ephemeral, /tmp-backed — do not rely on this surviving):
/tmp/claude-0/-root/d5fa93af-bbe2-4273-bebb-8cfef77d430a/scratchpad/ — same file set,
plus shot.mjs (Playwright screenshot loop using /opt/nxeon/node_modules/playwright,
read-only) which only exists here.

Reference screenshots of the CURRENT UI live at
/opt/nxeon/board-uploads/board/cmtkzdife00fkhlacy7559m07/ (16 PNGs, see the prompt
file for the manifest).

**Why:** the owner has rejected five previous redesigns for going generic; the fix that
worked was designing from the literal screenshots with a build→screenshot→compare loop
(see [[nxeon-redesign-generic-drift]]). The directions are mockups only; the real
screen-by-screen rebuild is a later phase after the owner picks a direction.

**How to apply:** if the owner picks a direction, start Phase 2 from that artifact's
HTML plus the brief, not from a description. Do not pick a winner for them. Published
artifact URLs: (fill in below once published)
