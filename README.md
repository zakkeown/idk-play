# IDK Play

A native iOS app for musicians who practice along with external sources (YouTube,
Ultimate Guitar — anything with a link). Keep an index of songs, generate a practice
session from light criteria, archive sessions to do again, and tap a song to open its
link in whatever native handler owns it.

## Features

- **Library** — add songs as a link + title + length + tags. Manual entry; search and
  filter by tag.
- **Generate** — build a session from a **time ceiling** and **per-tag minimums**
  (e.g. "under 45 min, at least 3 jazz"). Floors are hard, the time target is a hard
  ceiling filled nearest-without-exceeding, and a multi-tag song counts toward every
  tag it carries. Infeasible requests return a best-effort list plus a clear shortfall.
- **Sessions** — generated lists are archived as fixed setlists. Open one to replay it;
  tapping an entry opens the link in the native handler (`openURL`).

## Stack

- SwiftUI + SwiftData, **iOS 17+**.
- CloudKit mirroring via `ModelConfiguration(cloudKitDatabase: .automatic)`, with a
  local-only fallback when CloudKit is unavailable.
- Project generated with [XcodeGen](https://github.com/yonsm/XcodeGen) from `project.yml`.

## Build

```sh
brew install xcodegen        # one-time
xcodegen generate            # produces IDKPlay.xcodeproj
open IDKPlay.xcodeproj        # then run on a simulator or device
```

### Enabling iCloud sync (your step)

Cross-device sync needs a signed build:

1. In Xcode, select the `IDKPlay` target → Signing & Capabilities → set your **Team**.
2. Change the bundle id and the iCloud container in `IDKPlay.entitlements` to your own
   reverse-domain (e.g. `iCloud.com.yourname.IDKPlay`).
3. Build to a device signed into iCloud. The SwiftData schema is CloudKit-clean
   (defaults everywhere, optional relationships with inverses, no unique constraints),
   so no migration is required.

## Tests

```sh
xcodebuild test -scheme IDKPlay -destination 'platform=iOS Simulator,name=<device>'
```

`SessionGeneratorTests` covers the generator: time ceiling, tag floors, multi-tag
counting, rarest-first fill, shortfall reporting, and run-to-run variety.
