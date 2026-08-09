# VineyardMac Maintainer Handover

Last verified: 2026-08-09

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
- Active branch: `codex/gcenx-runtime-integrity`
- Active pull request: `Pape45/VineyardMac#4`, `Adopt verified Gcenx runtime installation`
- PR #4 was draft, mergeable, and green for the macOS build and SwiftLint when last checked.
- The GitHub CLI is authenticated as `Pape45` with `repo` and `workflow` access.
- Because both `origin` and the archived Whisky `upstream` exist, always pass `--repo Pape45/VineyardMac` to `gh pr` commands. An unqualified `gh pr view 4` previously resolved to the unrelated Whisky PR #4.

The branch contains five focused commits after `main`:

- verified Gcenx runtime installation and tests;
- safe handling for a missing runtime release URL;
- refreshed stable-toolchain and GPTK status documentation;
- maintainer handover documentation;
- safe in-app runtime update routing without pre-download uninstall.

Do not merge PR #4 or publish its release pointer without an explicit maintainer decision.

## Verified Stable Environment

- macOS 26.6.1, build 25G76.
- Xcode 26.6, build 17F113, selected from `/Applications/Xcode-26.6.0.app`.
- Rosetta 2 is installed.
- A signed Debug build succeeds for the app, CLI, and thumbnail extension.
- The resulting app passes `codesign --verify --deep --strict` outside the Codex sandbox.
- SwiftLint reports zero violations during the Xcode build.
- `swift test --package-path WhiskyKit` passes the three runtime installer tests.
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

PR #4 changes runtime installation from an unverified replacement to a staged, validated installation. It adds release metadata validation, SHA-256 verification, required-file checks, an embedded manifest/version check, atomic replacement that preserves the previous runtime until validation succeeds, and focused tests.

The in-app update prompt now opens the existing runtime download and installation flow directly. It no longer uninstalls the installed runtime before download, so download or validation failures leave the current runtime available.

Staged runtime `4.0.0-beta.2` contains Gcenx Game Porting Toolkit 3.0-3, D3DMetal 3.0, the VineyardMac Vulkan driver, DXVK-macOS, MoltenVK, GStreamer, Winetricks, licenses, and `RuntimeManifest.json`. The exact component and source inventory is in `Runtime/RuntimeManifest.json`.

The complete immutable artifact was built, smoke-tested, uploaded, and downloaded again with a matching hash:

- R2 bucket: `vineyardmac`
- URL: `https://data.vineyardmac.app/Wine/archive/Libraries-4.0.0-beta.2.tar.gz`
- Size: `404974593` bytes
- SHA-256: `86f9a7f6280b1648e5a7a640023a3a443870c882fdd214c062ce60b344004ef4`

Public access on this download bucket is intentional. Production safety comes from immutable versioned keys, release metadata, SHA-256 verification, runtime validation, and publishing the release pointer last.

The current public `Wine/WhiskyWineVersion.plist` still describes the old `4.0.0-beta.1` runtime and lacks the complete beta.2 metadata. The mutable `Wine/Libraries.tar.gz` is also the old beta.1 archive. The branch's stricter installer therefore rejects current first-run setup with a missing-data error. This is not evidence that Cloudflare is blocking the request.

Safe activation order after PR #4 is approved and merged:

1. Recheck the immutable beta.2 artifact's status, size, and SHA-256.
2. Prepare the complete release plist pointing directly to the immutable beta.2 URL.
3. Upload the matching root `RuntimeManifest.json` if the public copy is missing or stale.
4. Upload `WhiskyWineVersion.plist` last because clients treat it as the release pointer.
5. Remove the local app/runtime state and perform a genuinely fresh graphical setup test.
6. Create a new bottle and launch `winecfg` or the DirectX smoke executable before considering the runtime active.

Do not rebuild beta.2 merely because the local source downloads are absent. The immutable uploaded artifact already exists and was verified.

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

The next coordinator should first verify that the worktree is clean, PR #4 still targets the correct repository, and its new checks are green. It should then ask the maintainer whether to:

1. mark PR #4 ready and merge it;
2. activate the immutable beta.2 runtime on R2 after merge;
3. run the fresh-install graphical acceptance test;
4. return to GPTK 4 only after the stable runtime path works end to end.

Do not start a UI refactor or another runtime rebuild before this release path is resolved.
