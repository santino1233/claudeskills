---
name: nxeon-cloudflare-proxy-parked
description: Cloudflare proxy for nxeon.cloud is parked by the owner (2026-10-12); what is prepared, why it was not flipped, and the cheap option for later
metadata:
  type: project
---

Owner chose (2026-10-12) to drop proxying nxeon.cloud for now and come back later. cyrus.my IS proxied (packs CDN, real win). nxeon.cloud zone is prepared but unproxied: SSL strict, min TLS 1.2, nginx real-IP conf, tokens at /root/.secrets/cloudflare-nxeon.ini (settings only) and cloudflare-nxeon-dns.ini (DNS only).

**Why not proxied:** Cloudflare Free caps request bodies at 100 MB (portal file manager allows 250 MB, owner's choice) and requests at ~100 s (free-mc create runs up to 180 s: would bring back the 2026-09-02 "Something went wrong" bug). Users are 2/3 Asia, so the gain is small.

**How to apply:** do not re-propose a full proxy unprompted. If revisited, offer the assets-host option (Next assetPrefix + proxied assets.nxeon.cloud, portal stays direct). Never proxy mail/play/sites/staging/SRV records. See [[nxeon-cyrus-skills-universal-modder]] for the other Cyrus context from this session.
