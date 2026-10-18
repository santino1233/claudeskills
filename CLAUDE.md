# Shared Claude workspace (Nxeon, Cyrus and other projects)
- Memory index: memory/MEMORY.md (read it first). Cyrus: agent-notes/cyrus-research/CYRUS-TRACKER.md.
- Skills in skills/, notes in agent-notes/. All of it auto-syncs to GitHub every 2 minutes (claudeskills-sync); do not store secrets here.
- Both Claude accounts work from /root on the primary node. Heavy builds: scripts/devhost on node-2 only; never build in /opt/nxeon.
- NEVER run the `nginx` binary (nginx -t, nginx -c, test servers) on the PRIMARY server: it is production. A root nginx run with a config lacking `user www-data;` chowns /var/lib/nginx/* to nobody and breaks the live site (2026-10-18 incident). Test nginx configs on node-2 only.
