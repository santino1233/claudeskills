# R0: Minecraft 26.x build lane (2026-10-10)

Scope: prove a 26.x plugin builds and loads, on node-2 in /tank/nxeon-build/tmp/r0-26x only. Nothing deployed, no 26.x version marked buildable, registry.json untouched. Everything below is RAN unless it says NOT RUN.

## Headline (all RAN)
A plugin compiled with `javac --release 25 -proc:none` on Temurin 25 against paper-api `26.2.build.133-stable` produced class major 69, passed scan.js's bytecode scan (0 findings), and loaded and enabled on a real Paper 26.2 build 133 server on JDK 25 ("[HelloR0] HelloR0 enabled on 26.2 (java 25)"), and its `/hellor0` command answered.

## Toolchain (sha256 verified)
- Temurin 25.0.4.1+1, jdk-x64-linux tar.gz, sha256 dbb698396d478e7fa2b1e50f4103324b2a99b90569ee27c33f2261f9215cf41e (Adoptium API checksum).
- Gradle 9.8.1 zip, sha256 dce76f55f8e251a3a1f130eb120f30b3d271de2b76c9b0729d316b5a1b6dc01f (services.gradle.org published).
- Also fetched for comparison: Temurin 21.0.12.1+1 sha256 ce79869e...bcfaee94, Gradle 8.14.3 (published sha256 checked).

## Server jars (sha256 match the pins) and pack formats from version.json
| ver | sha256 | protocol | world_version | resource pack | data pack | java |
|---|---|---|---|---|---|---|
| 26.1.2 build 74 | 1d70b1da...e5f7 | 775 | 4790 | 84.0 | 101.1 | 25 |
| 26.2 build 133 | bf1dcf62...9ff1 | 776 | 4903 | **88.0** | 107.1 | 25 |
| 26.3 build 169 (BETA, reference only) | 185d9f42...81fb | 777 | 5023 | 97.1 | 121.0 | 25 |

Registry corrections: 26.2 resourcePack null -> **{major 88, minor 0}**. The other four numbers are confirmed (26.1.2 84.0 / 101.1, 26.2 data 107.1) and 26.3's 97.1 / 121.0 also match. `id` is 26.1.2, 26.2, 26.3; `stable: true` in all three files, even the beta 26.3 build, so do not use that flag for stability. These come from the server's own version.json, not from any client check; `resourcePackClientVerified` stays false.

## Classpath (step 3)
- Gradle 9.8.1 on JDK 25 with template + `-PjavaRelease=25`: resolves OK. 16.7s wall, 623 MB peak RSS (-Xmx1g). 48 jars (paper-api, adventure 5.2.0, guava 33.6.0, brigadier, etc.). Result: classpath/26.2.txt in the colon-joined format of the existing files, plus 26.2.sha256 (one `sha256  jarname` per line) and 26.2.classes.txt (21,068 classes).
- Gradle 8.14.3 on JDK 21 with the UNMODIFIED template (toolchain/release 21) FAILS: `Dependency resolution is looking for a library compatible with JVM runtime version 21, but 'io.papermc.paper:paper-api:26.2.build.133-stable' is only compatible with JVM runtime version 25 or newer.` The same Gradle 8.14.3 on JDK 21 succeeds if told `-PjavaRelease=25` (only the JVM-version attribute matters for resolution; same 48 jars, different order). So Gradle 9/JDK 25 is not strictly required for resolution, but the compile needs JDK 25 anyway; I used Gradle 9.8.1 in the repo script.
- Repo script reproduces it: refuses non-exact coordinates (`26.2-SNAPSHOT` -> rc 2); real run wrote 48 jars with a sha256 set identical to the manual run. I found and fixed one bug in it (the last jar was dropped because the path file has no trailing newline).

## Compile + scan (step 4)
- javac 25.0.4.1 `-J-Xmx768m --release 25 -proc:none -Xlint:deprecation,removal`, a JavaPlugin with a command and a PlayerJoinEvent listener using Adventure Component: 0 errors, 0 warnings, major version 69. Jar made with `jar --date`.
- scan.js `scanBytecode` (javap): clean plugin -> 0 findings. A positive-control class calling `setOp(true)` and `Bukkit.dispatchCommand` -> both flagged (rules `op`, `console-dispatch`). Works with JDK 25's javap and also with JDK 21's javap on major-69 classes (identical findings), so the image's default PATH javap is fine. No false positives, no breakage. NOT RUN: the scan.js source-level scan on 26.x code (it is plain text, independent of class version) and the "real javac output" unit test (skipped: no MB_TEST_JDK).

## Real Paper 26.2 boot (step 5)
`java -Xmx1g -Xms256m -jar paper.jar --nogui`, nice 10, wrapped in `timeout 420`, port 25599, online-mode=false, max-players=1, eula=true, stdin from a fifo. First boot also downloads the vanilla mojang_26.2.jar and applies patches. "Done (7.903s)" for server start (about 8.5s of JVM time after the one-off patch step); plugin loaded and enabled; `/hellor0` -> "Hello from R0"; `stop` on stdin shut down cleanly (plugin disabled, exit status 0). Peak RSS 879,728 kB (about 859 MB). No stray process, port 25599 closed. One harmless ERROR at start: "No key layers in MapLike[{}]" (my flat level-type property). Player-join listener was NOT exercised (no client or bot connected).

## Repo changes (worktree /tank/dev-worktrees/cyrus-r0, branch feature/cyrus-r0, commit 5a6af8db96)
- `services/modbuilder/tools/gen-classpath-26.sh` (new).
- `Dockerfile`: new empty-default ARGs JDK25_URL/JDK25_SHA256, GRADLE9_URL/GRADLE9_SHA256, MC26_PINS ("id=coordinate ..."). Checksum is mandatory when a URL is given. Installs /opt/mb/jdk25 and /opt/mb/gradle9, resolves classpaths into /opt/mb/classpath. NOT RUN: no docker build was done, so the Dockerfile edits are untested syntax-wise.
- `server.js`: `javacFor(mcVersion)` picks `/opt/mb/jdk25/bin/javac --release 25` only if the registry marks that version buildable with javaRelease 25; otherwise `javac --release 21` as today. Registry path: MB_REGISTRY, /opt/mb/app/registry.json, or the repo path. The image has no copy of lib/, so the build must stage registry.json (or mount it) before this does anything. Checked with a harness: today's registry -> empty map (inert); a temp copy with 26.2 buildable -> 25/JDK 25; 1.21.x unchanged.
- `template/build.gradle.kts`: `-PjavaRelease` (default 21, so 1.21.x output is unchanged).
- RAN `/opt/nxeon/scripts/devhost test test/modbuilder-pipeline.test.ts test/modbuilder-scan.test.ts test/modbuilder-jar.test.ts`: 12 tests, 12 pass, 0 fail (the real-javac scan test skips without MB_TEST_JDK).

## Owner steps still needed
1. Rebuild the modbuilder image for VM 88001 with the JDK25/Gradle9/MC26_PINS build args (values above) and stage registry.json into the container; check /health and one 1.21.x build still passes.
2. Also add 26.x to the service's MB_VERSIONS env and flip `buildable` in the registry only after the next two steps.
3. Run one real end-to-end 26.x build through the service, then the eval set against 26.2; also load a build on a 26.x server in the nxeon game stack and a real client check of the resource pack format (88.0 for 26.2).
4. 26.3 stays unpinned until Paper ships a stable build (only beta 169 exists).
5. Cleanup: /tank/nxeon-build/tmp/r0-26x is about 2 GB of toolchains and caches; delete when done.
