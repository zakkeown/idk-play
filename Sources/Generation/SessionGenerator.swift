import Foundation

/// The outcome of a generation run: the chosen songs, their total length, and
/// whether every constraint was satisfiable.
struct GenerationResult {
    enum Shortfall: Equatable {
        /// Fewer songs carry `tag` than the requested minimum.
        case notEnoughSongs(tag: String, needed: Int, available: Int)
        /// Enough songs exist, but the required ones can't fit under the time ceiling.
        case cannotFitWithinTarget(tag: String)

        var message: String {
            switch self {
            case let .notEnoughSongs(tag, needed, available):
                let s = available == 1 ? "" : "s"
                return "Only \(available) song\(s) tagged “\(tag)” (needed \(needed))."
            case let .cannotFitWithinTarget(tag):
                return "Couldn’t fit the required “\(tag)” songs within the time limit."
            }
        }
    }

    enum Status: Equatable {
        case ok
        case shortfall([Shortfall])
    }

    let entries: [SongCandidate]
    let totalSeconds: Int
    let status: Status

    var isOK: Bool { status == .ok }

    var shortfalls: [Shortfall] {
        if case let .shortfall(list) = status { return list }
        return []
    }
}

/// Builds a practice list from a pool of songs and light criteria.
///
/// Semantics (see the plan): per-tag minimums are **hard floors**, the target time
/// is a **hard ceiling** filled nearest-without-exceeding, a multi-tag song counts
/// toward every tag's floor, floors are filled rarest-tag-first to avoid painting
/// into infeasibility, and candidate pools are shuffled so repeat runs vary. If a
/// floor can't be met the result still returns a best-effort list plus a structured
/// shortfall — it never loops forever or silently under-delivers.
struct SessionGenerator {

    func generate(from songs: [SongCandidate], criteria: GenerationCriteria) -> GenerationResult {
        var rng = SystemRandomNumberGenerator()
        return generate(from: songs, criteria: criteria, using: &rng)
    }

    func generate<R: RandomNumberGenerator>(
        from songs: [SongCandidate],
        criteria: GenerationCriteria,
        using rng: inout R
    ) -> GenerationResult {
        let target = max(0, criteria.targetSeconds)

        // Pool honoring `allowedTags` (empty = any song is eligible).
        let allowed = Set(criteria.allowedTags)
        let pool = allowed.isEmpty
            ? songs
            : songs.filter { !Set($0.tags).isDisjoint(with: allowed) }

        // Collapse duplicate / empty requirements into a single count per tag.
        var requiredCounts: [String: Int] = [:]
        for req in criteria.tagMinimums where !req.tag.isEmpty && req.count > 0 {
            requiredCounts[req.tag, default: 0] += req.count
        }

        // A warm-up is a floor of one, merged with any explicit minimum for the same
        // tag via max (not sum) so requesting both doesn't over-require. The matching
        // song is later pinned to the front; here it just guarantees one gets picked.
        if let warmup = criteria.warmupTag, !warmup.isEmpty {
            requiredCounts[warmup] = max(requiredCounts[warmup] ?? 0, 1)
        }

        func availability(_ tag: String) -> Int {
            pool.reduce(0) { $0 + ($1.tags.contains(tag) ? 1 : 0) }
        }

        var selected: [SongCandidate] = []
        var selectedIDs: Set<UUID> = []
        var usedSeconds = 0
        var need = requiredCounts

        func fits(_ s: SongCandidate) -> Bool { usedSeconds + s.durationSeconds <= target }
        func take(_ s: SongCandidate) {
            selected.append(s)
            selectedIDs.insert(s.id)
            usedSeconds += s.durationSeconds
            for t in s.tags where need[t] != nil {
                need[t] = max(0, need[t]! - 1)
            }
        }
        // How many still-pending floors a song would help satisfy.
        func coverage(_ s: SongCandidate) -> Int {
            s.tags.reduce(0) { $0 + ((need[$1] ?? 0) > 0 ? 1 : 0) }
        }

        // 1. Satisfy floors, rarest tag first.
        let tagsByScarcity = requiredCounts.keys.sorted {
            let a = availability($0), b = availability($1)
            return a != b ? a < b : $0 < $1
        }
        for tag in tagsByScarcity {
            while (need[tag] ?? 0) > 0 {
                var candidates = pool.filter {
                    !selectedIDs.contains($0.id) && $0.tags.contains(tag) && fits($0)
                }
                if candidates.isEmpty { break } // can't meet this floor under budget
                candidates.shuffle(using: &rng)
                // Prefer the candidate covering the most pending floors; shuffle
                // first so ties break randomly (variety across runs).
                let best = candidates.max { coverage($0) < coverage($1) }!
                take(best)
            }
        }

        // 2. Fill remaining budget toward the ceiling. Repeat passes so smaller
        //    songs can slot into leftover time after larger ones.
        var fillPool = pool.filter { !selectedIDs.contains($0.id) }
        fillPool.shuffle(using: &rng)
        var addedSomething = true
        while addedSomething {
            addedSomething = false
            for s in fillPool where !selectedIDs.contains(s.id) && fits(s) {
                take(s)
                addedSomething = true
            }
        }

        // 3. Shuffle final order for a varied practice flow.
        selected.shuffle(using: &rng)

        // 3a. Pin a warm-up song to the front — done after the shuffle so it isn't
        //     undone. The floor in step 1 guarantees one was picked when available.
        if let warmup = criteria.warmupTag, !warmup.isEmpty,
           let idx = selected.firstIndex(where: { $0.tags.contains(warmup) }), idx != 0 {
            selected.insert(selected.remove(at: idx), at: 0)
        }

        // 4. Report any unmet floors.
        var shortfalls: [GenerationResult.Shortfall] = []
        for (tag, required) in requiredCounts {
            let avail = availability(tag)
            if avail < required {
                shortfalls.append(.notEnoughSongs(tag: tag, needed: required, available: avail))
            } else if (need[tag] ?? 0) > 0 {
                shortfalls.append(.cannotFitWithinTarget(tag: tag))
            }
        }
        shortfalls.sort { $0.message < $1.message }

        return GenerationResult(
            entries: selected,
            totalSeconds: usedSeconds,
            status: shortfalls.isEmpty ? .ok : .shortfall(shortfalls)
        )
    }
}
