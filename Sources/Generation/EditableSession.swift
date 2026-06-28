import Foundation

/// A mutable working copy of a generated list, edited on the Generate screen before
/// it is archived. Kept as a pure value type (no SwiftData) so reorder / add / remove
/// logic is unit-testable without a `ModelContainer`.
struct EditableSession {
    private(set) var entries: [SongCandidate]

    init(entries: [SongCandidate]) {
        self.entries = entries
    }

    init(_ result: GenerationResult) {
        self.init(entries: result.entries)
    }

    /// Live total of the current entries (recomputed as the user edits the list).
    var totalSeconds: Int {
        entries.reduce(0) { $0 + $1.durationSeconds }
    }

    /// Reorder entries (drag-to-sort).
    mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        entries.move(fromOffsets: source, toOffset: destination)
    }

    /// Remove entries (swipe-to-delete).
    mutating func remove(atOffsets offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
    }

    /// Append a candidate, ignoring it if one with the same id is already present.
    mutating func add(_ candidate: SongCandidate) {
        guard !entries.contains(where: { $0.id == candidate.id }) else { return }
        entries.append(candidate)
    }

    /// Library candidates not already in the list, sorted alphabetically by title —
    /// the pool offered by the "add song" control.
    func candidatesNotIncluded(from pool: [SongCandidate]) -> [SongCandidate] {
        let present = Set(entries.map(\.id))
        return pool
            .filter { !present.contains($0.id) }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}
