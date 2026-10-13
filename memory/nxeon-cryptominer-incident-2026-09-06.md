---
name: nxeon-cryptominer-incident-2026-09-06
description: "Root-level XMRig compromise on the primary via CVE-2025-55182 (Next.js RSC RCE); trojaned /usr/bin/ls was the persistence mechanism. RESOLVED 2026-09-08: entry vector confirmed, second re-compromise traced to nexion-ui (now stopped), codebase confirmed clean of any reinjection code, attribution = opportunistic botnet not targeted attack"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-09-08T10:25:04.878Z
---

The primary (51.79.162.96) was running a **root XMRig cryptominer** for ~33 hours. Found because
the owner reported the box was slow and dropping connections: RAM was 59/62GB with **swap fully
exhausted** (2.0/2.0GB) and load 8.4 on 8 threads, from ~11 concurrent miner instances at ~2.3GB each.

**The persistence mechanism is the important lesson: `/usr/bin/ls` itself was trojaned.**
Every conventional hunt came up empty — no cron entry, no systemd unit or timer, no watchdog
process, no `at` job, no PAM hook, no `ld.so.preload`, no rogue kernel module, no unauthorized SSH
key or account. There was nothing to find, because the trigger was simply **root running `ls`**.
That explains every symptom that made no sense: the ragged ~12-16 minute respawn cadence (that is
just how often something ran `ls`), the parent always being PID 1 (it forked and detached), and
instances *accumulating* rather than being replaced. It also means my own investigation commands
were re-triggering it while I hunted for it.

**How it was caught**: `dpkg -V` — `/usr/bin/ls` was the only non-config file on the whole system
failing its package checksum. Confirmed against a pristine `apt-get download coreutils`:
167,039 bytes vs 158,632, a different BuildID, **section headers stripped entirely** (anti-analysis),
linked against libc *only* where the real one needs libselinux/libcap/libpcre2, and importing
**`execve`/`waitpid`/`unlink`/`tmpnam`** — a directory-listing tool never executes other programs.
It carried a scrambled substitution alphabet (so its URLs never appear in `strings`) and the
base64 tag `bongripz4jezuz`. Evidence copy kept; SHA256
`2ce30a31faf2a5e0e626c76bdd4b8aecffde4851e8ff7df112f54e2d1f18d1cc`.

**Timeline**: miner planted 2026-09-05 07:13:51 (`/root/system-check/`, XMRig →
`pool.supportxmr.com:443` over TLS, wallet `86CqeACom…`, which is why it hid perfectly in normal
HTTPS egress). The attacker returned **2026-09-06 09:02:38** and replaced `ls` for durable
persistence. Payload re-fetched from `raw.githubusercontent.com`.

**Entry vector — CONFIRMED 2026-09-08: CVE-2025-55182 / CVE-2025-66478 ("React2Shell").** An
unauthenticated RCE via insecure deserialization of the React Server Components "Flight" protocol,
in the *framework itself* (React 19.0.0-19.2.0, every Next.js 15.x/16.x app-router build up to
16.0.6), reachable via a bare `POST /` on any app-router page — exactly the pattern observed from
day one. Mass-exploited (968,000+ exposed instances per public reporting) — this was an
**opportunistic drive-by, not a targeted attack**. GHSA-9qr9-h5gf-34mp. Fixed upstream at Next.js
15.0.5/15.1.9/15.2.6/15.3.6/15.4.8/**15.5.7**/16.0.7. This explains why the exhaustive audit of all
110 "use server" modules and every API route never found the bug — there was nothing to find in our
own code. Web app runs as `nxeon`, not root — the escalation to actual root is a *separate*
mechanism: the Proxmox API token (see below), not anything about this CVE.

**Resolution: the main app was never actually exposed.** Installed `next@15.5.21` is already past
the `15.5.7` fix line — confirmed via the official Vercel/Next.js advisory. No upgrade needed for
this CVE. (`npm audit` separately flags `next` as "high" suggesting a major bump to 16.3.4 — that's
an unrelated nested `postcss`/`sharp` issue, not this RCE; low priority.)

**The actual open door, and why a SECOND re-compromise happened during this investigation
(2026-09-08):** a separate isolated app, `nexion-ui` (`/opt/nexion-ui`, port 3020, design sandbox,
no DB/backend), was pinned to `next@15.5.4` — below the fix line, genuinely still vulnerable — and
its systemd unit ran as **root** (unlike the correctly-hardened main `nxeon-web.service`). The exact
same trojaned `/usr/bin/ls` reappeared; `nxeon-integrity.timer` caught it within ~4h45m (clean
00:17:20Z, rewritten-by-responder 05:02:35Z). Forensic-log correlation nailed it: `POST /login` from
`65.108.199.156`, UA `Assetnote/1.0.0`, malformed `next_action` header, on the nexion-ui vhost, ONE
SECOND before the retrojan was discovered. **Action taken: `nexion-ui-web.service` stopped and
disabled 2026-09-08** — it stays off (low-value, no real users) rather than being patched and
restarted; only re-enable after bumping to `next>=15.5.7` and adding a non-root systemd user.

