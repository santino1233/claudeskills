# Cyrus mod networking: design

Branch `feature/cyrus-v6-capabilities` (worktree `/tank/dev-worktrees/cyrus-v6-capabilities`). Read with
`THREAT-MODEL.md`, `AI-GATEWAY.md` and `ROLLOUT.md` in this folder. **Scope, per the owner (2026-10-08):** design,
manifest format and validation, consent UI, default-OFF settings, wrapper and gateway **stubs**, the allow-list policy.
Scanner hardening and adversarial testing go to a human security reviewer (ROLLOUT.md section 4).

## 1. The idea in one paragraph

Today the build service blocks all networking. Instead: a mod may use the network **only through one small,
reviewed Nxeon helper** (`dev.nxeon.cyrus.net.NxHttp`) that the build service adds to the jar itself, and **only to
hosts the mod declares** in `nx-capabilities.yml`. Plain web calls cost nothing. AI goes only through the Nxeon AI
gateway, which spends the server owner's Cyrus tokens within budgets the owner sets (default 0). The customer sees
what a mod connects to and confirms it before installing. Everything is OFF until the owner approves each phase.

## 2. The manifest: `src/main/resources/nx-capabilities.yml`

```yaml
version: 1
network:
  hosts:
    - host: api.example.com            # exact hostname: lower case, no IP, no wildcard, no port (443 only)
      purpose: Show the weather in the sidebar   # 8-160 characters, shown to the customer
  playerData: none                     # or a list of: names, chat, ip
  maxResponseKiB: 256                  # 16-1024, default 256
secrets:                               # optional; values are typed in by the server owner, never in the mod
  - name: weather_key
    host: api.example.com              # the only host the wrapper will ever send it to
    header: X-Api-Key                  # Authorization | X-Api-Key | X-Auth-Token, or `url: true` (webhook URLs)
    description: Your API key from example.com
ai: false                              # true = may call the Nxeon AI gateway (no host to declare)
```

Rules (one policy file, `services/modbuilder/rules/net-policy.json`, read by both validators):
- at most 8 hosts and 8 secrets; every host needs a purpose; each secret is bound to one declared host;
- deny-listed names (with the reason shown to the user): local and internal names, Nxeon's own domains (AI goes
  through the gateway capability instead), cloud metadata names, AI model providers, paste/file-drop/request-capture
  sites, tunnels, names that embed an IP address, dynamic-DNS names, mining pools;
- unknown keys are errors, so a typo can never silently widen what a mod may do.

Validators: `services/modbuilder/capabilities.js` (build service, JS) and `lib/cyrus/capabilities.ts` (portal, TS,
client-safe including its own SHA-256). `test/cyrus-capabilities.test.ts` runs 22 fixtures through both and requires
identical verdicts, messages and normalized output. The normalized manifest carries `policy` (policy version) and
`sha256` (canonical JSON hash); consent is bound to that hash.

Build service output (when wired, see 5): the normalized manifest goes into the build record as `capabilities`, the
portal mirrors it into `ModBuild.result.capabilities` (additive field, already wired in `lib/modbuilder/{client,store,types}.ts`),
and the service writes `nx-capabilities.properties` into the jar (`stampProperties()`): a self-hashing runtime stamp so the
wrapper needs no YAML parser and refuses an edited stamp.

## 3. The wrapper (`NxHttp`)

Only the public API is fixed so far, as a stub: `services/modbuilder/nxnet/src/dev/nxeon/cyrus/net/NxHttp.java`
(`NxHttp.of(plugin).get(url)/.post(url).json(..).send(callback)`, callbacks only, every call currently returns
`refusal() == "not_available"`). It is not referenced by the Dockerfile, so nothing ships. The transport and its
security requirements are deliberately left to the human security reviewer (ROLLOUT.md section 4); the free
per-mod limits it must enforce are already fixed in `net-policy.json` (`limits`) and mirrored by the pure
`checkNetLimits()` in `lib/cyrus/capabilities.ts`.

## 4. Consent and visibility

- `components/cyrus/capabilities/CapabilityConsent.tsx`: install-time box listing hosts, purposes, player data,
  secrets and (for AI mods) the budget and who pays; an explicit tick returns the manifest hash. Renders nothing for
  offline mods. `CapabilitySummary` is the read-only card for the listing page, Explain tab and NxLabs.
- Contract for the lifecycle agent's install dialog: pass the build's `result.capabilities`; send the hash the
  component returns as `acceptCapabilities` in `POST /api/mod-builder/builds/:id/install`. The route (gate added,
  `capabilityGate()`) answers 403 `networking_off` while `cyrus_mod_networking_enabled` is false, 422
  `manifest_invalid` if the stored manifest fails today's policy, 409 `consent_required` if the hash is missing or
  different. Mods without a manifest install exactly as before.

## 5. Not wired yet (on purpose)

The build service does not call `capabilities.js` yet and its scan is unchanged: wiring the manifest into the
pipeline goes together with the scanner work, after the security review (ROLLOUT.md phase 1).
