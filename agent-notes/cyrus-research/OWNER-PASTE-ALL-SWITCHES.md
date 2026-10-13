# Turn all safe Cyrus switches on (owner paste, 2026-10-13)

The auto-mode classifier blocks flag writes from the assistant ([Feature Flag Writes]); this is the one paste that does it.
Run on the primary. Web restarts once (about 40 s of 502s). Backup: `/opt/nxeon/.env.bak-allon-*`.

```bash
cd /opt/nxeon && cp -a .env .env.bak-allon-$(date +%Y%m%d-%H%M%S) && for k in CYRUS_SOUND_LIBRARY_CLEARED CYRUS_STORAGE CYRUS_STORAGE_ADDONS CYRUS_WALLET_PAY CYRUS_API_V1 CYRUS_MODPACK_INSTALL_REAL CYRUS_DATAPACK_DELIVERY_REAL CYRUS_HANDGUN_GRIP_FIX CYRUS_LIBRARY_CONTRIBUTE CYRUS_BYO_GAME_ASSETS CYRUS_GDPR_ERASE CYRUS_TESTFLIGHT_WORLDGEN CYRUS_WORLDGEN CYRUS_ARMOR_LANE CYRUS_NOTEBLOCK_LANE CYRUS_DATAPACK_STUDIO CYRUS_CUSTOMER_APP CYRUS_LEARNING CYRUS_PROMPT_COACH CYRUS_LIVE_ASSETS CYRUS_MC_TECHNIQUES CYRUS_DESIGNER_BUILDS CYRUS_CONFIG_STUDIO CYRUS_CREATURES; do sed -i "/^$k=/d" .env; echo "$k=1" >> .env; done && systemctl restart nxeon-worker && sleep 3 && systemctl restart nxeon-web && sleep 20 && systemctl is-active nxeon-web nxeon-worker && curl -s -o /dev/null -w "nxeon.cloud %{http_code}\n" https://nxeon.cloud/
```

## Deliberately NOT included (and why)
| Switch | Why it stays off |
|---|---|
| `cyrus_studio_public_enabled` + `cyrus_tok_live` (launch pair) | Opens Cyrus to everyone and starts real charging. The build service still runs on a personal Claude subscription login (not allowed for a public service; needs an API key), token prices and plan numbers are PLACEHOLDERS, and the Terms/Privacy need a lawyer. Say "launch" when you want it and I will do the API-key switch and flip both together. |
| `CYRUS_TRY_IT_EXPOSE` | Exposes throwaway test servers to the public internet: needs a port/firewall plan first. |
| `CYRUS_MESHGEN`, `CYRUS_MESHGEN_SCRATCH` | AI mesh service needs an isolated microVM worker first. |
| `CYRUS_NOTIFY_EMAIL` | Needs SPF/DKIM for the cyrus.my sender verified. |
| `CYRUS_ATTRIBUTION`, `CYRUS_CONVERSIONS` | Ad/referral tracking: consent and privacy wording first. |
| `CYRUS_ADMIN_HOST`, `CYRUS_ADMIN_HOST_ONLY` | Needs its own DNS record and Origin CA cert. |
| `cyrus_mods_public_enabled`, `cyrus_public_enabled` | Public community pages: part of the launch. |

Only the preview account sees any of this while the launch pair is off.
