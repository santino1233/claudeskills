# Geyser ticket (Micah Lee) - 2026-10-04, read-only investigation
Server: minecraft-lq4amk (cmupbaoar0lqhhlgdzaxuwxff), VM 655, node-3 (sgp1, 15.235.145.177), Minecraft 4GB/20 slots, paper 26.3, no dedicated IP.
Forwards in DB: only 20095 -> 25565/tcp (+ SSH 20094). Node-3 NAT chain NXEON_FWD_N3 matches (nothing for 19132/udp). Other node-3 servers use UDP forwards, so UDP path works.
Guest: container `mc` publishes only 25565/tcp + 25575/tcp; no UDP listener in the guest at all.
Plugins (uploaded manually, root-owned jars): Geyser-Spigot 2.11.3-SNAPSHOT, floodgate 2.2.5, voicechat 2.6.24 (platform-installed). Config sane (port 19132, auth floodgate, key.pem present).
Geyser FAILS TO ENABLE on every start: "Couldn't find asBukkitCopy or asCraftMirror method on CraftItemStack" (cloud-bukkit ItemStackParser vs Paper 26.3). 2.11.3 is the newest Geyser release on download.geysermc.org.
Platform: Geyser/Floodgate are in the Mods catalogue (Cross-play) but nothing forwards/publishes UDP; game panel has no port-forward UI (only VPS panel); staff can add via admin addPortForward.
Fix branch: /tank/nxeon-wt-geyser fix/minecraft-geyser-bedrock (see git log).
