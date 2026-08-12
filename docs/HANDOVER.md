# VineyardMac Maintainer Handover

Last verified: 2026-08-12

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
- Active branch: `runtime-beta2-activation-record`
- PR `Pape45/VineyardMac#4`, `Adopt verified Gcenx runtime installation`, was merged as `59a33f9d5965009b6ca836da158844bc000148d9` after its macOS build, WhiskyKit tests, and SwiftLint passed.
- The active branch was created from that merge and records the completed beta.2 activation. No follow-up pull request has been opened.
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
- SwiftLint, bison, LLVM, mingw-w64, pkgconf, Wrangler, and the required Xcode package dependencies were available when last checked. Recheck them after environment changes; do not reinstall automatically.

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

Bottle creation was corrected and graphically retested on 2026-08-12. Missing `Metadata.plist` is now created and persisted with the default Wine version `7.7.0`; creation stays on the main actor, preserves the same `Bottle` object, and publishes its available state without reloading the bottle list. A disposable bottle had active actions immediately and after a full app relaunch, then launched `winecfg.exe`. Its reference, files, and targeted Wine processes were removed afterward; no existing bottle was touched.

### Future activation procedure

For future runtime activations, keep this order:

1. Define the runtime being activated as the target version and the runtime referenced before any mutation as the previous public version.
2. Prepare the complete target release plist pointing directly to its versioned immutable URL. Verify its version, URL, and SHA-256 against the archive; extract the archive, validate its required files, embedded version, and manifest, and run the disposable-prefix smoke tests.
3. Stop the app and its Wine processes. Record whether the managed local `Libraries` runtime exists; move it whole to an explicit backup if present, or record its absence. Never touch bottles or bottle-list files.
4. Before any R2 mutation, download and verify exact rollback copies of the previous public `Wine/WhiskyWineVersion.plist` and `Wine/Libraries.tar.gz`. Save and verify the previous root `Wine/RuntimeManifest.json`, or record and verify its absence if it returns 404.
5. Treat every versioned key as immutable. Upload the target key only if it does not exist; otherwise verify its exact size and SHA-256. On any mismatch, stop and use a new target version and key; never overwrite an existing versioned key.
6. Upload the validated target bytes to mutable `Wine/Libraries.tar.gz` for older clients and verify its public SHA-256.
7. Upload the matching target `Wine/RuntimeManifest.json` and verify it byte for byte.
8. Upload the target `Wine/WhiskyWineVersion.plist` last and verify every public field because current clients treat it as the release pointer.
9. Immediately perform a genuinely fresh graphical setup test, create only a disposable bottle, and launch `winecfg` or the DirectX smoke executable before considering the target version active.

If publication or acceptance fails after the first R2 mutation, restore the previous public version exactly: restore and verify its saved plist first, restore and verify its saved mutable archive, then restore the root manifest to its saved bytes or to verified absence. Stop only the app and test-prefix Wine processes, quarantine any newly installed target runtime, and move the saved local runtime back unchanged; if it was previously absent, restore that absence. Never touch bottles or bottle lists, and keep all versioned immutable keys unchanged.

## GPTK 4 Investigation

GPTK 4 is a separate experiment, not a blocker for publishing the staged Gcenx 3.0-3 runtime.

The first experiment replaced the Gcenx evaluation libraries with GPTK 4 beta 2 on macOS 27 beta and Xcode 27 beta. D3D11 and D3D12 smoke tests crashed. A Wine source investigation then used Gcenx commit `2e232b59da4612f2f131bd2f690d70d8fbdf9b87` and added the GPTK 4-related Wine exports.

The patched PE `ntdll.dll` and `gdi32.dll` built successfully, but pairing them with the existing native `ntdll.so` failed with `ntdll_init_syscalls syscall count mismatch 232 / 233`. Building the matching native half with Homebrew LLVM 22 failed on non-private labels inside CFI blocks around the Wine syscall dispatcher.

The experiment is preserved outside the repository in:

- `~/Documents/VineyardMac-Recovery-2026-07-30/README.md`
- `~/Documents/VineyardMac-Recovery-2026-07-30/gptk4-wine77-backport.patch`
- `~/Documents/VineyardMac-Recovery-2026-07-30/evidence/`

Both GPTK 4 beta 2 disk images were also present in `~/Downloads` when last checked. No separate Vineyard/GPTK recovery ZIP was found. The temporary source trees and hybrid runtime were deliberately not preserved because they are reproducible and tied to the discarded beta toolchain.

Apple's `game-porting-toolkit-compiler` Homebrew formula remains version 0.1 and builds an x86_64 compiler from CrossOver 22.1.1 sources. It is not a GPTK 4-specific compiler and is not required for beta.2 packaging or publication. Do not make its installation a prerequisite. When GPTK 4 work resumes, use a separate branch and first test the complete matching Wine build with the stable Xcode toolchain.

## Known Product State

- The project is Swift/SwiftUI; Wine and graphics components are external managed artifacts, not C code implemented in the app repository.
- Public branding says VineyardMac, but source directories, targets, schemes, localization keys, CLI names, and some links still say Whisky.
- Do not mass-rename those identifiers. Bundle IDs and container paths own user data and require migration and rollback plans.
- The first priority remains stabilization, runtime activation, diagnostics, and reproducible compatibility testing. A broad UI redesign comes later.
- Common runtime failures still need actionable user-facing diagnostics and easier log access.
- High CPU usage was observed once while Whisky was running, but it has not been profiled or attributed. Treat it as an investigation, not a confirmed regression.
- There is no public VineyardMac release workflow, Sparkle release, Developer ID notarization, or Homebrew release automation yet.
- The single Xcode warning seen during the signed build was App Intents metadata extraction being skipped because the project has no AppIntents dependency; it did not fail the build.

## Recommended Next Decision

After the activation-record branch is reviewed, decide whether to open a pull request. Do not repeat or roll back the successful R2 activation without a new explicit decision. The disposable bottle's post-creation version warning and disabled-action regression are resolved; keep GPTK 4 and broad UI work separate.
