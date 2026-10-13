# Folder upload (branch feature/file-manager-folder-upload, worktree /opt/nxeon-wt-folderupload)
Root cause: browser can't send a directory as a File -> XHR onerror -> "Connection lost".
Fix: lib/upload-paths.ts (flatten + validation), route accepts relPath / mkdir=1, mkdirpPath in lib/sftp.ts,
queue rewritten (concurrency 3, folder group row, retry), Upload folder button.
Also found: route's ownedServer() didn't select guestSshPort -> dedicated-IP servers with non-22 guest ssh broke. Fixed.
Rate limit: 1200 req/min + 2GB/min bytes + 6 in-flight per user (in-memory, per process).
Not verified: full dev-server render of the portal, real SFTP upload on node-4/5, real folder drag in browser.
