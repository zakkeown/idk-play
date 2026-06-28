import Foundation
import SwiftData

/// A single entry in the user's practice library: an external link (YouTube,
/// Ultimate Guitar, anything with a URL) plus the metadata used to build sessions.
///
/// CloudKit-clean by construction: every stored attribute has a default and there
/// are no `.unique` constraints, so enabling CloudKit mirroring needs no migration.
@Model
final class Song {
    var id: UUID = UUID()
    var title: String = ""
    var urlString: String = ""
    var durationSeconds: Int = 0
    /// Normalized (trimmed, lowercased) tags. Stored inline rather than as a
    /// relationship to keep the model simple; the distinct-tag list is derived.
    var tags: [String] = []
    var dateAdded: Date = Date()
    var notes: String = ""

    init(
        id: UUID = UUID(),
        title: String = "",
        urlString: String = "",
        durationSeconds: Int = 0,
        tags: [String] = [],
        dateAdded: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.durationSeconds = durationSeconds
        self.tags = tags
        self.dateAdded = dateAdded
        self.notes = notes
    }

    var url: URL? { URL(string: urlString) }
}

extension Song {
    /// Build a library song from a shared-import draft. The draft type is
    /// SwiftData-free so the Share Extension can produce one; the app does this
    /// bridging step when it drains the import queue.
    convenience init(draft: SongDraft) {
        self.init(
            title: draft.title,
            urlString: draft.urlString,
            durationSeconds: draft.durationSeconds,
            tags: draft.tags
        )
    }
}
