import Foundation

/// A small cross-process hand-off. The Share Extension can't safely write the app's
/// CloudKit-backed SwiftData store, so instead it enqueues ``SongDraft``s into a JSON
/// file in the shared App Group container; the app drains them into SwiftData when it
/// next becomes active.
///
/// Reads and writes go through `NSFileCoordinator` so the extension writing and the
/// app draining can't corrupt the file. Storage is injectable so tests run against a
/// temp directory instead of the real container.
struct SharedImportQueue {
    /// Must match the `com.apple.security.application-groups` entry in both targets'
    /// entitlements.
    static let appGroupID = "group.com.idkplay.IDKPlay"
    private static let fileName = "pending-imports.json"

    let fileURL: URL
    private let coordinator = NSFileCoordinator()

    /// The real queue, backed by the shared App Group container, or `nil` if the
    /// container is unavailable (e.g. the app group isn't provisioned).
    static var shared: SharedImportQueue? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            .map(SharedImportQueue.init(directory:))
    }

    init(directory: URL) {
        self.fileURL = directory.appendingPathComponent(Self.fileName)
    }

    /// Append a draft, de-duplicating by id so an accidental double-enqueue (a retry)
    /// doesn't add the song twice.
    func enqueue(_ draft: SongDraft) {
        var pending = read()
        guard !pending.contains(where: { $0.id == draft.id }) else { return }
        pending.append(draft)
        write(pending)
    }

    /// Return every pending draft and clear the queue.
    func drain() -> [SongDraft] {
        let pending = dedup(read())
        write([])
        return pending
    }

    // MARK: - Coordinated file IO

    private func read() -> [SongDraft] {
        var result: [SongDraft] = []
        var coordinationError: NSError?
        coordinator.coordinate(readingItemAt: fileURL, options: [], error: &coordinationError) { url in
            guard let data = try? Data(contentsOf: url) else { return }
            result = (try? JSONDecoder().decode([SongDraft].self, from: data)) ?? []
        }
        return result
    }

    private func write(_ drafts: [SongDraft]) {
        var coordinationError: NSError?
        coordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: &coordinationError) { url in
            if drafts.isEmpty {
                try? FileManager.default.removeItem(at: url)
            } else if let data = try? JSONEncoder().encode(drafts) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    private func dedup(_ drafts: [SongDraft]) -> [SongDraft] {
        var seen = Set<UUID>()
        return drafts.filter { seen.insert($0.id).inserted }
    }
}
