# Contributing

Thanks for helping with VineyardMac. This project is a continuation of Whisky, so keep attribution and GPL-3.0-or-later licensing intact.

## Build environment

Use an Apple Silicon Mac running macOS 14 or later. Install Xcode and SwiftLint; external project dependencies are handled through Swift Package Manager.

Useful local checks:

```bash
swiftlint --strict
xcodebuild -project Whisky.xcodeproj -scheme Whisky -configuration Debug build
swift build --package-path WhiskyKit
```

If you do not have a signing identity for the app, use:

```bash
xcodebuild -project Whisky.xcodeproj -scheme Whisky -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

## Code style

Every change must pass SwiftLint. Building in Xcode also runs SwiftLint unless `SWIFTLINT_SKIP=YES` is set.

Avoid disabling SwiftLint rules unless the alternative is worse.

Use 4-space indentation.

Add user-facing strings to `Whisky/Localizable.xcstrings`. Do not translate other languages in regular code changes.

## Pull requests

Create a branch from `main` and keep each pull request focused. Include screenshots for UI changes and describe the manual testing you performed.

Before opening a PR, run the relevant local checks. After pushing, wait for the Build and SwiftLint checks to pass.

For large changes, open a [discussion](https://github.com/Pape45/VineyardMac/discussions) first so the direction can be agreed before code is written. Use the issue forms for reproducible bugs and focused feature requests.

Do not combine a broad Whisky-to-VineyardMac rename with unrelated work. Changes to signing, bundle identifiers, update feeds, or user data paths require an explicit migration plan.
