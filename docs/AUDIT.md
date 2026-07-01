# VineyardMac Audit

Last updated: 2026-07-01

This document tracks the practical work needed to turn the archived Whisky codebase into VineyardMac. It is not a promise of features. It is a checklist for keeping changes small, reviewable, and safe for contributors.

## Ground Rules

- Keep GPL-3.0-or-later licensing and Whisky attribution intact.
- Keep changes scoped. Rename, signing, Wine runtime, CI, and UI work should land separately.
- Follow the existing contribution style: SwiftLint clean, 4-space indentation, localized strings, and screenshots for UI changes.
- Do not remove old Whisky data paths until a migration exists.
- Prefer fixes that make local builds and debugging easier before adding new features.

## Current Baseline

- The app builds from `Whisky.xcodeproj` with Xcode 26.6.
- `swiftlint --strict` passes locally.
- Debug builds now use `Apple Development` signing with VineyardMac bundle identifiers:
  - `com.pape45.VineyardMac`
  - `com.pape45.VineyardMac.Cmd`
  - `com.pape45.VineyardMac.Thumbnail`
- The product, targets, schemes, many comments, localization strings, and user-facing copy still use Whisky names.
- GitHub Actions currently run SwiftLint only.
- There are no test targets.

## Confirmed Cleanup

- Release workflow still posts Whisky release URLs and updates the old Homebrew cask.
- Funding, issue templates, Discord links, Help menu links, and Crowdin references still point to Whisky-era infrastructure.
- Sparkle appcast is still `https://data.getwhisky.app/appcast.xml`.
- Wine library downloads and version checks still use `https://data.getwhisky.app/Wine/...`.
- `WhiskyKit/Package.swift` uses an SSH URL for `SemanticVersion`, while the Xcode workspace resolves it through HTTPS.
- `Bundle.whiskyBundleIdentifier` still falls back to `com.isaacmarovitz.Whisky`.
- CLI commands include unfinished or commented-out paths for export/install/uninstall.
- Several runtime errors are still reported with `print` instead of user-facing diagnostics.
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
   - Replace stale Help, Discord, Funding, and issue-template links.

2. Fix build and CI basics.
   - Change `WhiskyKit/Package.swift` package URL to HTTPS.
   - Add a macOS GitHub Actions build for the `Whisky` scheme.
   - Keep Release distribution disabled or documented until Developer ID signing and notarization are ready.

3. Separate VineyardMac runtime ownership.
   - Decide whether `WhiskyWine` remains the runtime name or becomes a VineyardMac-managed Wine package.
   - Stop relying on `data.getwhisky.app` before shipping builds to other users.
   - Document where Wine libraries, bottles, and logs live.

4. Improve diagnostics before UI redesign.
   - Convert common setup and launch failures into actionable messages.
   - Make logs easy to find from the UI.
   - Capture Wine version, bottle settings, launch command, and environment in one place.

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
