import Foundation
import SwiftData

/// A song *snapshot* captured inside an archived ``PracticeSession``.
///
/// Entries deliberately copy the song's data instead of holding a relationship to
/// ``Song``. An archived session is immutable history: it must stay stable and
/// openable even if the source song is later edited or deleted. `songID` is a soft
/// back-link only (no cascade), used to find the original if it still exists.
@Model
final class SessionEntry {
    var id: UUID = UUID()
    var position: Int = 0
    var title: String = ""
    var urlString: String = ""
    var durationSeconds: Int = 0
    var tags: [String] = []
    var songID: UUID?
    var session: PracticeSession?

    init(
        id: UUID = UUID(),
        position: Int = 0,
        title: String = "",
        urlString: String = "",
        durationSeconds: Int = 0,
        tags: [String] = [],
        songID: UUID? = nil
    ) {
        self.id = id
        self.position = position
        self.title = title
        self.urlString = urlString
        self.durationSeconds = durationSeconds
        self.tags = tags
        self.songID = songID
    }

    var url: URL? { URL(string: urlString) }
}

extension SessionEntry {
    /// Build an entry from a generated candidate, preserving its order.
    convenience init(position: Int, candidate: SongCandidate) {
        self.init(
            id: UUID(),
            position: position,
            title: candidate.title,
            urlString: candidate.urlString,
            durationSeconds: candidate.durationSeconds,
            tags: candidate.tags,
            songID: candidate.id
        )
    }
}
