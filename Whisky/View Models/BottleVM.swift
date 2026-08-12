//
//  BottleVM.swift
//  Whisky
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
import WhiskyKit

// swiftlint:disable:next todo
// TODO: Don't use unchecked!
final class BottleVM: ObservableObject, @unchecked Sendable {
    @MainActor static let shared = BottleVM()

    var bottlesList = BottleData()
    @Published var bottles: [Bottle] = []

    @MainActor
    func loadBottles() {
        bottles = bottlesList.loadBottles()
    }

    @MainActor
    func createNewBottle(bottleName: String, winVersion: WinVersion, bottleURL: URL) -> URL {
        let newBottleDir = bottleURL.appending(path: UUID().uuidString)

        Task { @MainActor in
            var bottle: Bottle?
            var createdBottleDirectory = false
            do {
                try FileManager.default.createDirectory(at: bottleURL, withIntermediateDirectories: true)
                try FileManager.default.createDirectory(at: newBottleDir, withIntermediateDirectories: false)
                createdBottleDirectory = true
                let newBottle = Bottle(bottleUrl: newBottleDir, inFlight: true)
                bottle = newBottle
                self.bottles.append(newBottle)

                newBottle.settings.windowsVersion = winVersion
                newBottle.settings.name = bottleName
                try await Wine.changeWinVersion(bottle: newBottle, win: winVersion)
                self.bottlesList.paths.append(newBottleDir)
                newBottle.isAvailable = true
                newBottle.inFlight = false
                self.bottles = self.bottles
            } catch {
                print("Failed to create new bottle: \(error)")
                if let bottle {
                    try? await Wine.killBottle(bottle: bottle)
                }
                if createdBottleDirectory {
                    try? FileManager.default.removeItem(at: newBottleDir)
                }
                if let bottle, let index = self.bottles.firstIndex(of: bottle) {
                    self.bottles.remove(at: index)
                }
            }
        }
        return newBottleDir
    }
}
