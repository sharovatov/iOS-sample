import XCTest

final class NotePersistenceTests: XCTestCase {
    @MainActor
    func testSavedNoteSurvivesProcessRelaunch() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        let editor = app.textViews["noteEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.tap()
        let marker = "Saved note " + UUID().uuidString
        editor.typeText(marker)
        let expected = try XCTUnwrap(editor.value as? String)
        XCTAssertTrue(expected.contains(marker))
        app.buttons["saveNote"].tap()
        XCTAssertFalse(app.alerts.firstMatch.exists)

        // Keep this installation and its data; only restart the app process.
        app.terminate()
        XCTAssertEqual(app.state, .notRunning)
        app.launch()

        let restoredEditor = app.textViews["noteEditor"]
        XCTAssertTrue(restoredEditor.waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts.firstMatch.exists)
        XCTAssertEqual(restoredEditor.value as? String, expected)
    }
}
