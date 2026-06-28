import SwiftData

/// Move any drafts the Share Extension queued in the App Group container into the
/// SwiftData store. Called when the app becomes active (launch + foreground), so a
/// link shared while the app was backgrounded shows up the next time it's opened.
@MainActor
func drainPendingImports(from queue: SharedImportQueue? = .shared, into context: ModelContext) {
    guard let queue else { return }
    let drafts = queue.drain()
    guard !drafts.isEmpty else { return }
    for draft in drafts {
        context.insert(Song(draft: draft))
    }
    try? context.save()
}
