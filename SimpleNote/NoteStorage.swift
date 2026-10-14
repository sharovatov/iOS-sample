import Foundation

struct NoteStorage {
    let fileURL: URL

    static var local: NoteStorage {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0]
        return NoteStorage(fileURL: directory.appendingPathComponent("note.txt"))
    }

    func load() throws -> String {
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch CocoaError.fileReadNoSuchFile {
            return ""
        }
    }

    func save(_ text: String) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
