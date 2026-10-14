import SwiftUI

struct NoteView: View {
    @StateObject private var model = NoteModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Note")
                    .font(.largeTitle.bold())
                Spacer()
                Button("Save") { model.save() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("saveNote")
            }

            TextEditor(text: $model.draft)
                .font(.body)
                .padding(8)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.secondary.opacity(0.4), lineWidth: 1)
                }
                .accessibilityLabel("Note")
                .accessibilityIdentifier("noteEditor")

            Text("Changes are kept only when you tap Save.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .alert("Note storage", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}
