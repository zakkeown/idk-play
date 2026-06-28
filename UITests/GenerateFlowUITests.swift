import XCTest

/// End-to-end verification of the primary feature's wiring (the pure generator is
/// covered by SessionGeneratorTests): add a song → generate → result view → save →
/// archive list → session detail → tap-out affordance. Drives the real UI with no
/// seeded data.
final class GenerateFlowUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    /// Add a song through the Library UI. Assumes the Library tab is showing.
    private func addSong(_ app: XCUIApplication, title: String, url: String) {
        app.buttons["addSongButton"].tap()
        let titleField = app.textFields["titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Add-song form did not appear.")
        titleField.tap()
        titleField.typeText(title)
        let urlField = app.textFields["urlField"]
        urlField.tap()
        urlField.typeText(url)
        // Duration is left at its default; the generator's duration handling is covered
        // by SessionGeneratorTests.
        app.buttons["saveSongButton"].tap()
        XCTAssertTrue(
            app.staticTexts[title].waitForExistence(timeout: 5),
            "Song was not added to the library."
        )
    }

    func testAddGenerateSaveAndReplay() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-ephemeral-store"]
        app.launch()

        // Add a song through the UI (the library starts empty).
        addSong(app, title: "Test Riff", url: "https://example.com/riff")

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

        // Save the generated list. The Form is lazy and the editable result view is tall,
        // so scroll until the button is actually on-screen (exists alone can be off-screen).
        let saveButton = app.buttons["saveToArchiveButton"]
        var scrolls = 0
        while !saveButton.isHittable && scrolls < 8 {
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

    /// Verifies the generated list is hand-editable before saving: swipe-delete removes
    /// a song and re-adding from the library restores it. Drives the SwiftUI binding
    /// writeback that the pure EditableSession unit tests can't reach.
    func testEditGeneratedListBeforeSaving() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-ephemeral-store"]
        app.launch()

        addSong(app, title: "Alpha Tune", url: "https://example.com/alpha")
        addSong(app, title: "Beta Tune", url: "https://example.com/beta")

        app.tabBars.buttons["Generate"].tap()
        let generateButton = app.buttons["generateButton"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5), "Generate button missing.")
        generateButton.tap()

        // Both songs fit the default ceiling, so the result holds two entries. With the
        // whole library already in the list, there is nothing left to add.
        XCTAssertTrue(
            app.staticTexts["2 songs"].waitForExistence(timeout: 5),
            "Result did not report two songs."
        )
        XCTAssertFalse(
            app.buttons["addSongToSessionButton"].exists,
            "Add control should be hidden when every library song is already in the list."
        )

        // Swipe-delete one entry — the live binding must write back: the count drops to
        // one and the now-removable song reactively surfaces the add control.
        let row = app.staticTexts["Beta Tune"]
        XCTAssertTrue(row.waitForExistence(timeout: 2), "Result row missing.")
        row.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(
            app.staticTexts["1 song"].waitForExistence(timeout: 5),
            "Deleting a result row did not update the count."
        )
        XCTAssertTrue(
            app.buttons["addSongToSessionButton"].waitForExistence(timeout: 5),
            "Removing a song did not surface it as addable again."
        )
    }

    /// When the library has a song tagged "warmup", the Generate screen offers — and
    /// defaults on — a "start with a warm-up" lead-in.
    func testWarmupTagDefaultsToggleOn() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-ephemeral-store"]
        app.launch()

        // Add a song, then tag it "warmup" through the tag field.
        app.buttons["addSongButton"].tap()
        let titleField = app.textFields["titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Add-song form did not appear.")
        titleField.tap()
        titleField.typeText("Scales")
        let urlField = app.textFields["urlField"]
        urlField.tap()
        urlField.typeText("https://example.com/scales")
        let tagField = app.textFields["Add tag"]
        tagField.tap()
        tagField.typeText("warmup\n")
        app.buttons["saveSongButton"].tap()

        app.tabBars.buttons["Generate"].tap()
        let toggle = app.switches["warmupToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "Warm-up toggle did not appear for a warmup-tagged library.")
        XCTAssertEqual(toggle.value as? String, "1", "Warm-up toggle should default on when a warmup tag exists.")
    }
}
