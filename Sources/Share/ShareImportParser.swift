import Foundation

/// Turns whatever the share sheet hands over into a ``SongDraft``.
///
/// The inputs are deliberately messy: some apps attach a clean `public.url`, others
/// only a `public.plain-text` blob like `"Black Dog - YouTube https://…"`, and the
/// page title may or may not arrive separately. This is pure and synchronous; the
/// best-effort YouTube length lookup happens afterwards (see ``YouTubeDurationFetcher``).
struct ShareImportParser {

    /// Build a draft from any combination of an attached URL, a text blob, and an
    /// explicit title. Returns `nil` if no URL can be found in any of them.
    func draft(url providedURL: String? = nil, text: String? = nil, title providedTitle: String? = nil) -> SongDraft? {
        // Prefer an explicit URL attachment; otherwise dig one out of the text.
        let fromURL = Self.detectLink(in: providedURL)
        let fromText = Self.detectLink(in: text)
        guard let urlString = (fromURL ?? fromText)?.urlString else { return nil }

        let source = LinkSource(urlString: urlString) ?? .web
        let title = Self.bestTitle(
            providedTitle: providedTitle,
            textRemainder: fromText?.remainder,
            urlString: urlString,
            source: source
        )
        let tags = source.defaultTag.map { [$0] } ?? []
        return SongDraft(title: title, urlString: urlString, durationSeconds: 0, tags: tags)
    }

    // MARK: - URL extraction

    /// A link found in a string plus whatever text was left around it.
    struct DetectedLink: Equatable {
        let urlString: String
        let remainder: String
    }

    /// First http(s) link in a string — works whether the whole string is the URL or
    /// the URL is embedded in surrounding text. `remainder` is that text minus the link.
    static func detectLink(in string: String?) -> DetectedLink? {
        guard let string, !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let whole = NSRange(string.startIndex..<string.endIndex, in: string)
        guard let match = detector?.firstMatch(in: string, range: whole),
              let url = match.url, (url.scheme ?? "").hasPrefix("http"),
              let matchedRange = Range(match.range, in: string) else { return nil }

        var remainder = string
        remainder.removeSubrange(matchedRange)
        return DetectedLink(
            urlString: url.absoluteString,
            remainder: remainder.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    // MARK: - Title

    private static func bestTitle(
        providedTitle: String?,
        textRemainder: String?,
        urlString: String,
        source: LinkSource
    ) -> String {
        for candidate in [providedTitle, textRemainder] {
            if let cleaned = cleanTitle(candidate, source: source), !cleaned.isEmpty {
                return cleaned
            }
        }
        return fallbackTitle(urlString: urlString, source: source)
    }

    /// Trim whitespace and strip a trailing site-name suffix the share text or page
    /// title commonly tacks on (e.g. `"Black Dog - YouTube"`).
    static func cleanTitle(_ raw: String?, source: LinkSource) -> String? {
        guard var title = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { return nil }
        for suffix in source.titleSuffixes where title.hasSuffix(suffix) {
            title = String(title.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return title.isEmpty ? nil : title
    }

    /// When no usable title is available, fall back to the host for web links (a
    /// recognisable hint) and to empty for YouTube/UG (the user fills it in, or the
    /// length lookup can supply more later).
    static func fallbackTitle(urlString: String, source: LinkSource) -> String {
        switch source {
        case .web:
            guard let host = URL(string: urlString)?.host else { return "" }
            return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        case .youtube, .ultimateGuitar:
            return ""
        }
    }
}

private extension LinkSource {
    /// Trailing site-name suffixes worth stripping from a shared title.
    var titleSuffixes: [String] {
        switch self {
        case .youtube: return [" - YouTube", " - YouTube Music"]
        case .ultimateGuitar: return [" | Ultimate Guitar", " - Ultimate Guitar"]
        case .web: return []
        }
    }
}