**Malware ID: commodity, not bespoke.** The `bongripz4jezuz` tag matches published IOCs for a known
self-propagating ELF file-infector (SonicWall "Ladvix", Intezer "OrBit (Re)turns") — treat any
writable ELF anywhere on the box as potentially suspect, not just `ls`.

**Attribution:** wallet `86CqeAComozQ67JJGm1cgEWZms56cLogui2hmg5QZr6TVAABiLLv47iYgirYZzz16s9doatnUb4CoRbcBi975sCN3XAXF2A`
on pool.supportxmr.com — ~201.5B hashes over ~11.5 days, 5 payouts (0.163 XMR total), no
per-rig segmentation implying ~40-50 concurrent victims sharing this wallet; went inactive after
09-06 (operator rotation/pool ban, not our doing). Source IP 118.99.81.244 is a flagged residential
proxy (Jakarta) — a disposable relay, blocking it has near-zero value on its own. Monero's design
means no further identity attribution is possible. **Verdict: large anonymous opportunistic
cryptojacking botnet, not a targeted attack on Nxeon, not further attributable.**

**CORRECTION (2026-09-08, before token cutover): the token/hookscript escalation chain doesn't
actually work on this Proxmox version.** Built an isolated test identity, proved the scoped token
could do every real app operation, then tried setting `hookscript` — got `"only root can set
'hookscript' config"` straight from Proxmox's own source: `hookscript`/`args`/`lock` are hardcoded
root@pam-only, unreachable by ANY delegated privilege, no matter how broad the role. Same for
vzdump's `--script` hook. So the *original* over-privileged token could never have escalated this
way either — the write-up above described a real, generally-known Proxmox anti-pattern that this
host's actual PVE build already closes. **Much simpler real explanation: `nexion-ui-web.service` ran
as root from 2026-09-04 22:41, 8.5h before the first compromise, already on a vulnerable Next.js
build — a code-exec CVE landing in an already-root process needs no escalation at all.** Can't be
100%-proven after the fact (nginx's shared log has no per-vhost Host field, journals rotated past
09-05) but the circumstantial case is strong given nexion-ui is CONFIRMED as the vector for both
later recompromises with the identical signature. **Practical upshot: the real production app,
correctly running unprivileged, may never have actually been directly breached — every confirmed
hit lands on the auxiliary root-running sandbox.** Scoping the Proxmox token (dropping
`VM.Config.Options`/`Sys.Modify`, both confirmed unused by any real code path) is still worth doing
as defense-in-depth, just no longer "the fix for how this happened" — that lesson is now "any
auxiliary service running as root is a full incident on its own, zero escalation required."

**Codebase reinjection hunt (2026-09-08): CLEAN.** Hashed all 1,980 git-tracked files against HEAD
byte-for-byte (0 mismatches), verified all 350 locked node_modules tarballs against
package-lock.json integrity + full file compare (0 mismatches), grepped repo-wide for
eval/new-Function/dynamic-require/base64-exec obfuscation (0 real hits), audited every
child_process call site (all argv-array, no shell, no user input reaching exec). **The hypothesis
that planted code re-plants the trojan even after cleanup is NOT supported** — the mechanism is
purely the external CVE being re-exploited, not anything living in our own code. Two non-issues
flagged in passing: `scripts/onboard-node.sh:515` has a legitimate vendor curl-pipe-to-root-bash
(NodeSource installer, manually run); `.kodely-secrets.local`'s own generator says "treat as
compromised" — assume read given two root compromises, rotation is owner's call.

**Fixed / in place now**: miner killed and `/root/system-check` deleted, with an **immutable empty
file** at that path so a loader's `mkdir` fails; genuine `ls` restored (`dpkg -V` clean);
118.99.81.244 blocked in `nxeon_blocklist_v4`; mining pool blackholed both in `/etc/hosts` and as
an nftables OUTPUT drop on its resolved IPs (logged, so a hit is an alarm); nginx now logs the
`Next-Action` header to `/var/log/nginx/forensic.log` (the header that would have identified the
vulnerable action, and which the default `combined` format does not record); and a daily
`nxeon-integrity.timer` runs `/opt/nxeon/scripts/integrity-check.sh` (`dpkg -V`, config files
filtered out) which would have caught this within a day.

**Still open — needs the owner** (full detail + status table in `docs/SECURITY.md`):
1. **Credential rotation** — every secret on the box across TWO root compromises now, assumed
   exposed. Per [[nxeon-live-credential-rotation-policy]] this needs explicit sign-off before
   acting, not done proactively. Highest priority within this: `/root/.ssh/nxeon_deploy` (GitHub
   deploy key, unencrypted) and `.kodely-secrets.local`.
2. **The Proxmox token privilege split** (root cause of web→host-root escalation, see Part 2 of
   `docs/SECURITY.md`) — the #1 architectural fix, independent of which CVE opens the door next
   time. In progress as of 2026-09-08 once the game sweep's then-current family finished.
3. **Staging is internet-facing on 8080/8443** — `scripts/firewall.nft`'s own comment already flags
   it as "a second, less-audited copy of the whole application" and offers the two-line tightening,
   deliberately left disabled.
4. `scripts/deploy-staging.sh`/`promote-production.sh` run `npm install` (not `npm ci
   --ignore-scripts`) as root on every deploy — flagged as the most plausible theoretical
   reinjection path even though node_modules is currently clean.
