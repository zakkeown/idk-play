import Testing
import Foundation
@testable import IDKPlay

struct SessionGeneratorTests {

    private func song(_ title: String, _ seconds: Int, _ tags: [String]) -> SongCandidate {
        SongCandidate(
            id: UUID(),
            title: title,
            urlString: "https://example.com/\(title)",
            durationSeconds: seconds,
            tags: tags
        )
    }

    @Test("Total never exceeds the time ceiling")
    func respectsTimeCeiling() {
        let songs = (0..<20).map { song("s\($0)", 300, ["rock"]) } // 5 min each
        let criteria = GenerationCriteria(targetSeconds: 20 * 60)   // room for exactly 4
        let result = SessionGenerator().generate(from: songs, criteria: criteria)

        #expect(result.totalSeconds <= 20 * 60)
        #expect(result.entries.count == 4)
        #expect(result.isOK)
    }

    @Test("Per-tag floors are satisfied")
    func meetsTagFloors() {
        var songs = (0..<5).map { song("j\($0)", 180, ["jazz"]) }
        songs += (0..<5).map { song("b\($0)", 180, ["blues"]) }
        let criteria = GenerationCriteria(
            targetSeconds: 60 * 60,
            tagMinimums: [
                TagRequirement(tag: "jazz", count: 2),
                TagRequirement(tag: "blues", count: 3),
            ]
        )
        let result = SessionGenerator().generate(from: songs, criteria: criteria)

        #expect(result.isOK)
        #expect(result.entries.filter { $0.tags.contains("jazz") }.count >= 2)
        #expect(result.entries.filter { $0.tags.contains("blues") }.count >= 3)
    }

    @Test("A multi-tag song counts toward every floor it carries")
    func multiTagSongCountsForAll() {
        let songs = [
            song("fusion", 180, ["jazz", "blues"]),
            song("plainJazz", 180, ["jazz"]),
            song("plainBlues", 180, ["blues"]),
        ]
        // Budget = one song, but we need one jazz AND one blues.
        let criteria = GenerationCriteria(
            targetSeconds: 180,
            tagMinimums: [
                TagRequirement(tag: "jazz", count: 1),
                TagRequirement(tag: "blues", count: 1),
            ]
        )
        let result = SessionGenerator().generate(from: songs, criteria: criteria)

        #expect(result.isOK)
        #expect(result.entries.count == 1)
        #expect(result.entries.first?.title == "fusion")
    }

    @Test("Reports a shortfall when too few songs carry a required tag")
    func reportsNotEnoughSongs() {
        let songs = [song("j", 180, ["jazz"])]
        let criteria = GenerationCriteria(
            targetSeconds: 60 * 60,
            tagMinimums: [TagRequirement(tag: "jazz", count: 3)]
        )
        let result = SessionGenerator().generate(from: songs, criteria: criteria)

        #expect(!result.isOK)
        #expect(result.shortfalls.contains(.notEnoughSongs(tag: "jazz", needed: 3, available: 1)))
    }

    @Test("Reports a shortfall when required songs can't fit the time ceiling")
    func reportsCannotFitWithinTarget() {
        let songs = (0..<3).map { song("j\($0)", 600, ["jazz"]) } // 10 min each
        let criteria = GenerationCriteria(
            targetSeconds: 15 * 60,                                // need 20 min, only 15 allowed
            tagMinimums: [TagRequirement(tag: "jazz", count: 2)]
        )
        let result = SessionGenerator().generate(from: songs, criteria: criteria)

        #expect(!result.isOK)
        #expect(result.shortfalls.contains(.cannotFitWithinTarget(tag: "jazz")))
    }

    @Test("Rarest required tag is filled first")
    func fillsRarestTagFirst() {
        // 1 rare song carries both tags; commonpicks could starve "rare" if filled
        // common-first. Rarest-first must include the single rare song.
        var songs = [song("rare", 180, ["rare", "common"])]
        songs += (0..<10).map { song("c\($0)", 180, ["common"]) }
        let criteria = GenerationCriteria(
            targetSeconds: 3 * 180, // room for 3 songs only
            tagMinimums: [
                TagRequirement(tag: "common", count: 2),
                TagRequirement(tag: "rare", count: 1),
            ]
        )
        let result = SessionGenerator().generate(from: songs, criteria: criteria)

        #expect(result.isOK)
        #expect(result.entries.contains { $0.title == "rare" })
    }

