//
//  WhiskyWineInstaller.swift
//  WhiskyKit
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import CryptoKit
import Foundation
import SemanticVersion

public class WhiskyWineInstaller {
    private static let releaseURL = URL(
        string: "https://data.vineyardmac.app/Wine/WhiskyWineVersion.plist"
    )!

    /// The Whisky application folder
    public static let applicationFolder = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
        )[0].appending(path: Bundle.whiskyBundleIdentifier)

    /// The folder of all the libfrary files
    public static let libraryFolder = applicationFolder.appending(path: "Libraries")

    /// URL to the installed `wine` `bin` directory
    public static let binFolder: URL = libraryFolder.appending(path: "Wine").appending(path: "bin")

    public static func isWhiskyWineInstalled() -> Bool {
        return whiskyWineVersion() != nil
    }

    public static func install(from archive: URL, release: WhiskyWineRelease) throws {
        try install(from: archive, release: release, applicationFolder: applicationFolder)
    }

    static func install(from archive: URL, release: WhiskyWineRelease, applicationFolder: URL) throws {
        let libraryFolder = applicationFolder.appending(path: "Libraries")
        guard try sha256(of: archive) == release.archiveSHA256.lowercased() else {
            throw WhiskyWineInstallerError.invalidChecksum
        }

        try requireSupportedOS(release.minimumMacOSVersion)
        try FileManager.default.createDirectory(at: applicationFolder, withIntermediateDirectories: true)

        let stagingFolder = applicationFolder.appending(path: ".runtime-install-\(UUID().uuidString)")
        let candidate = stagingFolder.appending(path: "Libraries")
        let backup = applicationFolder.appending(path: ".runtime-backup-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: stagingFolder) }

        try FileManager.default.createDirectory(at: stagingFolder, withIntermediateDirectories: true)
        try Tar.untar(tarBall: archive, toURL: stagingFolder)
        try validate(candidate, release: release)

        let hadInstalledRuntime = FileManager.default.fileExists(atPath: libraryFolder.path)
        if hadInstalledRuntime {
            try FileManager.default.moveItem(at: libraryFolder, to: backup)
        }

        do {
            try FileManager.default.moveItem(at: candidate, to: libraryFolder)
            if hadInstalledRuntime {
                try? FileManager.default.removeItem(at: backup)
            }
            try? FileManager.default.removeItem(at: archive)
        } catch {
            if hadInstalledRuntime, !FileManager.default.fileExists(atPath: libraryFolder.path) {
                try? FileManager.default.moveItem(at: backup, to: libraryFolder)
            }
            throw error
        }
    }

    public static func uninstall() {
        do {
            try FileManager.default.removeItem(at: libraryFolder)
        } catch {
            print("Failed to uninstall WhiskyWine: \(error)")
        }
    }

    public static func shouldUpdateWhiskyWine() async -> (Bool, SemanticVersion) {
        let localVersion = whiskyWineVersion()

        do {
            let remoteVersion = try await whiskyWineRelease().version
            return (localVersion.map { $0 < remoteVersion } ?? false, remoteVersion)
        } catch {
            print(error)
            return (false, SemanticVersion(0, 0, 0))
        }
    }

    public static func whiskyWineRelease() async throws -> WhiskyWineRelease {
        let (data, response) = try await URLSession(configuration: .ephemeral).data(from: releaseURL)
        guard let response = response as? HTTPURLResponse, 200..<300 ~= response.statusCode else {
            throw WhiskyWineInstallerError.releaseUnavailable
        }

        let release = try PropertyListDecoder().decode(WhiskyWineRelease.self, from: data)
        guard release.downloadURL != nil,
              release.archiveSHA256.range(
                of: #"^[0-9a-fA-F]{64}$"#,
                options: .regularExpression
              ) != nil else {
            throw WhiskyWineInstallerError.invalidRelease
        }
        return release
    }

    public static func whiskyWineVersion() -> SemanticVersion? {
        whiskyWineVersion(in: libraryFolder)
    }

    static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        while let data = try handle.read(upToCount: 1024 * 1024), !data.isEmpty {
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func whiskyWineVersion(in folder: URL) -> SemanticVersion? {
        do {
            let versionPlist = folder
                .appending(path: "WhiskyWineVersion")
                .appendingPathExtension("plist")

            let decoder = PropertyListDecoder()
            let data = try Data(contentsOf: versionPlist)
            let info = try decoder.decode(WhiskyWineVersion.self, from: data)
            return info.version
        } catch {
            print(error)
            return nil
        }
    }

    private static func validate(_ candidate: URL, release: WhiskyWineRelease) throws {
        let requiredFiles = [
            "Wine/bin/wine64",
            "Wine/bin/wineserver",
            "Wine/lib/external/D3DMetal.framework/Versions/A/D3DMetal",
            "Wine/lib/libMoltenVK.dylib",
            "Wine/lib/wine/x86_64-unix/winemac.drv.so",
            "Wine/lib/wine/x86_32on64-unix/winemac.drv.so",
            "DXVK/x64/d3d9.dll",
            "DXVK/x64/d3d10core.dll",
            "DXVK/x64/d3d11.dll",
            "DXVK/x64/dxgi.dll",
            "DXVK/x32/d3d9.dll",
            "DXVK/x32/d3d10core.dll",
            "DXVK/x32/d3d11.dll",
            "DXVK/x32/dxgi.dll",
            "winetricks",
            "verbs.txt",
            "RuntimeManifest.json",
            "WhiskyWineVersion.plist"
        ]
        guard requiredFiles.allSatisfy({
            FileManager.default.fileExists(atPath: candidate.appending(path: $0).path)
        }) else {
            throw WhiskyWineInstallerError.invalidArchive
        }

        let manifestData = try Data(contentsOf: candidate.appending(path: "RuntimeManifest.json"))
        let manifest = try JSONDecoder().decode(RuntimeManifest.self, from: manifestData)
        let releaseVersion = String(release.version).split(separator: "+", maxSplits: 1)[0]
        guard manifest.runtimeVersion == releaseVersion,
              whiskyWineVersion(in: candidate) == release.version else {
            throw WhiskyWineInstallerError.versionMismatch
        }
    }

    private static func requireSupportedOS(_ minimumVersion: String) throws {
        let components = minimumVersion.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else {
            throw WhiskyWineInstallerError.invalidRelease
        }
        let required = OperatingSystemVersion(
            majorVersion: components[0],
            minorVersion: components[1],
            patchVersion: components.count > 2 ? components[2] : 0
        )
        guard ProcessInfo.processInfo.isOperatingSystemAtLeast(required) else {
            throw WhiskyWineInstallerError.unsupportedOS(minimumVersion)
        }
    }
}

public struct WhiskyWineRelease: Codable, Equatable, Sendable {
    public let version: SemanticVersion
    public let archiveURL: String
    public let archiveSHA256: String
    public let minimumMacOSVersion: String

    public var downloadURL: URL? {
        URL(string: archiveURL)
    }
}

private struct WhiskyWineVersion: Codable {
    var version: SemanticVersion = SemanticVersion(1, 0, 0)
}

private struct RuntimeManifest: Codable {
    let runtimeVersion: String
}

public enum WhiskyWineInstallerError: LocalizedError {
    case invalidArchive
    case invalidChecksum
    case invalidRelease
    case releaseUnavailable
    case unsupportedOS(String)
    case versionMismatch

    public var errorDescription: String? {
        switch self {
        case .invalidArchive:
            "The downloaded runtime is incomplete."
        case .invalidChecksum:
            "The downloaded runtime failed its integrity check."
        case .invalidRelease:
            "The runtime release metadata is invalid."
        case .releaseUnavailable:
            "The runtime release information is unavailable."
        case .unsupportedOS(let version):
            "This runtime requires macOS \(version) or later."
        case .versionMismatch:
            "The runtime version does not match its release metadata."
        }
    }
}
