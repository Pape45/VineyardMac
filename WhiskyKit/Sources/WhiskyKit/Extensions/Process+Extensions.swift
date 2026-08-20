//
//  Process+Extensions.swift
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

import Foundation
import os.log

public enum ProcessOutput: Hashable {
    case started(Process)
    case message(String)
    case error(String)
    case terminated(Process)
}

enum ProcessLogRedactor {
    static let marker = "<redacted>"

    private static let sensitiveTerms = [
        "token", "secret", "password", "passwd", "credential", "cookie",
        "authorization", "apikey", "accesskey", "privatekey", "sessionid", "sessionkey"
    ]

    static func arguments(_ arguments: [String]) -> [String] {
        var redactNext = false

        return arguments.map { argument in
            if redactNext {
                redactNext = false
                return marker
            }

            if argument.hasPrefix("-") || argument.hasPrefix("/"),
               !argument.contains("="), !argument.contains(":"),
               isSensitiveName(argument) {
                redactNext = true
                return singleLine(argument)
            }

            return singleLine(redactInlineValue(in: argument))
        }
    }

    static func argumentsDescription(_ arguments: [String]) -> String {
        self.arguments(arguments).joined(separator: " ")
    }

    static func commandLine(_ command: String) -> String {
        argumentsDescription(command.split(whereSeparator: \.isWhitespace).map(String.init))
    }

    static func environment(_ environment: [String: String]) -> [String: String] {
        environment.reduce(into: [:]) { result, entry in
            result[entry.key] = isSensitiveName(entry.key) ? marker : redactInlineValue(in: entry.value)
        }
    }

    static func environmentDescription(_ environment: [String: String]) -> String {
        let redacted = self.environment(environment)
        return redacted.keys.sorted().map { key in
            "\(key)=\(singleLine(redacted[key] ?? ""))"
        }.joined(separator: "\n")
    }

    private static func redactInlineValue(in value: String) -> String {
        if var components = URLComponents(string: value) {
            var changed = false
            if components.password != nil {
                components.password = marker
                changed = true
            }
            if let queryItems = components.queryItems {
                components.queryItems = queryItems.map { item in
                    guard item.value != nil, isSensitiveName(item.name) else { return item }
                    changed = true
                    return URLQueryItem(name: item.name, value: marker)
                }
            }
            if changed {
                return components.string ?? value
            }
        }

        for separator in [Character("="), Character(":")] {
            guard let index = value.firstIndex(of: separator) else { continue }
            let name = String(value[..<index])
            if isSensitiveName(name) {
                return "\(name)\(separator)\(marker)"
            }
        }

        return value
    }

    private static func isSensitiveName(_ name: String) -> Bool {
        let normalized = name.lowercased().filter { $0.isLetter || $0.isNumber }
        return sensitiveTerms.contains { normalized.contains($0) }
    }

    private static func singleLine(_ value: String) -> String {
        value.replacingOccurrences(of: "\r", with: #"\r"#)
            .replacingOccurrences(of: "\n", with: #"\n"#)
    }
}

public extension Process {
    /// Run the process returning a stream output
    func runStream(name: String, fileHandle: FileHandle?) throws -> AsyncStream<ProcessOutput> {
        let safeName = ProcessLogRedactor.commandLine(name)
        let stream = makeStream(name: safeName, fileHandle: fileHandle)
        self.logProcessInfo(name: safeName)
        fileHandle?.writeInfo(for: self)
        try run()
        return stream
    }

    private func makeStream(name: String, fileHandle: FileHandle?) -> AsyncStream<ProcessOutput> {
        let pipe = Pipe()
        let errorPipe = Pipe()
        standardOutput = pipe
        standardError = errorPipe

        return AsyncStream<ProcessOutput> { continuation in
            continuation.onTermination = { termination in
                switch termination {
                case .finished:
                    break
                case .cancelled:
                    guard self.isRunning else { return }
                    self.terminate()
                @unknown default:
                    break
                }
            }

            continuation.yield(.started(self))

            pipe.fileHandleForReading.readabilityHandler = { pipe in
                guard let line = pipe.nextLine() else { return }
                continuation.yield(.message(line))
                guard !line.isEmpty else { return }
                Logger.wineKit.info("\(line, privacy: .public)")
                fileHandle?.write(line: line)
            }

            errorPipe.fileHandleForReading.readabilityHandler = { pipe in
                guard let line = pipe.nextLine() else { return }
                continuation.yield(.error(line))
                guard !line.isEmpty else { return }
                Logger.wineKit.warning("\(line, privacy: .public)")
                fileHandle?.write(line: line)
            }

            terminationHandler = { (process: Process) in
                do {
                    _ = try pipe.fileHandleForReading.readToEnd()
                    _ = try errorPipe.fileHandleForReading.readToEnd()
                    try fileHandle?.close()
                } catch {
                    Logger.wineKit.error("Error while clearing data: \(error)")
                }

                process.logTermination(name: name)
                continuation.yield(.terminated(process))
                continuation.finish()
            }
        }
    }

    private func logTermination(name: String) {
        if terminationStatus == 0 {
            Logger.wineKit.info(
                "Terminated \(name, privacy: .public) with status code '\(self.terminationStatus, privacy: .public)'"
            )
        } else {
            Logger.wineKit.warning(
                "Terminated \(name, privacy: .public) with status code '\(self.terminationStatus, privacy: .public)'"
            )
        }
    }

    private func logProcessInfo(name: String) {
        Logger.wineKit.info("Running process \(name, privacy: .public)")

        if let arguments = arguments {
            let description = ProcessLogRedactor.argumentsDescription(arguments)
            Logger.wineKit.info("Arguments: `\(description, privacy: .public)`")
        }
        if let executableURL = executableURL {
            Logger.wineKit.info("Executable: `\(executableURL.path(percentEncoded: false))`")
        }
        if let directory = currentDirectoryURL {
            Logger.wineKit.info("Directory: `\(directory.path(percentEncoded: false))`")
        }
        if let environment = environment {
            let description = ProcessLogRedactor.environmentDescription(environment)
            Logger.wineKit.info("Environment:\n\(description, privacy: .public)")
        }
    }
}

extension FileHandle {
    func nextLine() -> String? {
        let data = availableData
        guard !data.isEmpty else {
            readabilityHandler = nil
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
