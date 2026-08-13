# VineyardMac Maintainer Handover

Last verified: 2026-08-13

This is the operational handover for future coordinating and working agents. It records current facts, completed work, known blockers, and the safest next steps. Verify volatile facts such as Git status, pull request state, CI, remote files, and installed tools before acting.

## Read First

1. `AGENTS.md` contains the repository rules and validation workflow.
2. `docs/AUDIT.md` contains the stabilization roadmap.
3. `docs/RUNTIME.md` describes runtime construction, publishing, and smoke tests.
4. This file contains the current maintainer state and handover protocol.

When documentation conflicts with the checked-out repository or a current remote response, investigate and update the stale documentation instead of assuming it is correct.

## Maintainer Preferences

- Communicate with the maintainer in French unless public project text requires English.
- Critically evaluate requests and recommend the safer or simpler path when appropriate.
- Use Ponytail full: understand the complete path first, then make the smallest change that solves the real problem.
- Never install software, Homebrew formulae, Xcode components, Wine builds, or system dependencies. Stop and tell the maintainer exactly what to install.
- Ask immediately for missing identifiers, links, credentials, or decisions. Do not build workarounds around information the maintainer can provide.
- Use local repository evidence first, Context7 for current dependency/API documentation, and official web sources for unstable Apple, Wine, DXVK, Sparkle, and GitHub facts.
- Perform shell and automated tests directly. Ask the maintainer for graphical testing only when automation cannot reliably perform it.
- Keep code and documentation natural, concise, and consistent with the original contribution style.
- Preserve user changes in a dirty worktree. Never revert them without explicit approval.
- Keep commits focused, push the active branch, and wait for required GitHub checks before calling work complete.

## Two-Agent Protocol

The maintainer uses one coordinating chat and one working chat against the same repository.

### Coordinator

- Remains read-only by default: no edits, staging, commits, pushes, publishing, or long-running builds.
- Reads the four files above and checks current Git/GitHub state before planning.
- Challenges weak assumptions, maintains the order of work, and gives the maintainer one short worker prompt at a time.
- Does not dispatch a second write task until the previous worker has finished and reported its final Git status.
- Requests an explicit maintainer decision before merging, changing production release pointers, deleting data, changing signing, or installing anything.

### Worker

- Is the only chat allowed to modify the shared worktree during an assignment.
- Reads `AGENTS.md` and this file before acting.
- Handles the assigned task end to end: inspect, implement, validate, commit, push, and watch CI when applicable.
- Updates this file only when the recorded project state materially changes.
- Reports changed files, commands run, commit hash, push result, CI result, remaining risk, and final `git status`.
- Stops and asks the maintainer when an installation, credential, identifier, paid action, destructive operation, release publication, or graphical-only test is required.

The coordinator's normal worker instruction should be one sentence:

> Lis `AGENTS.md` et `docs/HANDOVER.md`, puis réalise [tâche précise] de bout en bout; respecte les changements locaux, n'installe rien, mets à jour le handover si l'état change, commit/push et attends la CI.

The maintainer pastes the worker's final report back into the coordinator chat before requesting the next task.

## Repository And GitHub

- Repository: `https://github.com/Pape45/VineyardMac`
- Original upstream: `https://github.com/Whisky-App/Whisky`
- Default branch: `main`
- PR `Pape45/VineyardMac#4`, `Adopt verified Gcenx runtime installation`, was merged as `59a33f9d5965009b6ca836da158844bc000148d9` after its macOS build, WhiskyKit tests, and SwiftLint passed.
- PR `Pape45/VineyardMac#5`, `Record beta.2 activation and fix bottle creation`, was merged as `95cb04223d74ef6d63644a9ca6c1ff6e91a64c6a` with the completed beta.2 activation record and bottle-creation fixes.
- The GitHub CLI is authenticated as `Pape45` with `repo` and `workflow` access.
- Because both `origin` and the archived Whisky `upstream` exist, always pass `--repo Pape45/VineyardMac` to `gh pr` commands. An unqualified `gh pr view 4` previously resolved to the unrelated Whisky PR #4.

