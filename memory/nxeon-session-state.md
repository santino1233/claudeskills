---
name: nxeon-session-state
description: "Where the Nxeon work paused on 2026-07-25 — what's done, what's mid-flight, and the next action"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-07-25T18:10:30.123Z
---

Paused 2026-07-25 (owner went home). Prod + staging healthy on a committed build; nothing half-deployed.

**THE NEXT ACTION: run a test migration.** Server `ggjgjhgjghh` (vmid 102, `51.79.226.200`) is deliberately clean — fresh Ubuntu 22.04, one blank 50 GB volume attached (`sdb`, no filesystem, so the engine's auto-detect path gets exercised). Source is `72.62.69.9` (root + SSH password, which only the owner can enter — the password is wiped from the Migration row after every run). Storage panel now reads 47 GB needed / 72 GB usable / "Fits comfortably". Watch the worker live and grade against [[nxeon-server-controlpanel]] and `docs/MIGRATION-FIELD-NOTES.md`.

**Shipped this session** (all committed + pushed): migration engine hardened against a 21-item real-world failure catalogue (web config now GENERATED not copied; Docker image save/load; standalone-container recreation; MySQL users+grants; TLS ladder; stale-reference sweep; real `curl --resolve` verification); admin sidebar rebuilt (41 items → 14 icon'd entries, no scrolling); Cloudflare OAuth; domain transfer-in; logo marquee; backup progress bars + keep-latest-2; wallet/card split checkout; mail attachments + rich signature; disk-usage via guest agent.

**Mid-flight when paused:** a disk-expansion agent (per-server "add storage": `Server.extraDiskGB`, `DISK_EXPAND` job, deploy-wizard upsell + post-deploy action, prorated wallet/card charge, renewal billing, online `growpart`+`resize2fs`). Needs `prisma db push` on integration. **Disk growth is one-way — never build a shrink path.**

**Volume model decision (important):** volumes stay **portable/detachable** — that's the product promise and matches AWS/DO/Hetzner. LVM pooling was built then deliberately **deferred**, because welding disks together contradicts that promise. Using a volume for `/var/lib/docker` is now an explicit `useVolumeForDocker` opt-in (default off) with a "can't detach while in use" warning. Capacity should come from disk expansion or a plan resize, not from silently consuming a volume.

**Still open:** safe-detach (block detaching a volume the server depends on — a reinstall could otherwise destroy it); Cloudflare "Connect" retry (scopes fixed to the verified dotted `dns.read dns.write zone.read`, but consent failed once on Cloudflare's side — try again, then clear the client's Logo field); wildcard cert for `*.studionexis.com` via DNS-01; mail auto-reply/forwarding are still store-only; email deliverability (spam) unresolved.

**Owner's standing preferences:** displayed must equal charged (three separate estimate bugs this session); be honest about what's simulated vs real; every change goes to GitHub + docs. See [[nxeon-platform]], [[nxeon-improvements-workflow]].
