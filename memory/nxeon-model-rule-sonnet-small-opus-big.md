---
name: nxeon-model-rule-sonnet-small-opus-big
description: Owner's model rule (2026-10-10): Sonnet for research and small items, Opus for big advanced-scope features that need extra attention; limit agent count to save usage
metadata:
  type: feedback
---

Use **Sonnet** for research and smaller items. Use **Opus** (Agent `model: "opus"`) for big, advanced-scope features that need extra attention (e.g. the project model + revision store, conflict engine, creature pipeline, gameplay designers). Never Fable. Keep agents few (one at a time unless told otherwise); too many agents burns weekly usage.

**Why:** owner hit 99% weekly usage on 2026-10-09 and wants quality where it matters without burning tokens. This refines (does not cancel) [[nxeon-model-split-preference]] and the earlier "Sonnet for everything" decision in [[nxeon-golive-decisions-2026-10-08]].
**How to apply:** do small items in the main (Sonnet) session; delegate a big feature to ONE Opus agent with a tight brief and caps; research agents stay Sonnet with page caps. Check [[nxeon-cyrus-master-plan-2026-10-10]] for what is big vs small.

Update 2026-10-18: the owner said to prioritise Sonnet MORE than Opus ("only if we absolutely need Opus") and to BUNDLE work into fewer, bigger agents, because each running agent burns tokens. Also keep about 4 concurrent heavy agents at most (node-2 capacity).