## Verified Stable Environment

- macOS 26.6.1, build 25G76.
- Xcode 26.6, build 17F113, selected from `/Applications/Xcode-26.6.0.app`.
- Rosetta 2 is installed.
- A signed Debug build succeeds for the app, CLI, and thumbnail extension.
- The resulting app passes `codesign --verify --deep --strict` outside the Codex sandbox.
- SwiftLint reports zero violations during the Xcode build.
- `swift test --package-path WhiskyKit` passes four focused tests: the three runtime installer tests and the missing bottle metadata regression test.
- SwiftLint, bison, LLVM, pkgconf, Wrangler, and the required Xcode package dependencies were available when last checked. The 2026-08-12 GPTK 4 audit found no installed `x86_64-w64-mingw32-gcc`; recheck tools after environment changes and do not reinstall automatically.

Current local bundle identifiers are:

- `com.pape45.VineyardMac`
- `com.pape45.VineyardMac.Cmd`
- `com.pape45.VineyardMac.Thumbnail`

Automatic `Apple Development` signing with the maintainer's Personal Team works for local development. The older certificate shown as `Not in Keychain` is not used. Public distribution still needs a deliberate Developer ID, notarization, update, and migration plan.

The useful validation commands are documented in `AGENTS.md`. A signed build was last run with:

```bash
xcodebuild -project Whisky.xcodeproj \
  -scheme Whisky \
  -configuration Debug \
  -destination platform=macOS \
  -disableAutomaticPackageResolution \
  build
```

## Runtime State

Merged PR #4 changes runtime installation from an unverified replacement to a staged, validated installation. It adds release metadata validation, SHA-256 verification, required-file checks, an embedded manifest/version check, atomic replacement that preserves the previous runtime until validation succeeds, and focused tests.

The in-app update prompt now opens the existing runtime download and installation flow directly. It no longer uninstalls the installed runtime before download, so download or validation failures leave the current runtime available.

Leaving or retrying the runtime download screen cancels its URL session task and progress observation. Stale callbacks cannot advance setup, and any archive they already moved is removed.

The runtime installation screen hides native back navigation while installation runs. After an error, its Retry button remains the only route back to a fresh download; the atomic installation task is not cancelled.

Active runtime `4.0.0-beta.2` contains Gcenx Game Porting Toolkit 3.0-3, D3DMetal 3.0, the VineyardMac Vulkan driver, DXVK-macOS, MoltenVK, GStreamer, Winetricks, licenses, and `RuntimeManifest.json`. The exact component and source inventory is in `Runtime/RuntimeManifest.json`.

The complete immutable artifact was built, smoke-tested, uploaded, and downloaded again with a matching hash:

- R2 bucket: `vineyardmac`
- URL: `https://data.vineyardmac.app/Wine/archive/Libraries-4.0.0-beta.2.tar.gz`
- Size: `404974593` bytes
- SHA-256: `86f9a7f6280b1648e5a7a640023a3a443870c882fdd214c062ce60b344004ef4`

Read-only prevalidation was repeated on 2026-08-11 from the immutable URL. The download matched the exact size and SHA-256 above; all 18 installer-required files and executable bits were present; the embedded version was `4.0.0-beta.2+2`; and its `RuntimeManifest.json` was byte-identical to the repository copy with SHA-256 `cc2bbe8061f5bb3176a14481bb0da3902c3300108ee9251b99d3a85178ef4c67`. Disposable-prefix smoke tests passed for D3D11 (`0xb000`), D3D12 device creation, and DXVK D3D11 using DXVK `1.10.3-20230507-async` with MoltenVK `1.4.2`. The isolated `/tmp` archive, extraction, compiled smoke executable, Wine prefix, and DXVK logs were removed afterward. No R2 object, release pointer, user bottle or container was modified, and no graphical test was run.

