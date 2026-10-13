---
name: nxeon-brand-gradient
description: The Nxeon brand gradient is blue -> violet (sampled from the logo) extended to a magenta terminus; exact magenta hex still outstanding
metadata:
  type: project
---

The Nxeon lockup's mark runs **#3b6be8 (blue) -> #7b3fef (violet)**, sampled from the logo the owner
supplied on 2026-09-03. There is **no magenta anywhere in the codebase** — I grepped the whole tree.

The owner describes the brand as "navy blue and magenta", so the design system defines the ramp as
three stops and extends past the logo's violet to a magenta terminus:

  --color-brand-a: #3b6be8   logo blue
  --color-brand-b: #7b3fef   logo violet
  --color-brand-c: #e5197e   PLACEHOLDER magenta — owner is sending the exact hex

**How to apply:** change `brand-c` in `/opt/nxeon-designsystem/app/globals.css` and every gradient in
the product follows — the CTA, the mark, the topology paths, the section rules and the illustrations
all read from the same three tokens. Do not hardcode a magenta anywhere else.

The owner also asked for **neon elements**. Neon is rationed to three owners only: a live resource
(cyan filament), the brand mark, and the primary brand action. It is never ambient or decorative —
that restriction is what keeps it from becoming the "random glow" the brief prohibits.

Related: [[nxeon-design-system-phase2]], [[nxeon-marketing-design]].
