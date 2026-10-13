# Swap the Claude account the Cyrus build service uses (VM 88001)

The VM authenticates with `CLAUDE_CODE_OAUTH_TOKEN` in `/root/claudebox.env` (health shows `"auth":"subscription"`).
Everything runs from the PRIMARY (it holds the jump-host key to node-2 and the VM). Script: `swap-build-account.sh` (this folder).

1. Get a token for the new account (any machine with the Claude CLI): `claude setup-token`, sign in as that account, copy the `sk-ant-oat...` token.
2. On the primary (from PowerShell: `ssh -t root@51.79.162.96`), then:
```
cd /root/claudeskills/agent-notes/cyrus-research
bash swap-build-account.sh preflight    # idle check + env backup
bash swap-build-account.sh settoken     # paste token (hidden)
bash swap-build-account.sh swap         # restart + verify, expect "auth":"subscription"
bash swap-build-account.sh rollback     # only if needed
```
Run one cheap build afterwards to confirm. A subscription login is for testing only: before public launch use an API key
(`API_KEY=sk-ant-... bash scripts/cyrus/deploy-modbuilder.sh`, `/health` auth must be `api_key`). Backups `/root/claudebox.env.acctbak-*` on the VM hold the old token: delete after a day of good builds.
