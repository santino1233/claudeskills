---
name: nxeon-pkill-nextstart-incident
description: "Never pkill by a generic process pattern on this box — \"pkill -f 'next start'\" restarted live production on 2026-09-03"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1716c7ee-ae35-4cf5-b557-9059709e07c4
  modified: 2026-09-03T18:47:57.141Z
---

On 2026-09-03 at 18:44 UTC I ran `pkill -f "next start"` intending to stop only my own sandbox on
port 3010. Production (`nxeon-web`), staging (`nxeon-staging-web`) and the old sandbox all run
`npm start` → `next start`, so the pattern matched them too and all three were killed. systemd
restarted them within about one second and prod returned 200s immediately, but this was a real,
avoidable production interruption.

**Why:** every Node service on this host shares the same command line. A `-f` pattern match is not a
targeted kill here — it is a wildcard across prod, staging and sandbox alike.

**How to apply:** stop a service by its identity, never by a command-line pattern.
- Own dev server on a known port:
  `PID=$(ss -ltnpH 'sport = :3010' | grep -oP 'pid=\K[0-9]+' | head -1); [ -n "$PID" ] && kill "$PID"`
- Anything systemd-managed: `systemctl stop <unit>` — and on this box that is a prod action needing
  sign-off, so ask first.
- Never `pkill -f` / `killall` against `node`, `next`, `npm` or any shared runtime name.

Related: [[nxeon-build-isolation]] (never build in the live prod tree) and
[[nxeon-design-system-phase2]] (the work this happened during).
