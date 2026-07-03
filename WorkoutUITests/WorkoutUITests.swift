// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  WorkoutUITests.swift
//  WorkoutUITests
//
//  Created by Dexter Darwich on 2025-12-30.
//

import XCTest

final class WorkoutUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testWRK38_saveShowsConfirmationThenAutoReturnsToTemplate() throws {
        // setUpWithError already launched the app; relaunch with a longer confirmation
        // delay so this test can reliably observe the screen despite XCUITest's
        // ~1s accessibility-snapshot polling interval (the app itself always uses 1s).
        let app = XCUIApplication()
        app.terminate()
        app.launchEnvironment["UITEST_SAVE_CONFIRMATION_DELAY"] = "3"
        app.launch()

        app.staticTexts["Push Day A"].tap()
        app.buttons["Start Workout"].tap()

        let finishButton = app.buttons["Finish Workout"]
        XCTAssertTrue(finishButton.waitForExistence(timeout: 5), "Expected to land in-progress with a Finish Workout button")
        finishButton.tap()

        let saveButton = app.buttons["Save Workout"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Expected WorkoutSummaryView with Save Workout button")
        saveButton.tap()

        let confirmation = app.staticTexts["Workout Complete!"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5), "Expected the checkmark confirmation screen right after saving")
        XCTAssertFalse(app.buttons["Save Workout"].exists, "Summary screen should be popped, not stacked under the confirmation")

        // The confirmation screen should auto-dismiss ~1s later, landing back on the template detail screen.
        let startWorkoutButton = app.buttons["Start Workout"]
        XCTAssertTrue(startWorkoutButton.waitForExistence(timeout: 4), "Expected to auto-return to the template detail screen")
        XCTAssertFalse(confirmation.exists, "Confirmation screen should be gone after auto-dismiss")
    }
}