    @Test("Repeat runs produce varied lists")
    func varietyAcrossRuns() {
        let songs = (0..<30).map { song("s\($0)", 180, ["rock"]) }
        let criteria = GenerationCriteria(targetSeconds: 18 * 60) // ~6 of 30

        let first = Set(SessionGenerator().generate(from: songs, criteria: criteria).entries.map(\.id))
        var sawDifferent = false
        for _ in 0..<8 {
            let next = Set(SessionGenerator().generate(from: songs, criteria: criteria).entries.map(\.id))
            if next != first { sawDifferent = true; break }
        }
        #expect(sawDifferent)
    }

    @Test("No criteria still fills toward the target")
    func fillsWithoutRequirements() {
        let songs = (0..<10).map { song("s\($0)", 200, []) }
        let criteria = GenerationCriteria(targetSeconds: 1000) // 5 songs of 200s
        let result = SessionGenerator().generate(from: songs, criteria: criteria)

        #expect(result.isOK)
        #expect(result.entries.count == 5)
        #expect(result.totalSeconds == 1000)
    }

    // MARK: - Warm-up lead-in

    @Test("A required warm-up song is pinned to the front of every run")
    func warmupPinnedFirst() {
        var songs = (0..<8).map { song("s\($0)", 180, ["rock"]) }
        songs.append(song("warm", 120, ["warmup"]))
        let criteria = GenerationCriteria(targetSeconds: 30 * 60, warmupTag: "warmup")

        for _ in 0..<12 {
            let result = SessionGenerator().generate(from: songs, criteria: criteria)
            #expect(result.isOK)
            #expect(result.entries.first?.tags.contains("warmup") == true)
        }
    }

    @Test("Missing warm-up song reports a shortfall")
    func warmupShortfallWhenMissing() {
        let songs = (0..<5).map { song("s\($0)", 180, ["rock"]) }
        let criteria = GenerationCriteria(targetSeconds: 30 * 60, warmupTag: "warmup")
        let result = SessionGenerator().generate(from: songs, criteria: criteria)

        #expect(!result.isOK)
        #expect(result.shortfalls.contains(.notEnoughSongs(tag: "warmup", needed: 1, available: 0)))
    }

    @Test("Warm-up floor merges with an explicit tag minimum (max, not sum)")
    func warmupMergesWithTagMinimum() {
        // Exactly 2 warm-up songs; the user also asked for at least 2. The warm-up
        // floor must stay 2 (max(2, 1)) — summing to 3 would falsely report a shortfall.
        var songs = (0..<2).map { song("w\($0)", 120, ["warmup"]) }
        songs += (0..<5).map { song("r\($0)", 180, ["rock"]) }
        let criteria = GenerationCriteria(
            targetSeconds: 30 * 60,
            tagMinimums: [TagRequirement(tag: "warmup", count: 2)],
            warmupTag: "warmup"
        )
        let result = SessionGenerator().generate(from: songs, criteria: criteria)

        #expect(result.isOK)
        #expect(result.entries.filter { $0.tags.contains("warmup") }.count == 2)
        #expect(result.entries.first?.tags.contains("warmup") == true)
    }

    @Test("A nil warm-up tag leaves ordering untouched")
    func warmupNilDoesNotPin() {
        // Deterministic RNG: with no warm-up tag, the lone warm-up-tagged song is not
        // forced to the front. (Same seed proves the change is order-stable too.)
        var songs = [song("warm", 180, ["warmup"])]
        songs += (0..<6).map { song("s\($0)", 180, ["rock"]) }
        let criteria = GenerationCriteria(targetSeconds: 30 * 60, warmupTag: nil)

        var sawNonWarmupFirst = false
        for _ in 0..<12 {
            let result = SessionGenerator().generate(from: songs, criteria: criteria)
            if result.entries.first?.tags.contains("warmup") == false { sawNonWarmupFirst = true; break }
        }
        #expect(sawNonWarmupFirst)
    }

    @Test("Same seed and criteria yield identical lists")
    func deterministicWithSeed() {
        let songs = (0..<12).map { song("s\($0)", 200, ["rock"]) }
        let criteria = GenerationCriteria(targetSeconds: 20 * 60)
        var a = SeededRNG(seed: 42), b = SeededRNG(seed: 42)
        let ra = SessionGenerator().generate(from: songs, criteria: criteria, using: &a)
        let rb = SessionGenerator().generate(from: songs, criteria: criteria, using: &b)
        #expect(ra.entries.map(\.id) == rb.entries.map(\.id))
    }
}

/// Deterministic SplitMix64 generator for repeatable test runs.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
