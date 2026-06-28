import Foundation
import SwiftData

/// Debug-only seeding, gated behind the `--seed-sample-data` launch argument, so
/// the app can be demoed/smoke-tested with realistic content. No effect in normal use.
enum SampleData {
    private static var args: [String] { ProcessInfo.processInfo.arguments }
    static var isSeedRequested: Bool { args.contains("--seed-sample-data") }
    static var isSeedSessionRequested: Bool { args.contains("--seed-sample-session") }

    static func seedIfNeeded(_ context: ModelContext) {
        if isSeedRequested { seedSongsIfEmpty(context) }
        if isSeedSessionRequested { seedSessionIfEmpty(context) }
    }

    private static func seedSongsIfEmpty(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Song>())) ?? 0
        guard existing == 0 else { return }
        for song in samples { context.insert(song) }
    }

    private static func seedSessionIfEmpty(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<PracticeSession>())) ?? 0
        guard existing == 0 else { return }
        let session = PracticeSession(title: "Warm-up + blues", dateCreated: Date())
        context.insert(session)
        for (index, song) in samples.prefix(4).enumerated() {
            let entry = SessionEntry(position: index, candidate: SongCandidate(song))
            entry.session = session
            context.insert(entry)
        }
    }

    static var samples: [Song] {
        [
            Song(title: "Autumn Leaves — comping study", urlString: "https://youtube.com/watch?v=aaa", durationSeconds: 312, tags: ["jazz", "comping"]),
            Song(title: "Blues in A — slow shuffle", urlString: "https://youtube.com/watch?v=bbb", durationSeconds: 254, tags: ["blues", "shuffle"]),
            Song(title: "Fingerstyle warm-up", urlString: "https://youtube.com/watch?v=ccc", durationSeconds: 188, tags: ["fingerstyle", "warmup"]),
            Song(title: "So What — modal vamp", urlString: "https://youtube.com/watch?v=ddd", durationSeconds: 540, tags: ["jazz", "modal"]),
            Song(title: "Texas blues licks", urlString: "https://youtube.com/watch?v=eee", durationSeconds: 366, tags: ["blues", "lead"]),
            Song(title: "Travis picking pattern", urlString: "https://ultimate-guitar.com/xyz", durationSeconds: 222, tags: ["fingerstyle", "technique"]),
        ]
    }
}
