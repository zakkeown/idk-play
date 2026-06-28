import Foundation

/// Pure YouTube helpers: pulling the canonical video ID out of the many URL shapes
/// the share sheet emits, and reading the duration from a fetched watch page.
/// No networking here — that lives in ``YouTubeDurationFetcher``.
enum YouTube {

    /// The 11-character video ID for any recognised YouTube URL, else `nil`.
    /// Handles `watch?v=`, `youtu.be/ID`, and `shorts|embed|live|v/ID`, across the
    /// `www`/`m`/`music` sub-domains and ignoring trailing query params.
    static func videoID(from url: URL) -> String? {
        let host = (url.host ?? "").lowercased()
        let isYouTube = host == "youtu.be"
            || host == "youtube.com" || host.hasSuffix(".youtube.com")
            || host == "youtube-nocookie.com" || host.hasSuffix(".youtube-nocookie.com")
        guard isYouTube else { return nil }

        let pathParts = url.pathComponents.filter { $0 != "/" }

        // youtu.be/<id>
        if host == "youtu.be" {
            return pathParts.first.flatMap(validID)
        }
        // youtube.com/watch?v=<id>
        if let v = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "v" })?.value,
           let id = validID(v) {
            return id
        }
        // youtube.com/{shorts,embed,live,v}/<id>
        if pathParts.count >= 2,
           ["shorts", "embed", "live", "v"].contains(pathParts[0].lowercased()) {
            return validID(pathParts[1])
        }
        return nil
    }

    static func videoID(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return nil }
        return videoID(from: url)
    }

    /// First `"lengthSeconds":"…"` value embedded in a fetched watch page, else `nil`.
    /// Tolerates backslash-escaped quotes (the field also appears inside escaped
    /// JSON string literals). Markup is undocumented, so callers must fail soft.
    static func lengthSeconds(fromWatchPageHTML html: String) -> Int? {
        // Tolerate an optional backslash before every quote: the field appears both
        // plainly (`"lengthSeconds":"213"`) and inside escaped JSON string literals
        // (`\"lengthSeconds\":\"213\"`).
        let pattern = #"\\?"lengthSeconds\\?"\s*:\s*\\?"(\d+)\\?""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let group = Range(match.range(at: 1), in: html) else { return nil }
        return Int(html[group])
    }

    /// A leading run of valid ID characters, accepted only if it is exactly 11 long
    /// (the canonical YouTube ID length) — this also trims trailing path/query junk.
    private static func validID(_ raw: String) -> String? {
        let id = String(raw.prefix { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-") })
        return id.count == 11 ? id : nil
    }
}
