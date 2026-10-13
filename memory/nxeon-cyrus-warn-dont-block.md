---
name: nxeon-cyrus-warn-dont-block
description: Owner rule (2026-10-12): Cyrus must not hard-cap what users choose; warn instead, across every config, designer and mod
metadata:
  type: feedback
---

Owner rule (2026-10-12, seen on the Config studio: "Mirror radius 20 is outside the allowed 1-8 chunks" blocked a legitimate value): the system must not impose hard caps on what people want to do. Show warnings (with the likely consequence, e.g. lag, memory, TPS) and let them proceed. Applies to everything, not just ChunkMirror or config values: studio ranges, designer params limits, generated-plugin clamps, perf-layer caps.

**Why:** Hard caps make Cyrus feel limited and untrustworthy; the owner wants power users able to do what they want with honest warnings.

**How to apply:** ranges become recommended ranges (soft min/max) with info/warn/danger tiers; the generated plugin must honour the saved value (log a warning, never silently clamp). Keep only real boundaries as hard: security (malware/escape/injection/obfuscation), legal, money/credit integrity, values that would crash or corrupt (type overflow, negative counts), and the reality-based TPS safety net (configurable, can be turned off by the owner of the server). Tell the owner which hard boundaries remain whenever relaxing a limit. See [[nxeon-cyrus-skills-universal-modder]] for the rest of the Cyrus context.
