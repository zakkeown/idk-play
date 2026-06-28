import SwiftUI
import SwiftData

struct GenerateView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Song.dateAdded, order: .reverse) private var songs: [Song]

    @State private var targetMinutes = 30
    @State private var requirements: [TagRequirement] = []
    @State private var includeWarmup = false
    @State private var warmupSeeded = false
    @State private var session = EditableSession(entries: [])
    @State private var hasResult = false
    @State private var shortfalls: [GenerationResult.Shortfall] = []
    @State private var savedConfirmation = false

    private var allTags: [String] { songs.distinctTags }
    private var warmupTag: String? { WarmupTag.detect(in: allTags) }

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

                if let warmupTag {
                    Section {
                        Toggle(isOn: $includeWarmup) {
                            Text("Start with a warm-up")
                            Text("Lead with one “\(warmupTag)” song.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityIdentifier("warmupToggle")
                    }
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
                    Button(action: generate) {
                        Text("Generate")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                    }
                    .accessibilityIdentifier("generateButton")
                    .disabled(songs.isEmpty)
                    .listRowBackground(LinearGradient.brand)
                }

                if hasResult {
                    GenerationResultView(
                        session: $session,
                        shortfalls: shortfalls,
                        libraryCandidates: songs.map(SongCandidate.init),
                        onEdit: { shortfalls = [] },
                        onRegenerate: generate,
                        onSave: save
                    )
                }
            }
            .navigationTitle("Generate")
            .alert("Saved to archive", isPresented: $savedConfirmation) {
                Button("OK", role: .cancel) {}
            }
            .onAppear(perform: seedWarmupDefault)
            .onChange(of: warmupTag) { _, _ in seedWarmupDefault() }
        }
    }

    /// Default the warm-up toggle on the first time a warm-up tag appears, without
    /// clobbering the user's later choice as the library reloads.
    private func seedWarmupDefault() {
        guard !warmupSeeded, warmupTag != nil else { return }
        includeWarmup = true
        warmupSeeded = true
    }

    private func generate() {
        let criteria = GenerationCriteria(
            targetSeconds: targetMinutes * 60,
            tagMinimums: requirements.filter { !$0.tag.isEmpty },
            allowedTags: [],
            warmupTag: includeWarmup ? warmupTag : nil
        )
        let result = SessionGenerator().generate(
            from: songs.map(SongCandidate.init),
            criteria: criteria
        )
        session = EditableSession(result)
        shortfalls = result.shortfalls
        hasResult = true
    }

    private func save() {
        guard hasResult else { return }
        let practice = PracticeSession(title: defaultTitle, dateCreated: Date())
        context.insert(practice)
        for (index, candidate) in session.entries.enumerated() {
            let entry = SessionEntry(position: index, candidate: candidate)
            entry.session = practice
            context.insert(entry)
        }
        try? context.save()
        session = EditableSession(entries: [])
        hasResult = false
        shortfalls = []
        savedConfirmation = true
    }

    private var defaultTitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Session · \(formatter.string(from: Date()))"
    }
}
