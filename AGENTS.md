# Repository Guidelines

## Project Structure & Module Organization

`Sources/` contains the iOS app code. Major areas are `Views/` for SwiftUI screens, `Models/` for SwiftData models, `Generation/` for practice-session selection logic, `Components/` for reusable controls, and `Support/` for shared utilities and theme code. App assets live in `Sources/Assets.xcassets/`; the source icon artwork is in `design/icon.png`. Unit tests are in `Tests/`, and end-to-end UI coverage is in `UITests/`. Project configuration is declared in `project.yml` and generated into `IDKPlay.xcodeproj`.

## Build, Test, and Development Commands

- `brew install xcodegen`: install XcodeGen once if it is missing.
- `xcodegen generate`: regenerate `IDKPlay.xcodeproj` after changing `project.yml`, targets, assets, or build settings.
- `open IDKPlay.xcodeproj`: open the generated project in Xcode for local development.
- `xcodebuild build -scheme IDKPlay -destination 'platform=iOS Simulator,name=<device>'`: build from the command line.
- `xcodebuild test -scheme IDKPlay -destination 'platform=iOS Simulator,name=<device>'`: run unit and UI tests.

## Coding Style & Naming Conventions

Use Swift 5 with 4-space indentation and the existing SwiftUI style. Name types in `PascalCase`; name functions, properties, and local values in `camelCase`. Keep SwiftUI screens suffixed with `View`, reusable controls in `Components/`, and SwiftData entities in `Models/`. Prefer small, focused files that match the primary type name, such as `SessionGenerator.swift` or `SongEditView.swift`. Add comments only where they clarify non-obvious behavior, such as CloudKit fallback or UI-test intent.

## Testing Guidelines

Unit tests use the Swift Testing framework in `Tests/` with `@Test` and `#expect`. UI tests use XCTest in `UITests/`. Name tests for behavior, for example `respectsTimeCeiling` or `testAddGenerateSaveAndReplay`. Add generator and model tests for pure logic, and UI tests only for key user flows. Run `xcodebuild test` before submitting changes that affect app behavior.

## Commit & Pull Request Guidelines

Recent commits use short imperative subjects, such as `Add app icon and brand reskin`. Keep the first line specific and under roughly 72 characters; add details in the body when needed. Pull requests should describe the user-visible change, list tests run, link related issues, and include screenshots or simulator recordings for UI changes.

## Configuration Notes

Do not hand-edit generated Xcode project settings unless unavoidable; change `project.yml` and regenerate. iCloud sync requires a signing team plus matching bundle and CloudKit container values in `IDKPlay.entitlements`.
