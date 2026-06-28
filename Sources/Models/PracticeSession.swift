import Foundation
import SwiftData

/// An archived practice list — a fixed setlist of song snapshots.
///
/// "Go back and do it again" means *replaying these exact entries*, so the
/// generation criteria are intentionally not persisted here.
@Model
final class PracticeSession {
    var id: UUID = UUID()
    var title: String = ""
    var dateCreated: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \SessionEntry.session)
    var entries: [SessionEntry]?

    init(
        id: UUID = UUID(),
        title: String = "",
        dateCreated: Date = Date(),
        entries: [SessionEntry]? = []
    ) {
        self.id = id
        self.title = title
        self.dateCreated = dateCreated
        self.entries = entries
    }

    var sortedEntries: [SessionEntry] {
        (entries ?? []).sorted { $0.position < $1.position }
    }

    var totalSeconds: Int {
        (entries ?? []).reduce(0) { $0 + $1.durationSeconds }
    }
}
