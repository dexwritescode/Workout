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
    func testSaveShowsConfirmationThenAutoReturnsToStagingView() throws {
        // Relaunch with a longer confirmation delay so this test can reliably observe the
        // screen despite XCUITest's ~1s accessibility-snapshot polling interval.
        let app = XCUIApplication()
        app.terminate()
        app.launchEnvironment["UITEST_SAVE_CONFIRMATION_DELAY"] = "3"
        app.launch()

        XCTAssertTrue(app.buttons["Start Workout"].waitForExistence(timeout: 5), "Expected a generated workout ready to start")
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

        let startWorkoutButton = app.buttons["Start Workout"]
        XCTAssertTrue(startWorkoutButton.waitForExistence(timeout: 4), "Expected to auto-return to the unified staging view")
        XCTAssertFalse(confirmation.exists, "Confirmation screen should be gone after auto-dismiss")
    }

    @MainActor
    func testStartWorkoutButtonHiddenWhileWorkoutActive() throws {
        let app = XCUIApplication()

        XCTAssertTrue(app.buttons["Start Workout"].waitForExistence(timeout: 5), "Expected Start Workout button before any workout is active")
        app.buttons["Start Workout"].tap()

        let minimizeButton = app.buttons["Minimize Workout"]
        XCTAssertTrue(minimizeButton.waitForExistence(timeout: 5), "Expected the active workout screen with a minimize button")
        minimizeButton.tap()

        app.buttons["Workout"].tap()
        XCTAssertTrue(app.buttons["Regenerate"].waitForExistence(timeout: 5), "Expected the staging view's Regenerate button to remain interactive")
        XCTAssertFalse(app.buttons["Start Workout"].exists, "Start Workout button should be hidden, not just disabled, while a workout is active")
    }

    @MainActor
    func testRegenerateSkipsConfirmWhenUntouchedButConfirmsAfterEdit() throws {
        let app = XCUIApplication()

        XCTAssertTrue(app.buttons["Regenerate"].waitForExistence(timeout: 5), "Expected a generated workout preview")

        app.buttons["Regenerate"].tap()
        XCTAssertFalse(app.alerts["Regenerate workout?"].waitForExistence(timeout: 2), "Should not confirm when nothing has been edited yet")

        app.buttons["Add Exercise"].tap()
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].waitForExistence(timeout: 5))
        app.staticTexts["Barbell Bench Press"].tap()

        app.buttons["Regenerate"].tap()
        XCTAssertTrue(app.alerts["Regenerate workout?"].waitForExistence(timeout: 5), "Should confirm before discarding an edited draft")
    }

    @MainActor
    func testSelectedSplitPersistsAcrossTabSwitches() throws {
        let app = XCUIApplication()

        XCTAssertTrue(app.buttons["Upper/Lower"].waitForExistence(timeout: 5))
        app.buttons["Upper/Lower"].tap()
        XCTAssertTrue(app.buttons["Regenerate"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Upper/Lower"].isSelected, "Upper/Lower should be selected right after tapping it")

        app.buttons["Recovery"].tap()
        app.buttons["Workout"].tap()

        XCTAssertTrue(app.buttons["Upper/Lower"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Upper/Lower"].isSelected, "Upper/Lower should still be selected after switching tabs and back")
    }

    @MainActor
    func testLoadingATemplateHidesSplitPickerAndConfirmsBeforeRegenerate() throws {
        let app = XCUIApplication()

        XCTAssertTrue(app.buttons["Regenerate"].waitForExistence(timeout: 5))

        app.buttons["Load Template"].tap()
        XCTAssertTrue(app.staticTexts["Push Day A"].waitForExistence(timeout: 5))
        app.staticTexts["Push Day A"].tap()

        XCTAssertFalse(app.staticTexts["TRAINING SPLIT"].exists, "Split picker should be hidden once a template is loaded")

        app.buttons["Regenerate"].tap()
        XCTAssertTrue(app.alerts["Regenerate workout?"].waitForExistence(timeout: 5), "Should confirm before discarding a freshly-loaded template")
    }

    @MainActor
    func testWorkoutSettingsModeSwitchTogglesFallbackAndScheduleRows() throws {
        let app = XCUIApplication()

        XCTAssertTrue(app.buttons["Workout Settings"].waitForExistence(timeout: 5))
        app.buttons["Workout Settings"].tap()

        XCTAssertTrue(app.buttons["workoutStartModePicker"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["If No Template"].exists, "Fallback row should be hidden in Smart Workout mode")
        XCTAssertFalse(app.staticTexts["Weekly Schedule"].exists, "Weekly Schedule row should be hidden in Smart Workout mode")

        app.buttons["workoutStartModePicker"].tap()
        app.buttons["Day Template"].tap()

        XCTAssertTrue(app.staticTexts["If No Template"].waitForExistence(timeout: 5), "Fallback row should appear once Day Template is selected")
        XCTAssertTrue(app.buttons["dayTemplateFallbackModePicker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Weekly Schedule"].waitForExistence(timeout: 5), "Weekly Schedule row should appear once Day Template is selected")

        // Regression: the "Mode" row's own label must stay visible (WRK-55 bug: it was blank,
        // making the Start Mode and If No Template rows visually indistinguishable).
        XCTAssertTrue(app.staticTexts["Mode"].exists)

        app.buttons["workoutStartModePicker"].tap()
        app.buttons["Freeform"].tap()

        XCTAssertFalse(app.staticTexts["If No Template"].exists, "Fallback row should hide again once mode leaves Day Template")
        XCTAssertFalse(app.staticTexts["Weekly Schedule"].exists)
        XCTAssertTrue(app.staticTexts["Mode"].exists, "Start Mode row must still render at full width, not collapse, with only one row left")
    }

    @MainActor
    func testWeeklyScheduleRowTapAssignsTemplateWithCorrectSheetTitle() throws {
        let app = XCUIApplication()

        app.buttons["Workout Settings"].tap()
        app.buttons["workoutStartModePicker"].tap()
        app.buttons["Day Template"].tap()

        XCTAssertTrue(app.staticTexts["Weekly Schedule"].waitForExistence(timeout: 5))
        app.staticTexts["Weekly Schedule"].tap()

        let mondayRow = app.buttons["weekdayRow-2"]
        XCTAssertTrue(mondayRow.waitForExistence(timeout: 5))
        // Tapping the element's default location hits its center — the blank space between the
        // day name and the chevron that was previously untappable (WRK-55 bug: missing
        // .contentShape(Rectangle()) meant only the rendered glyphs were hit-testable).
        mondayRow.tap()

        XCTAssertTrue(app.navigationBars["Assign Template"].waitForExistence(timeout: 5), "Sheet should use a context-appropriate title, not the misleading 'Load Template'")
        XCTAssertFalse(app.navigationBars["Load Template"].exists)

        XCTAssertTrue(app.staticTexts["Push Day A"].waitForExistence(timeout: 5))
        app.staticTexts["Push Day A"].tap()

        XCTAssertTrue(mondayRow.waitForExistence(timeout: 5))
        XCTAssertTrue(mondayRow.label.contains("Push Day A"), "Monday's row should reflect the newly assigned template: \(mondayRow.label)")
    }

    @MainActor
    func testWeeklyScheduleClearAssignmentOnlyOffersClearWhenSomethingIsAssigned() throws {
        let app = XCUIApplication()

        app.buttons["Workout Settings"].tap()
        app.buttons["workoutStartModePicker"].tap()
        app.buttons["Day Template"].tap()
        app.staticTexts["Weekly Schedule"].tap()

        let mondayRow = app.buttons["weekdayRow-2"]
        XCTAssertTrue(mondayRow.waitForExistence(timeout: 5))
        mondayRow.tap()

        XCTAssertTrue(app.navigationBars["Assign Template"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Clear Assignment"].exists, "An unassigned day should not offer a clear option")

        app.staticTexts["Push Day A"].tap()
        XCTAssertTrue(mondayRow.waitForExistence(timeout: 5))
        XCTAssertTrue(mondayRow.label.contains("Push Day A"))

        mondayRow.tap()
        XCTAssertTrue(app.navigationBars["Assign Template"].waitForExistence(timeout: 5))
        let clearButton = app.buttons["Clear Assignment"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5), "Once assigned, the sheet should offer a way to clear it")
        clearButton.tap()

        XCTAssertTrue(mondayRow.waitForExistence(timeout: 5))
        XCTAssertTrue(mondayRow.label.contains("None"), "Monday should be unassigned again after clearing: \(mondayRow.label)")
    }
}
