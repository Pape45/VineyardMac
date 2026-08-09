//
//  WhiskyWineInstallerTests.swift
//  WhiskyKitTests
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

import Foundation
@testable import WhiskyKit
import XCTest

final class WhiskyWineInstallerTests: XCTestCase {
    private let requiredRuntimeFiles = [
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
        "verbs.txt"
    ]

    func testSHA256() throws {
        let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        try Data("VineyardMac".utf8).write(to: file)

        XCTAssertEqual(
            try WhiskyWineInstaller.sha256(of: file),
            "ec27139cd08cf47e99f8be6b023ecaaaaa1aa7f40d45b37b5ba5c4a2fce9c209"
        )
    }

    func testInstallKeepsExistingRuntimeWhenValidationFails() throws {
        let testFolder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: testFolder) }
        let installedRuntime = testFolder.appending(path: "Libraries")
        try FileManager.default.createDirectory(at: installedRuntime, withIntermediateDirectories: true)
        let marker = installedRuntime.appending(path: "existing-runtime")
        try Data().write(to: marker)

        let sourceRoot = testFolder.appending(path: "source")
        try FileManager.default.createDirectory(
            at: sourceRoot.appending(path: "Libraries"),
            withIntermediateDirectories: true
        )
        let archive = testFolder.appending(path: "invalid.tar.gz")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-czf", archive.path, "-C", sourceRoot.path, "Libraries"]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        let release = try makeRelease(
            archiveURL: archive,
            sha256: try WhiskyWineInstaller.sha256(of: archive)
        )

        XCTAssertThrowsError(
            try WhiskyWineInstaller.install(from: archive, release: release, applicationFolder: testFolder)
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: marker.path))
    }

    func testInstallReplacesExistingRuntimeAfterValidation() throws {
        let testFolder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: testFolder) }
        let installedRuntime = testFolder.appending(path: "Libraries")
        try FileManager.default.createDirectory(at: installedRuntime, withIntermediateDirectories: true)
        let oldMarker = installedRuntime.appending(path: "existing-runtime")
        try Data().write(to: oldMarker)

        let sourceRoot = testFolder.appending(path: "source")
        let runtime = sourceRoot.appending(path: "Libraries")
        for path in requiredRuntimeFiles {
            let file = runtime.appending(path: path)
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data().write(to: file)
        }
        try Data(#"{"runtimeVersion":"4.0.0-beta.2"}"#.utf8)
            .write(to: runtime.appending(path: "RuntimeManifest.json"))
        try versionPlist().write(to: runtime.appending(path: "WhiskyWineVersion.plist"))

        let archive = testFolder.appending(path: "runtime.tar.gz")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-czf", archive.path, "-C", sourceRoot.path, "Libraries"]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)

        let release = try makeRelease(
            archiveURL: archive,
            sha256: try WhiskyWineInstaller.sha256(of: archive)
        )
        try WhiskyWineInstaller.install(from: archive, release: release, applicationFolder: testFolder)

        XCTAssertFalse(FileManager.default.fileExists(atPath: oldMarker.path))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: installedRuntime.appending(path: "RuntimeManifest.json").path
        ))
    }

    private func makeRelease(archiveURL: URL, sha256: String) throws -> WhiskyWineRelease {
        var plist: [String: Any] = try PropertyListSerialization.propertyList(
            from: versionPlist(),
            options: [],
            format: nil
        ) as? [String: Any] ?? [:]
        plist.merge([
            "archiveURL": archiveURL.absoluteString,
            "archiveSHA256": sha256,
            "minimumMacOSVersion": "14.0"
        ]) { _, new in new }
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        return try PropertyListDecoder().decode(WhiskyWineRelease.self, from: data)
    }

    private func versionPlist() throws -> Data {
        try PropertyListSerialization.data(
            fromPropertyList: [
                "version": [
                    "major": 4,
                    "minor": 0,
                    "patch": 0,
                    "preRelease": "beta.2",
                    "build": "2"
                ]
            ],
            format: .xml,
            options: 0
        )
    }
}
