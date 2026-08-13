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

Wine CI run [`31645682029`](https://github.com/Pape45/VineyardMac-Wine/actions/runs/31645682029) successfully built and packaged matching wine64 and wine32on64 outputs. Its unexpired `Libraries` artifact has ID `9163126162`, size `266840688` bytes, and expiry 2026-11-10; the artifact was not downloaded or executed during this task. The R2 upload step was skipped, as required.

The preserved patch and evidence establish three separate gates:

1. **Coherent Wine build — passed in CI.** `VineyardMac-Wine` built matching wine64 and wine32on64 outputs with GPTK 4 beta 2, both required exports, and the preserved CFI fix. The resulting artifact exists but has not yet been independently inspected or run.
2. **D3D11/D3D12 smoke — next gate.** Test the new CI artifact in a disposable prefix. The preserved earlier D3D11 and D3D12 logs both end in the same null-read page fault and WineDbg attachment; they remain failure evidence for the discarded hybrid runtime, not results for this coherent build.
3. **VineyardMac integration — not open.** It depends on a coherent runtime passing both graphics smoke tests. Only then can required files, manifest/version metadata, packaging, installer validation, and a disposable-bottle fresh setup be assessed without touching existing bottles.

Verdict: coherent GPTK 4 beta 2 build is now demonstrated in CI. D3D11/D3D12 smoke testing of that exact artifact is the next gate. Do not attempt VineyardMac runtime integration before both smoke tests pass. Public redistribution must remain non-commercial and retain Apple's notices.

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
