# Contributing

Thanks for helping with VineyardMac. This project is a continuation of Whisky, so keep attribution and GPL-3.0-or-later licensing intact.

## Build environment

Use Xcode on macOS. External dependencies are handled through Swift Package Manager.

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

Keep pull requests focused. Include screenshots for UI changes.

Before opening a PR, run the relevant local checks and make sure GitHub Actions are green.

For large changes, open an issue first so the direction can be agreed before code is written.
