---
name: nxeon-cyrus-asset-picks
description: Cyrus brand asset pack (66 pieces, 6 sheets) cut up and shortlisted; picker artifact + the owner's choices so far; where the full-res cuts live
metadata:
  type: project
---

Owner gave the Cyrus Asset Pack on the board card "Cyrus Asset Pack" (card cmuz9zg7h008ihl7e7lxnog1a): 5 sheets on 2026-10-08, plus a 6th ("Built with Cyrus" badges). I cut them into 66 transparent pieces and published a picker: https://claude.ai/artifact/XDphNe23qhwxiB8juvBgkc (db collections `cyrus-picks` doc per group = {choice, note}, `cyrus-keep` doc per asset = {on}).

**Files:** full-res transparent cuts `/root/agent-notes/cyrus-assets/full-res/<id>.png` (+ index.json), originals in `original-sheets/`, web thumbs in `picker/a/`. Working copies and scripts in /tank/cyrus-pack (segmentation = row/column gap cuts + a speck cleaner; auto-connected-component segmentation merged neighbours because the glows touch).

**Owner's choices as of 2026-10-08 09:00 UTC (before the badge groups were added):** app icon = black tile (iconset-r3-3); Y mark dark = white Y alt (iconset-r4-2); Y mark light = gradient Y (brand-ymark); wordmark dark = solid white (iconset-r7-1); wordmark light = black with gradient Y (iconset-r6-1); token coin = neon compact (coin-neon-small-face); hero dark = tilted coin (single-coin-tilted); hero light = silver 3/4 (coin-silver-3q); loading coin = neon spin set; avatar = cleared (undecided). Four "Built with Cyrus" groups (dark pages, light pages, stacked, seal) added afterwards, unpicked.

**Why / how to apply:** read the picks with ArtifactData (list cyrus-picks) before wiring any asset into Cyrus (portal integration branch feature/cyrus-v5, marketing page, favicon, token UI). Related: [[nxeon-cyrus-design-feedback]], [[nxeon-brand-asset-library]].
