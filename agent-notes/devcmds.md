# devcmds agent notes (2026-10-01)

Branch fix/valheim-devcommands, worktree /opt/nxeon-wt-devcmds, commit a2982bb445.

## Verdict
NxeonDevAdmin 1.0.0 (server-only) could never unlock god/fly/debugmode for any connected player.
In Valheim l-1.0.16 those commands run in the player's own client. They are checked against the
client's own ZNet.IsServer(), which is always false on a dedicated server. They are not
remoteCommand, so they never reach the server. On the server the 1.0.0 patch could not change a
result either: IsServer() is already true there.
`devcommands` IS forwarded (RPC_RemoteCommand -> "Remote admin ... executed command ...
remotely." -> server's Console.TryRunCommand). That flips only the server's m_cheat, which
serves only forwarded commands (sleep, skiptime, setkey, listkeys, ...).
Second bug: a vanilla client's LocalPlayerIsAdminOrHost() matches only "Steam_<id>", while
lloesche ADMINLIST_IDS writes bare IDs. So even a client-installed 1.0.0 fails for Jay.

## Fix
NxeonDevAdmin 2.0.0 is CLIENT-side and a no-op on the server. It patches IsCheatsEnabled and
ConsoleCommand.IsValid for synced-adminlist clients (either ID form) and sets Game.isModded.
DLL: worker/assets/valheim/NxeonDevAdmin.dll, also at /root/agent-notes/NxeonDevAdmin-2.0.0.dll
(sha256 da421fb10f692f207d8110d26b7f5ba90a113424202f84813bd277387c721747).

## Evidence / verification
- Decompiled with /tank/tools/ilspy/ilspycmd (DOTNET_ROLL_FORWARD=Major, DOTNET_ROOT=/tank/tools/dotnet).
  Decompiled sources: scratchpad/decomp/{Terminal,ZNet,all,PlatformUserID}.cs
- The public Steam depot assembly_valheim.dll is byte-identical to the customer copy (sha256 50035055...).
- Harness: tools/valheim-plugins/NxeonDevAdmin.Harness/run.sh (real dispatch code). Vanilla and
  1.0.0 reproduce Jay's "'god' is not valid in the current context."; 2.0.0 passes.
- test/valheim-devadmin-dll.test.ts passes; tsc clean.

## Tell Jay (after owner sign-off; ticket replies need approval)
1. Download NxeonDevAdmin.dll (we attach it).
2. r2modman -> Valheim -> his profile -> Settings -> Browse profile folder -> BepInEx\plugins ->
   new folder NxeonDevAdmin -> drop the DLL in.
3. Start modded. Join the server. F5. Type `devcommands` ONCE (must say "Dev commands: True").
   Then `god`, `fly`, `debugmode`.
4. If it fails: send BepInEx\LogOutput.log (look for "Nxeon Dev Admin 2.0.0 loaded").
Optional server side: add a "Steam_76561198327183538" line to adminlist.txt next to the bare one.

## Unverified
No real game client was run: BepInEx loading alongside his 23 mods, mod conflicts on the same
methods, and the Unity-native command bodies are all untested. Also unverified: whether
ADMINLIST_IDS overwrites hand-added adminlist lines.

## Tooling left on /tank (not system-wide)
/tank/tools/{dotnet,ilspy,depotdl,valheim-server,bepinex,nuget,valheim-devadmin-work,dotnethome}
