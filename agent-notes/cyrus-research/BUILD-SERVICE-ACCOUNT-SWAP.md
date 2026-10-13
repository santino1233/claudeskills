# Swap the Claude account the Cyrus build service uses (VM 88001), from PowerShell

Owner runs this. No secrets here: the new account is authorised interactively in your browser, the token never touches chat or git.
Facts (services/modbuilder/run.sh): the container reads ONE login file, `/root/.claude-modbuilder/.credentials.json`
(mounted at /run/claude-auth). Swapping accounts = replace that directory, then `./run.sh <current image>`.
Path: PC -> node-2 `root@178.63.94.114` (jump) -> VM `root@10.20.1.253`. Needs your SSH key for node-2 (same one you use now).
Do it when no build is running (step 1 checks). The restart takes ~15 s; queued builds in flight fail, so pick a quiet moment.

```powershell
$J = "root@178.63.94.114"; $V = "root@10.20.1.253"

# ---- STEP 1: preflight + backup (safe, read-mostly) ----
@'
set -e
echo "== health"; curl -s 127.0.0.1:7340/health | head -c 400; echo
curl -s 127.0.0.1:7340/health | grep -q '"running":0' || { echo "A BUILD IS RUNNING - wait and rerun"; exit 1; }
echo "== image"; docker inspect -f '{{.Config.Image}}' modbuilder
TS=$(date +%Y%m%d-%H%M%S)
cp -a /root/.claude-modbuilder /root/.claude-modbuilder.acctbak-$TS
cp -a /root/claudebox.env /root/claudebox.env.acctbak-$TS
echo "backup suffix: acctbak-$TS"; ls -d /root/.claude-modbuilder.acctbak-*
echo "== is the claude CLI on the VM host?"; command -v claude || echo "no host claude: step 2 will use the container image"
'@ | ssh -J $J $V "bash -s"

# ---- STEP 2: log in as the NEW account (interactive; opens a URL: open it in a browser signed in as the new account, paste the code back) ----
# Uses a separate directory so the live login is untouched until step 3.
ssh -t -J $J $V 'mkdir -p /root/.claude-modbuilder-new && chmod 700 /root/.claude-modbuilder-new && IMG=$(docker inspect -f "{{.Config.Image}}" modbuilder) && if command -v claude >/dev/null; then CLAUDE_CONFIG_DIR=/root/.claude-modbuilder-new claude login; else docker run --rm -it --entrypoint claude -v /root/.claude-modbuilder-new:/cfg -e CLAUDE_CONFIG_DIR=/cfg $IMG login; fi; ls -la /root/.claude-modbuilder-new/.credentials.json'
# The last line must list .credentials.json. If it does not, the login did not finish: rerun step 2.

# ---- STEP 3: swap + restart + verify ----
@'
set -e
curl -s 127.0.0.1:7340/health | grep -q '"running":0' || { echo "A BUILD IS RUNNING - wait and rerun"; exit 1; }
test -s /root/.claude-modbuilder-new/.credentials.json || { echo "no new login file: run step 2"; exit 1; }
IMG=$(docker inspect -f '{{.Config.Image}}' modbuilder)
TS=$(date +%Y%m%d-%H%M%S)
mv /root/.claude-modbuilder /root/.claude-modbuilder.old-$TS
mv /root/.claude-modbuilder-new /root/.claude-modbuilder
cd /opt/modbuilder && ./run.sh "$IMG"
for i in $(seq 1 20); do sleep 3; H=$(curl -s 127.0.0.1:7340/health) && echo "$H" | grep -q '"promptVersion"' && break; done
echo "$H" | head -c 400; echo
echo "$H" | grep -o '"auth":"[a-z_]*"'
echo "old login kept: /root/.claude-modbuilder.old-$TS"
'@ | ssh -J $J $V "bash -s"
# Expect "auth":"subscription_login". Then run ONE cheap real build from the preview account to confirm the new account works.

# ---- ROLLBACK (if health fails or builds error with auth/limit messages) ----
@'
set -e
OLD=$(ls -d /root/.claude-modbuilder.old-* | tail -1)
IMG=$(docker inspect -f '{{.Config.Image}}' modbuilder)
mv /root/.claude-modbuilder /root/.claude-modbuilder.failed-$(date +%s)
mv "$OLD" /root/.claude-modbuilder
cd /opt/modbuilder && ./run.sh "$IMG"
curl -s 127.0.0.1:7340/health | grep -o '"auth":"[a-z_]*"'
'@ | ssh -J $J $V "bash -s"
```

## Notes
- A subscription login is for your own testing. Before any public launch switch to a paid API key:
  `API_KEY=sk-ant-... bash scripts/cyrus/deploy-modbuilder.sh` on the primary (docs/CYRUS-DEPLOY-RUNBOOK.md section 4); `/health` `auth` must read `api_key`.
- Subscription usage limits are shared by everything on that login (all Cyrus builds, evals, flights). The new account's limits apply from now on.
- Cleanup later (after a day of good builds): `rm -rf /root/.claude-modbuilder.old-* /root/.claude-modbuilder.acctbak-*` on the VM (these hold the old account's login: do not leave them forever).
