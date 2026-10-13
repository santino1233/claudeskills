#!/bin/bash
# Waits for Cloudflare to make cyrus.my active, then issues the Let's Encrypt cert (DNS-01 via the Cloudflare token) and swaps it into nginx.
CRED=/root/.secrets/cloudflare-cyrus.ini; Z=474843c785f916483396b1935230a59a
T=$(sed 's/.*= *//' $CRED)
for i in $(seq 1 576); do   # up to 48 h, every 5 min
  S=$(curl -s -H "Authorization: Bearer $T" https://api.cloudflare.com/client/v4/zones/$Z | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['status'])")
  [ "$S" = active ] && break; sleep 300
done
[ "$S" = active ] || { echo "zone still $S"; exit 1; }
certbot certonly --dns-cloudflare --dns-cloudflare-credentials $CRED --dns-cloudflare-propagation-seconds 30 -d cyrus.my -d www.cyrus.my --non-interactive --agree-tos -m haxkodi@gmail.com || exit 2
sed -i 's#/etc/nginx/ssl-cyrus/self.crt;     \# CYRUS_CERT#/etc/letsencrypt/live/cyrus.my/fullchain.pem; \# CYRUS_CERT#; s#/etc/nginx/ssl-cyrus/self.key; \# CYRUS_KEY#/etc/letsencrypt/live/cyrus.my/privkey.pem; \# CYRUS_KEY#' /etc/nginx/sites-enabled/cyrus-my
nginx -t && systemctl reload nginx && echo "cyrus.my now uses the Let's Encrypt cert"
