import Foundation

/// Best-effort lookup of a YouTube video's length. Behind a protocol so the Share
/// Extension can inject a stub and so tests never hit the network — only the pure
/// parser (`YouTube.lengthSeconds(fromWatchPageHTML:)`) is exercised in tests.
protocol YouTubeDurationProviding {
    /// Seconds for the given video ID, or `nil` if it can't be determined.
    func durationSeconds(forVideoID id: String) async -> Int?
}

/// Live implementation: fetches the watch page with a desktop User-Agent (YouTube
/// serves leaner consent/variant markup to non-browser agents, where `lengthSeconds`
/// is often absent) and parses the embedded length. Best-effort and undocumented —
/// every failure path resolves to `nil`, leaving the user to enter the length.
struct YouTubeDurationFetcher: YouTubeDurationProviding {
    var session: URLSession = .shared
    var timeout: TimeInterval = 8

    func durationSeconds(forVideoID id: String) async -> Int? {
        guard let url = URL(string: "https://www.youtube.com/watch?v=\(id)") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
                + "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        guard let (data, _) = try? await session.data(for: request),
              let html = String(data: data, encoding: .utf8) else { return nil }
        return YouTube.lengthSeconds(fromWatchPageHTML: html)
    }
}
