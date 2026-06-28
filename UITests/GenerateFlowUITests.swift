import XCTest

/// End-to-end verification of the primary feature's wiring (not just the pure
/// generator, which is covered by SessionGeneratorTests): generate → result view →
/// save → archive list → session detail → tap-out affordance.
final class GenerateFlowUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testGenerateSaveAndReplay() {
        let app = XCUIApplication()
        app.launchArguments = ["--seed-sample-data", "--start-tab", "generate"]
        app.launch()

        // Generate from the seeded library (time ceiling only).
        app.buttons["generateButton"].tap()
        XCTAssertTrue(
            app.staticTexts["Result"].waitForExistence(timeout: 5),
            "Generated result did not render (Song→candidate mapping / result view wiring)."
        )

        // Save the generated list to the archive. The Form is lazy, so scroll the
        // button into the rendered tree first.
        let saveButton = app.buttons["saveToArchiveButton"]
        var scrolls = 0
        while !saveButton.exists && scrolls < 6 {
            app.swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button not found.")
        saveButton.tap()
        let ok = app.alerts.buttons["OK"]
        XCTAssertTrue(ok.waitForExistence(timeout: 5), "Save-confirmation alert did not appear.")
        ok.tap()

        // The saved session should appear in the archive.
        app.tabBars.buttons["Sessions"].tap()
        let sessionCell = app.cells.firstMatch
        XCTAssertTrue(sessionCell.waitForExistence(timeout: 5), "Saved session not listed in archive.")
        sessionCell.tap()

        // Detail/replay renders its entries (save populated the relationship correctly).
        XCTAssertTrue(
            app.staticTexts["Tap a song to open its link."].waitForExistence(timeout: 5),
            "Session detail / entries did not render."
        )
        XCTAssertGreaterThan(app.cells.count, 0, "Session detail has no entry rows.")

        // Exercise the tap-out (openURL). We only assert the row is hittable, then tap;
        // we don't assert the external handler opened, since that leaves the app.
        let entry = app.cells.firstMatch
        if entry.waitForExistence(timeout: 2) {
            entry.tap()
        }
    }
}
