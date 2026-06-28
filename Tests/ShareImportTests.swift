import Testing
import Foundation
@testable import IDKPlay

/// Covers the pure import core that the Share Extension reuses: source detection,
/// YouTube ID/length parsing, building a ``SongDraft`` from the messy shapes the
/// share sheet hands over, and the cross-process hand-off queue. No SwiftData, no
/// network — the fragile parts live here, in tested code.
struct ShareImportTests {

    // MARK: - LinkSource

    @Test("Detects the source from the host, including sub-domains")
    func detectsSource() {
        #expect(LinkSource(urlString: "https://www.youtube.com/watch?v=abc") == .youtube)
        #expect(LinkSource(urlString: "https://m.youtube.com/watch?v=abc") == .youtube)
        #expect(LinkSource(urlString: "https://music.youtube.com/watch?v=abc") == .youtube)
        #expect(LinkSource(urlString: "https://youtu.be/abc") == .youtube)
        #expect(LinkSource(urlString: "https://tabs.ultimate-guitar.com/tab/x") == .ultimateGuitar)
        #expect(LinkSource(urlString: "https://www.ultimate-guitar.com/tab/x") == .ultimateGuitar)
        #expect(LinkSource(urlString: "https://example.com/song") == .web)
    }

    @Test("Each source maps to its default tag; generic web carries none")
    func sourceDefaultTags() {
        #expect(LinkSource.youtube.defaultTag == "youtube")
        #expect(LinkSource.ultimateGuitar.defaultTag == "ultimate-guitar")
        #expect(LinkSource.web.defaultTag == nil)
    }

    // MARK: - YouTube video ID

    @Test("Extracts the video ID from every common URL shape")
    func extractsVideoID() {
        let id = "dQw4w9WgXcQ"
        #expect(YouTube.videoID(from: "https://www.youtube.com/watch?v=\(id)") == id)
        #expect(YouTube.videoID(from: "https://www.youtube.com/watch?v=\(id)&t=42s&list=PL") == id)
        #expect(YouTube.videoID(from: "https://youtu.be/\(id)") == id)
        #expect(YouTube.videoID(from: "https://youtu.be/\(id)?t=42") == id)
        #expect(YouTube.videoID(from: "https://m.youtube.com/watch?v=\(id)") == id)
        #expect(YouTube.videoID(from: "https://www.youtube.com/shorts/\(id)") == id)
        #expect(YouTube.videoID(from: "https://www.youtube.com/embed/\(id)") == id)
        #expect(YouTube.videoID(from: "https://www.youtube.com/live/\(id)") == id)
    }

    @Test("Returns nil for non-YouTube or ID-less URLs")
    func videoIDNilWhenAbsent() {
        #expect(YouTube.videoID(from: "https://example.com/watch?v=dQw4w9WgXcQ") == nil)
        #expect(YouTube.videoID(from: "https://www.youtube.com/feed/subscriptions") == nil)
        #expect(YouTube.videoID(from: "not a url") == nil)
    }

    // MARK: - YouTube length parsing

    @Test("Parses lengthSeconds out of watch-page markup")
    func parsesLengthSeconds() {
        let html = #"...,"videoDetails":{"videoId":"abc","lengthSeconds":"213","keywords":..."#
        #expect(YouTube.lengthSeconds(fromWatchPageHTML: html) == 213)
    }

    @Test("Parses lengthSeconds even when the JSON quotes are backslash-escaped")
    func parsesEscapedLengthSeconds() {
        let html = #"<script>var x = "{\"lengthSeconds\":\"4096\"}";</script>"#
        #expect(YouTube.lengthSeconds(fromWatchPageHTML: html) == 4096)
    }

    @Test("Returns nil when no length is present")
    func lengthNilWhenAbsent() {
        #expect(YouTube.lengthSeconds(fromWatchPageHTML: "<html>no length here</html>") == nil)
    }

    // MARK: - ShareImportParser

    private let parser = ShareImportParser()

    @Test("A bare YouTube URL yields a youtube-tagged draft")
    func draftFromBareURL() {
        let draft = parser.draft(url: "https://youtu.be/dQw4w9WgXcQ")
        #expect(draft?.urlString == "https://youtu.be/dQw4w9WgXcQ")
        #expect(draft?.tags == ["youtube"])
        #expect(draft?.durationSeconds == 0)
    }

    @Test("An explicit title is used and its site-name suffix is stripped")
    func draftUsesProvidedTitle() {
        let draft = parser.draft(
            url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            title: "Black Dog - YouTube"
        )
        #expect(draft?.title == "Black Dog")
        #expect(draft?.tags == ["youtube"])
    }

    @Test("A URL is pulled out of a plain-text blob, and the rest becomes the title")
    func draftFromTextBlob() {
        // The shape several apps hand over: a title and the link in one text item.
        let draft = parser.draft(
            text: "Black Dog - YouTube https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        )
        #expect(draft?.urlString == "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        #expect(draft?.title == "Black Dog")
        #expect(draft?.tags == ["youtube"])
    }

    @Test("An explicit URL attachment wins over one embedded in text")
    func explicitURLWins() {
        let draft = parser.draft(
            url: "https://tabs.ultimate-guitar.com/tab/led-zeppelin/black-dog-chords-12345",
            text: "see https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        )
        #expect(draft?.tags == ["ultimate-guitar"])
        #expect(draft?.urlString.contains("ultimate-guitar.com") == true)
    }

    @Test("A generic web link carries no auto-tag and falls back to the host as title")
    func draftFromGenericWeb() {
        let draft = parser.draft(url: "https://songsterr.com/a/wsa/some-tab")
        #expect(draft?.tags == [])
        #expect(draft?.title == "songsterr.com")
    }

    @Test("Returns nil when no URL can be found in any input")
    func draftNilWithoutURL() {
        #expect(parser.draft(text: "just some text, no link") == nil)
        #expect(parser.draft() == nil)
    }

    // MARK: - SharedImportQueue

    private func tempQueue() -> SharedImportQueue {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("idkplay-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return SharedImportQueue(directory: dir)
    }

    @Test("Enqueue then drain returns the draft and empties the queue")
    func queueEnqueueDrain() {
        let queue = tempQueue()
        let draft = SongDraft(title: "Riff", urlString: "https://youtu.be/dQw4w9WgXcQ", tags: ["youtube"])
        queue.enqueue(draft)

        let drained = queue.drain()
        #expect(drained.count == 1)
        #expect(drained.first?.title == "Riff")
        #expect(queue.drain().isEmpty) // cleared after the first drain
    }

    @Test("Queued drafts survive across queue instances (persisted, not in-memory)")
    func queuePersists() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("idkplay-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        SharedImportQueue(directory: dir).enqueue(
            SongDraft(title: "A", urlString: "https://example.com/a")
        )
        let reopened = SharedImportQueue(directory: dir).drain()
        #expect(reopened.map(\.title) == ["A"])
    }

    @Test("Enqueuing the same draft twice de-duplicates by id")
    func queueDedupes() {
        let queue = tempQueue()
        let draft = SongDraft(title: "Once", urlString: "https://example.com/x")
        queue.enqueue(draft)
        queue.enqueue(draft) // e.g. a retry after a crash
        #expect(queue.drain().count == 1)
    }

    @Test("Distinct drafts both queue and drain in order")
    func queueKeepsDistinct() {
        let queue = tempQueue()
        queue.enqueue(SongDraft(title: "First", urlString: "https://example.com/1"))
        queue.enqueue(SongDraft(title: "Second", urlString: "https://example.com/2"))
        #expect(queue.drain().map(\.title) == ["First", "Second"])
    }
}