Public access on this download bucket is intentional. Production safety comes from immutable versioned keys, release metadata, SHA-256 verification, runtime validation, and publishing the release pointer last.

`scripts/build-runtime.sh` keeps the generated archive name `Libraries.tar.gz` for local output and the mutable legacy upload, but writes the matching immutable `Wine/archive/Libraries-<version>.tar.gz` URL into `WhiskyWineVersion.plist`.

### Historical beta.2 activation

Beta.2 was activated on 2026-08-11. Public R2 now contains:

- unchanged immutable `Wine/archive/Libraries-4.0.0-beta.2.tar.gz`, `404974593` bytes, SHA-256 `86f9a7f6280b1648e5a7a640023a3a443870c882fdd214c062ce60b344004ef4`, ETag `e8c5990b55345d80952c28843c1d5f44-13`;
- mutable `Wine/Libraries.tar.gz` with the same size and SHA-256, ETag `03f940e4df39f65820edb1e5d1a9061a`;
- root `Wine/RuntimeManifest.json`, byte-identical to the repository, SHA-256 `cc2bbe8061f5bb3176a14481bb0da3902c3300108ee9251b99d3a85178ef4c67`;
- `Wine/WhiskyWineVersion.plist` version `4.0.0-beta.2+2`, immutable URL, archive SHA-256, and minimum macOS `14.0`, SHA-256 `b9f9c757a93ae9c5444b1ce45caf00e317b62036f696ccc833ea1b76a4fddf53`.

Wrangler 4.120.0 refused the 386 MiB local upload because `r2 object put` is capped at 300 MiB. An ephemeral R2-bound Worker instead streamed the already verified immutable object to the mutable key after checking both objects' size and ETag. The Worker was stopped immediately, its local files were removed, and the mutable object was downloaded again and matched the expected SHA-256 before the manifest or pointer was published.

The signed Debug app then completed a genuinely fresh graphical setup from an initially absent local runtime. The installed runtime reports `4.0.0-beta.2+2`, and its manifest matches the repository. A bottle created only under `/Users/pape/Documents/VineyardMac-Activation-2026-08-11/` initialized successfully and launched `winecfg.exe`; its reference, files, and targeted Wine processes were removed afterward. The app was closed, while the installed beta.2 runtime remains in Application Support. No rollback was needed and no existing bottle was touched. Beta.1 rollback files remain under `/Users/pape/Documents/VineyardMac-Activation-2026-08-11/backups/r2/`.

For that historical beta.2 activation, the previous public version was beta.1. Its release plist lacked the complete metadata required by the strict installer, so a beta.1 rollback would have protected older clients only. Strict app distribution and successful strict fresh-setup claims would have remained suspended until a fully validatable runtime was published under a new immutable key.

Do not rebuild beta.2 merely because the local source downloads are absent. The immutable uploaded artifact already exists and was verified; any future mismatch requires a new version and key, not replacement of beta.2.

Bottle creation was corrected and graphically retested on 2026-08-12. Missing `Metadata.plist` is now created and persisted with the default Wine version `7.7.0`; creation stays on the main actor, preserves the same `Bottle` object, and publishes its available state without reloading the bottle list. If a new creation fails, the app best-effort stops only that new prefix, removes only its newly created UUID directory, and removes its in-flight UI object without touching the parent or any pre-existing bottle. `WhiskyCmd create` keeps the model's `7.7.0` default, while `WhiskyCmd add` rejects a missing bottle directory or `Metadata.plist` before decoding or changing `BottleData`. A disposable bottle had active actions immediately and after a full app relaunch, then launched `winecfg.exe`. Its reference, files, and targeted Wine processes were removed afterward; no existing bottle was touched.

### Future activation procedure

For future runtime activations, keep this order:

