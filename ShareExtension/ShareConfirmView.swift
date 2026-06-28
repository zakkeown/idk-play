import SwiftUI

/// The quick confirm/edit sheet shown when a link is shared into IDK Play: prefilled
/// title, length (auto-filled for YouTube), source tag, and the link. Save enqueues
/// the draft for the app to pick up; Cancel dismisses without adding anything.
struct ShareConfirmView: View {
    @ObservedObject var model: ShareImportModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Song") {
                    TextField("Title", text: $model.title)
                        .accessibilityIdentifier("shareTitleField")
                    lengthRow
                }
                if !model.tags.isEmpty {
                    Section("Tags") { tagRow }
                }
                Section("Link") {
                    Text(model.urlString)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Add to IDK Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { model.onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { model.save() }
                        .disabled(!model.canSave)
                        .accessibilityIdentifier("shareSaveButton")
                }
            }
            .task { model.fetchLengthIfNeeded() }
        }
    }

    private var lengthRow: some View {
        HStack {
            Text("Length")
            Spacer()
            if model.isFetchingLength {
                ProgressView().controlSize(.small)
            } else {
                numberField(placeholder: "min", get: { model.seconds / 60 }, set: { model.seconds = max(0, $0) * 60 + (model.seconds % 60) })
                Text("m").foregroundStyle(.secondary)
                numberField(placeholder: "sec", get: { model.seconds % 60 }, set: { model.seconds = (model.seconds / 60) * 60 + min(59, max(0, $0)) })
                Text("s").foregroundStyle(.secondary)
            }
        }
    }

    private func numberField(placeholder: String, get: @escaping () -> Int, set: @escaping (Int) -> Void) -> some View {
        TextField(placeholder, value: Binding(get: get, set: set), format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 44)
    }

    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text(tag)
                        Button { model.removeTag(tag) } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                }
            }
        }
    }
}
