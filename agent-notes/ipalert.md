# ipalert (2026-10-02) — branch fix/ip-clash-alerts, worktree /opt/nxeon-wt-ipalert
Alerts via NodeAlert (dimensions IP-CLASH:ip / LEFTOVER-VM:vmid / UNKNOWN-VMID:vmid), pure plan in lib/fleet-alert-plan.ts.
Leftovers: vm-move already tags nxeon-moved; sweep reports leftovers (tag or DONE VmMove). Migrations leave no PVE VM.
IPAM reservations: Setting ipam.reserved_ips + scripts/ipam-reserve.ts. VM ids: vmid_used:<id> rows + sweep raises high-water, scripts/vmid-ack.ts.
Tests: test/ip-fleet-alerts.test.ts. Rollout: merge, deploy worker; first sweep baselines vmids.
