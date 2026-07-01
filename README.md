# VineyardMac

A modern macOS app for managing Wine bottles, running Windows applications, and improving compatibility workflows on Apple Silicon Macs.

VineyardMac started as an independent continuation of [Whisky](https://github.com/Whisky-App/Whisky), an open-source Wine wrapper for macOS built with SwiftUI.

This project is independently maintained and is not affiliated with the original Whisky project.

---

## Status

VineyardMac is currently in early development.

The initial goal is to preserve the useful foundation of Whisky while modernizing the project, improving maintainability, and exploring new features around diagnostics, compatibility profiles, and AI-assisted troubleshooting.

Expect breaking changes while the project is being renamed, cleaned up, and reorganized.

---

## Goals

VineyardMac aims to provide:

* A clean native macOS interface for Wine bottle management
* Better diagnostics for failed Windows app and game launches
* Improved compatibility workflows for Apple Silicon Macs
* Easier management of Wine, DXVK, Metal-related components, and bottle settings
* AI-assisted troubleshooting for logs, crashes, and configuration issues
* A maintained, community-friendly continuation of the original Whisky concept

---

## Planned Roadmap

### Short term

* Rename visible app branding from Whisky to VineyardMac
* Update documentation and setup instructions
* Review build process on current macOS versions
* Clean deprecated links and archived project references
* Audit dependencies and bundled components
* Preserve GPL-3.0 license compliance and attribution

### Medium term

* Improve bottle creation and management UX
* Add better error reporting and diagnostics
* Improve logs and crash explanations
* Add compatibility profiles for common apps and games
* Improve Wine component management
* Review support for current versions of macOS

### Long term

* Add AI-assisted troubleshooting
* Add guided fixes for common launch failures
* Add community-maintained compatibility data
* Improve developer tooling for contributors
* Explore plugin-style compatibility helpers

---

## System Requirements

VineyardMac is intended for modern Apple Silicon Macs.

Current baseline requirements are expected to follow the original Whisky project:

* Apple Silicon Mac
* macOS Sonoma 14.0 or later

These requirements may change as the project evolves.

---

## Building

Build instructions are being reviewed and updated.

For now, open the Xcode project in Xcode:

```bash
open Whisky.xcodeproj
```

The project still contains original Whisky naming internally while the transition to VineyardMac is in progress.

A full rename of the Xcode project, targets, bundle identifiers, and app metadata will be handled carefully to avoid breaking the build.

---

## Attribution

VineyardMac is based on Whisky by the Whisky-App contributors:

https://github.com/Whisky-App/Whisky

The original Whisky project is licensed under GPL-3.0.

This project preserves the original license and copyright notices. Substantial changes made in this repository are part of VineyardMac and are maintained independently from the original Whisky project.

Whisky is no longer actively maintained by its original maintainers. VineyardMac is a separate continuation and is not endorsed by, sponsored by, or affiliated with the original Whisky project or its maintainers.

---

## License

VineyardMac is licensed under the GNU General Public License v3.0.

See [`LICENSE`](LICENSE) for the full license text.

Because this project is based on GPL-3.0 software, redistributed modified versions must also comply with the GPL-3.0 license terms.

---

## Credits & Acknowledgments

VineyardMac exists because of the work done by the original Whisky contributors and the broader Wine/macOS compatibility ecosystem.

Special thanks to the original Whisky project and its contributors.

The original Whisky project also credited several important projects and technologies, including:

* Wine
* CrossOver
* Apple's Game Porting Toolkit
* DXVK-macOS
* MoltenVK
* Sparkle
* SwiftUI
* Other open-source dependencies used by the original project

Attribution for upstream projects will be preserved and expanded as the codebase is reviewed.

---

## Disclaimer

VineyardMac is an independent open-source project.

It is not affiliated with Apple, CodeWeavers, WineHQ, the original Whisky maintainers, or any commercial compatibility product.

Windows application and game compatibility can vary significantly depending on macOS version, hardware, Wine version, graphics stack, and application-specific behavior.

---

## Contributing

Contribution guidelines are not finalized yet.

Planned contribution areas include:

* Build fixes
* Documentation updates
* macOS compatibility testing
* Bottle management improvements
* UI/UX improvements
* Wine configuration fixes
* Compatibility profiles
* Log parsing and diagnostics
* AI-assisted troubleshooting workflows

Before opening large pull requests, please open an issue or discussion explaining the proposed change.

---

## Project Direction

VineyardMac is not intended to be a simple rebrand.

The project direction is to become a maintained, modern, developer-friendly Wine management app for macOS with better diagnostics, better user guidance, and eventually AI-assisted support features.

The first phase is stabilization and cleanup.

The second phase is modernization.

The third phase is new functionality.

