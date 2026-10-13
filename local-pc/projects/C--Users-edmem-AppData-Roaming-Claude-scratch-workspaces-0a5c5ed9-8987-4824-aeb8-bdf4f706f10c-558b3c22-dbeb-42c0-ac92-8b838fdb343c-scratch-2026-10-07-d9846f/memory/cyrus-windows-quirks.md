---
name: cyrus-windows-quirks
description: "Tooling quirks on this Windows machine — Python needs relative paths under AppData\\Roaming, screenshots via CDP scripts in Temp\\cyrus-shots"
metadata:
  node_type: memory
  type: reference
  originSessionId: a29cf244-79c9-4ba3-aea9-1b8beb78ecca
  modified: 2026-10-07T19:14:48.775Z
---

- Windows Python can't open project files under `AppData\Roaming` by absolute path (MSIX virtualization): `cd` into the project in Bash and use relative paths.
- Bash heredocs usually work; when they break, write a `.patchN.py` with the Write tool and run it.
- Visual checks: CDP scripts in `C:\Users\edmem\AppData\Local\Temp\cyrus-shots\` — `shot.mjs` (full page, real time), `shot2.mjs` (SHOT_URL env), `coreshot.mjs <conceptId>` (solo core via `/cores?solo=`). Headless virtual-time screenshots don't settle animations.

Related: [[visual-quality-bar]].
