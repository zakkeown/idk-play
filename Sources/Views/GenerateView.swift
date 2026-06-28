import SwiftUI
import SwiftData

struct GenerateView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Song.dateAdded, order: .reverse) private var songs: [Song]

    @State private var targetMinutes = 30
    @State private var requirements: [TagRequirement] = []
    @State private var result: GenerationResult?
    @State private var savedConfirmation = false

    private var allTags: [String] { songs.distinctTags }

    var body: some View {
        NavigationStack {
            Form {
                if songs.isEmpty {
                    Section {
                        Text("Add some songs to your library first.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Target length") {
                    Stepper("\(targetMinutes) min", value: $targetMinutes, in: 5...300, step: 5)
                }

                Section("Tag minimums") {
                    ForEach($requirements) { $req in
                        HStack {
                            Menu {
                                ForEach(allTags, id: \.self) { tag in
                                    Button(tag) { req.tag = tag }
                                }
                            } label: {
                                Text(req.tag.isEmpty ? "Choose tag" : req.tag)
                                    .foregroundStyle(req.tag.isEmpty ? .secondary : .primary)
                            }
                            Spacer()
                            Stepper("at least \(req.count)", value: $req.count, in: 1...20)
                                .labelsHidden()
                            Text("\(req.count)").monospacedDigit().frame(width: 24)
                        }
                    }
                    .onDelete { requirements.remove(atOffsets: $0) }

                    Button("Add requirement") {
                        requirements.append(TagRequirement(tag: allTags.first ?? "", count: 1))
                    }
                    .disabled(allTags.isEmpty)
                }

                Section {
                    Button("Generate", action: generate)
                        .disabled(songs.isEmpty)
                        .accessibilityIdentifier("generateButton")
                }

                if let result {
                    GenerationResultView(
                        result: result,
                        onRegenerate: generate,
                        onSave: save
                    )
                }
            }
            .navigationTitle("Generate")
            .alert("Saved to archive", isPresented: $savedConfirmation) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func generate() {
        let criteria = GenerationCriteria(
            targetSeconds: targetMinutes * 60,
            tagMinimums: requirements.filter { !$0.tag.isEmpty },
            allowedTags: []
        )
        result = SessionGenerator().generate(
            from: songs.map(SongCandidate.init),
            criteria: criteria
        )
    }

    private func save() {
        guard let result else { return }
        let session = PracticeSession(title: defaultTitle, dateCreated: Date())
        context.insert(session)
        for (index, candidate) in result.entries.enumerated() {
            let entry = SessionEntry(position: index, candidate: candidate)
            entry.session = session
            context.insert(entry)
        }
        self.result = nil
        savedConfirmation = true
    }

    private var defaultTitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Session · \(formatter.string(from: Date()))"
    }
}
