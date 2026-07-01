# Agent Guide

This file is the operating guide for AI agents working on VineyardMac.

VineyardMac is an independent continuation of the archived Whisky project. The repository is in a transition state: public docs now describe VineyardMac, but many source files, targets, bundle identifiers, update URLs, localization keys, comments, and user-visible links still use Whisky names. Treat that as known technical debt, not as permission to do a broad rename in unrelated work.

## Project Shape

- `Whisky/` is the macOS SwiftUI app target.
- `WhiskyKit/` is the shared Swift package with bottle, Wine, process, PE parsing, tar, and installer logic.
- `WhiskyCmd/` is the command line interface target.
- `WhiskyThumbnail/` is the Quick Look thumbnail extension.
- `Whisky.xcodeproj/` owns the app, CLI, thumbnail, SPM dependencies, schemes, signing, and build phases.
- `Libraries/cabextract` is a vendored executable/resource from the original project; inspect licensing before changing or replacing it.
- There are currently no test targets in the repo.

The app is primarily Swift/SwiftUI. Wine, DXVK, Metal/GPTK-related components, and Windows programs are external runtime dependencies or managed artifacts, not C code implemented in this repository.

## Current Direction

The first priority is stabilization and modernization, not cosmetic churn.

Prefer work in this order:

1. Make the project build and lint reliably on current macOS/Xcode.
2. Preserve existing bottle behavior and user data.
3. Fix stale infrastructure, links, dependency resolution, and update endpoints.
4. Improve diagnostics and logging around launch failures.
5. Add compatibility workflows, profiles, and AI-assisted troubleshooting.
6. Rename internal Whisky identifiers to VineyardMac only through deliberate, reviewed steps.

## Non-Negotiables

- Do not install tools, packages, Homebrew formulae, Xcode components, Wine builds, or system dependencies automatically. Report what is missing and let the maintainer install it.
- Do not run destructive cleanup commands against user bottles, app containers, logs, caches, downloaded Wine libraries, or shader caches unless explicitly requested.
- Do not change signing identities, team IDs, bundle identifiers, Sparkle feeds, release automation, or update URLs casually. These affect upgrades, sandbox containers, and user data paths.
- Do not mass-rewrite `Whisky` to `VineyardMac`. A safe rename must account for bundle IDs, container paths, localization keys, Sparkle appcast, CLI names, file headers, and GPL attribution.
- Preserve GPL-3.0-or-later headers and original Whisky attribution. New Swift files must satisfy `.swiftlint.yml` until the lint policy is intentionally changed.
- For current facts about Apple Game Porting Toolkit, Metal, Wine, DXVK, Rosetta, Sparkle, or package APIs, verify against official/current sources before making technical claims.
- For game/app troubleshooting, work from user-provided logs, owned local installs, reproducible commands, and observable runtime behavior. Do not distribute proprietary binaries, patches, or copyrighted game assets.

## Agent Tooling

Agents may have access to several external-context and automation tools. Use the least invasive tool that answers the question.

- Use local repository inspection first for project-specific behavior: `rg`, `git`, `xcodebuild`, SwiftPM, plists, logs, and source files.
- Use Context7 for current library, SDK, framework, package, and API documentation when touching dependencies or APIs such as Swift packages, Sparkle, swift-argument-parser, SwiftUI patterns, or other third-party libraries. Prefer official docs surfaced through Context7 over memory.
- Use the internal web search tool for current external facts that are not covered by local files or Context7, especially Apple Game Porting Toolkit, Wine, DXVK, MoltenVK, Rosetta, macOS/Xcode changes, and GitHub project status. Cite or record the sources used when the result affects code or project direction.
- Use browser automation only when a task genuinely requires interacting with a local app/site, checking rendered UI, testing a web workflow, or inspecting a page that search results cannot summarize reliably.
- Use computer-use only for local macOS UI tasks that cannot be done safely through shell commands or project files. Avoid using it for routine file edits, builds, Git operations, or package management.
- BrowserOS may be useful for browser automation and connected-service workflows, but do not use it by default for ordinary research if internal search or Context7 is enough.
- Never use any tool to install software, authenticate into services, modify system settings, or operate paid/external accounts without explicit maintainer approval.

## Build And Validation

Primary local workflow:

```bash
open Whisky.xcodeproj
xcodebuild -list -project Whisky.xcodeproj
xcodebuild -project Whisky.xcodeproj -scheme Whisky -configuration Debug build
swiftlint --strict
```

Useful package-level check:

```bash
swift build --package-path WhiskyKit
```

Known validation blockers observed on 2026-07-01:

- `xcodebuild` is present, but the active developer directory is Command Line Tools, not full Xcode. The maintainer must switch/install Xcode before Xcode builds can run.
- `swiftlint` is not installed on this machine. The Xcode build phase fails if `swiftlint` is missing.
- `WhiskyKit/Package.swift` currently references `SemanticVersion` via `git@github.com:SwiftPackageIndex/SemanticVersion.git`, while the Xcode workspace resolved file uses HTTPS. `swift build --package-path WhiskyKit` fails without GitHub SSH access. Ask before changing the package URL to HTTPS.

When validation cannot run, say exactly which command failed and why. Do not claim a build passed unless it actually ran successfully.

## Git And CI Discipline

