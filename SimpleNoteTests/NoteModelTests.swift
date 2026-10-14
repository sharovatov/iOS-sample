import XCTest
@testable import SimpleNote

final class NoteModelTests: XCTestCase {
    @MainActor
    func testEditingDraftLeavesSavedNoteUnchanged() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storage = NoteStorage(fileURL: directory.appendingPathComponent("note.txt"))
        let model = NoteModel(storage: storage)

        XCTAssertEqual(model.draft, "")
        XCTAssertNil(model.errorMessage)
        model.draft = "Saved note A\nCafé 📝"
        XCTAssertEqual(try storage.load(), "", "Typing must not save the first draft.")

        model.save()
        XCTAssertNil(model.errorMessage)
        let savedText = model.draft
        XCTAssertEqual(try storage.load(), savedText)

        model.draft = "Unsaved note B"
        XCTAssertEqual(model.draft, "Unsaved note B")
        XCTAssertEqual(try storage.load(), savedText)
        XCTAssertEqual(NoteModel(storage: storage).draft, savedText)
    }
}
