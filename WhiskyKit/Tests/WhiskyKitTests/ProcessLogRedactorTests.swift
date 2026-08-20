//
//  ProcessLogRedactorTests.swift
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

@testable import WhiskyKit
import XCTest

final class ProcessLogRedactorTests: XCTestCase {
    func testSensitiveValuesAreRedactedAndOrdinaryValuesRemain() {
        let environment = ProcessLogRedactor.environment([
            "API_TOKEN": "environment-secret",
            "COOKIE": "session-cookie",
            "DATABASE_URL": "https://user:database-secret@example.com/game",
            "LINE\nBREAK": "ordinary-key-value",
            "LANG": "en_US.UTF-8",
            "MULTILINE": "first\nsecond",
            "WINEDEBUG": "fixme-all"
        ])
        let environmentDescription = ProcessLogRedactor.environmentDescription(environment)
        let arguments = ProcessLogRedactor.arguments([
            "start",
            "--token",
            "argument-secret",
            "--password=hunter2",
            "https://example.com/play?session_id=url-secret&locale=en"
        ])
        let description = arguments.joined(separator: " ")

        XCTAssertEqual(environment["API_TOKEN"], ProcessLogRedactor.marker)
        XCTAssertEqual(environment["COOKIE"], ProcessLogRedactor.marker)
        XCTAssertFalse(environment["DATABASE_URL"]?.contains("database-secret") ?? true)
        XCTAssertEqual(environment["LANG"], "en_US.UTF-8")
        XCTAssertEqual(environment["WINEDEBUG"], "fixme-all")
        XCTAssertTrue(environmentDescription.contains(#"LINE\nBREAK=ordinary-key-value"#))
        XCTAssertTrue(environmentDescription.contains(#"MULTILINE=first\nsecond"#))
        XCTAssertFalse(environmentDescription.contains("LINE\nBREAK=ordinary-key-value"))
        XCTAssertFalse(environmentDescription.contains("MULTILINE=first\nsecond"))
        XCTAssertFalse(description.contains("argument-secret"))
        XCTAssertFalse(description.contains("hunter2"))
        XCTAssertFalse(description.contains("url-secret"))
        XCTAssertTrue(description.contains("start"))
        XCTAssertTrue(description.contains("locale=en"))
    }
}
