import Combine

@MainActor
final class NoteModel: ObservableObject {
    @Published var draft = ""
    @Published var errorMessage: String?
    private let storage: NoteStorage

    init(storage: NoteStorage = .local) {
        self.storage = storage
        do {
            draft = try storage.load()
        } catch {
            errorMessage = "The saved note could not be loaded. \(error.localizedDescription)"
        }
    }

    func save() {
        do {
            try storage.save(draft)
        } catch {
            errorMessage = "The note could not be saved. \(error.localizedDescription)"
        }
    }
}
