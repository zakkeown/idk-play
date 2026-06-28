import SwiftUI
import SwiftData

/// Add (when `song == nil`) or edit a library song.
struct SongEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let song: Song?

    @State private var title: String
    @State private var urlString: String
    @State private var seconds: Int
    @State private var tags: [String]
    @State private var notes: String

    init(song: Song?) {
        self.song = song
        _title = State(initialValue: song?.title ?? "")
        _urlString = State(initialValue: song?.urlString ?? "")
        _seconds = State(initialValue: song?.durationSeconds ?? 0)
        _tags = State(initialValue: song?.tags ?? [])
        _notes = State(initialValue: song?.notes ?? "")
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && URL(string: urlString.trimmingCharacters(in: .whitespaces)) != nil
            && !urlString.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Song") {
                    TextField("Title", text: $title)
                    TextField("Link (URL)", text: $urlString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    DurationField(seconds: $seconds)
                }
                Section("Tags") {
                    TagInputField(tags: $tags)
                }
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle(song == nil ? "Add Song" : "Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTags = normalizedTags(tags)

        if let song {
            song.title = cleanTitle
            song.urlString = cleanURL
            song.durationSeconds = seconds
            song.tags = cleanTags
            song.notes = notes
        } else {
            context.insert(Song(
                title: cleanTitle,
                urlString: cleanURL,
                durationSeconds: seconds,
                tags: cleanTags,
                notes: notes
            ))
        }
        dismiss()
    }

    private func normalizedTags(_ raw: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for tag in raw {
            let t = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !t.isEmpty, seen.insert(t).inserted {
                result.append(t)
            }
        }
        return result
    }
}
