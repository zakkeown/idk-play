import Testing
import Foundation
@testable import IDKPlay

struct EditableSessionTests {

    private func song(_ title: String, _ seconds: Int) -> SongCandidate {
        SongCandidate(
            id: UUID(),
            title: title,
            urlString: "https://example.com/\(title)",
            durationSeconds: seconds,
            tags: []
        )
    }

    @Test("Total reflects the current entries")
    func totalSums() {
        let session = EditableSession(entries: [song("a", 100), song("b", 200)])
        #expect(session.totalSeconds == 300)
    }

    @Test("Removing an entry updates entries and total")
    func removeUpdatesTotal() {
        var session = EditableSession(entries: [song("a", 100), song("b", 200), song("c", 50)])
        session.remove(atOffsets: IndexSet(integer: 1)) // drop "b"
        #expect(session.entries.map(\.title) == ["a", "c"])
        #expect(session.totalSeconds == 150)
    }

    @Test("Moving reorders entries")
    func moveReorders() {
        var session = EditableSession(entries: [song("a", 1), song("b", 1), song("c", 1)])
        session.move(fromOffsets: IndexSet(integer: 0), toOffset: 3) // a -> end
        #expect(session.entries.map(\.title) == ["b", "c", "a"])
    }

    @Test("Adding appends a new candidate")
    func addAppends() {
        var session = EditableSession(entries: [song("a", 100)])
        session.add(song("b", 200))
        #expect(session.entries.map(\.title) == ["a", "b"])
        #expect(session.totalSeconds == 300)
    }

    @Test("Adding a candidate already present is ignored")
    func addIgnoresDuplicateID() {
        let existing = song("a", 100)
        var session = EditableSession(entries: [existing])
        session.add(existing)
        #expect(session.entries.count == 1)
    }

    @Test("Available pool excludes included songs and is sorted alphabetically")
    func availableExcludesAndSorts() {
        let inList = song("Banana", 100)
        let session = EditableSession(entries: [inList])
        let pool = [song("delta", 1), inList, song("Alpha", 1), song("charlie", 1)]

        let available = session.candidatesNotIncluded(from: pool)
        #expect(available.map(\.title) == ["Alpha", "charlie", "delta"])
    }
}