Default repository workflow:

1. Work on a feature/fix branch unless the maintainer explicitly asks to commit on `main`.
2. Keep commits focused and reviewable.
3. Check `git status --short --branch` before editing, before committing, and before finishing.
4. Do not stage or commit unrelated user changes.
5. Run local validation before push whenever the needed tools are available.
6. After pushing, verify GitHub Actions and do not treat the change as done until required checks are green or a blocker is documented.

Useful commands:

```bash
git status --short --branch
git diff --check
gh run list --limit 10
gh run watch
```

For pull requests:

```bash
gh pr checks --watch
```

If `gh` is not authenticated, the network is unavailable, or GitHub Actions are not configured for the branch/event, report that directly. Do not invent CI status. If a workflow fails, inspect the failed job logs before proposing a fix:

```bash
gh run view --log-failed
```

## Code Style

- Swift version is configured as Swift 6 in the Xcode project; `WhiskyKit/Package.swift` uses swift-tools-version 5.9 and `swiftLanguageVersions: [.version("6")]`.
- macOS deployment target is currently 14.0.
- Indent Swift with 4 spaces.
- Keep comments sparse and useful.
- Existing code uses SwiftUI views, `ObservableObject`, `@Published`, async `Task`, `Process`, `PropertyListEncoder/Decoder`, and `os.log`.
- Be conservative with concurrency changes. Existing `@unchecked Sendable` types are technical debt; do not spread that pattern unless there is a clear reason.
- Prefer structured APIs for plist, URL, registry output, PE parsing, and package metadata. Avoid ad hoc string parsing where a safer API exists.

## Localization

- UI strings are generally referenced by localization key, for example `Text("button.createBottle")`.
- Add new user-visible strings to `Whisky/Localizable.xcstrings`.
- Do not manually translate all languages in code changes. Keep source text consistent and leave translation workflow to Crowdin unless the maintainer asks otherwise.
- Watch for typos in existing localization keys before reusing them; preserve compatibility unless doing a focused cleanup.

## User Data And Runtime Paths

The app derives paths from `Bundle.whiskyBundleIdentifier`.

- Bottle list: `~/Library/Containers/<bundle-id>/BottleVM.plist`
- Default bottles: `~/Library/Containers/<bundle-id>/Bottles`
- Managed Wine libraries: `~/Library/Application Support/<bundle-id>/Libraries`
- Logs: `~/Library/Logs/<bundle-id>`

Changing bundle identifiers or fallback identifiers can orphan existing bottles and libraries. Any migration must include backup, detection of old paths, and a rollback plan.

## Wine And Compatibility Work

Important runtime areas:

- `WhiskyKit/Sources/WhiskyKit/Wine/Wine.swift` runs `wine64` and `wineserver`, constructs bottle environments, toggles DXVK DLLs, edits Wine registry settings, and creates logs.
- `WhiskyKit/Sources/WhiskyKit/WhiskyWine/WhiskyWineInstaller.swift` installs/uninstalls the managed Wine payload and checks remote version metadata.
- `WhiskyKit/Sources/WhiskyKit/Whisky/BottleSettings.swift` stores Wine, Metal, DXVK, Windows version, AVX, and pinned program settings.
- `WhiskyKit/Sources/WhiskyKit/Whisky/Program.swift` and `Extensions/Program+Extensions.swift` launch programs through Wine or Terminal.

When debugging a failing game/app launch, capture:

- macOS version and hardware generation.
- VineyardMac/Whisky app version and bundle identifier.
- Wine/WhiskyWine version.
- Bottle path, Windows version, enhanced sync mode, DXVK settings, Metal settings, AVX setting, locale, custom environment, and launch arguments.
- The exact generated Wine command when relevant.
- Logs from `~/Library/Logs/<bundle-id>`.
- Whether the failure occurs through direct Wine launch, Terminal launch, CLI launch, or setup.

Prefer adding diagnostics that explain failures to users over silent `print` calls.

## Dependency And Release Notes

- Xcode workspace dependencies include Sparkle, SemanticVersion, swift-argument-parser, SwiftyTextTable, and Progress.swift.
- `WhiskyKit/Package.swift` separately declares SemanticVersion.
- `.github/workflows/SwiftLint.yml` still runs SwiftLint on Ubuntu.
- `.github/workflows/Release.yml` still points to original Whisky release and Homebrew automation. Treat it as stale until intentionally updated.
- Sparkle appcast and help links still reference original Whisky infrastructure in several places.

## Agent Workflow

Before editing:

1. Read `README.md`, `CONTRIBUTING.md`, and this file.
2. Check `git status --short --branch`.
3. Inspect the specific files you plan to modify.
4. Identify whether the change touches user data, signing, release/update infrastructure, localization, or external compatibility claims.

During implementation:

- Keep edits scoped.
- Use existing architecture and naming unless the task is a planned rename.
- Avoid unrelated formatting churn.
- Use `rg` for code search.
- Use `apply_patch` for manual edits.
- Preserve user changes in a dirty worktree.

Before finishing:

- Run the narrowest validation that is available.
- If UI changed and Xcode can run, build or preview the affected target and capture screenshots when useful.
- If validation is blocked by missing tools or local configuration, report the blocker directly.
- Summarize behavior changed, files changed, validation run, and remaining risks.
