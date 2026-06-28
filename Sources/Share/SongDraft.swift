import Foundation

/// A proposed library song produced from shared content, before it becomes a
/// SwiftData `Song`. `Codable` + Foundation-only so the Share Extension can build,
/// edit, and queue one without linking SwiftData; the app turns it into a `Song`
/// when it drains the queue (`Song(draft:)`).
struct SongDraft: Codable, Equatable, Identifiable {
    /// Stable across the encode→queue→decode→drain round-trip, so the drain step can
    /// de-duplicate if the same draft is enqueued twice (e.g. a retry after a crash).
    var id: UUID
    var title: String
    var urlString: String
    var durationSeconds: Int
    var tags: [String]

    init(
        id: UUID = UUID(),
        title: String,
        urlString: String,
        durationSeconds: Int = 0,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.durationSeconds = durationSeconds
        self.tags = tags
    }
}
