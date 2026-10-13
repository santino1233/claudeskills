# File manager archive extraction (branch feature/file-manager-extract, worktree /opt/nxeon-wt-extract)
- Pure logic + guest bash script: lib/archive-extract.ts; action extractArchive in lib/actions-files.ts; UI in components/customer/files/FileBrowser.tsx; tests test/archive-extract.test.ts (integration half needs unzip/bsdtar: NXEON_XT_PATH, LD_LIBRARY_PATH; scratch copies in the session scratchpad xt/root).
- Design/limits/guards documented in docs/DOCUMENTATION.md "SFTP and the file manager".
- Not verified: real VM run over SSH, package auto-install, RAR, UI render in browser.