1. Define the runtime being activated as the target version and the runtime referenced before any mutation as the previous public version.
2. Prepare the complete target release plist pointing directly to its versioned immutable URL. Verify its version, URL, and SHA-256 against the archive; extract the archive, validate its required files, embedded version, and manifest, and run the disposable-prefix smoke tests.
3. Stop the app and its Wine processes. Record whether the managed local `Libraries` runtime exists; move it whole to an explicit backup if present, or record its absence. Never touch a pre-existing bottle or bottle-list entry; only the later explicitly tracked disposable acceptance bottle and its new reference may be created and removed.
4. Before any R2 mutation, download and verify exact rollback copies of the previous public `Wine/WhiskyWineVersion.plist` and `Wine/Libraries.tar.gz`. Save and verify the previous root `Wine/RuntimeManifest.json`, or record and verify its absence if it returns 404.
5. Treat every versioned key as immutable. Upload the target key only if it does not exist; otherwise verify its exact size and SHA-256. On any mismatch, stop and use a new target version and key; never overwrite an existing versioned key.
6. Upload the validated target bytes to mutable `Wine/Libraries.tar.gz` for older clients and verify its public SHA-256.
7. Upload the matching target `Wine/RuntimeManifest.json` and verify it byte for byte.
8. Upload the target `Wine/WhiskyWineVersion.plist` last and verify every public field because current clients treat it as the release pointer.
9. Immediately perform a genuinely fresh graphical setup test, create one explicitly tracked disposable bottle, and launch `winecfg` or the DirectX smoke executable before considering the target version active. Then stop only its processes, delete only its directory, and remove only its matching reference.

If publication or acceptance fails after the first R2 mutation, restore the previous public version exactly: restore and verify its saved mutable archive, restore and verify the root manifest to its saved bytes or to verified absence, then restore and verify its saved plist last as the release pointer. Stop only the app and test-prefix Wine processes, remove only the explicitly tracked disposable bottle and its matching reference if created, quarantine any newly installed target runtime, and move the saved local runtime back unchanged; if it was previously absent, restore that absence. Never touch a pre-existing bottle or reference, and keep all versioned immutable keys unchanged.

## GPTK 4 Investigation

GPTK 4 is a separate experiment, not a blocker for publishing the staged Gcenx 3.0-3 runtime.

The first experiment replaced the Gcenx evaluation libraries with GPTK 4 beta 2 on macOS 27 beta and Xcode 27 beta. D3D11 and D3D12 smoke tests crashed. A Wine source investigation then used Gcenx commit `2e232b59da4612f2f131bd2f690d70d8fbdf9b87` and added the GPTK 4-related Wine exports.

The patched PE `ntdll.dll` and `gdi32.dll` built successfully, but pairing them with the existing native `ntdll.so` failed with `ntdll_init_syscalls syscall count mismatch 232 / 233`. Building the matching native half with Homebrew LLVM 22 failed on non-private labels inside CFI blocks around the Wine syscall dispatcher.

The experiment is preserved outside the repository in:

- `~/Documents/VineyardMac-Recovery-2026-07-30/README.md`
- `~/Documents/VineyardMac-Recovery-2026-07-30/gptk4-wine77-backport.patch`
- `~/Documents/VineyardMac-Recovery-2026-07-30/evidence/`

Both GPTK 4 beta 2 disk images were also present in `~/Downloads` when last checked. No separate Vineyard/GPTK recovery ZIP was found. The temporary source trees and hybrid runtime were deliberately not preserved because they are reproducible and tied to the discarded beta toolchain.

### Read-only GPTK 4 beta 2 feasibility audit

