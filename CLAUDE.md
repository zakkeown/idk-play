# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

IDK Play is a native iOS app (SwiftUI + SwiftData, iOS 17+) for musicians who practice along with external links (YouTube, Ultimate Guitar). You index songs, generate a practice session from light criteria, archive sessions to replay, and tap an entry to open its link in the native handler via `openURL`.

See `AGENTS.md` for contributor conventions (style, naming, commit/PR guidance); this file focuses on commands and architecture.

## Commands

The Xcode project is **generated** — never hand-edit `IDKPlay.xcodeproj`. Change `project.yml` and regenerate.

```sh
brew install xcodegen        # one-time
xcodegen generate            # regenerate IDKPlay.xcodeproj after editing project.yml, targets, sources, or assets
```

Build and test from the command line (pick a concrete simulator device name for `<device>`, e.g. `iPhone 15`):

```sh
xcodebuild build -scheme IDKPlay -destination 'platform=iOS Simulator,name=<device>'
xcodebuild test  -scheme IDKPlay -destination 'platform=iOS Simulator,name=<device>'
```

Run a single test by class or method with `-only-testing`:

```sh
xcodebuild test -scheme IDKPlay -destination 'platform=iOS Simulator,name=<device>' \
  -only-testing:IDKPlayTests/SessionGeneratorTests/respectsTimeCeiling
```

## Architecture

**Three tabs** (`RootView.swift`): Library (`Views/LibraryView.swift`, `SongEditView.swift`), Generate (`GenerateView.swift` → `GenerationResultView.swift`), Sessions (`SessionListView.swift` → `SessionDetailView.swift`).

**Data layer is SwiftData with CloudKit mirroring.** `IDKPlayApp.makeContainer()` builds a `ModelConfiguration(cloudKitDatabase: .automatic)` store and **falls back to a local-only store** when CloudKit is unavailable (e.g. simulator with no signed-in iCloud account). Real cross-device sync only activates in a build with a signing team that has the iCloud capability — see README for enabling it.

**The schema is "CloudKit-clean" by construction, and changes must keep it that way:** every `@Model` attribute has a default value, there are no `.unique` constraints, and relationships are optional with inverses (`PracticeSession.entries` ↔ `SessionEntry.session`). This is why models look verbose. Violating these rules breaks CloudKit mirroring and would require a migration.

**Two distinct data shapes for songs — this is intentional, not duplication:**
- `Song` (`Models/Song.swift`) is the editable library entry. Tags are stored inline (normalized: trimmed, lowercased) rather than as a relationship.
- `SessionEntry` (`Models/SessionEntry.swift`) is a **snapshot** copied into an archived `PracticeSession`. It deliberately does *not* hold a relationship to `Song` — an archived session is immutable history that stays stable and openable even if the source song is later edited or deleted. `songID` is a soft back-link only. "Go back and do it again" means replaying these exact snapshots, so generation criteria are not persisted on the session.

**The generator is a pure function, isolated from SwiftData on purpose.** `Generation/SessionGenerator.swift` operates on `SongCandidate` value snapshots (`Generation/SongCandidate.swift`) and `GenerationCriteria` (`Models/GenerationCriteria.swift`) — no `ModelContainer` needed, so it is trivially unit-testable. Keep new generation logic in this pure layer. Its semantics:
- **Per-tag minimums are hard floors**; the time target is a **hard ceiling** filled nearest-without-exceeding.
- A multi-tag song counts toward **every** tag's floor.
- Floors are filled **rarest-tag-first** (to avoid painting into infeasibility), preferring the candidate that covers the most still-pending floors.
- Pools are **shuffled** so repeat runs vary; the generic `generate(using:)` overload takes an injectable RNG for deterministic tests.
- Infeasible requests never loop or silently under-deliver — they return a best-effort list plus structured `GenerationResult.Shortfall` values.

## Tests

- Unit tests (`Tests/`) use the **Swift Testing** framework (`@Test`, `#expect`). `SessionGeneratorTests` covers the generator's contract: time ceiling, tag floors, multi-tag counting, rarest-first fill, shortfall reporting, and run-to-run variety.
- UI tests (`UITests/`) use **XCTest** for key user flows only (e.g. `GenerateFlowUITests`).
