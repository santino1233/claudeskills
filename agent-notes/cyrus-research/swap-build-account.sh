#!/bin/bash
# Swap the Claude account the Cyrus build service (VM 88001) uses. Run ON THE PRIMARY as root.
# The VM authenticates with CLAUDE_CODE_OAUTH_TOKEN in /root/claudebox.env (health: "auth":"subscription").
#   0. Get a token for the NEW account (anywhere): `claude setup-token`, sign in as that account, copy the sk-ant-oat... token it prints.
#   bash swap-build-account.sh preflight   # idle check + backup of the env file (safe)
#   bash swap-build-account.sh settoken    # paste the new token (hidden input, never on a command line or in git)
#   bash swap-build-account.sh swap        # write token, restart container, verify health
#   bash swap-build-account.sh rollback    # restore the previous env file + restart
# Path: primary -> node-2 (jump, the primary's own key) -> VM 10.20.1.253.
set -uo pipefail
J=${J:-root@178.63.94.114}; V=${V:-root@10.20.1.253}
R() { ssh -o BatchMode=yes -J "$J" "$V" "$@"; }
idle() { R "curl -s 127.0.0.1:7340/health | grep -q '\"running\":0'" || { echo "A BUILD IS RUNNING (or VM unreachable): wait and rerun"; exit 1; }; }
case "${1:-}" in
preflight)
  R "curl -s 127.0.0.1:7340/health | grep -o '\"auth\":\"[a-z_]*\"'; docker inspect -f 'image: {{.Config.Image}}' modbuilder"
  idle
  R 'TS=$(date +%Y%m%d-%H%M%S); cp -a /root/claudebox.env /root/claudebox.env.acctbak-$TS && echo "backup: /root/claudebox.env.acctbak-$TS"'
  ;;
settoken)
  read -rsp "Paste the NEW account token (hidden): " TOK; echo
  case "$TOK" in sk-ant-*) ;; *) echo "that does not look like a token (expected sk-ant-...)"; exit 1;; esac
  printf %s "$TOK" | R 'umask 077; cat > /root/.new-oauth-token && test -s /root/.new-oauth-token && echo "token staged on the VM (mode 600)"'
  unset TOK
  ;;
swap)
  idle
  R 'set -e; test -s /root/.new-oauth-token || { echo "no staged token: run settoken"; exit 1; }
     IMG=$(docker inspect -f "{{.Config.Image}}" modbuilder)
     { grep -v "^CLAUDE_CODE_OAUTH_TOKEN=" /root/claudebox.env || true; } > /root/.claudebox.env.new
     printf "CLAUDE_CODE_OAUTH_TOKEN=%s\n" "$(cat /root/.new-oauth-token)" >> /root/.claudebox.env.new
     chmod 600 /root/.claudebox.env.new && mv /root/.claudebox.env.new /root/claudebox.env
     shred -u /root/.new-oauth-token 2>/dev/null || rm -f /root/.new-oauth-token
     cd /opt/modbuilder && ./run.sh "$IMG"
     for i in $(seq 1 20); do sleep 3; H=$(curl -s 127.0.0.1:7340/health) && echo "$H" | grep -q "\"promptVersion\"" && break; done
     echo "$H" | grep -o "\"auth\":\"[a-z_]*\""; echo "running image: $IMG"'
  ;;
rollback)
  R 'set -e; B=$(ls -t /root/claudebox.env.acctbak-* | head -1); IMG=$(docker inspect -f "{{.Config.Image}}" modbuilder)
     cp -a "$B" /root/claudebox.env && cd /opt/modbuilder && ./run.sh "$IMG"; sleep 5
     curl -s 127.0.0.1:7340/health | grep -o "\"auth\":\"[a-z_]*\""; echo "restored from $B"'
  ;;
*) sed -n 2,11p "$0"; exit 2 ;;
esac
