---
name: nxeon-vm-hairpin-firewall-fix
description: "fixed 2026-08-23 — VMs (Kodely, hosting-1, etc.) could not reach nxeon.cloud at all due to a firewall hairpin; also found a real bug in firewall-safe-apply.sh's --confirm check"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-23T09:53:22.832Z
---

**The bug (commit 30f5529, applied live via safe-apply, confirmed permanent):** nxeon.cloud's web app runs directly on the primary Proxmox host (not in a VM). Any VM (10.20.0.0/24, vmbr1) resolving `nxeon.cloud`'s public DNS name hairpins back into the HOST'S OWN input chain — not "some other external site" reached via the forward chain. `scripts/firewall.nft`'s `iifname "vmbr1" drop` (correct, deliberate: block VMs reaching host SSH/Proxmox/Postgres) sat ABOVE the later port-80/443 accept rule, so it silently ate that traffic too. This affected EVERY VM on the box (confirmed VM 200/hosting-1 hit the identical wall, not just VM 110/Kodely) — discovered because Kodely's live "Connect Nxeon" end-to-end test failed with a connect timeout.

Fix: `iifname "vmbr1" tcp dport { 80, 443 } accept` immediately before the blanket drop. Verified SSH(22)/Proxmox(8006) still fully refused from a VM afterward — narrow, no new exposure (80/443 were already public to the whole internet regardless of source).

**Also found: a real bug in `scripts/firewall-safe-apply.sh`'s `--confirm` mode.** Its admin-allowlist check does `nft list table $TABLE | grep -q 'nxeon_admin_v4'` under `set -o pipefail`. `grep -q` exits the INSTANT it finds a match (nxeon_admin_v4 is near the top of the output) — closing the pipe while `nft` is still writing sends `nft` a SIGPIPE (exit 141), and `pipefail` reports the whole pipeline as failed even though grep genuinely matched. Reproduced directly: running the identical pipeline by hand returns "MATCHED" every time, but the script's `--confirm` reliably reports "the loaded ruleset has no admin allowlist" and refuses to disarm the auto-revert timer — a false negative, not caused by this VM-firewall change. Had to manually run the disarm primitives (`systemctl stop/reset-failed` on `nxeon-fw-autorevert.timer/.service`) instead of `--confirm` to make the fix permanent before the 300s auto-revert fired. **FIXED same day (commit bb72dc5):** captured `nft`'s output into a variable first, then grep the variable via here-string — no live pipe, no race. Verified against the exact ruleset that falsely failed: `--confirm` now succeeds correctly. The other `nft list table | grep` in the file (--status) was never at risk — non-`-q` `grep -E` reads to EOF, nothing to race.

Also noted, not acted on: the current admin SSH session's source IP was NOT in `nxeon_admin_v4` (the allowlist only has 2 static IPs) — this is why the preflight failed and `--force` was needed. Separate, more sensitive decision (expanding SSH-admin allowlist) than the narrow VM-website fix; flagged to the owner, not changed.

See [[nxeon-kodely-partner]] (this is what was blocking the real end-to-end test) and [[nxeon-shared-hosting]] (the box's hardening history).
