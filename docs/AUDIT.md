# VineyardMac Audit

Last updated: 2026-08-20

This document tracks the practical work needed to turn the archived Whisky codebase into VineyardMac. It is not a promise of features. It is a checklist for keeping changes small, reviewable, and safe for contributors.

## Ground Rules

- Keep GPL-3.0-or-later licensing and Whisky attribution intact.
- Keep changes scoped. Rename, signing, Wine runtime, CI, and UI work should land separately.
- Follow the existing contribution style: SwiftLint clean, 4-space indentation, localized strings, and screenshots for UI changes.
- Do not remove old Whisky data paths until a migration exists.
- Prefer fixes that make local builds and debugging easier before adding new features.

## Current Baseline

- The app builds from `Whisky.xcodeproj` on macOS 26.6.1 with Xcode 26.6.
- `swiftlint --strict` passes locally.
- Debug builds now use `Apple Development` signing with VineyardMac bundle identifiers:
  - `com.pape45.VineyardMac`
  - `com.pape45.VineyardMac.Cmd`
  - `com.pape45.VineyardMac.Thumbnail`
- The product, targets, schemes, many comments, localization strings, and user-facing copy still use Whisky names.
- GitHub Actions verify the macOS build, WhiskyKit tests, and SwiftLint.
- WhiskyKit has focused tests for runtime hashing, validation, replacement, bottle metadata, and process-log redaction.

## Confirmed Cleanup

- Wine library downloads and version checks use `https://data.vineyardmac.app/Wine/...`.
- Wine installation preserves the app's Application Support directory while replacing the managed runtime.
- Runtime downloads are checked against release metadata and installed through a validated staging directory.
- Active runtime `4.0.0-beta.2` uses Gcenx Game Porting Toolkit 3.0-3, keeps DXVK support, and includes its component manifest and licenses.
- Runtime builds keep the local and legacy filename `Libraries.tar.gz`, while generated release metadata points to the versioned immutable archive URL.
- Future activation procedures distinguish the target version from the previous public version, prevalidate locally, verify-only any existing immutable key, require a new version and key on any size or SHA-256 mismatch, publish the release pointer last, and run an immediate fresh setup test.
- Before publication, activation preserves exact rollback states for the public plist, mutable archive, and root manifest, including a missing manifest, and moves any managed local runtime to a reversible backup without touching pre-existing bottles or references.
- Acceptance may create and then remove only one explicitly tracked disposable bottle and its matching new reference. It never modifies a pre-existing bottle or reference.
- A failed activation restores and verifies the previous mutable archive, then the previous root manifest bytes or absence, and finally the previous plist as the release pointer; it also restores the prior local runtime or its absence and leaves every versioned immutable key unchanged.
- For the historical beta.2 activation, rolling back to beta.1 would have protected older clients only because beta.1 metadata was incomplete. Strict app distribution and successful strict fresh-setup claims would have waited for a fully validatable runtime under a new immutable key.
- The immutable beta.2 archive, mutable legacy archive, root manifest, and complete beta.2 release pointer are published. The immediate strict fresh setup, disposable-bottle creation, and `winecfg` acceptance test passed on 2026-08-11.
- Wrangler cannot upload this 386 MiB archive directly because `r2 object put` is capped at 300 MiB. The documented activation path streams the already verified immutable object to the mutable key through an ephemeral R2-bound Worker, then verifies the public SHA-256.
- Git history no longer embeds the retired `Whisky/Libraries/Wine` runtime payload.
- Failed app bottle creation best-effort stops only the attempted prefix, removes only its new UUID directory and UI object, and preserves the parent and every pre-existing bottle. `WhiskyCmd create` keeps Wine `7.7.0`, while `WhiskyCmd add` rejects missing directories or metadata before changing `BottleData`.
- Unfinished CLI export/install/uninstall stubs and the unused Progress.swift dependency have been removed.
- All Wine launches converge on `Process.runStream`. Known sensitive metadata forms in arguments and environments are heuristically masked, while environment keys and values are escaped onto one line. Dynamic process content remains private in Unified Logging; only fixed labels and safe numeric status codes are public.
- Wine `.log` files retain app, macOS, full runtime, bottle Wine, Windows, sync, Metal, DXR, AVX, DXVK, command, and heuristically redacted environment metadata. Raw Wine stdout and stderr remain for diagnosis, so users must inspect each file before sharing it.
- Common app launch, bottle creation, Wine tool, Winetricks, shortcut, runtime setup, and maintenance errors now use structured logging plus existing inline errors or localized alerts. Open Logs creates and reveals the Wine logs folder even before the first Wine launch; application errors otherwise remain in Unified Logging. Intentional `WhiskyCmd` output remains unchanged.
- `Bottle`, `Program`, and `BottleVM` use `@unchecked Sendable`; treat this as concurrency debt.

## First Release Target

The next local release should be boring:

- signed Debug build launches locally;
- branding no longer sends users to archived Whisky infrastructure;
- README and CONTRIBUTING describe VineyardMac accurately;
- CI verifies lint and at least one macOS build;
- setup failures produce useful logs or alerts;
- no public auto-update or notarized distribution yet.

## Work Queue

1. Stabilize project metadata.
   - Rename visible app metadata to VineyardMac.
   - Keep internal target names until the build is stable.

2. Fix build and CI basics.
   - Keep Release distribution disabled or documented until Developer ID signing and notarization are ready.

3. Separate VineyardMac runtime ownership.
   - Decide whether `WhiskyWine` remains the runtime name or becomes a VineyardMac-managed Wine package.
   - Keep the runtime manifest, source hashes, licenses, and release checksum current.
   - Document where Wine libraries, bottles, and logs live.

4. Improve diagnostics before UI redesign.
   - Core milestone complete: common setup and launch failures are actionable, Wine logs are directly accessible, and launch context uses known-form metadata redaction plus private Unified Logging fields. Raw Wine output still requires review before sharing.
   - Use reproducible game tests to identify the next real diagnostic gaps before adding classifiers, exports, or troubleshooting UI.

5. Redesign UI around real workflows.
   - Bottle list and status.
   - Program launch and per-program settings.
   - Setup/runtime management.
   - Logs and troubleshooting.
   - Compatibility notes later, once diagnostics are reliable.

## Not Now

- Public Sparkle updates.
- Homebrew cask automation.
- Full bundle/container migration from old Whisky installs.
- Large internal renames across every source file.
- AI troubleshooting UI before logs and failure states are structured.
