import Foundation

/// A "include at least `count` songs tagged `tag`" floor.
struct TagRequirement: Identifiable, Hashable {
    var id = UUID()
    var tag: String = ""
    var count: Int = 1
}

/// Transient input to ``SessionGenerator`` (never persisted).
///
/// - `targetSeconds`: a hard time ceiling — the generated total must not exceed it.
/// - `tagMinimums`: hard floors — at least N songs carrying each tag.
/// - `allowedTags`: optional pool restriction; empty means any song is eligible.
struct GenerationCriteria: Equatable {
    var targetSeconds: Int = 30 * 60
    var tagMinimums: [TagRequirement] = []
    var allowedTags: [String] = []
}
