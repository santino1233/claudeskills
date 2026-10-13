# OVH API rights for the admin OVH controls

Branch `feature/ovh-admin-controls`. Discovered 2026-10-06 with read-only GET calls only.

## What the current key has (and why it should be replaced)

`GET /auth/currentCredential` on the platform's current consumer key returns:

```
GET /*   PUT /*   POST /*   DELETE /*      status: validated, expiration: none, allowedIPs: none
```

So every control works with the current key: no call returned 403. But this key can also order and
terminate services, change contacts, or move IPs between servers. It sits in `/opt/nxeon/.env` and is
readable by the web process, the process that had an unauthenticated RCE in the 2026-09-06 cryptominer
incident. The panels show a "consumer key has wildcard write access" badge until it is replaced.

Recommended: create a NEW consumer key with exactly the rules below, put it in `.env` as
`OVH_CONSUMER_KEY`, restart, check the panels, then revoke the old key.
Keep the existing application key and secret. Never paste a key into chat.

## The rules to grant on the new key

OVH matches `*` against any characters, including `/`.

### Read (all panels, the hourly sweeps, provisioning lookups)

| Method | Path |
|---|---|
| GET | `/auth/currentCredential` |
| GET | `/ip` |
| GET | `/ip/*` |
| GET | `/dedicated/server` |
| GET | `/dedicated/server/*` |

### 1. Game firewall (strict mode + allow rules)

| Method | Path |
|---|---|
| PUT | `/ip/*/game/*` |
| POST | `/ip/*/game/*/rule` |
| DELETE | `/ip/*/game/*/rule/*` |

### 2. Network firewall

| Method | Path | Used for |
|---|---|---|
| POST | `/ip/*/firewall` | add the IP to the firewall (created disabled) |
| PUT | `/ip/*/firewall/*` | enable / disable |
| POST | `/ip/*/firewall/*/rule` | add rule |
| DELETE | `/ip/*/firewall/*/rule/*` | remove rule |

### 3. Reverse DNS

| Method | Path |
|---|---|
| POST | `/ip/*/reverse` |

### 4. Virtual MAC repair

| Method | Path | Used for |
|---|---|---|
| POST | `/dedicated/server/*/virtualMac` | create a vMAC for an IP |
| POST | `/dedicated/server/*/virtualMac/*/virtualAddress` | attach an IP to an existing vMAC |
| DELETE | `/dedicated/server/*/virtualMac/*/virtualAddress/*` | detach a stale binding |

### 5. Permanent DDoS mitigation

| Method | Path |
|---|---|
| POST | `/ip/*/mitigation` |
| DELETE | `/ip/*/mitigation/*` |

### 6. Unblock

| Method | Path |
|---|---|
| POST | `/ip/*/antihack/*/unblock` |
| POST | `/ip/*/spam/*/unblock` |
| POST | `/ip/*/arp/*/unblock` |

### 7, 8: read only

No write rights needed.

### 9. Reboot and rescue (owner only)

| Method | Path | Used for |
|---|---|---|
| POST | `/dedicated/server/*/reboot` | hard reboot |
| PUT | `/dedicated/server/*` | set netboot (`bootId`) to rescue / disk |

Note: `PUT /dedicated/server/*` matches every PUT under the server, not only the server object.
OVH rules cannot express "this exact path and nothing deeper". If that is too wide, leave it out:
rescue mode then shows "needs OVH API right" and plain reboot still works.

### Existing platform paths (already in use: do not drop them or provisioning breaks)

| Method | Path | Caller |
|---|---|---|
| POST | `/dedicated/server/*/virtualMac` | `allocateDedicatedIp` (provisioning), VM move |
| DELETE | `/dedicated/server/*/virtualMac/*/virtualAddress/*` | `releaseDedicatedIp`, worker admin-ops IP release, VM move |
| DELETE | `/dedicated/server/*/virtualMac/*` | same |
| POST | `/ip/*/move` | VM move between nodes (`lib/vm-move/ovh-ip-move.ts`) |
| POST | `/ip/*/reverse` | `setDedicatedReverse`, `scripts/set-mail-ptr.ts` |

The source of truth is `FEATURE_RIGHTS` in `lib/ovh-admin/rights.ts`. A test checks that every write
path in `lib/ovh-admin/actions.ts` is covered by it.

## Deliberately NOT granted (nothing in the platform needs them)

`/order/*`, `/me/*` writes, `/service/*`, `PUT /dedicated/server/*/serviceInfos` (auto-renew stays a
manual step in the OVH manager), `/dedicated/server/*/terminate`, `/dedicated/server/*/install/*`,
`/ip/*/terminate`, `DELETE /ip/*/firewall/*`.

## How the controls degrade without a right

Each panel reads the key's rules (cached for 5 minutes) and hides or disables a control whose rule is
missing, with "Needs OVH API right METHOD /path". If OVH still returns 403 (for example, rules changed
inside the cache window), the audited wrapper turns that into the same message and writes it to the
audit log.

## Endpoint facts learned (GET, 2026-10-06)

- All 303 GETs in the fleet-wide sweep returned 200.
- Paths used by the panels: `/ip/{block}`, `/game/{ip}` + `/rule/{id}`, `/firewall` + `/{ip}` + `/rule/{seq}`,
  `/mitigation`, `/mitigationProfiles`, `/antihack`, `/spam`, `/arp`, `/reverse/{ip}`, `/task`;
  `/dedicated/server/{s}`, `/serviceInfos`, `/specifications/network`, `/intervention/{id}`, `/task/{id}`,
  `/boot?bootType=rescue|harddisk`, `/boot/{id}`, `/virtualMac/{mac}/virtualAddress[/{ip}]`, `/plannedIntervention`.
- OVH's API has no attack history and no mitigation traffic stats any more (the schema has no
  `/mitigation/{ip}/stats` or `/topology`). The only attack signal is a mitigation object with `auto: true`.
- 404 (not 403) for: `/dedicated/server/{s}/statistics`, `/ola`, `/bandwidth`, `/rescueBoot`, `/burst`.
  These paths do not exist.
- 500 for `/ip/{dedicated-host-ip}/move`, `/phishing` and `/delegation` (OVH-side errors on the
  host's own IP). Not used.
- The node-5 (BHS) offer has no traffic quota (all quota fields are null), so it is shown as unmetered.
- Live findings at discovery time: game-firewall STRICT mode is on for 51.79.226.200 (studionexis/Soul
  Pilates) and 51.79.168.98 (cold-email relay). Both already have OPEN `OVH-GAME-FW` alerts, which kept
  flapping because of the sweep-overlap bug fixed on this branch. Nothing was changed at OVH.
  No IP was antihack/spam/ARP-blocked or under mitigation. All 5 servers have auto-renew on.
