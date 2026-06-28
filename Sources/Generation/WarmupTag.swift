import Foundation

/// Recognizes the library's "warm up" tag so the Generate screen can offer to lead
/// every session with one. Tags are normalized (trimmed, lowercased) on entry, so we
/// only need to match a small set of spellings.
enum WarmupTag {
    /// Accepted spellings of the warm-up tag, in normalized form.
    static let recognized: Set<String> = ["warmup", "warm-up", "warm up"]

    /// The first recognized warm-up tag in `tags`, or `nil` if none is present.
    static func detect(in tags: [String]) -> String? {
        tags.first { recognized.contains($0) }
    }
}