The audit was repeated on 2026-08-12 without installing, downloading, compiling, executing DMG content, or starting Wine. Apple's current [Game Porting Toolkit page](https://developer.apple.com/games/game-porting-toolkit) identifies GPTK 4 and Metal 4 support. Its current [companion repository](https://github.com/apple/game-porting-toolkit) requires Apple silicon, macOS 27, Xcode 27, and GPTK 4 for its latest Metal debugging and agent workflows; those are not the minimum requirements stated by the beta 2 evaluation environment itself. The mounted beta 2 README requires Apple silicon and macOS 15 or later, recommends at least 16 GB RAM, and reserves `gpucapture` for macOS 27 or later. Apple's [Xcode requirements](https://developer.apple.com/xcode/system-requirements) confirm that the installed Xcode 26.6 is supported on macOS 26.2 through 26.x.

The two local images were verified before read-only mounting:

- `Evaluation_environment_for_Windows_games_4.0_beta_2.dmg`: `26480358` bytes, SHA-256 `6248a0edc61553790753e5e9c060b8e53c940ed197f11409dcc34a35e05becc1`;
- `Game_Porting_Toolkit_4.0_beta_2.dmg`: `104459838` bytes, SHA-256 `03893ac4fab94ad9ff6aa32e887e2854bbf40fd90796f78a1d9bdbc02526ee5b`.

The toolkit image's embedded evaluation DMG has the same size and SHA-256 as the standalone image. The evaluation payload is D3DMetal `4.0b2` plus x86_64 graphics bridge libraries and Windows DLLs; it does not contain a complete Wine runtime. Mach-O deployment targets are macOS `14.0` for `D3DMetal` and `libd3dshared`, `26.4` for `libdxccontainer`, and `13.0` for `libdxcompiler`, `libdxilconv`, and `libmetalirconverter`. The current Apple silicon Mac has 48 GB RAM and macOS 26.6.1, so it meets the evaluation README and every bundled binary deployment target. Both volumes were detached and the dedicated `/tmp/vineyard-gptk4-audit.skabcj` tree was removed.

Rosetta successfully executed an installed system binary as x86_64. Installed build tools include Xcode 26.6 (`17F113`), Apple clang `21.0.0`, Homebrew LLVM/clang `22.1.8`, GNU Bison `3.8.2`, and pkgconf `3.0.5`. Neither `x86_64-w64-mingw32-gcc` nor Apple's `game-porting-toolkit-compiler` is installed locally. Apple's current [compiler formula](https://github.com/apple/homebrew-apple/blob/main/Formula/game-porting-toolkit-compiler.rb) remains version `0.1`, builds an x86_64-only clang from CrossOver 22.1.1 sources, and is not GPTK 4-specific.

The separate `/Users/pape/Projects/VineyardMac-Wine` repository was verified clean on `main` at `32ff36ff90a5ff10b7ee860aaa65d8b0808e9207`. That history contains CFI fix `2ed827dba3f8d9fd6e670dba2764e8d00b6bda87`, and GitHub Actions run [`28681593163`](https://github.com/Pape45/VineyardMac-Wine/actions/runs/28681593163) successfully configured, built, and packaged complete matching wine64 and wine32on64 outputs. This proved the coherent Wine build path and removed the CFI assembler failure as the first blocker.

Branch `gptk4-beta2-coherent-build` now records the minimal beta 2 port as commit `272c63cc1276d6392064a45164e6c2df4ad2121f`. Apple's GPTK license sections 2A(iii) and 2C permit non-commercial distribution of the Apple Software and separate Redistributables; the exact beta 2 redist, `License.rtf`, `Acknowledgements.rtf`, and `Read Me.rtf` were retained without altering Apple binaries. D3DMetal reports `4.0b2`, the source exports both `__wine_unix_call_dispatcher` and `D3DKMTEnumAdapters2`, and the existing CFI fix remains unchanged.

Wine CI run [`31645682029`](https://github.com/Pape45/VineyardMac-Wine/actions/runs/31645682029) successfully built and packaged matching wine64 and wine32on64 outputs from commit `272c63cc1276d6392064a45164e6c2df4ad2121f`. Its unexpired `Libraries` artifact ID `9163126162` was downloaded and matched its GitHub ZIP SHA-256 `ef5303d949919dfb2c990ee19bb304b97b9557e90242a72eb155fc80c239a6b6`; the contained `Libraries.tar.gz` has SHA-256 `4d4e711bfa95d74bc34b51a52e202f6002eb05e7090d53a39ab29eebaa1dc8af`. Artifact `SUMS` ID `9163126455` matched ZIP SHA-256 `c701d49c557577371ae2ae7ee81b79e6cbf291cb3d1679d1bcbf0bdd4d9dca40`, and all 4,604 entries in `SUMS.sha` passed against the extracted payload. The packaged x86_64 and i386 PE DLLs export `__wine_unix_call_dispatcher` from `ntdll.dll` and `D3DKMTEnumAdapters2` from `gdi32.dll`; D3DMetal reports `4.0b2`. The R2 upload step was skipped, as required.

Smoke tests of that exact artifact used two separate disposable prefixes and the preserved `vineyard-gptk4-directx.exe`. D3D11 and D3D12 both exited with code `1` before device creation because `gdi32.dll` forwards `D3DKMTEnumAdapters2` to the still-stubbed `win32u.dll.NtGdiDdDDIEnumAdapters2`. Neither run produced a page fault or `syscall count mismatch 232 / 233`. The two 19-line logs are preserved under `~/Documents/VineyardMac-Recovery-2026-07-30/evidence/gptk4-beta2-coherent-smoke-2026-08-13/` with SHA-256 `8c54bc2fc6a5ecb66e6427b04cad5fb272f67fdb7cd137d7f753eeb2c57bcb28` for D3D11 and `d127a6155740ec8ebb552f4ca64de94ab21716ef37166f5f0a834787a51c2076` for D3D12. Both targeted wineservers were stopped, no related process remained, and the dedicated downloads, extraction, and prefixes were removed.

Commit `8e3f45a222dc4c0ff5aa3e18690737b40fd526da` then implemented the missing Wine 7.7 `NtGdiDdDDIEnumAdapters2` path without importing Wine's modern GPU cache. It reuses the existing adapter handle list and `NtGdiDdDDIOpenAdapterFromLuid`, wires matching native and WoW64 syscall tables and the 32-bit thunk, and covers capacity queries, insufficient buffers, valid closable handles, and the public API in one targeted test. The deliberately minimal implementation exposes one logical adapter; broader multi-adapter behavior remains unverified.

Wine CI run [`31681294191`](https://github.com/Pape45/VineyardMac-Wine/actions/runs/31681294191) passed `sdk-smoke` and the complete matching wine64/wine32on64 build for that exact commit; its R2 upload step remained skipped. `Libraries` artifact ID `9176863656` matched its GitHub ZIP SHA-256 `e25dfb6433657493515df550e1fed366d9609d1907b449a101d1e32ec87d7b4e`, and the contained `Libraries.tar.gz` has SHA-256 `842f84cbef4690cfa78762fec7ea4bc4ac55396e6a37c1842e1aff627dd65dbf`. `SUMS` artifact ID `9176864184` matched ZIP SHA-256 `64164e56283d5bb0dadaaea99fb96ad4e2e0a5415099539d1c69cbc64799df36`, and all 4,604 payload entries passed `SUMS.sha`. The x86_64 and i386 payloads contain the `ntdll.dll` CFI export, the public `gdi32.dll` forwarder, and the native/32-on-64 `win32u` implementation and thunk; D3DMetal remains `4.0b2`.

Two new disposable-prefix tests of that exact artifact passed. D3D11 exited `0` with feature level `0xb000`; D3D12 exited `0` after creating its device. Neither log contains a page fault or any syscall count mismatch. Their transient SHA-256 values were `e9f82d3528929ae23ecfa633b468b861af2c6a62aa4efcfe827a22cb7f27c102` and `2e3b25b51a0007cc123fd1ef68cb756caade3be135acf3f734a1c28995676a3a`. Both exact-prefix wineservers were stopped and no related process remained before the dedicated downloads, extraction, logs, and prefixes were removed.

Packaging commit `ff85d649d8b722f709f9b134b2d1c4eba85281cd` created private strict-installer candidate `4.0.0-beta.3+3` without changing the GPTK 4 beta 2 redist or Wine backport. Wine CI run [`31708933259`](https://github.com/Pape45/VineyardMac-Wine/actions/runs/31708933259) passed `sdk-smoke` and the complete matching wine64/wine32on64 build; R2 upload was skipped. Exact artifact IDs and verified GitHub ZIP SHA-256 values are `9188539778` / `f93d38647a10b2d038ebadc3272ec5b4f3da6188414936cf1d5ae83545d318e8` for `Libraries`, `9188540605` / `baf28b45fa025d87ef6a50210386b82eb09cb4f8bf6a914a4113ae300dd86786` for `SUMS`, `9188541342` / `344bce241a3b9455c9d8c82764554909b0cb9019edb85015e21bbda00cdf4949` for `RuntimeManifest`, and `9188542069` / `5cf0496eeda62bd2b2de9b35ca5e19a86c1286fc787c6989c8c58667fe170742` for `WhiskyWineVersion`.

The candidate `Libraries.tar.gz` is `271043970` bytes with SHA-256 `066edfdf3024eb0c1fc1cbaa8d9de37e5c9e216d723ca6e787bb4adea6e63764`; `SUMS.sha`, `RuntimeManifest.json`, and the complete external plist have SHA-256 `eb3a1ddf800d3621a7f16d8780182958f4bf37807155a7be30ba59bfb2b9d8a6`, `5fa2aebbdbe85c4a2cb45e899d3e15743598ee00b0674ce72847f4080e0450f7`, and `58ed93275157560a46d3cccb805927c78bb878ac9b04a7786499a05ced630492`. The plist points to `https://data.vineyardmac.app/Wine/archive/Libraries-4.0.0-beta.3.tar.gz`, requires macOS `15.0`, and matches the archive hash. The embedded version is `4.0.0-beta.3+3`; the embedded and standalone manifests are byte-identical to the Wine repository copy.

All 4,612 checksum entries passed. The archive has one confined `Libraries` root, 518 directories, 11 internal symlinks, no hardlinks, all 18 strict-installer files, executable `wine64` and `wineserver`, and byte-identical Apple notices and required Wine licenses. The prior smoke artifact's 4,604 files remain; the candidate adds exactly two DXVK `d3d9.dll` files, one manifest, three Apple notices, and two Wine license files. Of 141 comparable graphics binaries, 23 were byte-identical and 118 changed across the clean rebuild; two DXVK `d3d9.dll` files were added and none removed. The smoke-critical D3DMetal, `libd3dshared`, MoltenVK, x86_64 `d3d11.dll`, `d3d12.dll`, `dxgi.dll`, and `win32u.dll` remained byte-identical, while `gdi32.dll` and `ntdll.dll` changed.

Because graphics bytes changed, the exact candidate was retested with the preserved DirectX executable in two fresh disposable prefixes. D3D11 exited `0` at feature level `0xb000`; D3D12 exited `0` after device creation. Neither log contains a page fault or `syscall count mismatch 232 / 233`; transient log SHA-256 values are `397dbd31632c861860a8b98fb0ae836cefaced5dc11adaa821dff065fdc59260` and `b8a774c6baaeb659f1a49e238c73ef58bf04d4e100de88ccb8106939c9c54608`. Both targeted wineservers stopped and no related process remained. The reserved beta.3 key returned HTTP 404 before and after CI. Public runtime beta.2 and repository `Runtime/RuntimeManifest.json` remain unchanged.

The VineyardMac installation gate passed locally on 2026-08-13 without changing the production endpoint or R2. The exact run `31708933259` artifacts were reverified at commit `ff85d649d8b722f709f9b134b2d1c4eba85281cd`; beta.3 still returned HTTP 404. An ephemeral Swift runner outside the repository imported the current `WhiskyKit`, decoded the complete external plist, copied the archive because installation consumes its input, and called the public `WhiskyWineInstaller.install(from:release:)` API. The installer targeted `~/Library/Application Support/com.pape45.VineyardMac/Libraries`, installed `4.0.0-beta.3+3`, reproduced `RuntimeManifest.json` byte for byte at SHA-256 `5fa2aebbdbe85c4a2cb45e899d3e15743598ee00b0674ce72847f4080e0450f7`, passed all 4,612 checksums, and left no staging or backup directory.

The current Debug app built and passed strict signature verification without changing signing settings. It created only bottle `1A75B0FB-E78A-4EB4-A017-9D771436C0C4`; the action buttons enabled without refresh, metadata recorded Wine `7.7.0`, and the app launched `winecfg.exe` under that exact prefix. DirectX was not repeated because the same artifact had already passed D3D11 and D3D12. The app then closed, only the exact prefix's wineserver was stopped, and no test process survived. The disposable bottle and its sole reference were removed. The initial beta.2 runtime was restored with 5,248 files, 567 directories, and 243 symlinks; its content, metadata, and symlink inventories matched their initial SHA-256 values `06d7ff6fb9907c73a74aae1ab066ebaa3fcfbbc3dd898292806d5828ce9ba105`, `6ae88af6311795fa1311a5d1c5a585dad52aca7f74a051dc0560b86b35a0e99d`, and `834dafb707c0143212c58658cd3be5adbe169a7c22f4e70449d99f6dfe640d32`. The original empty `BottleVM.plist` returned byte-identically at SHA-256 `178dedc7f7fe35005594f5062085ee1f4081ddc30954995dc0ee9c420d8903c2`, and the initially absent bottles directory remained absent.

The preserved patch and evidence establish four separate gates:

1. **Coherent Wine build — passed in CI and independently verified.** `VineyardMac-Wine` built matching wine64 and wine32on64 outputs with GPTK 4 beta 2, both requested PE exports, and the preserved CFI fix. The artifact and checksum manifest match GitHub's recorded digests and the complete extracted payload passes `SUMS.sha`.
2. **D3D11/D3D12 smoke — passed.** The rebuilt exact artifact creates both devices, exits `0`, and shows neither the earlier page fault nor a syscall count mismatch.
3. **Strict artifact packaging — passed privately.** Candidate `4.0.0-beta.3+3` has complete release metadata, manifest, notices, checksums, and all 18 required paths; no public object was created.
4. **VineyardMac installation — passed locally and fully restored.** The real public installer accepted the candidate, the signed app created a disposable bottle with active controls and launched `winecfg`, and exact pre-test runtime and bottle-list state was restored afterward.

Verdict: coherent GPTK 4 beta 2 build, strict private candidate integrity, D3D11/D3D12 device creation, and real VineyardMac installation are demonstrated. Public runtime beta.2 remains active; beta.3 is neither published nor left installed. Public redistribution must remain non-commercial and retain Apple's notices.

## Known Product State

- The project is Swift/SwiftUI; Wine and graphics components are external managed artifacts, not C code implemented in the app repository.
- Public branding says VineyardMac, but source directories, targets, schemes, localization keys, CLI names, and some links still say Whisky.
- Do not mass-rename those identifiers. Bundle IDs and container paths own user data and require migration and rollback plans.
- The first priority remains stabilization, runtime activation, diagnostics, and reproducible compatibility testing. A broad UI redesign comes later.
- Common runtime failures still need actionable user-facing diagnostics and easier log access.
- High CPU usage was observed once while Whisky was running, but it has not been profiled or attributed. Treat it as an investigation, not a confirmed regression.
- There is no public VineyardMac release workflow, Sparkle release, Developer ID notarization, or Homebrew release automation yet.
- The single Xcode warning seen during the signed build was App Intents metadata extraction being skipped because the project has no AppIntents dependency; it did not fail the build.

## Guardrails

Do not repeat or roll back the successful R2 activation without a new explicit decision. The disposable bottle's post-creation version warning and disabled-action regression are resolved; keep GPTK 4 and broad UI work separate.
