import Foundation

/// A lightweight value snapshot of a ``Song`` consumed by ``SessionGenerator``.
///
/// Keeping the generator free of SwiftData types makes it a pure function over
/// plain values — trivial to unit test without a `ModelContainer`.
struct SongCandidate: Identifiable, Hashable {
    let id: UUID
    let title: String
    let urlString: String
    let durationSeconds: Int
    let tags: [String]
}

extension SongCandidate {
    init(_ song: Song) {
        self.init(
            id: song.id,
            title: song.title,
            urlString: song.urlString,
            durationSeconds: song.durationSeconds,
            tags: song.tags
        )
    }
}
