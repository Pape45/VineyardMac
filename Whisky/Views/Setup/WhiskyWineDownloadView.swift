//
//  WhiskyWineDownloadView.swift
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

import SwiftUI
import WhiskyKit

struct WhiskyWineDownloadView: View {
    @State private var fractionProgress: Double = 0
    @State private var completedBytes: Int64 = 0
    @State private var totalBytes: Int64 = 0
    @State private var downloadSpeed: Double = 0
    @State private var downloadTask: URLSessionDownloadTask?
    @State private var observation: NSKeyValueObservation?
    @State private var startTime: Date?
    @State private var errorMessage: String?
    @Binding var tarLocation: URL
    @Binding var runtimeRelease: WhiskyWineRelease?
    @Binding var path: [SetupStage]
    var body: some View {
        VStack {
            VStack {
                Text("setup.whiskywine.download")
                    .font(.title)
                    .fontWeight(.bold)
                Text("setup.whiskywine.download.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if let errorMessage {
                    VStack {
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .foregroundStyle(.red)
                            .frame(width: 60, height: 60)
                        Text(errorMessage)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        Button("setup.retry") {
                            startDownload()
                        }
                    }
                } else {
                    VStack {
                        ProgressView(value: fractionProgress, total: 1)
                        HStack {
                            Text(String(format: String(localized: "setup.whiskywine.progress"),
                                        formatBytes(bytes: completedBytes),
                                        formatBytes(bytes: totalBytes)))
                            + Text(String(" "))
                            + (shouldShowEstimate() ?
                               Text(String(format: String(localized: "setup.whiskywine.eta"),
                                           formatRemainingTime(remainingBytes: totalBytes - completedBytes)))
                               : Text(String()))
                            Spacer()
                        }
                        .font(.subheadline)
                        .monospacedDigit()
                    }
                    .padding(.horizontal)
                }
                Spacer()
            }
            Spacer()
        }
        .frame(width: 400, height: 200)
        .onAppear {
            startDownload()
        }
    }

    func startDownload() {
        downloadTask?.cancel()
        errorMessage = nil
        completedBytes = 0
        totalBytes = 0
        fractionProgress = 0
        startTime = Date()

        Task {
            do {
                let release = try await WhiskyWineInstaller.whiskyWineRelease()
                guard let downloadURL = release.downloadURL else {
                    throw WhiskyWineInstallerError.invalidRelease
                }
                downloadTask = URLSession(configuration: .ephemeral).downloadTask(
                    with: downloadURL
                ) { url, response, error in
                    do {
                        if let error {
                            throw error
                        }
                        guard let response = response as? HTTPURLResponse,
                              200..<300 ~= response.statusCode,
                              let url else {
                            throw URLError(.badServerResponse)
                        }

                        let savedArchive = FileManager.default.temporaryDirectory
                            .appending(path: "VineyardMac-\(UUID().uuidString)")
                            .appendingPathExtension("tar.gz")
                        try FileManager.default.moveItem(at: url, to: savedArchive)

                        Task { @MainActor in
                            tarLocation = savedArchive
                            runtimeRelease = release
                            proceed()
                        }
                    } catch {
                        Task { @MainActor in
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                observeDownloadProgress()
                downloadTask?.resume()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func observeDownloadProgress() {
        observation = downloadTask?.observe(\.countOfBytesReceived) { task, _ in
            Task { @MainActor in
                let currentTime = Date()
                let elapsedTime = currentTime.timeIntervalSince(startTime ?? currentTime)
                if completedBytes > 0 {
                    downloadSpeed = Double(completedBytes) / elapsedTime
                }
                totalBytes = task.countOfBytesExpectedToReceive
                completedBytes = task.countOfBytesReceived
                if totalBytes > 0 {
                    fractionProgress = Double(completedBytes) / Double(totalBytes)
                }
            }
        }
    }

    func formatBytes(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: bytes)
    }

    func shouldShowEstimate() -> Bool {
        let elapsedTime = Date().timeIntervalSince(startTime ?? Date())
        return Int(elapsedTime.rounded()) > 5 && completedBytes != 0
    }

    func formatRemainingTime(remainingBytes: Int64) -> String {
        let remainingTimeInSeconds = Double(remainingBytes) / downloadSpeed

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        if shouldShowEstimate() {
            return formatter.string(from: TimeInterval(remainingTimeInSeconds)) ?? ""
        } else {
            return ""
        }
    }

    func proceed() {
        path.append(.whiskyWineInstall)
    }
}
