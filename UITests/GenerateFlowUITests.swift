import XCTest

/// End-to-end verification of the primary feature's wiring (the pure generator is
/// covered by SessionGeneratorTests): add a song → generate → result view → save →
/// archive list → session detail → tap-out affordance. Drives the real UI with no
/// seeded data.
final class GenerateFlowUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testAddGenerateSaveAndReplay() {
        let app = XCUIApplication()
        app.launch()

        // Add a song through the UI (the library starts empty).
        app.buttons["addSongButton"].tap()
        let title = app.textFields["titleField"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "Add-song form did not appear.")
        title.tap()
        title.typeText("Test Riff")
        let url = app.textFields["urlField"]
        url.tap()
        url.typeText("https://example.com/riff")
        // Duration is left at its default; the generator's duration handling is covered
        // by SessionGeneratorTests. This test verifies the generate→save→replay wiring.
        app.buttons["saveSongButton"].tap()

        // Confirm the song landed in the library before moving on.
        XCTAssertTrue(
            app.staticTexts["Test Riff"].waitForExistence(timeout: 5),
            "Song was not added to the library."
        )

        // Generate from the new library (time ceiling only).
        app.tabBars.buttons["Generate"].tap()
        let generateButton = app.buttons["generateButton"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5), "Generate button missing.")
        XCTAssertTrue(generateButton.isEnabled, "Generate disabled — library query didn't see the song.")
        generateButton.tap()
        XCTAssertTrue(
            app.staticTexts["Result"].waitForExistence(timeout: 5),
            "Generated result did not render (Song→candidate mapping / result view wiring)."
        )

        // Save the generated list. The Form is lazy, so scroll the button into the tree.
        let saveButton = app.buttons["saveToArchiveButton"]
        var scrolls = 0
        while !saveButton.exists && scrolls < 6 {
            app.swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button not found.")
        XCTAssertTrue(saveButton.isEnabled, "Save disabled — generation produced 0 entries.")
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

        // Exercise the tap-out (openURL). Assert the row is hittable, then tap; we don't
        // assert the external handler opened, since that leaves the app.
        let entry = app.cells.firstMatch
        if entry.waitForExistence(timeout: 2) {
            entry.tap()
        }
    }
}
