import Foundation

/// Where a shared link came from. Drives the tag applied automatically on import
/// and whether a YouTube length lookup is worth attempting.
///
/// Foundation-only by design: this and the rest of `Sources/Share` are compiled
/// into the Share Extension as well as the app, so nothing here may touch SwiftData.
enum LinkSource: Equatable {
    case youtube
    case ultimateGuitar
    case web

    init(url: URL) {
        let host = (url.host ?? "").lowercased()
        func matches(_ domain: String) -> Bool {
            host == domain || host.hasSuffix("." + domain)
        }
        if matches("youtube.com") || matches("youtu.be") || matches("youtube-nocookie.com") {
            self = .youtube
        } else if matches("ultimate-guitar.com") {
            self = .ultimateGuitar
        } else {
            self = .web
        }
    }

    /// Convenience for strings straight off the share sheet; `nil` if unparseable.
    init?(urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.host != nil else { return nil }
        self.init(url: url)
    }

    /// Tag applied automatically on import, or `nil` for a generic web link (where a
    /// host-based tag would just be noise).
    var defaultTag: String? {
        switch self {
        case .youtube: return "youtube"
        case .ultimateGuitar: return "ultimate-guitar"
        case .web: return nil
        }
    }
}
