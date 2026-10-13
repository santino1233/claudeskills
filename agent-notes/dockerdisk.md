# dockerdisk (2026-10-04) - branch fix/guest-docker-storage-and-l4d2-disk, worktree /tank/nxeon-wt-dockerdisk
Commit 26f5441d54. Classic Docker store on NEW guests (lib/guest-docker.ts), big-image disk guard, lib/game-image-footprint.ts,
CI test/game-disk-fit.test.ts, l4d2 seeds 30/35/35 (+4tier entry 30), docs section at end of docs/DOCUMENTATION.md.
tsc clean; full suite = same 46 pre-existing failures as main (identical list before/after).
Scratch: /tank/dockerdisk-scratch (sizes.txt = skopeo layer sums, before/after test lists).
Owner: reseed (or UPDATE OsTemplate l4d2 minDiskGB=30) in prod; rebuild golden template; decide the KNOWN_UNDERSIZED plans.
